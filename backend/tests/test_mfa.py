"""Unit tests for TOTP helpers and password-login MFA branching."""

import uuid
from types import SimpleNamespace
from unittest.mock import AsyncMock

import pyotp
import pytest
from fastapi import HTTPException

from app.core.security import create_mfa_token, decode_token
from app.routers import auth as auth_module
from app.schemas import MfaTokenRequest, MfaTotpCodeRequest, UserLogin
from app.services import mfa as mfa_module
from tests.auth_helpers import fake_request


def test_encrypt_decrypt_roundtrip():
    secret = mfa_module.generate_totp_secret()
    cipher = mfa_module.encrypt_totp_secret(secret)
    assert cipher != secret
    assert mfa_module.decrypt_totp_secret(cipher) == secret


def test_verify_totp_code_accepts_current():
    secret = mfa_module.generate_totp_secret()
    code = pyotp.TOTP(secret).now()
    assert mfa_module.verify_totp_code(secret, code)
    assert not mfa_module.verify_totp_code(secret, "000000")


def test_qr_svg_contains_svg_root():
    uri = mfa_module.build_otpauth_uri("JBSWY3DPEHPK3PXP", "user@example.com")
    svg = mfa_module.qr_svg_for_uri(uri)
    assert "<svg" in svg.lower()


def test_create_mfa_token_purpose():
    token = create_mfa_token(str(uuid.uuid4()), "enroll")
    payload = decode_token(token)
    assert payload["type"] == "mfa"
    assert payload["purpose"] == "enroll"


@pytest.mark.asyncio
async def test_login_requires_enrollment_when_totp_disabled(monkeypatch):
    user = SimpleNamespace(
        id=uuid.uuid4(),
        hashed_password="hashed",
        is_active=True,
        totp_enabled=False,
        role=SimpleNamespace(value="customer"),
    )

    class FakeResult:
        def scalar_one_or_none(self):
            return user

    class FakeDb:
        async def execute(self, *_a, **_k):
            return FakeResult()

    monkeypatch.setattr(auth_module, "verify_password", lambda *_a, **_k: True)
    monkeypatch.setattr(auth_module, "is_login_locked", AsyncMock(return_value=False))
    monkeypatch.setattr(auth_module, "clear_login_failures", AsyncMock())

    result = await auth_module.login(
        fake_request(), UserLogin(email="a@example.com", password="password1"), FakeDb()
    )
    assert result.mfa_enrollment_required is True
    assert result.mfa_token
    assert result.access_token is None


@pytest.mark.asyncio
async def test_login_requires_verify_when_totp_enabled(monkeypatch):
    user = SimpleNamespace(
        id=uuid.uuid4(),
        hashed_password="hashed",
        is_active=True,
        totp_enabled=True,
        role=SimpleNamespace(value="customer"),
    )

    class FakeResult:
        def scalar_one_or_none(self):
            return user

    class FakeDb:
        async def execute(self, *_a, **_k):
            return FakeResult()

    monkeypatch.setattr(auth_module, "verify_password", lambda *_a, **_k: True)
    monkeypatch.setattr(auth_module, "is_login_locked", AsyncMock(return_value=False))
    monkeypatch.setattr(auth_module, "clear_login_failures", AsyncMock())

    result = await auth_module.login(
        fake_request(), UserLogin(email="a@example.com", password="password1"), FakeDb()
    )
    assert result.mfa_required is True
    assert result.mfa_enrollment_required is False
    assert result.mfa_token


@pytest.mark.asyncio
async def test_totp_verify_issues_tokens(monkeypatch):
    secret = mfa_module.generate_totp_secret()
    user = SimpleNamespace(
        id=uuid.uuid4(),
        email="verify@example.com",
        is_active=True,
        totp_enabled=True,
        totp_secret=mfa_module.encrypt_totp_secret(secret),
        role=SimpleNamespace(value="customer"),
    )
    mfa_token = create_mfa_token(str(user.id), "verify")

    monkeypatch.setattr(auth_module, "_user_from_mfa_token", AsyncMock(return_value=user))
    monkeypatch.setattr(auth_module, "_consume_mfa_token", AsyncMock())
    monkeypatch.setattr(auth_module, "clear_login_failures", AsyncMock())

    class FakeDb:
        pass

    tokens = await auth_module.totp_verify(
        MfaTotpCodeRequest(mfa_token=mfa_token, code=pyotp.TOTP(secret).now()),
        FakeDb(),
    )
    assert tokens.access_token
    assert tokens.refresh_token


