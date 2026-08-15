"""Razorpay Orders API + webhook HMAC + refunds. Keys only from env."""

from __future__ import annotations

import httpx

from app.config import get_settings
from app.services.payments.base import ProviderOrder, WebhookEvent
from app.services.payments.hmac_util import loads_json, parse_razorpay_event, signatures_match

RAZORPAY_ORDERS_URL = "https://api.razorpay.com/v1/orders"
RAZORPAY_PAYMENTS_URL = "https://api.razorpay.com/v1/payments"


class RazorpayPaymentProvider:
    name = "razorpay"

    def __init__(self) -> None:
        settings = get_settings()
        self.key_id = settings.razorpay_key_id
        self.key_secret = settings.razorpay_key_secret
        self.webhook_secret = settings.razorpay_webhook_secret

    async def create_order(
        self, amount_paise: int, currency: str, receipt: str, notes: dict[str, str]
    ) -> ProviderOrder:
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.post(
                RAZORPAY_ORDERS_URL,
                auth=(self.key_id, self.key_secret),
                json={"amount": amount_paise, "currency": currency, "receipt": receipt, "notes": notes},
            )
            response.raise_for_status()
            data = response.json()
        return ProviderOrder(
            provider_order_id=data["id"],
            key_id=self.key_id,
            amount_paise=int(data.get("amount", amount_paise)),
            currency=data.get("currency", currency),
            extra=data,
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
        if not provider_payment_id:
            return
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.post(
                f"{RAZORPAY_PAYMENTS_URL}/{provider_payment_id}/refund",
                auth=(self.key_id, self.key_secret),
                json={},
            )
            response.raise_for_status()
