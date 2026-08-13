"""GET /dashboard/merchant/{id} and /dashboard/admin/platform.

Unlike most of this suite, these two endpoints aggregate over real SQL
(func.count, func.to_char, group_by) that isn't worth re-implementing in a
fake db -- doing so would just be testing the fake's SQL emulation, not the
route. Uses ASGI + a real database instead, same pattern as
test_businesses_mine.py. NOTE: never run this file locally against the
project's dev DATABASE_URL -- see backend/tests/CLAUDE.md; it's meant for
CI's ephemeral Postgres service container only.
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
        json={"name": f"Dash Test {uuid.uuid4().hex[:6]}", "address": "1 Main St", "city": "Chennai"},
    )
    assert res.status_code == 201, res.text
    return res.json()


@pytest.mark.asyncio
async def test_merchant_dashboard_requires_merchant_or_admin_role(client):
    customer = await _register(client, "customer")

    response = await client.get(
        f"/api/v1/dashboard/merchant/{uuid.uuid4()}", headers=customer["headers"]
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_merchant_dashboard_404s_for_missing_business(client):
    merchant = await _register(client, "merchant")

    response = await client.get(
        f"/api/v1/dashboard/merchant/{uuid.uuid4()}", headers=merchant["headers"]
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_merchant_dashboard_403s_for_non_owning_merchant(client):
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])
    other_merchant = await _register(client, "merchant")

    response = await client.get(
        f"/api/v1/dashboard/merchant/{business['id']}", headers=other_merchant["headers"]
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_merchant_dashboard_returns_stats_shape_for_owner(client):
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])

    response = await client.get(
        f"/api/v1/dashboard/merchant/{business['id']}", headers=owner["headers"]
    )
    assert response.status_code == 200
    body = response.json()
    assert set(body.keys()) == {
        "total_reviews",
        "average_rating",
        "sentiment_breakdown",
        "recent_reviews",
        "review_volume_by_month",
    }
    assert body["total_reviews"] == 0
    assert body["recent_reviews"] == []
    assert set(body["sentiment_breakdown"].keys()) == {"positive", "neutral", "negative"}


@pytest.mark.asyncio
async def test_platform_analytics_requires_admin_role(client):
    merchant = await _register(client, "merchant")

    response = await client.get("/api/v1/dashboard/admin/platform", headers=merchant["headers"])
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_platform_analytics_returns_counts_shape_for_admin(client):
    admin = await _register_admin(client)

    response = await client.get("/api/v1/dashboard/admin/platform", headers=admin["headers"])
    assert response.status_code == 200
    body = response.json()
    assert set(body.keys()) == {
        "total_users",
        "total_businesses",
        "pending_businesses",
        "total_reviews",
        "reported_reviews",
    }
    # Real, shared DB -- other tests contribute rows, so only non-negative
    # counts are asserted, not exact values.
    assert all(isinstance(v, int) and v >= 0 for v in body.values())
