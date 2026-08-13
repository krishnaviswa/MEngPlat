"""GET /businesses/admin/all and GET /reviews/admin/all (S-021) — RBAC and
happy-path coverage via the real FastAPI dependency-injection chain.

test_admin_browse.py already covers the route bodies' own query/filter logic
DB-free (fake db, direct function calls) but -- same limitation noted in that
file's docstring -- a direct function call never resolves
`Depends(require_roles(UserRole.ADMIN))`, since FastAPI only resolves
`Depends(...)` params when routing an actual request, not when a test calls
the Python function directly. This file closes that gap end-to-end (401/403
per the Tester role's required scenarios) plus proves the `business` summary
actually round-trips through real JSON serialization, not just the fake db.

Uses ASGI + a real database, same pattern as test_dashboard.py.
NOTE: never run this file locally against the project's dev DATABASE_URL --
see backend/tests/CLAUDE.md; it's meant for CI's ephemeral Postgres service
container only.
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


async def _create_business(client: AsyncClient, merchant_headers: dict) -> dict:
    res = await client.post(
        "/api/v1/businesses",
        headers=merchant_headers,
        json={"name": f"Admin Browse Test {uuid.uuid4().hex[:6]}", "address": "1 Main St", "city": "Chennai"},
    )
    assert res.status_code == 201, res.text
    return res.json()


@pytest.mark.asyncio
async def test_list_all_businesses_admin_requires_admin_role(client):
    customer = await _register(client, "customer")

    response = await client.get("/api/v1/businesses/admin/all", headers=customer["headers"])
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_list_all_businesses_admin_anonymous_401(client):
    response = await client.get("/api/v1/businesses/admin/all")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_list_all_businesses_admin_includes_pending_not_just_approved(client):
    merchant = await _register(client, "merchant")
    business = await _create_business(client, merchant["headers"])  # starts PENDING, never approved
    admin = await _register_admin(client)

    response = await client.get("/api/v1/businesses/admin/all?page_size=100", headers=admin["headers"])
    assert response.status_code == 200
    ids = {b["id"] for b in response.json()}
    assert business["id"] in ids

    # Distinct from the public list, which defaults to approved-only and so
    # must NOT surface this still-pending business.
    public = await client.get("/api/v1/businesses")
    assert business["id"] not in {b["id"] for b in public.json()}


@pytest.mark.asyncio
async def test_list_admin_reviews_requires_admin_role(client):
    merchant = await _register(client, "merchant")

    response = await client.get("/api/v1/reviews/admin/all", headers=merchant["headers"])
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_list_admin_reviews_anonymous_401(client):
    response = await client.get("/api/v1/reviews/admin/all")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_list_admin_reviews_carries_business_summary_and_scopes_by_business_id(client):
    merchant = await _register(client, "merchant")
    business = await _create_business(client, merchant["headers"])
    admin = await _register_admin(client)

    approve = await client.post(f"/api/v1/businesses/{business['id']}/approve", headers=admin["headers"])
    assert approve.status_code == 200, approve.text

    customer = await _register(client, "customer")
    review = await client.post(
        "/api/v1/reviews",
        headers=customer["headers"],
        json={"business_id": business["id"], "rating": 5, "body": "Great place, would come back again."},
    )
    assert review.status_code == 201, review.text

    scoped = await client.get(
        f"/api/v1/reviews/admin/all?business_id={business['id']}", headers=admin["headers"]
    )
    assert scoped.status_code == 200
    body = scoped.json()
    assert len(body) == 1
    assert body[0]["business"] is not None
    assert body[0]["business"]["id"] == business["id"]
    assert body[0]["business"]["name"] == business["name"]


@pytest.mark.asyncio
async def test_reported_reviews_now_carries_business_summary(client):
    """Regression for AC 5's note: /reviews/reported previously rendered
    reviews with no business name at all."""
    merchant = await _register(client, "merchant")
    business = await _create_business(client, merchant["headers"])
    admin = await _register_admin(client)
    await client.post(f"/api/v1/businesses/{business['id']}/approve", headers=admin["headers"])

    customer = await _register(client, "customer")
    review = await client.post(
        "/api/v1/reviews",
        headers=customer["headers"],
        json={"business_id": business["id"], "rating": 1, "body": "Not a great experience at all here."},
    )
    assert review.status_code == 201, review.text

    reporter = await _register(client, "customer")
    report = await client.post(
        f"/api/v1/reviews/{review.json()['id']}/report",
        headers=reporter["headers"],
        json={"reason": "This review looks fake and misleading."},
    )
    assert report.status_code == 200, report.text

    reported = await client.get("/api/v1/reviews/reported", headers=admin["headers"])
    assert reported.status_code == 200
    match = next(r for r in reported.json() if r["id"] == review.json()["id"])
    assert match["business"] is not None
    assert match["business"]["id"] == business["id"]