@pytest.mark.asyncio
async def test_totp_verify_rejects_bad_code(monkeypatch):
    secret = mfa_module.generate_totp_secret()
    user = SimpleNamespace(
        id=uuid.uuid4(),
        is_active=True,
        totp_enabled=True,
        totp_secret=mfa_module.encrypt_totp_secret(secret),
        role=SimpleNamespace(value="customer"),
    )
    monkeypatch.setattr(auth_module, "_user_from_mfa_token", AsyncMock(return_value=user))

    with pytest.raises(HTTPException) as exc:
        await auth_module.totp_verify(
            MfaTotpCodeRequest(mfa_token="x", code="000000"),
            SimpleNamespace(),
        )
    assert exc.value.status_code == 401


@pytest.mark.asyncio
async def test_totp_setup_rejects_already_enabled(monkeypatch):
    user = SimpleNamespace(totp_enabled=True, email="a@example.com")
    monkeypatch.setattr(auth_module, "_user_from_mfa_token", AsyncMock(return_value=user))

    with pytest.raises(HTTPException) as exc:
        await auth_module.totp_setup(MfaTokenRequest(mfa_token="x"), SimpleNamespace())
    assert exc.value.status_code == 400


class _FlushOnlyDb:
    """Minimal fake DB for router handlers that only call db.flush()/db.refresh()."""

    async def flush(self):
        pass

    async def refresh(self, _obj):
        pass


@pytest.mark.asyncio
async def test_totp_setup_returns_uri_secret_qr_and_keeps_totp_disabled(monkeypatch):
    """S-020 AC1: /mfa/totp/setup hands back enrollment material without
    enabling TOTP yet -- enabling only happens on a successful /confirm."""
    user = SimpleNamespace(totp_enabled=False, email="setup@example.com")
    monkeypatch.setattr(auth_module, "_user_from_mfa_token", AsyncMock(return_value=user))

    result = await auth_module.totp_setup(MfaTokenRequest(mfa_token="x"), _FlushOnlyDb())

    assert result.secret
    assert result.otpauth_uri.startswith("otpauth://")
    assert "<svg" in result.qr_svg.lower()
    assert user.totp_secret  # stored (encrypted) for the upcoming /confirm
    assert user.totp_enabled is False


@pytest.mark.asyncio
async def test_totp_confirm_enables_totp_and_issues_tokens_on_correct_code(monkeypatch):
    """S-020 AC1: a correct first code on /confirm is what finally issues
    session tokens and flips totp_enabled -- not /setup, not /login."""
    secret = mfa_module.generate_totp_secret()
    user = SimpleNamespace(
        id=uuid.uuid4(),
        email="confirm@example.com",
        totp_enabled=False,
        totp_secret=mfa_module.encrypt_totp_secret(secret),
        role=SimpleNamespace(value="customer"),
    )
    monkeypatch.setattr(auth_module, "_user_from_mfa_token", AsyncMock(return_value=user))
    monkeypatch.setattr(auth_module, "_consume_mfa_token", AsyncMock())
    monkeypatch.setattr(auth_module, "clear_login_failures", AsyncMock())

    tokens = await auth_module.totp_confirm(
        MfaTotpCodeRequest(mfa_token="x", code=pyotp.TOTP(secret).now()),
        _FlushOnlyDb(),
    )

    assert tokens.access_token
    assert tokens.refresh_token
    assert user.totp_enabled is True


@pytest.mark.asyncio
async def test_totp_confirm_rejects_bad_code_and_leaves_totp_disabled(monkeypatch):
    """S-020 AC4: a wrong code on /confirm is a 401 with no tokens issued,
    and enrollment is not marked complete."""
    secret = mfa_module.generate_totp_secret()
    user = SimpleNamespace(
        id=uuid.uuid4(),
        totp_enabled=False,
        totp_secret=mfa_module.encrypt_totp_secret(secret),
        role=SimpleNamespace(value="customer"),
    )
    monkeypatch.setattr(auth_module, "_user_from_mfa_token", AsyncMock(return_value=user))

    with pytest.raises(HTTPException) as exc:
        await auth_module.totp_confirm(
            MfaTotpCodeRequest(mfa_token="x", code="000000"),
            _FlushOnlyDb(),
        )

    assert exc.value.status_code == 401
    assert user.totp_enabled is False


async def test_mfa_token_cannot_authenticate_as_an_access_token():
    """S-020 AC1/AC2: the short-lived mfa_token returned by /login is not a
    session token -- it must be rejected by get_current_user (type != access)
    before ever reaching the database, so it can't be used in place of the
    tokens gated behind enroll/verify."""
    from fastapi.security import HTTPAuthorizationCredentials

    import app.dependencies as dependencies_module

    class _ExplodingDB:
        async def execute(self, *args, **kwargs):
            raise AssertionError("an mfa token must not reach the database")

    mfa_token = create_mfa_token(str(uuid.uuid4()), "enroll")
    creds = HTTPAuthorizationCredentials(scheme="Bearer", credentials=mfa_token)

    with pytest.raises(HTTPException) as exc:
        await dependencies_module.get_current_user(creds, _ExplodingDB())

    assert exc.value.status_code == 401
