"""Contract every WhatsApp provider implements (S-050)."""

from __future__ import annotations

import abc
from dataclasses import dataclass, field
from typing import Any, ClassVar


@dataclass
class InboundMessage:
    from_phone: str
    message_id: str
    type: str  # text | image | other
    text: str | None = None
    media_id: str | None = None
    mime_type: str | None = None
    caption: str | None = None
    raw: dict[str, Any] = field(default_factory=dict)


class WhatsAppProvider(abc.ABC):
    provider_name: ClassVar[str]

    @abc.abstractmethod
    def is_available(self) -> bool:
        """False when the merchant card must show an unavailable empty state."""

    @abc.abstractmethod
    def display_number(self) -> str:
        """Digits used in wa.me links (no +)."""

    @abc.abstractmethod
    def verify_webhook_challenge(self, mode: str | None, token: str | None) -> bool: ...

    @abc.abstractmethod
    def verify_signature(self, body: bytes, signature: str | None) -> bool: ...

    @abc.abstractmethod
    def parse_inbound(self, body: bytes) -> list[InboundMessage]: ...

    @abc.abstractmethod
    async def send_message(self, to_phone: str, text: str) -> None: ...

    @abc.abstractmethod
    async def download_media(self, media_id: str) -> tuple[bytes, str]:
        """Return (bytes, content_type)."""

    def click_to_chat_url(self, prefilled_text: str) -> str:
        number = "".join(c for c in self.display_number() if c.isdigit())
        from urllib.parse import quote

        return f"https://wa.me/{number}?text={quote(prefilled_text)}"
