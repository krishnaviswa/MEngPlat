"""Password-reset token store (ADR-007). Fail-closed by design -- unlike
app/services/cache.py, every function here lets a Redis error propagate.
Reset tokens are a single-shot secret: silently proceeding through a Redis
outage would either drop a reset the user was told happened, or accept a
password change with no stored challenge ever having been recorded.
"""

import hashlib
import secrets

from app.services.cache import get_redis

RESET_TOKEN_TTL_SECONDS = 3600


def _reset_key(token: str) -> str:
    digest = hashlib.sha256(token.encode("utf-8")).hexdigest()
    return f"auth:reset:{digest}"


async def create_reset_token(user_id: str) -> str:
    """Store a fresh high-entropy token (hashed) for user_id. Raises on Redis error."""
    token = secrets.token_urlsafe(32)
    client = await get_redis()
    await client.set(_reset_key(token), user_id, ex=RESET_TOKEN_TTL_SECONDS, nx=True)
    return token


async def consume_reset_token(token: str) -> str | None:
    """Look up and delete (single-use) the user_id for token. Raises on Redis error.

    Returns None for a missing/expired/already-used token -- callers must not
    distinguish those cases in the response (technical spec AC 2).
    """
    client = await get_redis()
    key = _reset_key(token)
    user_id = await client.get(key)
    if user_id is None:
        return None
    await client.delete(key)
    return user_id
