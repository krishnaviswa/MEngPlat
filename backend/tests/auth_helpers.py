"""Shared helpers for auth integration tests (password login + mandatory TOTP)."""

from __future__ import annotations

import pyotp
from httpx import AsyncClient
from starlette.requests import Request


def fake_request(headers: dict[str, str] | None = None) -> Request:
    """Minimal Request for calling rate-limited router functions (register,
    login) directly, bypassing HTTP -- slowapi's decorator requires a real
    Request instance to read the client IP from, even in a unit test."""
    raw_headers = [(k.lower().encode(), v.encode()) for k, v in (headers or {}).items()]
    return Request(
        {
            "type": "http",
            "method": "POST",
            "path": "/",
            "query_string": b"",
            "headers": raw_headers,
            "client": ("127.0.0.1", 0),
            "app": None,
        }
    )


async def complete_password_login(
    client: AsyncClient,
    email: str,
    password: str = "testpass123",
) -> dict:
    """Password login then enroll/verify TOTP; returns TokenResponse JSON."""
    login = await client.post("/api/v1/auth/login", json={"email": email, "password": password})
    assert login.status_code == 200, login.text
    body = login.json()

    if body.get("access_token") and body.get("refresh_token"):
        return body

    if body.get("mfa_enrollment_required"):
        mfa_token = body["mfa_token"]
        setup = await client.post("/api/v1/auth/mfa/totp/setup", json={"mfa_token": mfa_token})
        assert setup.status_code == 200, setup.text
        secret = setup.json()["secret"]
        code = pyotp.TOTP(secret).now()
        confirm = await client.post(
            "/api/v1/auth/mfa/totp/confirm",
            json={"mfa_token": mfa_token, "code": code},
        )
        assert confirm.status_code == 200, confirm.text
        return confirm.json()

    if body.get("mfa_required"):
        from app.services.mfa import DEMO_TOTP_SECRET

        mfa_token = body["mfa_token"]
        code = pyotp.TOTP(DEMO_TOTP_SECRET).now()
        verify = await client.post(
            "/api/v1/auth/mfa/totp/verify",
            json={"mfa_token": mfa_token, "code": code},
        )
        assert verify.status_code == 200, verify.text
        return verify.json()

    raise AssertionError(f"Unexpected login response: {body}")


async def register_and_get_token(
    client: AsyncClient,
    email: str,
    *,
    password: str = "testpass123",
    role: str = "customer",
    full_name: str = "Test User",
) -> str:
    res = await client.post(
        "/api/v1/auth/register",
        json={"email": email, "full_name": full_name, "password": password, "role": role},
    )
    assert res.status_code == 201, res.text
    tokens = await complete_password_login(client, email, password)
    return tokens["access_token"]
