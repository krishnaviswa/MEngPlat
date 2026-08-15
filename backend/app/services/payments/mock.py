"""In-process mock gateway. No network; HMAC still required on webhooks."""

from __future__ import annotations

import uuid

from app.config import get_settings
from app.services.payments.base import ProviderOrder, WebhookEvent
from app.services.payments.hmac_util import loads_json, parse_razorpay_event, signatures_match
from app.services.payments.sku import FEATURED_CURRENCY


class MockPaymentProvider:
    name = "mock"

    def __init__(self) -> None:
        settings = get_settings()
        self.webhook_secret = settings.razorpay_webhook_secret or "mock-webhook-secret"
        self.key_id = settings.razorpay_key_id or "rzp_test_mock"

    async def create_order(
        self, amount_paise: int, currency: str, receipt: str, notes: dict[str, str]
    ) -> ProviderOrder:
        order_id = f"order_mock_{uuid.uuid4().hex[:16]}"
        return ProviderOrder(
            provider_order_id=order_id,
            key_id=self.key_id,
            amount_paise=amount_paise,
            currency=currency or FEATURED_CURRENCY,
            extra={"receipt": receipt, "notes": notes},
        )

    def verify_webhook(self, body: bytes, signature: str) -> WebhookEvent | None:
        if not signatures_match(self.webhook_secret, body, signature):
            return None
        try:
            payload = loads_json(body)
        except (ValueError, UnicodeDecodeError):
            return None
        return parse_razorpay_event(payload)

    async def refund(self, provider_order_id: str, provider_payment_id: str | None = None) -> None:
        return None
