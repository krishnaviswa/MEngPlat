"""blocklist_token / is_token_blocklisted -- the logout revocation functions
in app/services/cache.py. Uses a fake Redis client the same way
test_cache_lock.py does (none is reachable in this environment).
"""

import time

import pytest

from app.services import cache as cache_module
from app.services.cache import blocklist_token, is_token_blocklisted


class FakeRedis:
    def __init__(self, *, existing_keys: set[str] | None = None, raise_on_call: Exception | None = None):
        self.existing_keys = set(existing_keys or [])
        self._raise = raise_on_call
        self.set_calls: list[dict] = []
        self.exists_calls: list[str] = []

    async def set(self, key, value, ex=None):
        self.set_calls.append({"key": key, "value": value, "ex": ex})
        if self._raise:
            raise self._raise
        return True

    async def exists(self, key):
        self.exists_calls.append(key)
        if self._raise:
            raise self._raise
        return 1 if key in self.existing_keys else 0


@pytest.fixture(autouse=True)
def _reset_shared_redis_singleton():
    """cache.py caches its Redis client in a module-level global -- clear it
    so each test's fake client doesn't leak into the next test."""
    cache_module._redis = None
    yield
    cache_module._redis = None


async def test_blocklist_token_sets_key_with_ttl_from_exp(monkeypatch):
    fake = FakeRedis()

    async def fake_get_redis():
        return fake

    monkeypatch.setattr(cache_module, "get_redis", fake_get_redis)

    await blocklist_token("jti-1", time.time() + 100)

    assert len(fake.set_calls) == 1
    call = fake.set_calls[0]
    assert call["key"] == "blocklist:token:jti-1"
    assert call["value"] == "1"
    # Allow a small delta for time elapsed between computing exp and the assert.
    assert 95 <= call["ex"] <= 100


async def test_blocklist_token_skips_when_exp_already_past(monkeypatch):
    fake = FakeRedis()

    async def fake_get_redis():
        return fake

    monkeypatch.setattr(cache_module, "get_redis", fake_get_redis)

    await blocklist_token("jti-1", time.time() - 10)

    assert fake.set_calls == []


async def test_blocklist_token_fails_open_silently_on_redis_error(monkeypatch):
    fake = FakeRedis(raise_on_call=ConnectionError("redis unreachable"))

    async def fake_get_redis():
        return fake

    monkeypatch.setattr(cache_module, "get_redis", fake_get_redis)

    await blocklist_token("jti-1", time.time() + 100)  # must not raise


async def test_is_token_blocklisted_true_when_key_exists(monkeypatch):
    fake = FakeRedis(existing_keys={"blocklist:token:jti-1"})

    async def fake_get_redis():
        return fake

    monkeypatch.setattr(cache_module, "get_redis", fake_get_redis)

    assert await is_token_blocklisted("jti-1") is True


async def test_is_token_blocklisted_false_when_key_missing(monkeypatch):
    fake = FakeRedis()

    async def fake_get_redis():
        return fake

    monkeypatch.setattr(cache_module, "get_redis", fake_get_redis)

    assert await is_token_blocklisted("jti-1") is False


async def test_is_token_blocklisted_fails_open_on_redis_error(monkeypatch):
    """The other half of the fail-open contract get_current_user relies on:
    an unreachable Redis must not turn every request into a 401."""
    fake = FakeRedis(raise_on_call=ConnectionError("redis unreachable"))

    async def fake_get_redis():
        return fake

    monkeypatch.setattr(cache_module, "get_redis", fake_get_redis)

    assert await is_token_blocklisted("jti-1") is False
