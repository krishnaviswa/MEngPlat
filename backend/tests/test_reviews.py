"""Review create/like/report/reply route handlers.

Calls the route handlers directly with a fake db rather than going through
ASGI + a real database (none is reachable in this environment -- see
test_google_auth.py for the same constraint). Because the fake db never
performs real lazy-loading, it cannot reproduce the MissingGreenlet crash a
real async session would raise on an un-eager-loaded relationship access --
so the regression test for that (test_create_review_eager_loads_reply)
instead asserts on the SELECT statement's loader options directly: the bug
was a *missing* selectinload(Review.reply), and that's exactly what's
checked, independent of whether the db is real or fake.

FakeDB.refresh() does enforce one thing a real AsyncSession would: it raises
if called on an object that was never add()-ed and flush()-ed first, since a
real session raises InvalidRequestError in that case (this caught a genuine
missing-flush() bug in reply_to_review's new-reply path).
"""

import uuid
from datetime import datetime, timezone

import pytest
from fastapi import BackgroundTasks, HTTPException

from app.models import (
    Business,
    BusinessStatus,
    Merchant,
    Reply,
    Review,
    ReviewLike,
    ReviewReport,
    ReviewStatus,
    User,
    UserRole,
)
from app.routers import reviews as reviews_module
from app.schemas import ReplyCreate, ReviewCreate, ReviewReportCreate
from app.services.ai.base import AICallMeta, ReviewAnalysisResult


class FakeResult:
    def __init__(self, items):
        self._items = list(items)

    def scalar_one_or_none(self):
        return self._items[0] if self._items else None

    def scalar_one(self):
        return self._items[0]

    def scalars(self):
        return self

    def all(self):
        return self._items


def _clause_matches(obj, clause) -> bool:
    if hasattr(clause, "clauses"):
        return all(_clause_matches(obj, c) for c in clause.clauses)
    return getattr(obj, clause.left.key, None) == clause.right.value


def _apply_pending_defaults(obj) -> None:
    """Replicate the Python- and server-side column defaults a real flush
    (Review.status/like_count, Reply.created_at, ...) would apply -- same
    reason test_google_auth.py's FakeDB special-cases User.is_active."""
    if getattr(obj, "id", None) is None:
        obj.id = uuid.uuid4()
    if isinstance(obj, Review):
        if obj.status is None:
            obj.status = ReviewStatus.ACTIVE
        if obj.like_count is None:
            obj.like_count = 0
        if obj.created_at is None:
            obj.created_at = datetime.now(timezone.utc)
    elif isinstance(obj, Reply):
        if obj.created_at is None:
            obj.created_at = datetime.now(timezone.utc)


def _eager_loaded(stmt) -> set[str]:
    """Relationship attribute names the statement eager-loads via .options(selectinload(...))."""
    names: set[str] = set()
    for opt in getattr(stmt, "_with_options", ()):
        path = getattr(opt, "path", None)
        if path is None:
            continue
        for entry in path.path:
            key = getattr(entry, "key", None)
            if key:
                names.add(key)
    return names


