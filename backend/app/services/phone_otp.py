"""Phone OTP store (ADR-011). Redis hashed codes, fail-closed like password reset."""

from __future__ import annotations

import hashlib
import re
import secrets

from app.services.cache import get_redis

OTP_TTL_SECONDS = 300
OTP_GENERIC_MESSAGE = "If that number can receive SMS, we sent a sign-in code."


class InvalidPhoneError(ValueError):
    pass


def normalize_phone(raw: str) -> str:
    digits = re.sub(r"\D", "", raw or "")
    if len(digits) == 10:
        return f"+91{digits}"
    if digits.startswith("91") and len(digits) == 12:
        return f"+{digits}"
    if digits.startswith("0") and len(digits) == 11:
        return f"+91{digits[1:]}"
    if len(digits) >= 10:
        return f"+{digits}"
    raise InvalidPhoneError("Enter a valid mobile number")


def _otp_key(phone: str) -> str:
    return f"auth:otp:{phone}"


def _hash_code(code: str) -> str:
    return hashlib.sha256(code.encode("utf-8")).hexdigest()


async def issue_otp(phone: str) -> str:
    """Store a hashed 6-digit code. Returns the plaintext code for the SMS provider only."""
    code = f"{secrets.randbelow(1_000_000):06d}"
    client = await get_redis()
    await client.set(_otp_key(phone), _hash_code(code), ex=OTP_TTL_SECONDS)
    return code


async def consume_otp(phone: str, code: str) -> bool:
    """True if code matches; deletes the challenge. Raises on Redis error.

    Temporary demo bypass: when `SMS_PROVIDER=mock` and `DEMO_PHONE_OTP` is set,
    that exact code is accepted (see docs/agents/REMOVE-ME-demo-fixed-otp.md).
    """
    from app.config import get_settings

    settings = get_settings()
    demo = (settings.demo_phone_otp or "").strip()
    if demo and settings.sms_provider == "mock" and code.strip() == demo:
        return True

    client = await get_redis()
    key = _otp_key(phone)
    stored = await client.get(key)
    if stored is None:
        return False
    digest = stored.decode() if isinstance(stored, bytes) else stored
    if digest != _hash_code(code.strip()):
        return False
    await client.delete(key)
    return True
