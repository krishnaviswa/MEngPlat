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
