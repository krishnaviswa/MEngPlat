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


async def _create_approved_business(client: AsyncClient, name: str) -> dict:
    merchant_email = f"merchant-{uuid.uuid4().hex[:8]}@example.com"
    merchant_token = await register_and_get_token(
        client, merchant_email, role="merchant", full_name="Test Merchant"
    )
    create = await client.post(
        "/api/v1/businesses",
        headers={"Authorization": f"Bearer {merchant_token}"},
        json={"name": name, "address": "12 Main St", "city": "Chennai"},
    )
    assert create.status_code == 201, create.text
    created = create.json()

    admin_email = f"admin-{uuid.uuid4().hex[:8]}@example.com"
    admin_token = await register_and_get_token(client, admin_email, role="admin", full_name="Test Admin")
    approve = await client.post(
        f"/api/v1/businesses/{created['id']}/approve",
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert approve.status_code == 200, approve.text
    return approve.json()


@pytest.mark.asyncio
async def test_slugs_filter_returns_only_matching_businesses(client):
    suffix = uuid.uuid4().hex[:8]
    target = await _create_approved_business(client, f"Slug Filter Target {suffix}")
    await _create_approved_business(client, f"Slug Filter Other {suffix}")

    response = await client.get(f"/api/v1/businesses?slugs={target['slug']}")
    assert response.status_code == 200
    items = response.json()
    assert [b["slug"] for b in items] == [target["slug"]]


@pytest.mark.asyncio
async def test_slugs_filter_supports_comma_separated_list(client):
    suffix = uuid.uuid4().hex[:8]
    first = await _create_approved_business(client, f"Slug Filter A {suffix}")
    second = await _create_approved_business(client, f"Slug Filter B {suffix}")

    response = await client.get(f"/api/v1/businesses?slugs={first['slug']},{second['slug']}")
    assert response.status_code == 200
    returned_slugs = {b["slug"] for b in response.json()}
    assert returned_slugs == {first["slug"], second["slug"]}


@pytest.mark.asyncio
async def test_slugs_filter_with_unknown_slug_returns_empty(client):
    response = await client.get("/api/v1/businesses?slugs=no-such-business-slug-at-all")
    assert response.status_code == 200
    assert response.json() == []
