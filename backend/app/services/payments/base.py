"""The contract every payment provider implements. Routers never call Razorpay directly."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Protocol


@dataclass
class ProviderOrder:
    provider_order_id: str
    key_id: str
    amount_paise: int
    currency: str
    extra: dict[str, Any]


@dataclass
class WebhookEvent:
    event: str
    provider_order_id: str
    provider_payment_id: str | None
    amount_captured_paise: int | None
    gateway_fee_paise: int | None
    raw: dict[str, Any]


class PaymentProvider(Protocol):
    name: str

    async def create_order(
        self, amount_paise: int, currency: str, receipt: str, notes: dict[str, str]
    ) -> ProviderOrder: ...

    def verify_webhook(self, body: bytes, signature: str) -> WebhookEvent | None: ...

    async def refund(self, provider_order_id: str, provider_payment_id: str | None = None) -> None: ...
