"""S-079: admin "Processing" business status -- start-review / return-to-pending.

Router-level unit tests against a FakeDB (no live Postgres in this sandbox),
following test_businesses_cache_invalidation.py's convention.
"""

import uuid

import pytest
from fastapi import HTTPException

from app.models import AuditLog, Business, BusinessStatus, User, UserRole
from app.routers import businesses as businesses_module


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


# ---------------------------------------------------------------------------
# AC1: PENDING -> PROCESSING via start-review, with audit trail.
# ---------------------------------------------------------------------------


async def test_start_review_moves_pending_to_processing_and_writes_audit_log():
    business = _make_business(status=BusinessStatus.PENDING)
    admin = _make_admin()
    db = FakeDB(businesses=[business])

    result = await businesses_module.start_review(business.id, db, admin)

    assert result.status == "processing"
    assert business.status == BusinessStatus.PROCESSING
    assert len(db.added) == 1
    entry = db.added[0]
    assert isinstance(entry, AuditLog)
    assert entry.action == "start_review"
    assert entry.admin_id == admin.id
    assert entry.entity_id == str(business.id)


async def test_start_review_409s_when_business_is_not_pending():
    business = _make_business(status=BusinessStatus.APPROVED)
    admin = _make_admin()
    db = FakeDB(businesses=[business])

    with pytest.raises(HTTPException) as exc:
        await businesses_module.start_review(business.id, db, admin)

    assert exc.value.status_code == 409
    assert business.status == BusinessStatus.APPROVED
    assert db.added == []


async def test_start_review_404s_for_unknown_business():
    admin = _make_admin()
    db = FakeDB(businesses=[])

    with pytest.raises(HTTPException) as exc:
        await businesses_module.start_review(uuid.uuid4(), db, admin)

    assert exc.value.status_code == 404


# ---------------------------------------------------------------------------
# AC2: PROCESSING -> PENDING via return-to-pending, with audit trail.
# ---------------------------------------------------------------------------


async def test_return_to_pending_moves_processing_to_pending_and_writes_audit_log():
    business = _make_business(status=BusinessStatus.PROCESSING)
    admin = _make_admin()
    db = FakeDB(businesses=[business])

    result = await businesses_module.return_to_pending(business.id, db, admin)

    assert result.status == "pending"
    assert business.status == BusinessStatus.PENDING
    assert len(db.added) == 1
    entry = db.added[0]
    assert isinstance(entry, AuditLog)
    assert entry.action == "return_to_pending"
    assert entry.admin_id == admin.id


async def test_return_to_pending_409s_when_business_is_not_processing():
    business = _make_business(status=BusinessStatus.PENDING)
    admin = _make_admin()
    db = FakeDB(businesses=[business])

    with pytest.raises(HTTPException) as exc:
        await businesses_module.return_to_pending(business.id, db, admin)

    assert exc.value.status_code == 409
    assert business.status == BusinessStatus.PENDING
    assert db.added == []


async def test_return_to_pending_404s_for_unknown_business():
    admin = _make_admin()
    db = FakeDB(businesses=[])

    with pytest.raises(HTTPException) as exc:
        await businesses_module.return_to_pending(uuid.uuid4(), db, admin)

    assert exc.value.status_code == 404


# ---------------------------------------------------------------------------
# AC3/AC4: existing approve/suspend endpoints work unmodified from PROCESSING.
# ---------------------------------------------------------------------------


async def test_approve_business_from_processing_status(monkeypatch):
    async def fake_cache_delete(pattern):
        pass

    monkeypatch.setattr(businesses_module, "cache_delete_pattern", fake_cache_delete)

    business = _make_business(status=BusinessStatus.PROCESSING)
    admin = _make_admin()
    db = FakeDB(businesses=[business])

    await businesses_module.approve_business(business.id, db, admin)

    assert business.status == BusinessStatus.APPROVED


async def test_suspend_business_from_processing_status(monkeypatch):
    async def fake_cache_delete(pattern):
        pass

    monkeypatch.setattr(businesses_module, "cache_delete_pattern", fake_cache_delete)

    business = _make_business(status=BusinessStatus.PROCESSING)
    admin = _make_admin()
    db = FakeDB(businesses=[business])

    await businesses_module.suspend_business(business.id, db, admin)

    assert business.status == BusinessStatus.SUSPENDED
