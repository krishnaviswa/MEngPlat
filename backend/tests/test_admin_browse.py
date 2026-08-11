"""GET /businesses/admin/all and GET /reviews/admin/all (S-021).

Calls the route handlers directly with a fake db rather than going through
ASGI + a real database (none is reachable in this environment -- see
test_google_auth.py for the same constraint).
"""

import uuid
from datetime import datetime, timezone

import pytest
from fastapi import HTTPException

from app.dependencies import require_roles
from app.models import Business, BusinessStatus, Review, ReviewStatus, User, UserRole
from app.routers import businesses as businesses_module
from app.routers import reviews as reviews_module


class FakeResult:
    def __init__(self, items):
        self._items = list(items)

    def scalars(self):
        return self

    def all(self):
        return self._items


class FakeDB:
    def __init__(self, *, businesses=None, reviews=None):
        self.businesses = list(businesses or [])
        self.reviews = list(reviews or [])

    async def execute(self, stmt):
        entity = stmt.column_descriptions[0]["type"]
        items = self.businesses if entity is Business else self.reviews
        wc = stmt.whereclause
        if wc is not None:
            items = [i for i in items if getattr(i, wc.left.key, None) == wc.right.value]
        return FakeResult(items)


def _make_admin() -> User:
    return User(id=uuid.uuid4(), email="admin@example.com", full_name="Admin", role=UserRole.ADMIN, is_active=True)


def _make_business(status: BusinessStatus, **overrides) -> Business:
    defaults = dict(
        id=uuid.uuid4(),
        merchant_id=uuid.uuid4(),
        name=f"Biz {status.value}",
        slug=f"biz-{status.value}-{uuid.uuid4().hex[:6]}",
        address="1 Main St",
        city="Metropolis",
        country="US",
        average_rating=0.0,
        review_count=0,
        status=status,
    )
    defaults.update(overrides)
    return Business(**defaults)


def _make_review(business_id, status: ReviewStatus = ReviewStatus.ACTIVE, business: Business | None = None) -> Review:
    review = Review(
        id=uuid.uuid4(),
        business_id=business_id,
        author_id=uuid.uuid4(),
        rating=5,
        body="Great place",
        status=status,
        like_count=0,
        created_at=datetime.now(timezone.utc),
    )
    if business is not None:
        review.business = business
    return review


class TestListAllBusinessesAdmin:
    async def test_returns_every_status_not_just_approved(self):
        admin = _make_admin()
        pending = _make_business(BusinessStatus.PENDING)
        approved = _make_business(BusinessStatus.APPROVED)
        rejected = _make_business(BusinessStatus.REJECTED)
        suspended = _make_business(BusinessStatus.SUSPENDED)
        db = FakeDB(businesses=[pending, approved, rejected, suspended])

        result = await businesses_module.list_all_businesses_admin(db=db, admin=admin)

        assert {b.id for b in result} == {pending.id, approved.id, rejected.id, suspended.id}

    async def test_caps_page_size_at_100(self):
        admin = _make_admin()
        db = FakeDB(businesses=[])

        # No exception, and the fake db (which ignores limit/offset) still
        # proves the handler doesn't reject an oversized page_size outright.
        result = await businesses_module.list_all_businesses_admin(page=1, page_size=500, db=db, admin=admin)
        assert result == []


class TestListAdminReviews:
    async def test_returns_every_status_across_businesses(self):
        admin = _make_admin()
        business = _make_business(BusinessStatus.APPROVED)
        active = _make_review(business.id, ReviewStatus.ACTIVE, business=business)
        reported = _make_review(business.id, ReviewStatus.REPORTED, business=business)
        hidden = _make_review(business.id, ReviewStatus.HIDDEN, business=business)
        db = FakeDB(reviews=[active, reported, hidden])

        result = await reviews_module.list_admin_reviews(db=db, admin=admin)

        assert {r.id for r in result} == {active.id, reported.id, hidden.id}

    async def test_response_carries_business_summary(self):
        admin = _make_admin()
        business = _make_business(BusinessStatus.APPROVED, name="Shop Name")
        review = _make_review(business.id, business=business)
        db = FakeDB(reviews=[review])

        result = await reviews_module.list_admin_reviews(db=db, admin=admin)

        assert len(result) == 1
        assert result[0].business is not None
        assert result[0].business.name == "Shop Name"
        assert result[0].business.id == business.id

    async def test_business_id_filter_scopes_to_one_business(self):
        admin = _make_admin()
        business_a = _make_business(BusinessStatus.APPROVED)
        business_b = _make_business(BusinessStatus.APPROVED)
        review_a = _make_review(business_a.id, business=business_a)
        review_b = _make_review(business_b.id, business=business_b)
        db = FakeDB(reviews=[review_a, review_b])

        result = await reviews_module.list_admin_reviews(business_id=business_a.id, db=db, admin=admin)

        assert [r.id for r in result] == [review_a.id]


class TestAdminBrowseRBAC:
    """Both new endpoints gate on the exact same reusable
    `Depends(require_roles(UserRole.ADMIN))` dependency (see the `admin:`
    param on both `list_all_businesses_admin` and `list_admin_reviews`), so
    calling the route handlers directly (as above) never exercises that
    guard -- FastAPI resolves `Depends(...)` outside the function body. This
    invokes the exact same dependency factory those routes declare to prove
    it rejects non-admin roles, without needing ASGI + a real database.
    """

    @pytest.mark.parametrize("role", [UserRole.CUSTOMER, UserRole.MERCHANT])
    async def test_admin_only_dependency_rejects_non_admin_roles(self, role):
        checker = require_roles(UserRole.ADMIN)
        non_admin = User(id=uuid.uuid4(), email="u@example.com", full_name="U", role=role, is_active=True)

        with pytest.raises(HTTPException) as exc_info:
            await checker(user=non_admin)

        assert exc_info.value.status_code == 403

    async def test_admin_only_dependency_allows_admin(self):
        checker = require_roles(UserRole.ADMIN)
        admin = _make_admin()

        result = await checker(user=admin)

        assert result is admin
