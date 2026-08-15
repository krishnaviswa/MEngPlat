"""S-034: admin platform series, admin user suspend/reactivate, category
create conflict handling, and RBAC on the new `app/routers/admin.py` +
`GET /dashboard/admin/platform/series` endpoints.

Calls service functions / route handlers directly with a fake db (same
pattern as test_admin_browse.py) rather than ASGI + a real database -- none
is reliably reachable from this environment for multi-test runs (the shared
`AsyncSessionLocal` engine is a module-level singleton bound to the event
loop of whichever test used it first; pytest-asyncio's function-scoped event
loops mean a second async-DB test in the same process hits asyncpg
"another operation is in progress" / cross-loop errors -- a pre-existing
constraint of this test suite, not a product bug. See test_dashboard.py and
test_admin_browse_asgi.py for the same documented limitation). Endpoint-level
RBAC is proven here by invoking the exact same `require_roles(UserRole.ADMIN)`
dependency factory the routes declare, same technique as
test_admin_browse.py::TestAdminBrowseRBAC.
"""

from __future__ import annotations

import uuid
from datetime import date, datetime, timedelta, timezone

import pytest
from fastapi import HTTPException
from sqlalchemy.exc import IntegrityError

from app.dependencies import require_roles
from app.models import AuditLog, Category, User, UserRole
from app.routers import businesses as businesses_module
from app.schemas import CategoryCreate
from app.services import admin_users
from app.services.admin_users import SelfOrAdminTargetError
from app.services.platform_analytics import _zero_fill_buckets


def _make_user(role: UserRole = UserRole.CUSTOMER, *, is_active: bool = True, **overrides) -> User:
    defaults = dict(
        id=uuid.uuid4(),
        email=f"{role.value}-{uuid.uuid4().hex[:6]}@example.com",
        full_name=f"Test {role.value.title()}",
        role=role,
        is_active=is_active,
    )
    defaults.update(overrides)
    return User(**defaults)


def _make_admin(**overrides) -> User:
    return _make_user(UserRole.ADMIN, **overrides)


# ---------------------------------------------------------------------------
# RBAC: /admin/users, /admin/users/{id}/suspend|reactivate,
# /dashboard/admin/platform/series all gate on Depends(require_roles(UserRole.ADMIN)).
# A direct function call never resolves Depends(...), so this exercises the
# exact dependency factory those routes declare -- FastAPI would 403 the same
# way for a real request.
# ---------------------------------------------------------------------------
class TestAdminPlatformRBAC:
    @pytest.mark.parametrize("role", [UserRole.CUSTOMER, UserRole.MERCHANT])
    async def test_admin_only_dependency_rejects_non_admin_roles(self, role):
        checker = require_roles(UserRole.ADMIN)
        non_admin = _make_user(role)

        with pytest.raises(HTTPException) as exc_info:
            await checker(user=non_admin)

        assert exc_info.value.status_code == 403

    async def test_admin_only_dependency_allows_admin(self):
        checker = require_roles(UserRole.ADMIN)
        admin = _make_admin()

        result = await checker(user=admin)

        assert result is admin


# ---------------------------------------------------------------------------
# admin_users service: suspend / reactivate — self/admin refusal, 404 (via
# None target), idempotent no-op (no duplicate AuditLog), actual state change.
# ---------------------------------------------------------------------------
class FakeUsersDB:
    """Fakes just enough of AsyncSession for admin_users.py: `.get()` by pk
    and `.add()` for AuditLog rows (`.flush()` is a no-op — no IntegrityError
    path in this module)."""

    def __init__(self, users: dict):
        self._users = users
        self.added: list = []

    async def get(self, model, pk):
        assert model is User
        return self._users.get(pk)

    def add(self, obj):
        self.added.append(obj)

    async def flush(self):
        pass


