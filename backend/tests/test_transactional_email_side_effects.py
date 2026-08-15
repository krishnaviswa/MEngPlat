"""S-035: best-effort email + the in-app notification rows it rides beside
(AC 1, AC 3, AC 4).

Calls the route handlers directly with a fake db, same convention as
test_reviews.py / test_businesses_cache_invalidation.py (no real Postgres
connection assumed). Unlike those files' fakes, this one also tracks a
`users` table so `db.get(User, merchant.user_id)` -- the lookup S-035 added
to resolve a notification recipient's email address -- resolves to a real
row instead of always `None`.

AC 1's "send fails must not fail the core action" is exercised by patching
at the lowest safe boundary: `app.services.email.get_email_provider`, so the
*real* `try_send_listing_approved` / `try_send_new_review` run for real and
their own internal try/except is what's actually under test here (not a
mock standing in for that contract) -- the email-provider-level swallow
behavior itself is unit-tested directly in test_email_provider.py.
"""

import uuid
from datetime import datetime, timezone

import pytest
from fastapi import BackgroundTasks, HTTPException

from app.models import (
    AuditLog,
    Business,
    BusinessStatus,
    Merchant,
    Notification,
    NotificationType,
    Review,
    User,
    UserRole,
)
from app.routers import businesses as businesses_module
from app.routers import reviews as reviews_module
from app.schemas import ReviewCreate
from app.services.ai.base import AICallMeta, ReviewAnalysisResult
import app.services.email as email_module


class FakeResult:
    def __init__(self, items):
        self._items = list(items)

    def scalar_one(self):
        return self._items[0]

    def scalar_one_or_none(self):
        return self._items[0] if self._items else None


def _clause_matches(obj, clause) -> bool:
    if hasattr(clause, "clauses"):
        return all(_clause_matches(obj, c) for c in clause.clauses)
    return getattr(obj, clause.left.key, None) == clause.right.value


class FakeDB:
    def __init__(self, *, businesses=None, merchants=None, users=None, reviews=None):
        self.businesses = list(businesses or [])
        self.merchants = list(merchants or [])
        self.users = list(users or [])
        self.reviews = list(reviews or [])
        self.added: list[object] = []

    def _table_for(self, model):
        return {
            Business: self.businesses,
            Merchant: self.merchants,
            User: self.users,
            Review: self.reviews,
        }.get(model, [])

    async def get(self, model, id_, options=None):
        return next((o for o in self._table_for(model) if o.id == id_), None)

    async def execute(self, stmt):
        items = self._table_for(stmt.column_descriptions[0]["type"])
        wc = stmt.whereclause
        if wc is not None:
            items = [i for i in items if _clause_matches(i, wc)]
        return FakeResult(items)

    def add(self, obj):
        self.added.append(obj)
        if isinstance(obj, Review):
            self.reviews.append(obj)

    async def flush(self):
        for obj in self.added:
            if getattr(obj, "id", None) is None:
                obj.id = uuid.uuid4()
            if isinstance(obj, Review):
                if obj.status is None:
                    from app.models import ReviewStatus

                    obj.status = ReviewStatus.ACTIVE
                if obj.like_count is None:
                    obj.like_count = 0
                if obj.created_at is None:
                    obj.created_at = datetime.now(timezone.utc)

    async def refresh(self, obj):
        pass


class RaisingProvider:
    """Stands in for an email vendor that is down / errors on every send."""

    async def send(self, to, subject, text, html=None):
        raise RuntimeError("vendor unreachable")


class RecordingProvider:
    def __init__(self):
        self.sent: list[dict] = []

    async def send(self, to, subject, text, html=None):
        self.sent.append({"to": to, "subject": subject, "text": text})


def _make_business(**overrides) -> Business:
    # Represents an already-persisted row -- set the Python-side column
    # defaults a real flush() would apply (country/average_rating/review_count),
    # same as test_businesses_cache_invalidation.py's fixture.
    defaults = dict(
        id=uuid.uuid4(),
        merchant_id=uuid.uuid4(),
        name="Test Biz",
        slug="test-biz",
        address="1 Main St",
        city="Metropolis",
        country="US",
        average_rating=0.0,
        review_count=0,
        status=BusinessStatus.PENDING,
    )
    defaults.update(overrides)
    return Business(**defaults)


