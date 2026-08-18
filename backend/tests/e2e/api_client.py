"""Sync API helpers for e2e (Playwright APIRequestContext + Pydantic)."""

from __future__ import annotations

import time
from typing import Any

import pyotp
from playwright.sync_api import APIRequestContext, Playwright

from app.schemas import BusinessResponse, ReviewResponse, TokenResponse, UserResponse
from app.services.mfa import DEMO_TOTP_SECRET

PASSWORD = "E2ePassw0rd12"


class Api:
    def __init__(self, playwright: Playwright, api_url: str) -> None:
        self._ctx: APIRequestContext = playwright.request.new_context(base_url=f"{api_url.rstrip('/')}/")

    def dispose(self) -> None:
        self._ctx.dispose()

    def _headers(self, token: str | None) -> dict[str, str]:
        if not token:
            return {}
        return {"Authorization": f"Bearer {token}"}

    def get(self, path: str, token: str | None = None):
        return self._ctx.get(path.lstrip("/"), headers=self._headers(token))

    def post(self, path: str, token: str | None = None, json: Any = None):
        return self._ctx.post(path.lstrip("/"), headers=self._headers(token), data=json)

    def patch(self, path: str, token: str | None = None, json: Any = None):
        return self._ctx.patch(path.lstrip("/"), headers=self._headers(token), data=json)

    def register(
        self,
        email: str,
        *,
        role: str = "customer",
        password: str = PASSWORD,
        full_name: str = "E2E User",
    ) -> UserResponse:
        payload = {
            "email": email,
            "full_name": full_name,
            "password": password,
            "role": role,
        }
        res = None
        for _ in range(8):
            res = self.post("auth/register", json=payload)
            if res.status == 201:
                return UserResponse.model_validate(res.json())
            if res.status == 429:
                time.sleep(12)
                continue
            break
        assert res is not None and res.status == 201, res.text() if res else "no response"
        return UserResponse.model_validate(res.json())

    def complete_password_login(self, email: str, password: str = PASSWORD) -> dict:
        login = None
        for _ in range(8):
            login = self.post("auth/login", json={"email": email, "password": password})
            if login.status != 429:
                break
            time.sleep(8)
        assert login is not None and login.status == 200, login.text() if login else "no login"
        body = login.json()
        if body.get("access_token") and body.get("refresh_token"):
            return body
        if body.get("mfa_enrollment_required"):
            mfa_token = body["mfa_token"]
            setup = self.post("auth/mfa/totp/setup", json={"mfa_token": mfa_token})
            assert setup.status == 200, setup.text()
            secret = setup.json()["secret"]
            confirm = self.post(
                "auth/mfa/totp/confirm",
                json={"mfa_token": mfa_token, "code": pyotp.TOTP(secret).now()},
            )
            assert confirm.status == 200, confirm.text()
            return confirm.json()
        if body.get("mfa_required"):
            mfa_token = body["mfa_token"]
            verify = self.post(
                "auth/mfa/totp/verify",
                json={"mfa_token": mfa_token, "code": pyotp.TOTP(DEMO_TOTP_SECRET).now()},
            )
            assert verify.status == 200, verify.text()
            return verify.json()
        raise AssertionError(f"Unexpected login response: {body}")

    def tokens(self, email: str, password: str = PASSWORD) -> TokenResponse:
        return TokenResponse.model_validate(self.complete_password_login(email, password))

    def seed_admin_tokens(self) -> TokenResponse | None:
        login = self.post(
            "auth/login",
            json={"email": "admin@merchanthub.ai", "password": "admin12345ok"},
        )
        if login.status != 200:
            return None
        body = login.json()
        if body.get("mfa_required"):
            verify = self.post(
                "auth/mfa/totp/verify",
                json={
                    "mfa_token": body["mfa_token"],
                    "code": pyotp.TOTP(DEMO_TOTP_SECRET).now(),
                },
            )
            if verify.status != 200:
                return None
            return TokenResponse.model_validate(verify.json())
        if body.get("access_token"):
            return TokenResponse.model_validate(body)
        return None

    def list_businesses(self) -> list[BusinessResponse]:
        res = self.get("businesses")
        assert res.status == 200, res.text()
        payload = res.json()
        assert isinstance(payload, list)
        return [BusinessResponse.model_validate(item) for item in payload]

    def list_cities(self) -> list[str]:
        res = self.get("businesses/cities")
        assert res.status == 200, res.text()
        return list(res.json())

    def create_business(self, token: str, name: str, city: str = "Chennai") -> BusinessResponse:
        kyc = self.patch(
            "auth/me",
            token=token,
            json={"national_id_type": "pan", "national_id_number": "ABCDE1234F"},
        )
        assert kyc.status == 200, kyc.text()
        res = self.post(
            "businesses",
            token=token,
            json={
                "name": name,
                "address": "1 Test Street",
                "city": city,
                "country": "IN",
                "phone": "+919876500098",
                "email": "e2e-business@example.com",
            },
        )
        assert res.status == 201, res.text()
        return BusinessResponse.model_validate(res.json())

    def approve_business(self, admin_token: str, business_id) -> BusinessResponse:
        res = self.post(f"businesses/{business_id}/approve", token=admin_token)
        assert res.status == 200, res.text()
        return BusinessResponse.model_validate(res.json())

    def create_review(self, token: str, business_id, body: str) -> ReviewResponse:
        res = self.post(
            "reviews",
            token=token,
            json={"business_id": str(business_id), "rating": 5, "body": body},
        )
        assert res.status == 201, res.text()
        return ReviewResponse.model_validate(res.json())
