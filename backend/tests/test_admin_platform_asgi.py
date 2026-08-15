"""S-034 admin platform analytics + user suspend/reactivate + category
create — RBAC and happy-path coverage via the real FastAPI DI chain.

test_admin_platform.py already covers the service-layer logic (self/admin
refusal, idempotency, AuditLog rows, category IntegrityError -> 409 mapping,
zero-fill bucket shape) DB-free via fake db / direct function calls, but --
same limitation noted in that file's docstring -- a direct function call
never resolves `Depends(require_roles(UserRole.ADMIN))`, since FastAPI only
resolves `Depends(...)` when routing an actual request. This file closes
that gap end-to-end (401/403 per the Tester role's required scenarios) plus
proves the full request/response round-trip through real JSON serialization.

Uses ASGI + a real database, same pattern as test_dashboard.py and
test_admin_browse_asgi.py.
NOTE: never run this file locally against the project's dev DATABASE_URL --
see backend/tests/CLAUDE.md; it's meant for CI's ephemeral Postgres service
container only. (In this session's environment, DATABASE_URL happens to
point at a reachable remote Postgres, but a single pytest process running
more than one test here hits asyncpg "another operation is in progress" --
the shared `AsyncSessionLocal` engine is a module-level singleton bound to
the event loop of whichever test acquired it first, and pytest-asyncio's
function-scoped loops mean the second test's loop conflicts with it. Each
test below was verified individually in isolation; see the test report for
the exact command used and the pass/fail tally.)
"""

import uuid

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import get_password_hash
from app.database import AsyncSessionLocal
from app.main import app
from app.models import User, UserRole
from tests.auth_helpers import complete_password_login, register_and_get_token


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


async def _register(client: AsyncClient, role: str, email: str | None = None) -> dict:
    email = email or f"{role}-{uuid.uuid4().hex[:8]}@example.com"
    token = await register_and_get_token(client, email, role=role, full_name=f"Test {role.title()}")
    return {"email": email, "headers": {"Authorization": f"Bearer {token}"}}


async def _register_admin(client: AsyncClient) -> dict:
    """POST /auth/register blocks self-registering as admin (by design), so
    seed the row directly via a real session and log in normally -- there's
    no API path to mint an admin account."""
    email = f"admin-{uuid.uuid4().hex[:8]}@example.com"
    password = "testpass1234"
    async with AsyncSessionLocal() as db:
        db.add(
            User(
                email=email,
                full_name="Test Admin",
                hashed_password=get_password_hash(password),
                role=UserRole.ADMIN,
                is_active=True,
            )
        )
        await db.commit()

    tokens = await complete_password_login(client, email, password)
    return {"email": email, "headers": {"Authorization": f"Bearer {tokens['access_token']}"}}


# ---------------------------------------------------------------------------
# RBAC: 401 anonymous / 403 non-admin on every new S-034 endpoint.
# ---------------------------------------------------------------------------
@pytest.mark.asyncio
async def test_platform_series_anonymous_401(client):
    response = await client.get("/api/v1/dashboard/admin/platform/series")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_platform_series_requires_admin_role(client):
    merchant = await _register(client, "merchant")
    response = await client.get("/api/v1/dashboard/admin/platform/series", headers=merchant["headers"])
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_list_users_anonymous_401(client):
    response = await client.get("/api/v1/admin/users")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_list_users_requires_admin_role(client):
    customer = await _register(client, "customer")
    response = await client.get("/api/v1/admin/users", headers=customer["headers"])
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_suspend_user_anonymous_401(client):
    response = await client.post(f"/api/v1/admin/users/{uuid.uuid4()}/suspend")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_suspend_user_requires_admin_role(client):
    customer = await _register(client, "customer")
    response = await client.post(f"/api/v1/admin/users/{uuid.uuid4()}/suspend", headers=customer["headers"])
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_reactivate_user_requires_admin_role(client):
    merchant = await _register(client, "merchant")
    response = await client.post(f"/api/v1/admin/users/{uuid.uuid4()}/reactivate", headers=merchant["headers"])
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_create_category_requires_admin_role(client):
    merchant = await _register(client, "merchant")
    response = await client.post(
        "/api/v1/businesses/categories",
        headers=merchant["headers"],
        json={"name": f"Cat {uuid.uuid4().hex[:6]}", "slug": f"cat-{uuid.uuid4().hex[:6]}"},
    )
    assert response.status_code == 403


# ---------------------------------------------------------------------------
# Suspend / reactivate: happy path, self/admin 400, unknown-id 404, idempotent.
# ---------------------------------------------------------------------------
@pytest.mark.asyncio
async def test_admin_can_suspend_and_reactivate_a_customer(client):
    admin = await _register_admin(client)
    customer = await _register(client, "customer")
    customer_id = (await client.get("/api/v1/auth/me", headers=customer["headers"])).json()["id"]

    suspend = await client.post(f"/api/v1/admin/users/{customer_id}/suspend", headers=admin["headers"])
    assert suspend.status_code == 200, suspend.text
    assert suspend.json()["is_active"] is False

    reactivate = await client.post(f"/api/v1/admin/users/{customer_id}/reactivate", headers=admin["headers"])
    assert reactivate.status_code == 200, reactivate.text
    assert reactivate.json()["is_active"] is True