def _make_merchant_pair(business: Business, *, email: str = "owner@example.com"):
    merchant_user = User(id=uuid.uuid4(), email=email, full_name="Owner", role=UserRole.MERCHANT, is_active=True)
    merchant = Merchant(id=business.merchant_id, user_id=merchant_user.id)
    return merchant, merchant_user


def _make_admin() -> User:
    return User(id=uuid.uuid4(), email="admin@example.com", full_name="Admin", role=UserRole.ADMIN, is_active=True)


class FakeAIProvider:
    async def analyze_review_text(self, text, context=None):
        return ReviewAnalysisResult(
            sentiment="Positive",
            summary="Great",
            positives=["friendly"],
            complaints=[],
            suggested_response="Thanks!",
            meta=AICallMeta(provider="fake"),
        )


@pytest.fixture(autouse=True)
def _neuter_unrelated_side_effects(monkeypatch):
    """Search-cache busting / AI-summary debounce aren't what these tests
    are about -- silence them so failures point at email/notification logic."""

    async def _noop_cache(pattern):
        pass

    async def _noop_rating(db, business_id):
        pass

    def _noop_bg(business_id):
        pass

    monkeypatch.setattr(businesses_module, "cache_delete_pattern", _noop_cache)
    monkeypatch.setattr(reviews_module, "cache_delete_pattern", _noop_cache)
    monkeypatch.setattr(reviews_module, "update_business_rating", _noop_rating)
    monkeypatch.setattr(reviews_module, "refresh_merchant_ai_summary_bg", _noop_bg)
    monkeypatch.setattr(reviews_module, "get_ai_provider", lambda: FakeAIProvider())
    yield


# ---------------------------------------------------------------------------
# AC 3: approve_business must persist the previously-missing APPROVAL
# notification row, in addition to the best-effort email.
# ---------------------------------------------------------------------------
class TestApproveBusinessNotificationAndEmail:
    async def test_creates_approval_notification_row(self, monkeypatch):
        business = _make_business()
        merchant, merchant_user = _make_merchant_pair(business)
        admin = _make_admin()
        db = FakeDB(businesses=[business], merchants=[merchant], users=[merchant_user])
        monkeypatch.setattr(email_module, "get_email_provider", lambda: RecordingProvider())

        await businesses_module.approve_business(business.id, db, admin)

        notifications = [o for o in db.added if isinstance(o, Notification)]
        assert len(notifications) == 1
        assert notifications[0].type == NotificationType.APPROVAL
        assert notifications[0].user_id == merchant_user.id
        assert business.name in notifications[0].message

    async def test_creates_audit_log_row(self, monkeypatch):
        business = _make_business()
        merchant, merchant_user = _make_merchant_pair(business)
        admin = _make_admin()
        db = FakeDB(businesses=[business], merchants=[merchant], users=[merchant_user])
        monkeypatch.setattr(email_module, "get_email_provider", lambda: RecordingProvider())

        await businesses_module.approve_business(business.id, db, admin)

        audit_rows = [o for o in db.added if isinstance(o, AuditLog)]
        assert len(audit_rows) == 1
        assert audit_rows[0].action == "approve"

    async def test_sends_listing_approved_email_to_business_owner(self, monkeypatch):
        business = _make_business()
        merchant, merchant_user = _make_merchant_pair(business, email="owner@example.com")
        admin = _make_admin()
        db = FakeDB(businesses=[business], merchants=[merchant], users=[merchant_user])
        provider = RecordingProvider()
        monkeypatch.setattr(email_module, "get_email_provider", lambda: provider)

        await businesses_module.approve_business(business.id, db, admin)

        assert len(provider.sent) == 1
        assert provider.sent[0]["to"] == "owner@example.com"
        assert business.name in provider.sent[0]["subject"] or business.name in provider.sent[0]["text"]

    async def test_approve_succeeds_and_still_persists_notification_when_email_send_fails(self, monkeypatch):
        """AC 1: a vendor/send failure must never block the core action --
        the business is still approved and the in-app notification still
        lands, using the real try_send_listing_approved (not a mock of it)
        so its own catch-all-and-log contract is what's actually exercised."""
        business = _make_business()
        merchant, merchant_user = _make_merchant_pair(business)
        admin = _make_admin()
        db = FakeDB(businesses=[business], merchants=[merchant], users=[merchant_user])
        monkeypatch.setattr(email_module, "get_email_provider", lambda: RaisingProvider())

        response = await businesses_module.approve_business(business.id, db, admin)

        assert response.status == BusinessStatus.APPROVED
        assert business.status == BusinessStatus.APPROVED
        notifications = [o for o in db.added if isinstance(o, Notification)]
        assert len(notifications) == 1
        assert notifications[0].type == NotificationType.APPROVAL

    async def test_no_merchant_row_skips_notification_and_email_without_error(self, monkeypatch):
        """Orphan business (no Merchant row) -- approve must not 500."""
        business = _make_business()
        admin = _make_admin()
        db = FakeDB(businesses=[business])
        provider = RecordingProvider()
        monkeypatch.setattr(email_module, "get_email_provider", lambda: provider)

        response = await businesses_module.approve_business(business.id, db, admin)

        assert response.status == BusinessStatus.APPROVED
        assert provider.sent == []
        assert not any(isinstance(o, Notification) for o in db.added)


