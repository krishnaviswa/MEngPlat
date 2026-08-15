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
from datetime import datetime, timedelta, timezone

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select

from app.core.security import get_password_hash
from app.database import AsyncSessionLocal
from app.main import app
from app.models import Review, User, UserRole
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
    # S-033 extended DashboardStats with rating_distribution + reply_rate.
    assert set(body.keys()) == {
        "total_reviews",
        "average_rating",
        "sentiment_breakdown",
        "recent_reviews",
        "review_volume_by_month",
        "rating_distribution",
        "reply_rate",
    }
    assert body["total_reviews"] == 0
    assert body["recent_reviews"] == []
    assert set(body["sentiment_breakdown"].keys()) == {"positive", "neutral", "negative"}
    # S-033 AC 8 / AC 5: zero reviews in range -> mix keys still "1"-"5" at 0, reply_rate null (not 0/0).
    assert set(body["rating_distribution"].keys()) == {"1", "2", "3", "4", "5"}
    assert all(v == 0 for v in body["rating_distribution"].values())
    assert body["reply_rate"] is None


@pytest.mark.asyncio
async def test_merchant_dashboard_range_filters_out_older_reviews(client):
    """S-033 AC 3 / AC 5: range=30 excludes a review created outside the
    window (rating mix + reply-rate), while range=all still counts it --
    proving the filter is real SQL on Review.created_at, not just present in
    the response shape."""
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])
    admin = await _register_admin(client)
    approve = await client.post(f"/api/v1/businesses/{business['id']}/approve", headers=admin["headers"])
    assert approve.status_code == 200, approve.text

    recent_customer = await _register(client, "customer")
    recent = await client.post(
        "/api/v1/reviews",
        headers=recent_customer["headers"],
        json={"business_id": business["id"], "rating": 5, "body": "Great place, recent review here."},
    )
    assert recent.status_code == 201, recent.text

    old_customer = await _register(client, "customer")
    old = await client.post(
        "/api/v1/reviews",
        headers=old_customer["headers"],
        json={"business_id": business["id"], "rating": 1, "body": "Old review, backdated by this test."},
    )
    assert old.status_code == 201, old.text

    # Backdate the second review's created_at directly -- the API always
    # writes "now", so this is the only way to get a review outside a 30-day
    # window without waiting 30 days.
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(Review).where(Review.id == uuid.UUID(old.json()["id"])))
        old_review = result.scalar_one()
        old_review.created_at = datetime.now(timezone.utc) - timedelta(days=60)
        await db.commit()

    range_all = await client.get(
        f"/api/v1/dashboard/merchant/{business['id']}?range=all", headers=owner["headers"]
    )
    assert range_all.status_code == 200
    all_mix = range_all.json()["rating_distribution"]
    assert sum(all_mix.values()) == 2

    range_30 = await client.get(
        f"/api/v1/dashboard/merchant/{business['id']}?range=30", headers=owner["headers"]
    )
    assert range_30.status_code == 200
    body_30 = range_30.json()
    mix_30 = body_30["rating_distribution"]
    assert sum(mix_30.values()) == 1
    assert mix_30["5"] == 1  # the recent review
    assert mix_30["1"] == 0  # the backdated one is excluded
    # Neither review in range=30 has a merchant reply.
    assert body_30["reply_rate"] == 0.0


@pytest.mark.asyncio
async def test_merchant_dashboard_invalid_range_422(client):
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])

    response = await client.get(
        f"/api/v1/dashboard/merchant/{business['id']}?range=bogus", headers=owner["headers"]
    )
    assert response.status_code == 422


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
