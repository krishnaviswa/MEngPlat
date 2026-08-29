"""Sync API helpers for e2e (Playwright APIRequestContext + Pydantic)."""

from __future__ import annotations

import time
from typing import Any

import pyotp
from playwright.sync_api import APIRequestContext, Playwright

from app.schemas import (
    BusinessReportResponse,
    BusinessResponse,
    DashboardStats,
    FeaturedCheckoutResponse,
    PlatformAnalytics,
    ReauthResponse,
    ReplyResponse,
    ReviewResponse,
    SupportTicketResponse,
    TokenResponse,
    UserResponse,
)
from app.services.mfa import DEMO_TOTP_SECRET

PASSWORD = "E2ePassw0rd12"
# Fixed demo OTP the mock SMS provider accepts in Compose (backend/scripts/seed.py).
DEMO_PHONE_OTP = "123456"
# Structural mock national IDs accepted by S-070 validation.
DEMO_PAN = "ABCDE1234F"


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

    # --- S-124 additions: helpers over existing endpoints ---------------------

    def delete(self, path: str, token: str | None = None):
        return self._ctx.delete(path.lstrip("/"), headers=self._headers(token))

    def me(self, token: str) -> UserResponse:
        res = self.get("auth/me", token=token)
        assert res.status == 200, res.text()
        return UserResponse.model_validate(res.json())

    def reauth_token(self, token: str, *, password: str = PASSWORD) -> str:
        res = self.post("auth/reauth", token=token, json={"password": password})
        assert res.status == 200, res.text()
        return ReauthResponse.model_validate(res.json()).reauth_token

    def set_national_id(
        self, token: str, *, id_type: str = "pan", number: str = DEMO_PAN
    ) -> UserResponse:
        res = self.patch(
            "auth/me",
            token=token,
            json={"national_id_type": id_type, "national_id_number": number},
        )
        assert res.status == 200, res.text()
        return UserResponse.model_validate(res.json())

    def update_me_email(self, token: str, email: str, reauth_token: str) -> UserResponse:
        res = self.patch(
            f"auth/me?reauth_token={reauth_token}", token=token, json={"email": email}
        )
        assert res.status == 200, res.text()
        return UserResponse.model_validate(res.json())

    def report_review(self, token: str, review_id, reason: str = "This looks like spam content.") -> None:
        res = self.post(f"reviews/{review_id}/report", token=token, json={"reason": reason})
        assert res.status == 200, res.text()

    def list_reviews(self, business_id) -> list[ReviewResponse]:
        res = self.get(f"reviews/business/{business_id}")
        assert res.status == 200, res.text()
        return [ReviewResponse.model_validate(r) for r in res.json()]

    def reported_reviews(self, admin_token: str) -> list[ReviewResponse]:
        res = self.get("reviews/reported", token=admin_token)
        assert res.status == 200, res.text()
        return [ReviewResponse.model_validate(r) for r in res.json()]

    def moderate_review(self, admin_token: str, review_id, action: str) -> None:
        res = self.post(f"reviews/{review_id}/moderate?action={action}", token=admin_token)
        assert res.status == 200, res.text()

    def reply_to_review(self, merchant_token: str, review_id, body: str) -> ReplyResponse:
        res = self.post(f"reviews/{review_id}/reply", token=merchant_token, json={"body": body})
        assert res.status == 201, res.text()
        return ReplyResponse.model_validate(res.json())

    def create_business_report(self, token: str, business_id, reason: str) -> BusinessReportResponse:
        res = self.post(f"businesses/{business_id}/reports", token=token, json={"reason": reason})
        assert res.status == 201, res.text()
        return BusinessReportResponse.model_validate(res.json())

    def start_review(self, admin_token: str, business_id) -> BusinessResponse:
        res = self.post(f"businesses/{business_id}/start-review", token=admin_token)
        assert res.status == 200, res.text()
        return BusinessResponse.model_validate(res.json())

    def create_support_ticket(
        self, *, name: str, phone: str, issue: str, business_id=None, token: str | None = None
    ) -> SupportTicketResponse:
        body: dict = {"name": name, "phone": phone, "issue": issue}
        if business_id:
            body["business_id"] = str(business_id)
        res = self.post("support-tickets", token=token, json=body)
        assert res.status == 201, res.text()
        return SupportTicketResponse.model_validate(res.json())

    def admin_update_support_ticket(
        self, admin_token: str, ticket_id, *, status: str | None = None, admin_response: str | None = None
    ) -> SupportTicketResponse:
        body: dict = {}
        if status is not None:
            body["status"] = status
        if admin_response is not None:
            body["admin_response"] = admin_response
        res = self.patch(f"admin/support-tickets/{ticket_id}", token=admin_token, json=body)
        assert res.status == 200, res.text()
        return SupportTicketResponse.model_validate(res.json())

    def admin_add_report_message(self, admin_token: str, report_id, body: str):
        res = self.post(
            f"admin/business-reports/{report_id}/messages", token=admin_token, json={"body": body}
        )
        assert res.status == 201, res.text()
        return res.json()

    def admin_update_business_report(self, admin_token: str, report_id, status: str) -> BusinessReportResponse:
        res = self.patch(
            f"admin/business-reports/{report_id}", token=admin_token, json={"status": status}
        )
        assert res.status == 200, res.text()
        return BusinessReportResponse.model_validate(res.json())

    def request_featured_boost(
        self, merchant_token: str, business_id, sku_code: str
    ) -> FeaturedCheckoutResponse:
        res = self.post(
            "payments/featured/checkout",
            token=merchant_token,
            json={"business_id": str(business_id), "sku_code": sku_code},
        )
        assert res.status == 200, res.text()
        return FeaturedCheckoutResponse.model_validate(res.json())

    def featured_skus(self, merchant_token: str) -> list[dict]:
        res = self.get("payments/featured/skus", token=merchant_token)
        assert res.status == 200, res.text()
        return list(res.json())

    def mock_complete_payment(self, admin_token: str, provider_order_id: str, outcome: str = "paid"):
        """DEBUG-only. Returns the raw response so callers can skip on 404."""
        return self.post(
            "payments/mock/complete",
            token=admin_token,
            json={"provider_order_id": provider_order_id, "outcome": outcome},
        )

    def admin_platform(self, admin_token: str) -> PlatformAnalytics:
        res = self.get("dashboard/admin/platform", token=admin_token)
        assert res.status == 200, res.text()
        return PlatformAnalytics.model_validate(res.json())

    def dashboard_stats(self, token: str, business_id, date_range: str = "30") -> DashboardStats:
        res = self.get(f"dashboard/merchant/{business_id}?date_range={date_range}", token=token)
        assert res.status == 200, res.text()
        return DashboardStats.model_validate(res.json())

    def list_users(self, admin_token: str, page: int = 1, page_size: int = 20) -> list[UserResponse]:
        res = self.get(f"admin/users?page={page}&page_size={page_size}", token=admin_token)
        assert res.status == 200, res.text()
        return [UserResponse.model_validate(u) for u in res.json()]

    def suspend_user(self, admin_token: str, user_id) -> UserResponse:
        res = self.post(f"admin/users/{user_id}/suspend", token=admin_token)
        assert res.status == 200, res.text()
        return UserResponse.model_validate(res.json())

    def reactivate_user(self, admin_token: str, user_id) -> UserResponse:
        res = self.post(f"admin/users/{user_id}/reactivate", token=admin_token)
        assert res.status == 200, res.text()
        return UserResponse.model_validate(res.json())

    def create_category(self, admin_token: str, name: str, slug: str):
        return self.post("businesses/categories", token=admin_token, json={"name": name, "slug": slug})

    def admin_list_payments(self, admin_token: str) -> list[dict]:
        res = self.get("payments/admin/payments", token=admin_token)
        assert res.status == 200, res.text()
        return list(res.json())

    def admin_payment_action(self, admin_token: str, payment_id, action: str):
        """action in {approve, reject, refund}. Returns the raw response."""
        return self.post(f"payments/admin/payments/{payment_id}/{action}", token=admin_token)

    def whatsapp_drafts(self, admin_token: str):
        res = self.get("admin/whatsapp/drafts", token=admin_token)
        assert res.status == 200, res.text()
        return res.json()
