"""Step-up reauth + email change on PATCH /auth/me."""

from __future__ import annotations

import uuid

import pytest
from httpx import ASGITransport, AsyncClient

from app.core.security import decode_token
from app.main import app
from tests.auth_helpers import register_and_get_token


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_email_change_requires_reauth_then_succeeds(client):
    email = f"reauth-{uuid.uuid4().hex[:8]}@example.com"
    password = "testpass1234"
    token = await register_and_get_token(client, email, password=password)
    headers = {"Authorization": f"Bearer {token}"}

    blocked = await client.patch(
        "/api/v1/auth/me",
        headers=headers,
        json={"email": f"new-{uuid.uuid4().hex[:8]}@example.com"},
    )
    assert blocked.status_code == 401
    me = await client.get("/api/v1/auth/me", headers=headers)
    assert me.json()["email"] == email

    reauth = await client.post("/api/v1/auth/reauth", headers=headers, json={"password": password})
    assert reauth.status_code == 200, reauth.text
    reauth_token = reauth.json()["reauth_token"]
    claims = decode_token(reauth_token)
    assert claims.get("type") == "reauth"

    new_email = f"changed-{uuid.uuid4().hex[:8]}@example.com"
    patched = await client.patch(
        "/api/v1/auth/me",
        headers=headers,
        params={"reauth_token": reauth_token},
        json={"email": new_email},
    )
    assert patched.status_code == 200, patched.text
    assert patched.json()["email"] == new_email
