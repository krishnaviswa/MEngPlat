"""S-036 payments port, fee split, HMAC, RBAC, featured activate/disable."""

from __future__ import annotations

import json
import uuid
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, patch

import pytest
from fastapi import HTTPException

from app.dependencies import require_roles
from app.models import Payment, PaymentStatus, User, UserRole
from app.services.payments.hmac_util import parse_razorpay_event, sign_body, signatures_match
from app.services.payments.mock import MockPaymentProvider
from app.services.payments.sku import FEATURED_AMOUNT_PAISE, MOCK_GATEWAY_FEE_PAISE, split_fees


def _make_user(role: UserRole) -> User:
    return User(
        id=uuid.uuid4(),
        email=f"{role.value}-{uuid.uuid4().hex[:6]}@example.com",
        full_name="Test",
        role=role,
        is_active=True,
    )


class TestFeeSplit:
    def test_mock_estimate_sums_to_captured(self):
        platform, gateway = split_fees(FEATURED_AMOUNT_PAISE, None)
        assert gateway == MOCK_GATEWAY_FEE_PAISE
        assert platform + gateway == FEATURED_AMOUNT_PAISE

    def test_webhook_fee_not_double_counted(self):
        platform, gateway = split_fees(49900, 1178)
        assert gateway == 1178
        assert platform == 48722


class TestHmac:
    def test_round_trip(self):
        body = b'{"event":"payment.captured"}'
        sig = sign_body("secret", body)
        assert signatures_match("secret", body, sig)
        assert not signatures_match("secret", body, "deadbeef")

    def test_parse_captured_payload(self):
        event = parse_razorpay_event(
            {
                "event": "payment.captured",
                "payload": {
                    "payment": {
                        "entity": {
                            "id": "pay_1",
                            "order_id": "order_1",
                            "amount": 49900,
                            "fee": 1178,
                        }
                    }
                },
            }
        )
        assert event is not None
        assert event.provider_order_id == "order_1"
        assert event.gateway_fee_paise == 1178


class TestMockProvider:
    async def test_create_order_no_network(self):
        provider = MockPaymentProvider()
        order = await provider.create_order(49900, "INR", "r1", {"sku": "featured_7d"})
        assert order.provider_order_id.startswith("order_mock_")
        assert order.amount_paise == 49900

    async def test_verify_rejects_bad_signature(self):
        provider = MockPaymentProvider()
        body = json.dumps(
            {
                "event": "payment.captured",
                "payload": {"payment": {"entity": {"order_id": "order_x", "amount": 49900}}},
            }
        ).encode()
        assert provider.verify_webhook(body, "nope") is None
        sig = sign_body(provider.webhook_secret, body)
        event = provider.verify_webhook(body, sig)
        assert event is not None
        assert event.provider_order_id == "order_x"


class TestPaymentsRBAC:
    @pytest.mark.parametrize("role", [UserRole.CUSTOMER, UserRole.ADMIN])
    async def test_checkout_requires_merchant(self, role):
        checker = require_roles(UserRole.MERCHANT)
        with pytest.raises(HTTPException) as exc:
            await checker(user=_make_user(role))
        assert exc.value.status_code == 403

    @pytest.mark.parametrize("role", [UserRole.CUSTOMER, UserRole.MERCHANT])
    async def test_admin_actions_require_admin(self, role):
        checker = require_roles(UserRole.ADMIN)
        with pytest.raises(HTTPException) as exc:
            await checker(user=_make_user(role))
        assert exc.value.status_code == 403


class FakeFlushDB:
    def __init__(self):
        self.added = []

    def add(self, obj):
        self.added.append(obj)

    async def flush(self):
        pass

    async def execute(self, stmt):
        class R:
            def scalar_one_or_none(self_inner):
                return None

        return R()


class TestApplyCaptured:
    async def test_paid_creates_placement_and_invalidates_search(self):
        from app.services.payments.base import WebhookEvent
        from app.services.payments.featured import apply_captured_payment

        payment = Payment(
            id=uuid.uuid4(),
            business_id=uuid.uuid4(),
            merchant_user_id=uuid.uuid4(),
            provider="mock",
            provider_order_id="order_mock_abc",
            status=PaymentStatus.CREATED,
            amount_paise=49900,
            currency="INR",
        )
        db = FakeFlushDB()
        event = WebhookEvent(
            event="payment.captured",
            provider_order_id=payment.provider_order_id,
            provider_payment_id="pay_1",
            amount_captured_paise=49900,
            gateway_fee_paise=None,
            raw={},
        )
        with patch("app.services.payments.featured.cache_delete_pattern", new_callable=AsyncMock) as cache:
            activated = await apply_captured_payment(db, payment, event)
        assert activated is True
        assert payment.status == PaymentStatus.PAID
        assert payment.platform_fee_paise + payment.gateway_fee_paise == 49900
        assert db.added
        cache.assert_awaited_once_with("search:*")

    async def test_failed_does_not_place(self):
        from app.services.payments.featured import mark_payment_failed

        payment = Payment(
            id=uuid.uuid4(),
            business_id=uuid.uuid4(),
            merchant_user_id=uuid.uuid4(),
            provider="mock",
            provider_order_id="order_mock_fail",
            status=PaymentStatus.CREATED,
            amount_paise=49900,
            currency="INR",
        )
        db = FakeFlushDB()
        await mark_payment_failed(db, payment)
        assert payment.status == PaymentStatus.FAILED
        assert db.added == []


class TestDisableRefund:
    async def test_disable_sets_disabled_at(self):
        from app.models import FeaturedPlacement
        from app.services.payments.featured import disable_placement

        placement = FeaturedPlacement(
            id=uuid.uuid4(),
            business_id=uuid.uuid4(),
            payment_id=uuid.uuid4(),
            starts_at=datetime.now(timezone.utc),
            ends_at=datetime.now(timezone.utc) + timedelta(days=7),
            disabled_at=None,
        )
        db = FakeFlushDB()
        with patch("app.services.payments.featured.cache_delete_pattern", new_callable=AsyncMock) as cache:
            await disable_placement(db, placement)
        assert placement.disabled_at is not None
        cache.assert_awaited_once_with("search:*")

    async def test_refund_rejects_created(self):
        from app.services.payments.featured import refund_payment

        payment = Payment(
            id=uuid.uuid4(),
            business_id=uuid.uuid4(),
            merchant_user_id=uuid.uuid4(),
            provider="mock",
            provider_order_id="order_x",
            status=PaymentStatus.CREATED,
            amount_paise=49900,
            currency="INR",
        )
        with pytest.raises(ValueError):
            await refund_payment(FakeFlushDB(), payment)
