"""Contract every partner provider implements (S-123). Routers never call a provider class directly."""

from __future__ import annotations

import abc
from typing import Any, ClassVar


class PartnerProvider(abc.ABC):
    provider_name: ClassVar[str]

    @abc.abstractmethod
    def verify_request_signature(self, body: bytes, signature: str | None, secret: str) -> bool:
        """True when ``X-MH-Signature`` matches an HMAC-SHA256 of the raw body."""

    @abc.abstractmethod
    async def send_callback(self, callback_url: str, event: dict[str, Any], secret: str) -> None:
        """Deliver a signed event to the partner's registered callback URL.

        The ``mock`` provider logs the delivery (with its signature) instead of
        making an HTTP call.
        """
