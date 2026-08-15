"""Phone OTP normalize + auth routes (S-044)."""

from __future__ import annotations

from unittest.mock import AsyncMock, patch

import pytest
from fastapi import HTTPException

from app.models import UserRole
from app.routers.auth import phone_otp_request, phone_otp_verify
from app.schemas import PhoneOtpRequest, PhoneOtpVerifyRequest
from app.services.phone_otp import InvalidPhoneError, normalize_phone
from tests.auth_helpers import fake_request


def test_normalize_ten_digit_india():
    assert normalize_phone("9876543210") == "+919876543210"
    assert normalize_phone("+91 98765 43210") == "+919876543210"


def test_normalize_rejects_short():
    with pytest.raises(InvalidPhoneError):
        normalize_phone("123")


async def test_request_always_generic_and_sends():
    with (
        patch("app.routers.auth.issue_otp", new_callable=AsyncMock, return_value="123456") as issue,
        patch("app.routers.auth.get_sms_provider") as gp,
    ):
        gp.return_value.send_otp = AsyncMock()
        result = await phone_otp_request(fake_request(), PhoneOtpRequest(phone="9876543210"))
    issue.assert_awaited()
    gp.return_value.send_otp.assert_awaited()
    assert "sent a sign-in code" in result.message.lower() or "sms" in result.message.lower()


async def test_verify_new_user_requires_name():
    class FakeDB:
        async def execute(self, stmt):
            class R:
                def scalar_one_or_none(self_inner):
                    return None

            return R()

    with patch("app.routers.auth.consume_otp", new_callable=AsyncMock, return_value=True):
        with pytest.raises(HTTPException) as exc:
            await phone_otp_verify(
                fake_request(),
                PhoneOtpVerifyRequest(phone="9876543210", code="123456"),
                db=FakeDB(),
            )
    assert exc.value.status_code == 400


async def test_verify_bad_code_is_401():
    with patch("app.routers.auth.consume_otp", new_callable=AsyncMock, return_value=False):
        with pytest.raises(HTTPException) as exc:
            await phone_otp_verify(
                fake_request(),
                PhoneOtpVerifyRequest(phone="9876543210", code="000000", full_name="Ada"),
                db=AsyncMock(),
            )
    assert exc.value.status_code == 401


async def test_verify_blocks_admin_self_register():
    with patch("app.routers.auth.consume_otp", new_callable=AsyncMock, return_value=True):
        db = AsyncMock()

        class R:
            def scalar_one_or_none(self):
                return None

        db.execute = AsyncMock(return_value=R())
        with pytest.raises(HTTPException) as exc:
            await phone_otp_verify(
                fake_request(),
                PhoneOtpVerifyRequest(
                    phone="9876543210",
                    code="123456",
                    full_name="Ada",
                    role=UserRole.ADMIN,
                ),
                db=db,
            )
    assert exc.value.status_code == 403


def test_sms_mock_needs_no_keys(monkeypatch):
    from app.config import get_settings
    from app.services.sms import validate_startup_config

    monkeypatch.setenv("SMS_PROVIDER", "mock")
    get_settings.cache_clear()
    try:
        validate_startup_config()
    finally:
        get_settings.cache_clear()


def test_msg91_without_keys_fails_startup(monkeypatch):
    from app.config import get_settings
    from app.services.sms import validate_startup_config

    monkeypatch.setenv("SMS_PROVIDER", "msg91")
    monkeypatch.setenv("MSG91_AUTH_KEY", "")
    monkeypatch.setenv("MSG91_TEMPLATE_ID", "")
    get_settings.cache_clear()
    try:
        with pytest.raises(RuntimeError, match="MSG91"):
            validate_startup_config()
    finally:
        get_settings.cache_clear()
