"""app/services/password_reset.py (ADR-007) -- hashed, single-use, fail-closed
Redis-backed reset tokens.

Uses a fake Redis client rather than a real one (none is reachable in this
environment), same convention as test_cache_lock.py -- the behavior under
test is create_reset_token / consume_reset_token's own logic (key shape, TTL,
single-use delete, and failing CLOSED on a Redis error), not Redis itself.
"""

import hashlib

import pytest

from app.services import password_reset as password_reset_module
from app.services.password_reset import (
    RESET_TOKEN_TTL_SECONDS,
    _reset_key,
    consume_reset_token,
    create_reset_token,
)


class FakeRedis:
    def __init__(self, *, raise_on: str | None = None):
        self.store: dict[str, str] = {}
        self._raise_on = raise_on
        self.set_calls: list[dict] = []
        self.get_calls: list[str] = []
        self.delete_calls: list[str] = []

    async def set(self, key, value, ex=None, nx=None):
        if self._raise_on == "set":
            raise ConnectionError("redis unreachable")
        self.set_calls.append({"key": key, "value": value, "ex": ex, "nx": nx})
        self.store[key] = value
        return True

    async def get(self, key):
        if self._raise_on == "get":
            raise ConnectionError("redis unreachable")
        self.get_calls.append(key)
        return self.store.get(key)

    async def delete(self, key):
        if self._raise_on == "delete":
            raise ConnectionError("redis unreachable")
        self.delete_calls.append(key)
        self.store.pop(key, None)


def test_reset_key_is_sha256_hex_digest_of_the_token_not_the_raw_token():
    token = "some-high-entropy-token"
    key = _reset_key(token)
    assert key == f"auth:reset:{hashlib.sha256(token.encode('utf-8')).hexdigest()}"
    assert token not in key


async def test_create_reset_token_stores_hashed_token_with_one_hour_ttl(monkeypatch):
    fake = FakeRedis()

    async def fake_get_redis():
        return fake

    monkeypatch.setattr(password_reset_module, "get_redis", fake_get_redis)

    user_id = "user-123"
    token = await create_reset_token(user_id)

    assert len(fake.set_calls) == 1
    call = fake.set_calls[0]
    assert call["key"] == _reset_key(token)
    assert call["value"] == user_id
    assert call["ex"] == RESET_TOKEN_TTL_SECONDS == 3600
    assert call["nx"] is True
    # The raw token itself is never the Redis key/value -- only its hash is.
    assert token != call["key"]
    assert token != call["value"]


async def test_create_reset_token_raises_on_redis_error_fail_closed(monkeypatch):
    """Unlike app/services/cache.py's fail-open helpers, a Redis outage here
    must propagate -- forgot-password's router turns this into a 503 rather
    than silently proceeding without ever having recorded a challenge."""
    fake = FakeRedis(raise_on="set")

    async def fake_get_redis():
        return fake

    monkeypatch.setattr(password_reset_module, "get_redis", fake_get_redis)

    with pytest.raises(ConnectionError):
        await create_reset_token("user-123")


async def test_consume_reset_token_returns_user_id_for_a_valid_token(monkeypatch):
    fake = FakeRedis()

    async def fake_get_redis():
        return fake

    monkeypatch.setattr(password_reset_module, "get_redis", fake_get_redis)

    token = await create_reset_token("user-456")
    user_id = await consume_reset_token(token)

    assert user_id == "user-456"


async def test_consume_reset_token_is_single_use_second_call_returns_none(monkeypatch):
    fake = FakeRedis()

    async def fake_get_redis():
        return fake

    monkeypatch.setattr(password_reset_module, "get_redis", fake_get_redis)

    token = await create_reset_token("user-789")
    first = await consume_reset_token(token)
    second = await consume_reset_token(token)

    assert first == "user-789"
    assert second is None
    assert fake.delete_calls == [_reset_key(token)]


async def test_consume_reset_token_returns_none_for_unknown_token(monkeypatch):
    fake = FakeRedis()

    async def fake_get_redis():
        return fake

    monkeypatch.setattr(password_reset_module, "get_redis", fake_get_redis)

    assert await consume_reset_token("never-issued-token") is None
    # A miss must not attempt a delete on a key that was never set.
    assert fake.delete_calls == []


async def test_consume_reset_token_raises_on_redis_error_fail_closed(monkeypatch):
    fake = FakeRedis(raise_on="get")

    async def fake_get_redis():
        return fake

    monkeypatch.setattr(password_reset_module, "get_redis", fake_get_redis)

    with pytest.raises(ConnectionError):
        await consume_reset_token("whatever-token")
