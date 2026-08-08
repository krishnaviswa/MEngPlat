import json
from typing import Any
from uuid import UUID

import redis.asyncio as redis

from app.config import get_settings

settings = get_settings()
_redis: redis.Redis | None = None


async def get_redis() -> redis.Redis:
    global _redis
    if _redis is None:
        _redis = redis.from_url(settings.redis_url, decode_responses=True)
    return _redis


async def cache_get(key: str) -> Any | None:
    try:
        client = await get_redis()
        value = await client.get(key)
        return json.loads(value) if value else None
    except Exception:
        return None


async def cache_set(key: str, value: Any, ttl: int = 300) -> None:
    try:
        client = await get_redis()
        await client.set(key, json.dumps(value, default=str), ex=ttl)
    except Exception:
        pass


async def cache_delete_pattern(pattern: str) -> None:
    try:
        client = await get_redis()
        keys = [key async for key in client.scan_iter(match=pattern)]
        if keys:
            await client.delete(*keys)
    except Exception:
        pass


async def try_acquire_lock(key: str, ttl: int) -> bool:
    """Best-effort SET NX EX lock. Returns False on any Redis error.

    This intentionally fails CLOSED, unlike every other function in this
    module (which fail open -- a cache miss is harmless). A debounce lock
    exists specifically to stop N events from triggering N expensive calls;
    if Redis is unreachable and this returned True unconditionally instead,
    every caller would proceed as if it held the lock, and the debounce
    protection would silently vanish at exactly the moment -- an outage --
    when duplicate expensive work is most likely. The trade-off is that a
    Redis outage also pauses whatever this lock gates (here: merchant AI
    summary refreshes) rather than letting it run unprotected.
    """
    try:
        client = await get_redis()
        return bool(await client.set(key, "1", ex=ttl, nx=True))
    except Exception:
        return False
