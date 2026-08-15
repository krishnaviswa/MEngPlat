"""POST /auth/forgot-password and POST /auth/reset-password (S-035, ADR-007).

Router functions called directly with fakes, same convention as
test_auth_hardening.py (login/lockout) and test_cache_lock.py (fail-closed
Redis behavior) -- `@limiter.limit(...)` needs a real Request instance
(tests.auth_helpers.fake_request), not a live server.

AC 2's enumeration-parity claim is the main thing under test: a registered
password account, an unregistered email, and a Google-only account must all
produce the exact same HTTP outcome and response body.
"""

import uuid

import pytest
from fastapi import HTTPException
from pydantic import ValidationError

from app.core.rate_limit import limiter
from app.core.security import get_password_hash, verify_password
from app.models import User, UserRole
from app.routers import auth as auth_module
from app.schemas import ForgotPasswordRequest, ResetPasswordRequest
from tests.auth_helpers import fake_request


@pytest.fixture(autouse=True)
def _reset_rate_limiter():
    """forgot_password/reset_password are @limiter.limit("5/minute") and the
    limiter is a shared module-level singleton keyed by client IP -- every
    fake_request() in this file resolves to the same 127.0.0.1, so without a
    reset each test would silently borrow from the previous test's quota
    (same convention as test_rate_limit.py's client fixture)."""
    limiter.reset()
    yield
    limiter.reset()


class FakeRedis:
    def __init__(self, *, raise_on_ping: Exception | None = None):
        self._raise_on_ping = raise_on_ping

    async def ping(self):
        if self._raise_on_ping:
            raise self._raise_on_ping
        return True


class FakeResult:
    def __init__(self, items):
        self._items = list(items)

    def scalar_one_or_none(self):
        return self._items[0] if self._items else None


class FakeDb:
    def __init__(self, users=None):
        self.users = list(users or [])
        self.executed = 0
        self.flushed = False

    async def execute(self, stmt):
        self.executed += 1
        wc = stmt.whereclause
        col_key = wc.left.key
        target = str(wc.right.value)
        items = [u for u in self.users if str(getattr(u, col_key, None)) == target]
        return FakeResult(items)

    async def flush(self):
        self.flushed = True


def _password_user(**overrides) -> User:
    defaults = dict(
        id=uuid.uuid4(),
        email="known@example.com",
        full_name="Known User",
        hashed_password=get_password_hash("oldpassword123"),
        role=UserRole.CUSTOMER,
        is_active=True,
    )
    defaults.update(overrides)
    return User(**defaults)


def _google_only_user(**overrides) -> User:
    defaults = dict(
        id=uuid.uuid4(),
        email="google@example.com",
        full_name="Google User",
        hashed_password=None,
        role=UserRole.CUSTOMER,
        is_active=True,
        auth_provider="google",
    )
    defaults.update(overrides)
    return User(**defaults)


# ---------------------------------------------------------------------------
# AC 2: no account enumeration -- same outcome for known / unknown / Google-only.
# ---------------------------------------------------------------------------
class TestForgotPasswordEnumeration:
    async def _call(self, monkeypatch, *, users, email, created_tokens, sent):
        redis = FakeRedis()

        async def fake_get_redis():
            return redis

        monkeypatch.setattr(auth_module, "get_redis", fake_get_redis)

        async def fake_create_reset_token(user_id):
            created_tokens.append(user_id)
            return "generated-token"

        async def fake_try_send(to, token):
            sent.append(to)

        monkeypatch.setattr(auth_module, "create_reset_token", fake_create_reset_token)
        monkeypatch.setattr(auth_module, "try_send_password_reset", fake_try_send)

        db = FakeDb(users=users)
        result = await auth_module.forgot_password(
            fake_request(), ForgotPasswordRequest(email=email), db
        )
        return result

    async def test_registered_password_account_creates_token_and_sends(self, monkeypatch):
        user = _password_user(email="known@example.com")
        created, sent = [], []
        result = await self._call(
            monkeypatch, users=[user], email="known@example.com", created_tokens=created, sent=sent
        )
        assert result.message == auth_module.FORGOT_PASSWORD_GENERIC_MESSAGE
        assert created == [str(user.id)]
        assert sent == ["known@example.com"]

    async def test_unregistered_email_creates_no_token_and_sends_nothing(self, monkeypatch):
        created, sent = [], []
        result = await self._call(
            monkeypatch, users=[], email="nobody@example.com", created_tokens=created, sent=sent
        )
        assert result.message == auth_module.FORGOT_PASSWORD_GENERIC_MESSAGE
        assert created == []
        assert sent == []

    async def test_google_only_account_creates_no_token_and_sends_nothing(self, monkeypatch):
        user = _google_only_user(email="google@example.com")
        created, sent = [], []
        result = await self._call(
            monkeypatch, users=[user], email="google@example.com", created_tokens=created, sent=sent
        )
        assert result.message == auth_module.FORGOT_PASSWORD_GENERIC_MESSAGE
        assert created == []
        assert sent == []

    async def test_response_body_is_identical_for_known_unknown_and_google_only(self, monkeypatch):
        known = _password_user(email="known2@example.com")
        google_only = _google_only_user(email="google2@example.com")

        known_result = await self._call(
            monkeypatch, users=[known], email="known2@example.com", created_tokens=[], sent=[]
        )
        unknown_result = await self._call(
            monkeypatch, users=[], email="nobody2@example.com", created_tokens=[], sent=[]
        )
        google_result = await self._call(
            monkeypatch, users=[google_only], email="google2@example.com", created_tokens=[], sent=[]
        )

        assert known_result.model_dump() == unknown_result.model_dump() == google_result.model_dump()