class TestSuspendReactivateUser:
    async def test_suspend_refused_for_self(self):
        admin = _make_admin()
        db = FakeUsersDB({admin.id: admin})

        with pytest.raises(SelfOrAdminTargetError):
            await admin_users.suspend_user(db, admin.id, admin)
        assert db.added == []

    async def test_suspend_refused_for_another_admin(self):
        admin = _make_admin()
        other_admin = _make_admin()
        db = FakeUsersDB({admin.id: admin, other_admin.id: other_admin})

        with pytest.raises(SelfOrAdminTargetError):
            await admin_users.suspend_user(db, other_admin.id, admin)
        assert db.added == []

    async def test_reactivate_refused_for_self(self):
        admin = _make_admin()
        db = FakeUsersDB({admin.id: admin})

        with pytest.raises(SelfOrAdminTargetError):
            await admin_users.reactivate_user(db, admin.id, admin)
        assert db.added == []

    async def test_reactivate_refused_for_another_admin(self):
        admin = _make_admin()
        other_admin = _make_admin()
        db = FakeUsersDB({admin.id: admin, other_admin.id: other_admin})

        with pytest.raises(SelfOrAdminTargetError):
            await admin_users.reactivate_user(db, other_admin.id, admin)
        assert db.added == []

    async def test_suspend_unknown_user_returns_none(self):
        admin = _make_admin()
        db = FakeUsersDB({admin.id: admin})

        result = await admin_users.suspend_user(db, uuid.uuid4(), admin)

        assert result is None

    async def test_reactivate_unknown_user_returns_none(self):
        admin = _make_admin()
        db = FakeUsersDB({admin.id: admin})

        result = await admin_users.reactivate_user(db, uuid.uuid4(), admin)

        assert result is None

    async def test_suspend_flips_active_customer_and_writes_audit_log(self):
        admin = _make_admin()
        customer = _make_user(UserRole.CUSTOMER, is_active=True)
        db = FakeUsersDB({admin.id: admin, customer.id: customer})

        result = await admin_users.suspend_user(db, customer.id, admin)

        assert result is customer
        assert result.is_active is False
        assert len(db.added) == 1
        log = db.added[0]
        assert isinstance(log, AuditLog)
        assert log.action == "suspend"
        assert log.entity_type == "user"
        assert log.entity_id == str(customer.id)
        assert log.admin_id == admin.id

    async def test_reactivate_flips_inactive_merchant_and_writes_audit_log(self):
        admin = _make_admin()
        merchant = _make_user(UserRole.MERCHANT, is_active=False)
        db = FakeUsersDB({admin.id: admin, merchant.id: merchant})

        result = await admin_users.reactivate_user(db, merchant.id, admin)

        assert result is merchant
        assert result.is_active is True
        assert len(db.added) == 1
        assert db.added[0].action == "reactivate"

    async def test_suspend_already_inactive_is_idempotent_no_duplicate_audit_log(self):
        admin = _make_admin()
        already_suspended = _make_user(UserRole.CUSTOMER, is_active=False)
        db = FakeUsersDB({admin.id: admin, already_suspended.id: already_suspended})

        result = await admin_users.suspend_user(db, already_suspended.id, admin)

        assert result is already_suspended
        assert result.is_active is False
        assert db.added == []  # no-op: state didn't change, so no new AuditLog row

    async def test_reactivate_already_active_is_idempotent_no_duplicate_audit_log(self):
        admin = _make_admin()
        already_active = _make_user(UserRole.CUSTOMER, is_active=True)
        db = FakeUsersDB({admin.id: admin, already_active.id: already_active})

        result = await admin_users.reactivate_user(db, already_active.id, admin)

        assert result is already_active
        assert result.is_active is True
        assert db.added == []


# ---------------------------------------------------------------------------
# POST /businesses/categories — 409 on duplicate name/slug (IntegrityError ->
# HTTPException mapping), 201 happy path.
# ---------------------------------------------------------------------------
class FakeCategoryDB:
    """Fakes AsyncSession.add/flush/rollback/refresh for create_category.
    `raise_on_flush` simulates the unique-constraint violation Postgres would
    raise for a duplicate name/slug."""

    def __init__(self, *, raise_on_flush: bool = False):
        self.raise_on_flush = raise_on_flush
        self.added: list = []
        self.rolled_back = False
        self.refreshed: list = []

    def add(self, obj):
        self.added.append(obj)

    async def flush(self):
        if self.raise_on_flush:
            raise IntegrityError("INSERT INTO categories ...", {}, Exception("duplicate key"))

    async def rollback(self):
        self.rolled_back = True

    async def refresh(self, obj):
        self.refreshed.append(obj)


class TestCreateCategory:
    async def test_duplicate_name_or_slug_maps_to_409_not_500(self):
        admin = _make_admin()
        db = FakeCategoryDB(raise_on_flush=True)
        payload = CategoryCreate(name="Restaurants", slug="restaurants")

        with pytest.raises(HTTPException) as exc_info:
            await businesses_module.create_category(payload, db=db, admin=admin)

        assert exc_info.value.status_code == 409
        assert db.rolled_back is True

    async def test_happy_path_creates_category(self):
        admin = _make_admin()
        db = FakeCategoryDB(raise_on_flush=False)
        payload = CategoryCreate(name="Bakery", slug="bakery", description="Bread & pastries")

        result = await businesses_module.create_category(payload, db=db, admin=admin)

        assert isinstance(result, Category)
        assert result.name == "Bakery"
        assert result.slug == "bakery"
        assert len(db.added) == 1
        assert db.refreshed == [result]
        assert db.rolled_back is False


# ---------------------------------------------------------------------------
# platform_analytics: zero-fill bucket shape (pure function, no DB needed --
# the SQL aggregation itself was verified during Builder's own checks per the
# slice changelog; this proves the window math independent of that).
# ---------------------------------------------------------------------------
class TestZeroFillBuckets:
    def test_day_granularity_bucket_count_matches_window(self):
        now = datetime(2026, 8, 15, 12, 0, tzinfo=timezone.utc)
        days = 7
        cutoff = now - timedelta(days=days)

        buckets = _zero_fill_buckets(cutoff, now, "day")

        assert len(buckets) == days + 1  # inclusive of both endpoints
        assert buckets[0] == cutoff.date().isoformat()
        assert buckets[-1] == now.date().isoformat()
        # Strictly ascending, one calendar day apart.
        parsed = [date.fromisoformat(b) for b in buckets]
        assert parsed == sorted(parsed)
        assert all((b - a).days == 1 for a, b in zip(parsed, parsed[1:]))

    def test_week_granularity_buckets_land_on_mondays(self):
        now = datetime(2026, 8, 15, 12, 0, tzinfo=timezone.utc)  # a Saturday
        cutoff = now - timedelta(days=90)

        buckets = _zero_fill_buckets(cutoff, now, "week")

        assert len(buckets) > 0
        for b in buckets:
            assert date.fromisoformat(b).weekday() == 0  # Monday

    def test_zero_days_window_still_yields_at_least_one_bucket(self):
        now = datetime(2026, 8, 15, 12, 0, tzinfo=timezone.utc)
        cutoff = now  # days=... but same instant -- boundary case

        buckets = _zero_fill_buckets(cutoff, now, "day")

        assert buckets == [now.date().isoformat()]
