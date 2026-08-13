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
    assert response.headers["x-content-type-options"] == "nosniff"
    assert response.headers["x-frame-options"] == "DENY"
    assert "strict-transport-security" not in {k.lower() for k in response.headers}


@pytest.mark.asyncio
async def test_register_and_login(client):
    register = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "testuser@example.com",
            "full_name": "Test User",
            "password": "testpass1234",
            "role": "customer",
        },
    )
    assert register.status_code == 201

    from tests.auth_helpers import complete_password_login

    tokens = await complete_password_login(client, "testuser@example.com", "testpass1234")
    assert "access_token" in tokens
    assert "refresh_token" in tokens

@pytest.mark.asyncio
async def test_list_businesses(client):
    response = await client.get("/api/v1/businesses")
    assert response.status_code == 200
    assert isinstance(response.json(), list)


@pytest.mark.asyncio
async def test_list_cities(client):
    response = await client.get("/api/v1/businesses/cities")
    assert response.status_code == 200
    body = response.json()
    assert isinstance(body, list)
    assert all(isinstance(city, str) and city for city in body)
    assert body == sorted(body)