class TestForgotPasswordRedisDown:
    async def test_returns_503_before_the_account_lookup(self, monkeypatch):
        """The 503 branch must not itself distinguish known vs unknown
        addresses -- it fires before the DB is ever queried."""

        async def failing_get_redis():
            raise ConnectionError("redis unreachable")

        monkeypatch.setattr(auth_module, "get_redis", failing_get_redis)
        db = FakeDb(users=[_password_user(email="known@example.com")])

        with pytest.raises(HTTPException) as exc_info:
            await auth_module.forgot_password(
                fake_request(), ForgotPasswordRequest(email="known@example.com"), db
            )

        assert exc_info.value.status_code == 503
        assert db.executed == 0


# ---------------------------------------------------------------------------
# reset-password
# ---------------------------------------------------------------------------
class TestResetPassword:
    async def test_valid_token_updates_password_and_issues_no_session_tokens(self, monkeypatch):
        user = _password_user()
        db = FakeDb(users=[user])

        async def fake_consume(token):
            return str(user.id)

        monkeypatch.setattr(auth_module, "consume_reset_token", fake_consume)

        result = await auth_module.reset_password(
            fake_request(),
            ResetPasswordRequest(token="valid-token", new_password="brandnewpass123"),
            db,
        )

        assert result.message == "Password updated. Sign in with your new password."
        assert not hasattr(result, "access_token")
        assert db.flushed is True
        assert verify_password("brandnewpass123", user.hashed_password)
        assert not verify_password("oldpassword123", user.hashed_password)

    async def test_missing_or_expired_token_returns_generic_400(self, monkeypatch):
        db = FakeDb(users=[])

        async def fake_consume(token):
            return None

        monkeypatch.setattr(auth_module, "consume_reset_token", fake_consume)

        with pytest.raises(HTTPException) as exc_info:
            await auth_module.reset_password(
                fake_request(),
                ResetPasswordRequest(token="stale-token", new_password="brandnewpass123"),
                db,
            )
        assert exc_info.value.status_code == 400
        assert exc_info.value.detail == "Invalid or expired reset link"

    async def test_token_valid_but_user_row_gone_returns_generic_400_not_500(self, monkeypatch):
        """Same generic 400 as an invalid token -- never leaks that the token
        itself was structurally fine but the account disappeared."""
        db = FakeDb(users=[])
        missing_user_id = str(uuid.uuid4())

        async def fake_consume(token):
            return missing_user_id

        monkeypatch.setattr(auth_module, "consume_reset_token", fake_consume)

        with pytest.raises(HTTPException) as exc_info:
            await auth_module.reset_password(
                fake_request(),
                ResetPasswordRequest(token="orphan-token", new_password="brandnewpass123"),
                db,
            )
        assert exc_info.value.status_code == 400
        assert exc_info.value.detail == "Invalid or expired reset link"

    async def test_redis_error_on_consume_returns_503(self, monkeypatch):
        db = FakeDb(users=[])

        async def fake_consume(token):
            raise ConnectionError("redis unreachable")

        monkeypatch.setattr(auth_module, "consume_reset_token", fake_consume)

        with pytest.raises(HTTPException) as exc_info:
            await auth_module.reset_password(
                fake_request(),
                ResetPasswordRequest(token="whatever", new_password="brandnewpass123"),
                db,
            )
        assert exc_info.value.status_code == 503


# ---------------------------------------------------------------------------
# Schema validation: new_password reuses UserRegister's policy (min 12,
# letter + digit), not a weaker rule.
# ---------------------------------------------------------------------------
def test_reset_password_request_rejects_short_password():
    with pytest.raises(ValidationError):
        ResetPasswordRequest(token="t", new_password="short1")


def test_reset_password_request_rejects_letters_only():
    with pytest.raises(ValidationError):
        ResetPasswordRequest(token="t", new_password="abcdefghijkl")


def test_reset_password_request_rejects_digits_only():
    with pytest.raises(ValidationError):
        ResetPasswordRequest(token="t", new_password="123456789012")


def test_reset_password_request_accepts_letter_and_digit_password():
    payload = ResetPasswordRequest(token="t", new_password="brandnewpass123")
    assert payload.new_password == "brandnewpass123"


def test_forgot_password_request_requires_email_shape():
    with pytest.raises(ValidationError):
        ForgotPasswordRequest(email="not-an-email")
    assert ForgotPasswordRequest(email="valid@example.com").email == "valid@example.com"
