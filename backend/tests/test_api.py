import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_health(client):
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


@pytest.mark.asyncio
async def test_register_and_login(client):
    register = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "testuser@example.com",
            "full_name": "Test User",
            "password": "testpass123",
            "role": "customer",
        },
    )
    assert register.status_code == 201

    login = await client.post(
        "/api/v1/auth/login",
        json={"email": "testuser@example.com", "password": "testpass123"},
    )
    assert login.status_code == 200
    assert "access_token" in login.json()


@pytest.mark.asyncio
async def test_list_businesses(client):
    response = await client.get("/api/v1/businesses")
    assert response.status_code == 200
    assert isinstance(response.json(), list)
