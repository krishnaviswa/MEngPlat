import json
from datetime import UTC, datetime
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


async def blocklist_token(jti: str, exp: float) -> None:
    """Revoke a token by jti until it would have expired anyway.

    TTL is derived from the token's own exp claim, so the blocklist entry
    self-expires exactly when the token would have stopped working
    naturally -- nothing ever needs to clean this up. Fails open like
    cache_get/cache_set: if Redis is unreachable, the token simply isn't
    blocklisted rather than raising into the logout/refresh request.
    """
    ttl = int(exp - datetime.now(UTC).timestamp())
    if ttl <= 0:
        return
    try:
        client = await get_redis()
        await client.set(f"blocklist:token:{jti}", "1", ex=ttl)
    except Exception:
        pass


async def is_token_blocklisted(jti: str) -> bool:
    """Fail-open blocklist check: Redis unreachable -> not blocklisted -> allow.

    Deliberately the opposite of try_acquire_lock's fail-closed behavior.
    This is called from get_current_user, the chokepoint for every
    authenticated request platform-wide -- failing closed here would mean a
    Redis outage 401s every protected request across the whole platform,
    whereas failing open just means a revoked token stays valid until its
    natural exp (<=30 min for access tokens) during the outage.
    """
    try:
        client = await get_redis()
        return bool(await client.exists(f"blocklist:token:{jti}"))
    except Exception:
        return False
