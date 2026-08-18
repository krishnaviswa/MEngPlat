import uuid

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app
from tests.auth_helpers import register_and_get_token


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


async def _register_merchant(client: AsyncClient, email: str | None = None) -> dict:
    email = email or f"merchant-{uuid.uuid4().hex[:8]}@example.com"
    token = await register_and_get_token(
        client,
        email,
        role="merchant",
        full_name="Test Merchant",
    )
    return {"email": email, "headers": {"Authorization": f"Bearer {token}"}}


@pytest.mark.asyncio
async def test_mine_requires_merchant_role(client):
    email = f"customer-{uuid.uuid4().hex[:8]}@example.com"
    token = await register_and_get_token(client, email, role="customer", full_name="Customer")
    headers = {"Authorization": f"Bearer {token}"}

    response = await client.get("/api/v1/businesses/mine", headers=headers)
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_mine_returns_owned_businesses(client):
    merchant = await _register_merchant(client)
    create = await client.post(
        "/api/v1/businesses",
        headers=merchant["headers"],
        json={
            "name": "Mine Test Cafe",
            "address": "12 Main St",
            "city": "Chennai",
            "phone": "+919876500001",
            "email": "mine-test@example.com",
        },
    )
    assert create.status_code == 201
    created = create.json()

    mine = await client.get("/api/v1/businesses/mine", headers=merchant["headers"])
    assert mine.status_code == 200
    items = mine.json()
    assert isinstance(items, list)
    assert any(b["id"] == created["id"] and b["name"] == "Mine Test Cafe" for b in items)
    assert all(b["status"] == "pending" for b in items if b["id"] == created["id"])


@pytest.mark.asyncio
async def test_mine_empty_before_create(client):
    merchant = await _register_merchant(client)
    mine = await client.get("/api/v1/businesses/mine", headers=merchant["headers"])
    assert mine.status_code == 200
    assert mine.json() == []
