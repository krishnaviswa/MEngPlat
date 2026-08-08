"""try_acquire_lock -- the debounce lock merchant-summary refresh relies on.

Uses a fake Redis client rather than a real one (none is reachable in this
environment), which is fine here: the behavior under test is try_acquire_lock's
own logic (the SET NX EX call shape, and failing closed on error), not Redis
itself.
"""

import pytest

from app.services import cache as cache_module
from app.services.cache import try_acquire_lock


class FakeRedis:
    def __init__(self, *, already_held: bool = False, raise_on_set: Exception | None = None):
        self._already_held = already_held
        self._raise_on_set = raise_on_set
        self.set_calls: list[dict] = []

    async def set(self, key, value, ex=None, nx=None):
        self.set_calls.append({"key": key, "value": value, "ex": ex, "nx": nx})
        if self._raise_on_set:
            raise self._raise_on_set
        return None if (nx and self._already_held) else True


@pytest.fixture(autouse=True)
def _reset_shared_redis_singleton():
    """cache.py caches its Redis client in a module-level global -- clear it
    so each test's fake client doesn't leak into the next test."""
    cache_module._redis = None
    yield
    cache_module._redis = None


async def test_acquires_when_not_already_held(monkeypatch):
    fake = FakeRedis(already_held=False)
    async def fake_get_redis():
        return fake

    monkeypatch.setattr(cache_module, "get_redis", fake_get_redis)

    assert await try_acquire_lock("ai:summary-lock:biz-1", ttl=300) is True
    assert fake.set_calls == [{"key": "ai:summary-lock:biz-1", "value": "1", "ex": 300, "nx": True}]


async def test_does_not_acquire_when_already_held(monkeypatch):
    fake = FakeRedis(already_held=True)
    async def fake_get_redis():
        return fake

    monkeypatch.setattr(cache_module, "get_redis", fake_get_redis)

    assert await try_acquire_lock("ai:summary-lock:biz-1", ttl=300) is False


async def test_fails_closed_on_redis_error(monkeypatch):
    """Deliberately the opposite of cache_get/cache_set's fail-open behavior:
    an unreachable Redis must not silently disable the debounce protection
    it exists to provide (see the docstring on try_acquire_lock)."""
    fake = FakeRedis(raise_on_set=ConnectionError("redis unreachable"))
    async def fake_get_redis():
        return fake

    monkeypatch.setattr(cache_module, "get_redis", fake_get_redis)

    assert await try_acquire_lock("ai:summary-lock:biz-1", ttl=300) is False