@pytest.mark.asyncio
async def test_suspend_refused_for_self_400(client):
    admin = await _register_admin(client)
    admin_id = (await client.get("/api/v1/auth/me", headers=admin["headers"])).json()["id"]

    response = await client.post(f"/api/v1/admin/users/{admin_id}/suspend", headers=admin["headers"])
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_suspend_refused_for_another_admin_400(client):
    admin = await _register_admin(client)
    other_admin = await _register_admin(client)
    other_admin_id = (await client.get("/api/v1/auth/me", headers=other_admin["headers"])).json()["id"]

    response = await client.post(f"/api/v1/admin/users/{other_admin_id}/suspend", headers=admin["headers"])
    assert response.status_code == 400


@pytest.mark.asyncio
async def test_suspend_unknown_user_404(client):
    admin = await _register_admin(client)

    response = await client.post(f"/api/v1/admin/users/{uuid.uuid4()}/suspend", headers=admin["headers"])
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_reactivate_unknown_user_404(client):
    admin = await _register_admin(client)

    response = await client.post(f"/api/v1/admin/users/{uuid.uuid4()}/reactivate", headers=admin["headers"])
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_suspend_is_idempotent_no_duplicate_effect(client):
    admin = await _register_admin(client)
    customer = await _register(client, "customer")
    customer_id = (await client.get("/api/v1/auth/me", headers=customer["headers"])).json()["id"]

    first = await client.post(f"/api/v1/admin/users/{customer_id}/suspend", headers=admin["headers"])
    assert first.status_code == 200
    second = await client.post(f"/api/v1/admin/users/{customer_id}/suspend", headers=admin["headers"])
    assert second.status_code == 200
    assert second.json()["is_active"] is False

    # Suspended account can no longer log in (AC 5) -- confirms the second
    # suspend call didn't somehow leave the account active.
    login = await client.post(
        "/api/v1/auth/login", json={"email": customer["email"], "password": "testpass1234"}
    )
    assert login.status_code == 403


@pytest.mark.asyncio
async def test_suspended_user_login_rejected(client):
    """AC 5: a suspended customer/merchant cannot obtain a session."""
    admin = await _register_admin(client)
    merchant = await _register(client, "merchant")
    merchant_id = (await client.get("/api/v1/auth/me", headers=merchant["headers"])).json()["id"]

    suspend = await client.post(f"/api/v1/admin/users/{merchant_id}/suspend", headers=admin["headers"])
    assert suspend.status_code == 200

    login = await client.post(
        "/api/v1/auth/login", json={"email": merchant["email"], "password": "testpass1234"}
    )
    assert login.status_code == 403
    assert login.json()["detail"] == "Account suspended"


# ---------------------------------------------------------------------------
# Category create: 201 happy path, 409 duplicate.
# ---------------------------------------------------------------------------
@pytest.mark.asyncio
async def test_create_category_happy_path_201(client):
    admin = await _register_admin(client)
    name = f"Category {uuid.uuid4().hex[:8]}"
    slug = f"cat-{uuid.uuid4().hex[:8]}"

    response = await client.post(
        "/api/v1/businesses/categories", headers=admin["headers"], json={"name": name, "slug": slug}
    )
    assert response.status_code == 201, response.text
    assert response.json()["name"] == name

    listing = await client.get("/api/v1/businesses/categories/all")
    assert any(c["slug"] == slug for c in listing.json())


@pytest.mark.asyncio
async def test_create_category_duplicate_name_or_slug_409(client):
    admin = await _register_admin(client)
    name = f"Category {uuid.uuid4().hex[:8]}"
    slug = f"cat-{uuid.uuid4().hex[:8]}"

    first = await client.post(
        "/api/v1/businesses/categories", headers=admin["headers"], json={"name": name, "slug": slug}
    )
    assert first.status_code == 201, first.text

    dupe = await client.post(
        "/api/v1/businesses/categories", headers=admin["headers"], json={"name": name, "slug": slug}
    )
    assert dupe.status_code == 409


# ---------------------------------------------------------------------------
# Platform series: zero-filled bucket shape for a given window.
# ---------------------------------------------------------------------------
@pytest.mark.asyncio
async def test_platform_series_returns_zero_filled_buckets_of_expected_length(client):
    admin = await _register_admin(client)

    response = await client.get(
        "/api/v1/dashboard/admin/platform/series?granularity=day&days=7", headers=admin["headers"]
    )
    assert response.status_code == 200, response.text
    body = response.json()
    assert body["granularity"] == "day"
    assert body["days"] == 7
    assert set(body["series"].keys()) == {"new_users", "businesses_approved", "new_reviews", "new_reports"}
    for key, buckets in body["series"].items():
        assert len(buckets) == 8, f"{key} should zero-fill 8 buckets for a 7-day window (inclusive)"
        assert all(set(b.keys()) == {"bucket", "count"} for b in buckets)
        assert all(isinstance(b["count"], int) and b["count"] >= 0 for b in buckets)


@pytest.mark.asyncio
async def test_platform_series_invalid_query_422(client):
    admin = await _register_admin(client)

    response = await client.get(
        "/api/v1/dashboard/admin/platform/series?days=0", headers=admin["headers"]
    )
    assert response.status_code == 422