class FakeDB:
    def __init__(self, *, businesses=None, merchants=None, reviews=None, likes=None, reports=None, replies=None):
        self.businesses = list(businesses or [])
        self.merchants = list(merchants or [])
        self.reviews = list(reviews or [])
        self.likes = list(likes or [])
        self.reports = list(reports or [])
        self.replies = list(replies or [])
        self.added: list[object] = []
        self.deleted: list[object] = []
        self.executed_statements: list[object] = []
        # Pre-seeded fixture rows represent existing DB state and are already
        # persistent; objects passed to add() need an intervening flush()
        # before refresh(), same as a real session enforces.
        self._persistent_ids = {
            id(o)
            for table in (self.businesses, self.merchants, self.reviews, self.likes, self.reports, self.replies)
            for o in table
        }

    def _table_for(self, model):
        return {
            Business: self.businesses,
            Merchant: self.merchants,
            Review: self.reviews,
            ReviewLike: self.likes,
            ReviewReport: self.reports,
            Reply: self.replies,
        }.get(model, [])

    async def get(self, model, id_, options=None):
        return next((o for o in self._table_for(model) if o.id == id_), None)

    async def execute(self, stmt):
        self.executed_statements.append(stmt)
        items = self._table_for(stmt.column_descriptions[0]["type"])
        wc = stmt.whereclause
        if wc is not None:
            items = [i for i in items if _clause_matches(i, wc)]
        return FakeResult(items)

    def add(self, obj):
        self.added.append(obj)
        for model, table in (
            (Business, self.businesses),
            (Merchant, self.merchants),
            (Review, self.reviews),
            (ReviewLike, self.likes),
            (ReviewReport, self.reports),
            (Reply, self.replies),
        ):
            if isinstance(obj, model):
                table.append(obj)
                break
        if isinstance(obj, Reply):
            # Real back_populates would sync review.reply the moment a flush
            # resolves the FK -- replicate that so reply_to_review's
            # `if review.reply:` branch sees a just-added reply on a second
            # call within the same test, same as it would in a real session.
            review = next((r for r in self.reviews if r.id == obj.review_id), None)
            if review is not None:
                review.reply = obj

    async def flush(self):
        for obj in self.added:
            _apply_pending_defaults(obj)
            self._persistent_ids.add(id(obj))

    async def refresh(self, obj):
        # Real SQLAlchemy raises InvalidRequestError if you refresh() an
        # object that was never flushed -- enforce the same here so a missing
        # flush() in route code fails the test instead of silently working.
        if id(obj) not in self._persistent_ids:
            raise AssertionError(
                "FakeDB.refresh() called on an object that was never added+flushed -- "
                "a real AsyncSession would raise InvalidRequestError here; add a flush() call"
            )
        _apply_pending_defaults(obj)

    async def delete(self, obj):
        self.deleted.append(obj)
        for table in (self.businesses, self.merchants, self.reviews, self.likes, self.reports, self.replies):
            if obj in table:
                table.remove(obj)


class FakeProvider:
    provider_name = "fake"

    def __init__(self, sentiment: str = "Positive"):
        self._sentiment = sentiment

    async def analyze_review_text(self, text, context=None):
        return ReviewAnalysisResult(
            sentiment=self._sentiment,
            summary="Great service",
            positives=["friendly staff"],
            complaints=[],
            suggested_response="Thanks for the kind words!",
            meta=AICallMeta(provider="fake"),
        )

    async def analyze_image(self, image_url, context=None):
        raise NotImplementedError

    async def generate_merchant_summary(self, reviews, context=None):
        raise NotImplementedError


def _make_business(**overrides) -> Business:
    defaults = dict(
        id=uuid.uuid4(),
        merchant_id=uuid.uuid4(),
        name="Test Biz",
        slug="test-biz",
        address="1 Main St",
        city="Metropolis",
        status=BusinessStatus.APPROVED,
    )
    defaults.update(overrides)
    return Business(**defaults)


def _make_user(role: UserRole = UserRole.CUSTOMER) -> User:
    return User(id=uuid.uuid4(), email="u@example.com", full_name="U", role=role, is_active=True)


@pytest.fixture(autouse=True)
def _patch_review_create_side_effects(monkeypatch):
    """create_review's downstream side effects (rating recalculation, cache
    busting, background AI summary refresh) aren't what these tests are
    about -- neuter them so each test only exercises the code path it names."""

    async def _noop_rating(db, business_id):
        pass

    async def _noop_cache(pattern):
        pass

    def _noop_bg(business_id):
        pass

    monkeypatch.setattr(reviews_module, "update_business_rating", _noop_rating)
    monkeypatch.setattr(reviews_module, "cache_delete_pattern", _noop_cache)
    monkeypatch.setattr(reviews_module, "refresh_merchant_ai_summary_bg", _noop_bg)
    yield


