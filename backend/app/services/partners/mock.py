"""In-process mock partner provider (S-123). No vendor keys; HMAC verified for real.

The callback is a **best-effort real HTTP POST** to the partner's registered URL
(so the loop is visible end to end in local dev) — it logs and swallows any
failure, and never blocks the review submission that triggered it.
"""

from __future__ import annotations

import json
import logging
from typing import Any

import httpx

from app.services.partners.hmac_util import header_value, signatures_match

logger = logging.getLogger("app.partners")


class MockPartnerProvider:
    provider_name = "mock"

    def verify_request_signature(self, body: bytes, signature: str | None, secret: str) -> bool:
        return signatures_match(secret, body, signature)

    async def send_callback(self, callback_url: str, event: dict[str, Any], secret: str) -> None:
        body = json.dumps(event, separators=(",", ":"), sort_keys=True).encode("utf-8")
        signature = header_value(secret, body)
        logger.info("partner callback (mock) -> %s  X-MH-Signature: %s  %s", callback_url, signature, body.decode())
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.post(
                    callback_url,
                    content=body,
                    headers={"Content-Type": "application/json", "X-MH-Signature": signature},
                )
            logger.info("partner callback delivered -> %s (%s)", callback_url, resp.status_code)
        except Exception as exc:  # noqa: BLE001 - callback delivery must never fail the review
            logger.warning("partner callback POST failed -> %s (%s)", callback_url, exc)
