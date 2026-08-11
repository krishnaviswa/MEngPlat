import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app
from tests.auth_helpers import register_and_get_token


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


async def _register_login(client: AsyncClient, email: str, role: str = "customer") -> str:
    return await register_and_get_token(client, email, role=role)

@pytest.mark.asyncio
async def test_patch_me_updates_name_and_ignores_role(client):
    token = await _register_login(client, "patchme@example.com")
    headers = {"Authorization": f"Bearer {token}"}

    res = await client.patch(
        "/api/v1/auth/me",
        headers=headers,
        json={"full_name": "Updated Name", "role": "admin", "email": "hacker@example.com"},
    )
    assert res.status_code == 200
    body = res.json()
    assert body["full_name"] == "Updated Name"
    assert body["role"] == "customer"
    assert body["email"] == "patchme@example.com"


@pytest.mark.asyncio
async def test_public_stats_summary_shape(client):
    res = await client.get("/api/v1/businesses/stats/summary")
    assert res.status_code == 200
    body = res.json()
    assert set(body.keys()) == {"total_businesses", "total_reviews", "total_categories", "total_cities"}
    assert "total_users" not in body
    assert "pending_businesses" not in body
    assert "reported_reviews" not in body


@pytest.mark.asyncio
async def test_favorites_requires_auth(client):
    res = await client.get("/api/v1/favorites")
    assert res.status_code == 401


@pytest.mark.asyncio
async def test_favorites_toggle_flow(client):
    token = await _register_login(client, "favuser@example.com")
    headers = {"Authorization": f"Bearer {token}"}

    businesses = await client.get("/api/v1/businesses")
    assert businesses.status_code == 200
    listing = businesses.json()
    if not listing:
        pytest.skip("No seeded businesses in test DB")

    business_id = listing[0]["id"]

    created = await client.post("/api/v1/favorites", headers=headers, json={"business_id": business_id})
    assert created.status_code == 201
    assert created.json()["favorited"] is True

    listed = await client.get("/api/v1/favorites", headers=headers)
    assert listed.status_code == 200
    assert any(b["id"] == business_id for b in listed.json())

    deleted = await client.delete(f"/api/v1/favorites/{business_id}", headers=headers)
    assert deleted.status_code == 204

    listed_after = await client.get("/api/v1/favorites", headers=headers)
    assert all(b["id"] != business_id for b in listed_after.json())


@pytest.mark.asyncio
async def test_search_accepts_sort_and_page(client):
    res = await client.get("/api/v1/search/businesses", params={"page": 1, "page_size": 5, "sort": "name"})
    assert res.status_code == 200
    assert isinstance(res.json(), list)