class TestCreateReview:
    async def test_succeeds_and_reply_is_none(self, monkeypatch):
        business = _make_business()
        user = _make_user()
        db = FakeDB(businesses=[business])
        monkeypatch.setattr(reviews_module, "get_ai_provider", lambda: FakeProvider())

        payload = ReviewCreate(business_id=business.id, rating=5, title="Great", body="Loved the service here")
        result = await reviews_module.create_review(payload, BackgroundTasks(), db, user)

        assert result.reply is None
        assert result.rating == 5
        assert result.status == ReviewStatus.ACTIVE

    async def test_eager_loads_reply(self, monkeypatch):
        """Regression test for Finding 0: the refetch query used to omit
        selectinload(Review.reply) while _review_response() unconditionally
        reads review.reply -- against a real async session that lazy-loads
        outside an active greenlet and 500s on every submission."""
        business = _make_business()
        user = _make_user()
        db = FakeDB(businesses=[business])
        monkeypatch.setattr(reviews_module, "get_ai_provider", lambda: FakeProvider())

        payload = ReviewCreate(business_id=business.id, rating=4, title=None, body="Pretty good overall")
        await reviews_module.create_review(payload, BackgroundTasks(), db, user)

        review_selects = [
            s for s in db.executed_statements if s.column_descriptions[0]["type"] is Review
        ]
        assert review_selects, "expected a SELECT against Review"
        assert "reply" in _eager_loaded(review_selects[-1])

    async def test_odd_sentiment_casing_does_not_raise(self, monkeypatch):
        """coerce_sentiment must normalize "Positive" before Sentiment(...)
        sees it -- an uncoerced value used to raise ValueError and roll back
        the just-created review via get_db's except-block."""
        business = _make_business()
        user = _make_user()
        db = FakeDB(businesses=[business])
        monkeypatch.setattr(reviews_module, "get_ai_provider", lambda: FakeProvider(sentiment="MIXED"))

        payload = ReviewCreate(business_id=business.id, rating=5, title=None, body="Works fine for me overall")
        await reviews_module.create_review(payload, BackgroundTasks(), db, user)  # must not raise

    async def test_missing_business_returns_404(self):
        db = FakeDB()
        user = _make_user()
        payload = ReviewCreate(business_id=uuid.uuid4(), rating=3, title=None, body="whatever body text")

        with pytest.raises(HTTPException) as exc_info:
            await reviews_module.create_review(payload, BackgroundTasks(), db, user)
        assert exc_info.value.status_code == 404

    async def test_owner_merchant_reviews_own_business_returns_403(self, monkeypatch):
        merchant_user = _make_user(role=UserRole.MERCHANT)
        business = _make_business()
        merchant = Merchant(id=business.merchant_id, user_id=merchant_user.id)
        db = FakeDB(businesses=[business], merchants=[merchant])
        monkeypatch.setattr(reviews_module, "get_ai_provider", lambda: FakeProvider())

        payload = ReviewCreate(
            business_id=business.id, rating=5, title="Great place", body="Loved my own café very much"
        )
        with pytest.raises(HTTPException) as exc_info:
            await reviews_module.create_review(payload, BackgroundTasks(), db, merchant_user)
        assert exc_info.value.status_code == 403
        assert exc_info.value.detail == "Cannot review your own business"

    async def test_merchant_reviews_other_business_succeeds(self, monkeypatch):
        merchant_user = _make_user(role=UserRole.MERCHANT)
        own_business = _make_business(name="Own Biz", slug="own-biz")
        other_business = _make_business(name="Other Biz", slug="other-biz")
        merchant = Merchant(id=own_business.merchant_id, user_id=merchant_user.id)
        db = FakeDB(businesses=[own_business, other_business], merchants=[merchant])
        monkeypatch.setattr(reviews_module, "get_ai_provider", lambda: FakeProvider())

        payload = ReviewCreate(
            business_id=other_business.id, rating=4, title="Nice spot", body="Good food and friendly staff here"
        )
        result = await reviews_module.create_review(payload, BackgroundTasks(), db, merchant_user)
        assert result.rating == 4
        assert result.business_id == other_business.id

    async def test_duplicate_review_returns_409(self, monkeypatch):
        user = _make_user()
        business = _make_business()
        existing = Review(
            id=uuid.uuid4(),
            business_id=business.id,
            author_id=user.id,
            rating=3,
            body="First review on this business",
        )
        db = FakeDB(businesses=[business], reviews=[existing])
        monkeypatch.setattr(reviews_module, "get_ai_provider", lambda: FakeProvider())

        payload = ReviewCreate(
            business_id=business.id, rating=5, title="Again", body="Trying to post a second review here"
        )
        with pytest.raises(HTTPException) as exc_info:
            await reviews_module.create_review(payload, BackgroundTasks(), db, user)
        assert exc_info.value.status_code == 409
        assert exc_info.value.detail == "You have already reviewed this business"

    async def test_different_users_can_review_same_business(self, monkeypatch):
        business = _make_business()
        user_a = _make_user()
        user_b = User(id=uuid.uuid4(), email="b@example.com", full_name="B", role=UserRole.CUSTOMER, is_active=True)
        db = FakeDB(businesses=[business])
        monkeypatch.setattr(reviews_module, "get_ai_provider", lambda: FakeProvider())

        payload_a = ReviewCreate(
            business_id=business.id, rating=5, title="Great", body="First customer loved this place a lot"
        )
        payload_b = ReviewCreate(
            business_id=business.id, rating=4, title="Good", body="Second customer also enjoyed the visit"
        )
        result_a = await reviews_module.create_review(payload_a, BackgroundTasks(), db, user_a)
        result_b = await reviews_module.create_review(payload_b, BackgroundTasks(), db, user_b)
        assert result_a.rating == 5
        assert result_b.rating == 4
        assert len([r for r in db.reviews if r.business_id == business.id]) == 2


