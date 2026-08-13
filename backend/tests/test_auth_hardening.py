"""Password policy, login lockout, and refresh-token rotation.

Router tests call handlers directly with fakes (same pattern as
test_auth_logout.py / test_google_auth.py). Cache lockout tests use a fake
Redis client like test_cache_blocklist.py.
"""

import uuid
from types import SimpleNamespace
from unittest.mock import AsyncMock

import pytest
from fastapi import HTTPException
from pydantic import ValidationError

from app.core.security import create_refresh_token, decode_token, get_password_hash
from app.routers import auth as auth_module
from app.schemas import UserLogin, UserRegister
from app.services import cache as cache_module
from app.services.cache import (
    LOGIN_FAIL_LIMIT,
    clear_login_failures,
    is_login_locked,
    record_login_failure,
)
from tests.auth_helpers import fake_request


class FakeRedis:
    def __init__(self, *, raise_on_call: Exception | None = None):
        self.store: dict[str, str] = {}
        self._raise = raise_on_call

    async def exists(self, key):
        if self._raise:
            raise self._raise
        return 1 if key in self.store else 0

    async def incr(self, key):
        if self._raise:
            raise self._raise
        self.store[key] = str(int(self.store.get(key, "0")) + 1)
        return int(self.store[key])

    async def expire(self, key, seconds):
        if self._raise:
            raise self._raise

    async def set(self, key, value, ex=None):
        if self._raise:
            raise self._raise
        self.store[key] = value
        return True

    async def delete(self, *keys):
        if self._raise:
            raise self._raise
        for key in keys:
            self.store.pop(key, None)


@pytest.fixture(autouse=True)
def _reset_shared_redis_singleton():
    cache_module._redis = None
    yield
    cache_module._redis = None


def test_register_password_rejects_short():
    with pytest.raises(ValidationError):
        UserRegister(email="a@example.com", full_name="A", password="short1ab")


def test_register_password_rejects_letters_only():
    with pytest.raises(ValidationError):
        UserRegister(email="a@example.com", full_name="A", password="abcdefghijkl")


def test_register_password_rejects_digits_only():
    with pytest.raises(ValidationError):
        UserRegister(email="a@example.com", full_name="A", password="123456789012")


def test_register_password_accepts_letter_and_digit():
    user = UserRegister(email="a@example.com", full_name="A", password="testpass1234")
    assert user.password == "testpass1234"


@pytest.mark.asyncio
async def test_lockout_after_five_failures(monkeypatch):
    fake = FakeRedis()

    async def fake_get_redis():
        return fake

    monkeypatch.setattr(cache_module, "get_redis", fake_get_redis)

    email = "lock@example.com"
    locked = False
    for _ in range(LOGIN_FAIL_LIMIT):
        locked = await record_login_failure(email)
    assert locked is True
    assert await is_login_locked(email) is True

    await clear_login_failures(email)
    assert await is_login_locked(email) is False


@pytest.mark.asyncio
async def test_lockout_fails_open_when_redis_down(monkeypatch):
    fake = FakeRedis(raise_on_call=ConnectionError("redis unreachable"))

    async def fake_get_redis():
        return fake

    monkeypatch.setattr(cache_module, "get_redis", fake_get_redis)

    assert await is_login_locked("x@example.com") is False
    assert await record_login_failure("x@example.com") is False
    await clear_login_failures("x@example.com")


@pytest.mark.asyncio
async def test_login_returns_429_when_locked(monkeypatch):
    monkeypatch.setattr(auth_module, "is_login_locked", AsyncMock(return_value=True))

    with pytest.raises(HTTPException) as exc:
        await auth_module.login(
            fake_request(),
            UserLogin(email="a@example.com", password="whatever1234"),
            SimpleNamespace(),
        )
    assert exc.value.status_code == 429


@pytest.mark.asyncio
async def test_login_records_failure_on_bad_password(monkeypatch):
    user = SimpleNamespace(
        hashed_password=get_password_hash("correcthorse1"),
        is_active=True,
        totp_enabled=True,
        id=uuid.uuid4(),
        role=SimpleNamespace(value="customer"),
    )

    class FakeResult:
        def scalar_one_or_none(self):
            return user

    class FakeDb:
        async def execute(self, *_a, **_k):
            return FakeResult()

    monkeypatch.setattr(auth_module, "is_login_locked", AsyncMock(return_value=False))
    record = AsyncMock(return_value=True)
    monkeypatch.setattr(auth_module, "record_login_failure", record)

    with pytest.raises(HTTPException) as exc:
        await auth_module.login(
            fake_request(),
            UserLogin(email="a@example.com", password="wrongpassword1"),
            FakeDb(),
        )
    assert exc.value.status_code == 429
    record.assert_awaited_once()


@pytest.mark.asyncio
async def test_refresh_blocklists_old_jti(monkeypatch):
    subject = str(uuid.uuid4())
    old = create_refresh_token(subject)
    old_jti = decode_token(old)["jti"]
    blocklisted: list[str] = []

    async def fake_blocklist(jti, exp):
        blocklisted.append(jti)

    monkeypatch.setattr(auth_module, "is_token_blocklisted", AsyncMock(return_value=False))
    monkeypatch.setattr(auth_module, "blocklist_token", fake_blocklist)

    user = SimpleNamespace(id=subject, is_active=True, role=SimpleNamespace(value="customer"))

    class FakeResult:
        def scalar_one_or_none(self):
            return user

    class FakeDb:
        async def execute(self, *_a, **_k):
            return FakeResult()

    tokens = await auth_module.refresh_token(old, FakeDb())
    assert tokens.refresh_token != old
    assert old_jti in blocklisted


@pytest.mark.asyncio
async def test_refresh_rejects_already_rotated_jti(monkeypatch):
    subject = str(uuid.uuid4())
    old = create_refresh_token(subject)
    monkeypatch.setattr(auth_module, "is_token_blocklisted", AsyncMock(return_value=True))

    with pytest.raises(HTTPException) as exc:
        await auth_module.refresh_token(old, SimpleNamespace())
    assert exc.value.status_code == 401
    assert "revoked" in exc.value.detail.lower()
