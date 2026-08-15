"""Search-cache invalidation on business-mutating endpoints. Calls the route
handlers directly with a fake db, following test_reviews.py's convention (no
real Postgres connection in this environment). The only thing under test is
that update_business/approve_business/suspend_business each call
cache_delete_pattern("search:*") -- response shape is already covered by
test_businesses_mine.py's integration-style tests.
"""

import uuid

from app.models import Business, BusinessStatus, User, UserRole
from app.routers import businesses as businesses_module
from app.schemas import BusinessUpdate


class FakeResult:
    def __init__(self, items):
        self._items = list(items)

    def scalar_one(self):
        return self._items[0]

    def scalar_one_or_none(self):
        # S-035's approve_business added a Merchant lookup (for the new
        # best-effort approval email) that this fake didn't support --
        # approve_business's own test below only cares about the search-cache
        # invalidation and status change, so no Merchant fixture rows are
        # seeded and this always resolves to "not found", same as it would
        # for a Business with no matching Merchant row in a real session.
        return self._items[0] if self._items else None


def _clause_matches(obj, clause) -> bool:
    if hasattr(clause, "clauses"):
        return all(_clause_matches(obj, c) for c in clause.clauses)
    return getattr(obj, clause.left.key, None) == clause.right.value


class FakeDB:
    def __init__(self, *, businesses=None):
        self.businesses = list(businesses or [])
        self.added: list[object] = []

    async def get(self, model, id_):
        if model is not Business:
            return None
        return next((b for b in self.businesses if b.id == id_), None)

    async def execute(self, stmt):
        items = list(self.businesses)
        wc = stmt.whereclause
        if wc is not None:
            items = [i for i in items if _clause_matches(i, wc)]
        return FakeResult(items)

    def add(self, obj):
        self.added.append(obj)


def _make_business(**overrides) -> Business:
    # Represents an already-persisted row, so the Python-side column
    # defaults (country/average_rating/review_count) that a real flush()
    # would apply are set explicitly here rather than left for the model.
    defaults = dict(
        id=uuid.uuid4(),
        merchant_id=uuid.uuid4(),
        name="Test Business",
        slug="test-business",
        address="1 Main St",
        city="Metropolis",
        country="US",
        average_rating=0.0,
        review_count=0,
        status=BusinessStatus.PENDING,
    )
    defaults.update(overrides)
    return Business(**defaults)


def _make_admin() -> User:
    return User(id=uuid.uuid4(), email="admin@example.com", full_name="Admin", role=UserRole.ADMIN, is_active=True)


async def test_update_business_invalidates_search_cache(monkeypatch):
    calls: list[str] = []

    async def fake_cache_delete(pattern):
        calls.append(pattern)

    monkeypatch.setattr(businesses_module, "cache_delete_pattern", fake_cache_delete)

    business = _make_business()
    admin = _make_admin()
    db = FakeDB(businesses=[business])

    # category_ids left None so the raw BusinessCategory delete/insert path
    # (an orthogonal codepath, not what this test is about) is skipped.
    await businesses_module.update_business(business.id, BusinessUpdate(name="New Name"), db, admin)

    assert calls == ["search:*"]


async def test_approve_business_invalidates_search_cache(monkeypatch):
    calls: list[str] = []

    async def fake_cache_delete(pattern):
        calls.append(pattern)

    monkeypatch.setattr(businesses_module, "cache_delete_pattern", fake_cache_delete)

    business = _make_business(status=BusinessStatus.PENDING)
    admin = _make_admin()
    db = FakeDB(businesses=[business])

    await businesses_module.approve_business(business.id, db, admin)

    assert calls == ["search:*"]
    assert business.status == BusinessStatus.APPROVED


async def test_suspend_business_invalidates_search_cache(monkeypatch):
    calls: list[str] = []

    async def fake_cache_delete(pattern):
        calls.append(pattern)

    monkeypatch.setattr(businesses_module, "cache_delete_pattern", fake_cache_delete)

    business = _make_business(status=BusinessStatus.APPROVED)
    admin = _make_admin()
    db = FakeDB(businesses=[business])

    await businesses_module.suspend_business(business.id, db, admin)

    assert calls == ["search:*"]
    assert business.status == BusinessStatus.SUSPENDED
