import uuid

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


async def _register_merchant(client: AsyncClient, email: str | None = None) -> dict:
    email = email or f"merchant-{uuid.uuid4().hex[:8]}@example.com"
    res = await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "full_name": "Test Merchant",
            "password": "testpass123",
            "role": "merchant",
        },
    )
    assert res.status_code == 201
    login = await client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": "testpass123"},
    )
    assert login.status_code == 200
    token = login.json()["access_token"]
    return {"email": email, "headers": {"Authorization": f"Bearer {token}"}}


@pytest.mark.asyncio
async def test_mine_requires_merchant_role(client):
    email = f"customer-{uuid.uuid4().hex[:8]}@example.com"
    register = await client.post(
        "/api/v1/auth/register",
        json={
            "email": email,
            "full_name": "Customer",
            "password": "testpass123",
            "role": "customer",
        },
    )
    assert register.status_code == 201
    login = await client.post(
        "/api/v1/auth/login",
        json={"email": email, "password": "testpass123"},
    )
    headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

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