class TestLikeReview:
    async def test_like_is_idempotent(self):
        business = _make_business()
        review = Review(
            id=uuid.uuid4(), business_id=business.id, author_id=uuid.uuid4(), rating=5, body="nice", like_count=0
        )
        user = _make_user()
        db = FakeDB(reviews=[review])

        await reviews_module.like_review(review.id, db, user)
        await reviews_module.like_review(review.id, db, user)

        assert review.like_count == 1
        assert len(db.likes) == 1

    async def test_missing_review_returns_404(self):
        db = FakeDB()
        user = _make_user()

        with pytest.raises(HTTPException) as exc_info:
            await reviews_module.like_review(uuid.uuid4(), db, user)
        assert exc_info.value.status_code == 404


class TestReportReview:
    async def test_report_sets_status_to_reported(self):
        business = _make_business()
        review = Review(id=uuid.uuid4(), business_id=business.id, author_id=uuid.uuid4(), rating=1, body="bad")
        user = _make_user()
        db = FakeDB(reviews=[review])

        result = await reviews_module.report_review(
            review.id, ReviewReportCreate(reason="This review is spam and abusive"), db, user
        )

        assert review.status == ReviewStatus.REPORTED
        assert len(db.reports) == 1
        assert result.message


class TestReplyToReview:
    async def test_non_owner_merchant_gets_403(self):
        business = _make_business()
        other_business = _make_business()
        review = Review(id=uuid.uuid4(), business_id=business.id, author_id=uuid.uuid4(), rating=5, body="great")
        merchant_user = _make_user(role=UserRole.MERCHANT)
        merchant = Merchant(id=other_business.merchant_id, user_id=merchant_user.id)
        db = FakeDB(businesses=[business, other_business], reviews=[review], merchants=[merchant])

        with pytest.raises(HTTPException) as exc_info:
            await reviews_module.reply_to_review(review.id, ReplyCreate(body="Thanks for the feedback"), db, merchant_user)
        assert exc_info.value.status_code == 403

    async def test_owner_can_reply_and_edit_in_place(self):
        business = _make_business()
        review = Review(id=uuid.uuid4(), business_id=business.id, author_id=uuid.uuid4(), rating=5, body="great")
        merchant_user = _make_user(role=UserRole.MERCHANT)
        merchant = Merchant(id=business.merchant_id, user_id=merchant_user.id)
        db = FakeDB(businesses=[business], reviews=[review], merchants=[merchant])

        first = await reviews_module.reply_to_review(
            review.id, ReplyCreate(body="Thanks for the feedback!"), db, merchant_user
        )
        assert first.body == "Thanks for the feedback!"
        assert len(db.replies) == 1

        second = await reviews_module.reply_to_review(
            review.id, ReplyCreate(body="Edited: thanks again!"), db, merchant_user
        )
        assert second.body == "Edited: thanks again!"
        assert len(db.replies) == 1, "editing an existing reply must not create a second row"
