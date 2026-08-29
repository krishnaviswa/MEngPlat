"""HMAC helpers for the partner review channel (S-123).

Same scheme as the Razorpay / WhatsApp webhook checks: hex HMAC-SHA256 of the
raw request body, keyed by the partner's shared secret. The header value may
carry an optional ``sha256=`` prefix (``X-MH-Signature: sha256=<hex>``).
"""

from __future__ import annotations

import hashlib
import hmac


def sign_body(secret: str, body: bytes) -> str:
    """Return the bare hex HMAC-SHA256 of ``body`` under ``secret``."""
    return hmac.new(secret.encode("utf-8"), body, hashlib.sha256).hexdigest()


def header_value(secret: str, body: bytes) -> str:
    """Return the full ``sha256=<hex>`` header value a partner should send."""
    return f"sha256={sign_body(secret, body)}"


def signatures_match(secret: str, body: bytes, signature: str | None) -> bool:
    """Constant-time compare; tolerates a missing signature or ``sha256=`` prefix."""
    provided = (signature or "").strip()
    if provided.startswith("sha256="):
        provided = provided[len("sha256=") :]
    expected = sign_body(secret, body)
    return bool(provided) and hmac.compare_digest(expected, provided)
