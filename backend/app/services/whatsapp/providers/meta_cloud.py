"""Meta WhatsApp Cloud API adapter. Unused unless WHATSAPP_PROVIDER=meta_cloud + token."""

from __future__ import annotations

import hashlib
import hmac
import logging

import httpx

from app.config import get_settings
from app.services.whatsapp.base import InboundMessage, WhatsAppProvider
from app.services.whatsapp.payload import loads_json, parse_meta_payload
from app.services.whatsapp.registry import register_provider

logger = logging.getLogger(__name__)
GRAPH = "https://graph.facebook.com/v21.0"


@register_provider("meta_cloud")
class MetaCloudWhatsAppProvider(WhatsAppProvider):
    provider_name = "meta_cloud"

    def __init__(self) -> None:
        settings = get_settings()
        self._token = settings.meta_whatsapp_access_token
        self._phone_id = settings.meta_whatsapp_phone_number_id
        self._verify_token = settings.meta_whatsapp_verify_token
        self._secret = settings.meta_whatsapp_app_secret
        self._number = "".join(c for c in settings.whatsapp_business_number if c.isdigit())

    def is_available(self) -> bool:
        return bool(self._token and self._phone_id and self._number and self._verify_token and self._secret)

    def display_number(self) -> str:
        return self._number

    def verify_webhook_challenge(self, mode: str | None, token: str | None) -> bool:
        if not self._verify_token:
            return False
        return mode == "subscribe" and hmac.compare_digest(token or "", self._verify_token)

    def verify_signature(self, body: bytes, signature: str | None) -> bool:
        if not signature or not self._secret:
            return False
        expected = "sha256=" + hmac.new(self._secret.encode(), body, hashlib.sha256).hexdigest()
        return hmac.compare_digest(expected, signature)

    def parse_inbound(self, body: bytes) -> list[InboundMessage]:
        try:
            return parse_meta_payload(loads_json(body))
        except (ValueError, UnicodeDecodeError):
            return []

    async def send_message(self, to_phone: str, text: str) -> None:
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.post(
                f"{GRAPH}/{self._phone_id}/messages",
                headers={"Authorization": f"Bearer {self._token}"},
                json={
                    "messaging_product": "whatsapp",
                    "to": to_phone,
                    "type": "text",
                    "text": {"body": text[:4096]},
                },
            )
            response.raise_for_status()

    async def download_media(self, media_id: str) -> tuple[bytes, str]:
        headers = {"Authorization": f"Bearer {self._token}"}
        async with httpx.AsyncClient(timeout=30.0) as client:
            meta = await client.get(f"{GRAPH}/{media_id}", headers=headers)
            meta.raise_for_status()
            url = meta.json().get("url")
            mime = meta.json().get("mime_type") or "image/jpeg"
            if not url:
                raise FileNotFoundError("media url missing")
            binary = await client.get(url, headers=headers)
            binary.raise_for_status()
            return binary.content, mime