# ---------------------------------------------------------------------------
# AC 4: create_review must email the business owner (never the reviewer),
# in addition to the existing REVIEW notification.
# ---------------------------------------------------------------------------
class TestCreateReviewNotificationAndEmail:
    async def test_creates_review_notification_row(self, monkeypatch):
        business = _make_business(status=BusinessStatus.APPROVED)
        merchant, merchant_user = _make_merchant_pair(business)
        reviewer = User(
            id=uuid.uuid4(), email="reviewer@example.com", full_name="Reviewer", role=UserRole.CUSTOMER, is_active=True
        )
        db = FakeDB(businesses=[business], merchants=[merchant], users=[merchant_user, reviewer])
        monkeypatch.setattr(email_module, "get_email_provider", lambda: RecordingProvider())

        payload = ReviewCreate(business_id=business.id, rating=5, title="Great", body="Loved the service here")
        await reviews_module.create_review(payload, BackgroundTasks(), db, reviewer)

        notifications = [o for o in db.added if isinstance(o, Notification)]
        assert len(notifications) == 1
        assert notifications[0].type == NotificationType.REVIEW
        assert notifications[0].user_id == merchant_user.id

    async def test_emails_business_owner_not_the_reviewer(self, monkeypatch):
        business = _make_business(status=BusinessStatus.APPROVED)
        merchant, merchant_user = _make_merchant_pair(business, email="owner@example.com")
        reviewer = User(
            id=uuid.uuid4(), email="reviewer@example.com", full_name="Reviewer", role=UserRole.CUSTOMER, is_active=True
        )
        db = FakeDB(businesses=[business], merchants=[merchant], users=[merchant_user, reviewer])
        provider = RecordingProvider()
        monkeypatch.setattr(email_module, "get_email_provider", lambda: provider)

        payload = ReviewCreate(business_id=business.id, rating=4, title=None, body="Pretty good overall stay")
        await reviews_module.create_review(payload, BackgroundTasks(), db, reviewer)

        assert len(provider.sent) == 1
        assert provider.sent[0]["to"] == "owner@example.com"
        assert provider.sent[0]["to"] != reviewer.email

    async def test_create_review_succeeds_and_still_persists_notification_when_email_send_fails(self, monkeypatch):
        """AC 1: same best-effort contract on the review-create path."""
        business = _make_business(status=BusinessStatus.APPROVED)
        merchant, merchant_user = _make_merchant_pair(business)
        reviewer = User(
            id=uuid.uuid4(), email="reviewer@example.com", full_name="Reviewer", role=UserRole.CUSTOMER, is_active=True
        )
        db = FakeDB(businesses=[business], merchants=[merchant], users=[merchant_user, reviewer])
        monkeypatch.setattr(email_module, "get_email_provider", lambda: RaisingProvider())

        payload = ReviewCreate(business_id=business.id, rating=3, title=None, body="It was fine overall I guess")
        result = await reviews_module.create_review(payload, BackgroundTasks(), db, reviewer)

        assert result.rating == 3
        assert any(r for r in db.reviews if r.id == result.id)
        notifications = [o for o in db.added if isinstance(o, Notification)]
        assert len(notifications) == 1
        assert notifications[0].type == NotificationType.REVIEW
