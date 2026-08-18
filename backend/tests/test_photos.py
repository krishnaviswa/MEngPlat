"""Photo upload RBAC/ownership -- regression coverage for the IDOR fix where
any authenticated user could upload/overwrite photos on a business they don't
own (see SECURITY_AUDIT.md)."""

import uuid

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app
from tests.auth_helpers import register_and_get_token

PNG_BYTES = (
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01"
    b"\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01"
    b"\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82"
)


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


async def _register(client: AsyncClient, role: str) -> dict:
    email = f"{role}-{uuid.uuid4().hex[:8]}@example.com"
    token = await register_and_get_token(client, email, role=role, full_name="Test User")
    return {"headers": {"Authorization": f"Bearer {token}"}}


async def _create_business(client: AsyncClient, merchant: dict) -> str:
    create = await client.post(
        "/api/v1/businesses",
        headers=merchant["headers"],
        json={
            "name": f"Photo Test Biz {uuid.uuid4().hex[:6]}",
            "address": "1 Main St",
            "city": "Chennai",
            "phone": "+919876500004",
            "email": "photo-test@example.com",
        },
    )
    assert create.status_code == 201, create.text
    return create.json()["id"]


def _photo_files():
    return {"file": ("logo.png", PNG_BYTES, "image/png")}


@pytest.mark.asyncio
async def test_photo_upload_by_owning_merchant_succeeds(client):
    merchant = await _register(client, "merchant")
    business_id = await _create_business(client, merchant)

    res = await client.post(
        "/api/v1/photos/upload",
        headers=merchant["headers"],
        data={"business_id": business_id, "photo_type": "gallery"},
        files=_photo_files(),
    )
    assert res.status_code == 201, res.text


@pytest.mark.asyncio
async def test_photo_upload_by_non_owning_merchant_is_forbidden(client):
    owner = await _register(client, "merchant")
    business_id = await _create_business(client, owner)
    other_merchant = await _register(client, "merchant")

    res = await client.post(
        "/api/v1/photos/upload",
        headers=other_merchant["headers"],
        data={"business_id": business_id, "photo_type": "logo"},
        files=_photo_files(),
    )
    assert res.status_code == 403, res.text


@pytest.mark.asyncio
async def test_photo_upload_by_customer_is_forbidden(client):
    owner = await _register(client, "merchant")
    business_id = await _create_business(client, owner)
    customer = await _register(client, "customer")

    res = await client.post(
        "/api/v1/photos/upload",
        headers=customer["headers"],
        data={"business_id": business_id, "photo_type": "storefront"},
        files=_photo_files(),
    )
    assert res.status_code == 403, res.text
