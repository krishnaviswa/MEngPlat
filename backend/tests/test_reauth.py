"""Step-up reauth + email change on PATCH /auth/me."""

from __future__ import annotations

import uuid

import pytest
from httpx import ASGITransport, AsyncClient

from fastapi import HTTPException

from app.core.security import create_reauth_token, decode_token
from app.main import app
from app.models import NationalIdType, User, UserRole
from app.routers import auth as auth_module
from app.schemas import ReauthRequest, UserProfileUpdate
from app.services.google_auth import GoogleIdentity
from tests.auth_helpers import fake_request, register_and_get_token


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


class _MemDb:
    async def execute(self, stmt):
        class _Result:
            def scalar_one_or_none(self):
                return None

        return _Result()

    async def flush(self):
        pass

    async def refresh(self, obj):
        pass


@pytest.mark.asyncio
async def test_merchant_national_id_change_requires_reauth():
    user = User(
        id=uuid.uuid4(),
        email="m@example.com",
        full_name="Mina",
        role=UserRole.MERCHANT,
        is_active=True,
    )
    payload = UserProfileUpdate(national_id_type=NationalIdType.PAN, national_id_number="ABCDE1234F")
    with pytest.raises(HTTPException) as exc:
        await auth_module.update_me(payload, user, _MemDb(), None, None)
    assert exc.value.status_code == 401

    city_only = UserProfileUpdate(city="Chennai")
    await auth_module.update_me(city_only, user, _MemDb(), None, None)
    assert user.city == "Chennai"

    token = create_reauth_token(str(user.id))
    await auth_module.update_me(payload, user, _MemDb(), token, None)
    assert user.national_id_type == NationalIdType.PAN
    assert user.national_id_number == "ABCDE1234F"


@pytest.mark.asyncio
async def test_customer_national_id_change_does_not_require_reauth():
    user = User(
        id=uuid.uuid4(),
        email="c@example.com",
        full_name="Casey",
        role=UserRole.CUSTOMER,
        is_active=True,
    )
    payload = UserProfileUpdate(national_id_type=NationalIdType.PAN, national_id_number="ABCDE1234F")
    await auth_module.update_me(payload, user, _MemDb(), None, None)
    assert user.national_id_number == "ABCDE1234F"


@pytest.mark.asyncio
async def test_reauth_google_credential_matches_sub(monkeypatch):
    user = User(
        id=uuid.uuid4(),
        email="owner@example.com",
        full_name="Owner",
        hashed_password=None,
        role=UserRole.MERCHANT,
        google_sub="sub-owner",
        is_active=True,
    )

    async def fake_verify(credential: str, client_id: str) -> GoogleIdentity:
        assert credential == "id-token"
        return GoogleIdentity(
            sub="sub-owner",
            email="owner@example.com",
            email_verified=True,
            name="Owner",
            picture=None,
        )

    monkeypatch.setattr(auth_module, "verify_google_id_token", fake_verify)
    result = await auth_module.reauth(fake_request(), ReauthRequest(credential="id-token"), user)
    claims = decode_token(result.reauth_token)
    assert claims.get("type") == "reauth"
    assert str(claims.get("sub")) == str(user.id)
