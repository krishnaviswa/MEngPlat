"""HMAC helpers shared by mock and Razorpay webhook verification."""

from __future__ import annotations

import hashlib
import hmac
import json
from typing import Any

from app.services.payments.base import WebhookEvent


def sign_body(secret: str, body: bytes) -> str:
    return hmac.new(secret.encode("utf-8"), body, hashlib.sha256).hexdigest()


def signatures_match(secret: str, body: bytes, signature: str) -> bool:
    expected = sign_body(secret, body)
    return hmac.compare_digest(expected, signature or "")


def parse_razorpay_event(payload: dict[str, Any]) -> WebhookEvent | None:
    event = str(payload.get("event") or "")
    payment = ((payload.get("payload") or {}).get("payment") or {}).get("entity") or {}
    order_id = payment.get("order_id") or payload.get("order_id")
    if not order_id:
        return None
    amount = payment.get("amount")
    fee = payment.get("fee")
    return WebhookEvent(
        event=event,
        provider_order_id=str(order_id),
        provider_payment_id=str(payment["id"]) if payment.get("id") else None,
        amount_captured_paise=int(amount) if amount is not None else None,
        gateway_fee_paise=int(fee) if fee is not None else None,
        raw=payload,
    )


def loads_json(body: bytes) -> dict[str, Any]:
    return json.loads(body.decode("utf-8"))
