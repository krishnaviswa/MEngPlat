"""Deterministic WhatsApp provider — no network (S-050 AC9)."""

from __future__ import annotations

import hashlib
import hmac
import logging

from app.config import get_settings
from app.services.whatsapp.base import InboundMessage, WhatsAppProvider
from app.services.whatsapp.payload import loads_json, parse_meta_payload
from app.services.whatsapp.registry import register_provider

logger = logging.getLogger(__name__)

MOCK_NUMBER = "15551234567"
MOCK_VERIFY_TOKEN = "mock-verify-token"
MOCK_WEBHOOK_SECRET = "mock-webhook-secret"

# 1x1 PNG so S-051 tests persist a real file through LocalStorageProvider.
MOCK_PNG = (
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01"
    b"\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01"
    b"\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82"
)


@register_provider("mock")
class MockWhatsAppProvider(WhatsAppProvider):
    provider_name = "mock"

    def __init__(self) -> None:
        settings = get_settings()
        self._number = "".join(c for c in (settings.whatsapp_business_number or MOCK_NUMBER) if c.isdigit()) or MOCK_NUMBER
        self._verify_token = settings.meta_whatsapp_verify_token or MOCK_VERIFY_TOKEN
        self._secret = settings.meta_whatsapp_app_secret or MOCK_WEBHOOK_SECRET

    def is_available(self) -> bool:
        return True

    def display_number(self) -> str:
        return self._number

    def verify_webhook_challenge(self, mode: str | None, token: str | None) -> bool:
        return mode == "subscribe" and hmac.compare_digest(token or "", self._verify_token)

    def verify_signature(self, body: bytes, signature: str | None) -> bool:
        if not signature:
            return False
        if signature == "sha256=mock":
            return True
        expected = "sha256=" + hmac.new(self._secret.encode(), body, hashlib.sha256).hexdigest()
        return hmac.compare_digest(expected, signature)

    def parse_inbound(self, body: bytes) -> list[InboundMessage]:
        try:
            return parse_meta_payload(loads_json(body))
        except (ValueError, UnicodeDecodeError):
            return []

    async def send_message(self, to_phone: str, text: str) -> None:
        logger.info("whatsapp_mock_ack to=%s text=%s", to_phone, text)

    async def download_media(self, media_id: str) -> tuple[bytes, str]:
        if media_id == "mock-media-fail":
            raise FileNotFoundError("mock media missing")
        return MOCK_PNG, "image/png"
