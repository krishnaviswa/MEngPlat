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
from app.services.payments.sku import get_sku, mock_gateway_fee_paise, split_fees


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
        amount = get_sku("featured_7d")["amount_paise"]
        platform, gateway = split_fees(amount, None)
        assert gateway == mock_gateway_fee_paise(amount)
        assert platform + gateway == amount

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
    async def test_paid_records_fees_without_placement(self):
        from app.services.payments.base import WebhookEvent
        from app.services.payments.featured import apply_captured_payment

        payment = Payment(
            id=uuid.uuid4(),
            business_id=uuid.uuid4(),
            merchant_user_id=uuid.uuid4(),
            provider="mock",
            provider_order_id="order_mock_abc",
            status=PaymentStatus.CREATED,
            amount_paise=29900,
            currency="INR",
            sku_code="featured_7d",
            duration_days=7,
        )
        db = FakeFlushDB()
        event = WebhookEvent(
            event="payment.captured",
            provider_order_id=payment.provider_order_id,
            provider_payment_id="pay_1",
            amount_captured_paise=29900,
            gateway_fee_paise=None,
            raw={},
        )
        with patch("app.services.payments.featured.cache_delete_pattern", new_callable=AsyncMock) as cache:
            activated = await apply_captured_payment(db, payment, event)
        assert activated is False
        assert payment.status == PaymentStatus.PAID
        assert payment.platform_fee_paise + payment.gateway_fee_paise == 29900
        assert db.added == []
        cache.assert_not_awaited()

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

    async def test_refund_disables_linked_placement(self):
        from app.models import FeaturedPlacement
        from app.services.payments.featured import refund_payment

        payment = Payment(
            id=uuid.uuid4(),
            business_id=uuid.uuid4(),
            merchant_user_id=uuid.uuid4(),
            provider="mock",
            provider_order_id="order_refund",
            status=PaymentStatus.PAID,
            amount_paise=49900,
            currency="INR",
        )
        placement = FeaturedPlacement(
            id=uuid.uuid4(),
            business_id=payment.business_id,
            payment_id=payment.id,
            starts_at=datetime.now(timezone.utc),
            ends_at=datetime.now(timezone.utc) + timedelta(days=7),
            disabled_at=None,
        )

        class FakeDB:
            async def execute(self, stmt):
                class R:
                    def scalar_one_or_none(self_inner):
                        return placement

                return R()

            async def flush(self):
                pass

        with patch("app.services.payments.featured.cache_delete_pattern", new_callable=AsyncMock) as cache:
            with patch("app.services.payments.get_payment_provider") as gp:
                gp.return_value.refund = AsyncMock()
                result = await refund_payment(FakeDB(), payment)
        assert result.status == PaymentStatus.REFUNDED
        assert placement.disabled_at is not None
        cache.assert_awaited_once_with("search:*")


class TestSkuAndSchema:
    def test_catalog_has_three_skus(self):
        from app.services.payments.sku import catalog, sku_payload

        codes = {s["code"] for s in catalog()}
        assert codes == {"featured_7d", "featured_15d", "featured_30d"}
        assert sku_payload("featured_7d")["listed_price_inr"] == 299
        assert sku_payload("featured_15d")["listed_price_inr"] == 499
        assert sku_payload("featured_30d")["listed_price_inr"] == 899
        assert get_sku("featured_30d")["amount_paise"] == 89900

    def test_payment_and_placement_tables_store_no_card_pan(self):
        from app.models import FeaturedPlacement, Payment

        forbidden = {
            "pan",
            "card_number",
            "card_last4",
            "last4",
            "cvv",
            "cvc",
            "card_token",
            "network_token",
            "card_pan",
        }
        payment_cols = {c.name.lower() for c in Payment.__table__.columns}
        placement_cols = {c.name.lower() for c in FeaturedPlacement.__table__.columns}
        assert not (payment_cols & forbidden)
        assert not (placement_cols & forbidden)


class TestPlacementActive:
    def test_disabled_or_expired_is_not_active(self):
        from app.models import FeaturedPlacement
        from app.services.payments.featured import is_placement_active

        now = datetime.now(timezone.utc)
        live = FeaturedPlacement(
            id=uuid.uuid4(),
            business_id=uuid.uuid4(),
            payment_id=uuid.uuid4(),
            starts_at=now - timedelta(days=1),
            ends_at=now + timedelta(days=6),
            disabled_at=None,
        )
        assert is_placement_active(live, now) is True
        live.disabled_at = now
        assert is_placement_active(live, now) is False
        live.disabled_at = None
        live.ends_at = now - timedelta(seconds=1)
        assert is_placement_active(live, now) is False


class TestApplyCapturedAlreadyPaid:
    async def test_already_paid_does_not_stack_placement(self):
        from app.services.payments.base import WebhookEvent
        from app.services.payments.featured import apply_captured_payment

        payment = Payment(
            id=uuid.uuid4(),
            business_id=uuid.uuid4(),
            merchant_user_id=uuid.uuid4(),
            provider="mock",
            provider_order_id="order_dup",
            status=PaymentStatus.PAID,
            amount_paise=49900,
            currency="INR",
        )
        db = FakeFlushDB()
        event = WebhookEvent(
            event="payment.captured",
            provider_order_id=payment.provider_order_id,
            provider_payment_id="pay_1",
            amount_captured_paise=49900,
            gateway_fee_paise=1178,
            raw={},
        )
        with patch("app.services.payments.featured.cache_delete_pattern", new_callable=AsyncMock) as cache:
            activated = await apply_captured_payment(db, payment, event)
        assert activated is False
        assert db.added == []
        cache.assert_not_awaited()


class TestFeaturedCheckoutRouter:
    async def test_pending_listing_is_400(self):
        from types import SimpleNamespace

        from app.models import BusinessStatus
        from app.routers.payments import featured_checkout
        from app.schemas import FeaturedCheckoutRequest

        biz = SimpleNamespace(id=uuid.uuid4(), status=BusinessStatus.PENDING)
        with (
            patch("app.routers.payments.get_merchant_for_user", new_callable=AsyncMock, return_value=SimpleNamespace()),
            patch("app.routers.payments.get_owned_business", new_callable=AsyncMock, return_value=biz),
        ):
            with pytest.raises(HTTPException) as exc:
                await featured_checkout(
                    FeaturedCheckoutRequest(business_id=biz.id, sku_code="featured_7d"),
                    db=FakeFlushDB(),
                    user=_make_user(UserRole.MERCHANT),
                )
        assert exc.value.status_code == 400

    async def test_unknown_sku_is_400(self):
        from app.routers.payments import featured_checkout
        from app.schemas import FeaturedCheckoutRequest

        with pytest.raises(HTTPException) as exc:
            await featured_checkout(
                FeaturedCheckoutRequest(business_id=uuid.uuid4(), sku_code="featured_forever"),
                db=FakeFlushDB(),
                user=_make_user(UserRole.MERCHANT),
            )
        assert exc.value.status_code == 400

    async def test_active_placement_is_409(self):
        from types import SimpleNamespace

        from app.models import BusinessStatus
        from app.routers.payments import featured_checkout
        from app.schemas import FeaturedCheckoutRequest

        biz = SimpleNamespace(id=uuid.uuid4(), status=BusinessStatus.APPROVED)
        with (
            patch("app.routers.payments.get_merchant_for_user", new_callable=AsyncMock, return_value=SimpleNamespace()),
            patch("app.routers.payments.get_owned_business", new_callable=AsyncMock, return_value=biz),
            patch("app.routers.payments.get_active_placement_for_business", new_callable=AsyncMock, return_value=object()),
        ):
            with pytest.raises(HTTPException) as exc:
                await featured_checkout(
                    FeaturedCheckoutRequest(business_id=biz.id, sku_code="featured_7d"),
                    db=FakeFlushDB(),
                    user=_make_user(UserRole.MERCHANT),
                )
        assert exc.value.status_code == 409

    async def test_approved_checkout_uses_requested_sku(self):
        from types import SimpleNamespace

        from app.models import BusinessStatus
        from app.routers.payments import featured_checkout
        from app.schemas import FeaturedCheckoutRequest
        from app.services.payments.mock import MockPaymentProvider

        biz = SimpleNamespace(id=uuid.uuid4(), status=BusinessStatus.APPROVED)
        with (
            patch("app.routers.payments.get_merchant_for_user", new_callable=AsyncMock, return_value=SimpleNamespace()),
            patch("app.routers.payments.get_owned_business", new_callable=AsyncMock, return_value=biz),
            patch("app.routers.payments.get_active_placement_for_business", new_callable=AsyncMock, return_value=None),
            patch("app.routers.payments.get_payment_provider", return_value=MockPaymentProvider()),
        ):
            result = await featured_checkout(
                FeaturedCheckoutRequest(business_id=biz.id, sku_code="featured_15d"),
                db=FakeFlushDB(),
                user=_make_user(UserRole.MERCHANT),
            )
        assert result.amount_paise == 49900
        assert result.currency == "INR"
        assert result.sku.code == "featured_15d"
        assert result.sku.duration_days == 15
        assert result.sku.listed_price_inr == 499
        assert result.checkout.amount == 49900


class TestWebhookAndMockComplete:
    async def test_webhook_missing_signature_is_400(self):
        from app.routers.payments import razorpay_webhook

        class DummyRequest:
            async def body(self):
                return b"{}"

        with pytest.raises(HTTPException) as exc:
            await razorpay_webhook(DummyRequest(), db=FakeFlushDB(), x_razorpay_signature=None)
        assert exc.value.status_code == 400

    async def test_mock_complete_404_when_debug_false(self):
        from types import SimpleNamespace

        from app.routers.payments import mock_complete
        from app.schemas import MockCompleteRequest

        with patch("app.routers.payments.get_settings", return_value=SimpleNamespace(debug=False)):
            with pytest.raises(HTTPException) as exc:
                await mock_complete(
                    MockCompleteRequest(provider_order_id="order_x", outcome="paid"),
                    db=FakeFlushDB(),
                    user=_make_user(UserRole.ADMIN),
                )
        assert exc.value.status_code == 404


class TestPlacementLedgerRBAC:
    async def test_merchant_response_omits_fee_split(self):
        from app.routers.payments import get_placement

        business_id = uuid.uuid4()
        with (
            patch("app.routers.payments.get_merchant_for_user", new_callable=AsyncMock, return_value=object()),
            patch("app.routers.payments.get_owned_business", new_callable=AsyncMock, return_value=object()),
            patch("app.routers.payments.get_active_placement_for_business", new_callable=AsyncMock, return_value=None),
        ):
            resp = await get_placement(business_id, db=FakeFlushDB(), user=_make_user(UserRole.MERCHANT))
        assert resp.payment is None
        assert {s.code for s in resp.skus} == {"featured_7d", "featured_15d", "featured_30d"}
        assert resp.sku.listed_price_inr == 299

    async def test_admin_response_includes_fee_split(self):
        from types import SimpleNamespace

        from app.models import FeaturedPlacement
        from app.routers.payments import get_placement

        business_id = uuid.uuid4()
        payment = Payment(
            id=uuid.uuid4(),
            business_id=business_id,
            merchant_user_id=uuid.uuid4(),
            provider="mock",
            provider_order_id="order_ledger",
            status=PaymentStatus.PAID,
            amount_paise=49900,
            currency="INR",
            platform_fee_paise=48722,
            gateway_fee_paise=1178,
            created_at=datetime.now(timezone.utc),
        )

        placement = FeaturedPlacement(
            id=uuid.uuid4(),
            business_id=business_id,
            payment_id=payment.id,
            starts_at=datetime.now(timezone.utc),
            ends_at=datetime.now(timezone.utc) + timedelta(days=7),
            disabled_at=None,
        )

        class AdminDB(FakeFlushDB):
            async def get(self, model, ident):
                return payment

        with (
            patch(
                "app.routers.payments.get_business",
                new_callable=AsyncMock,
                return_value=SimpleNamespace(id=business_id),
            ),
            patch(
                "app.routers.payments.get_active_placement_for_business",
                new_callable=AsyncMock,
                return_value=placement,
            ),
        ):
            resp = await get_placement(business_id, db=AdminDB(), user=_make_user(UserRole.ADMIN))
        assert resp.payment is not None
        assert resp.payment.platform_fee_paise == 48722
        assert resp.payment.gateway_fee_paise == 1178
        assert resp.payment.platform_fee_paise + resp.payment.gateway_fee_paise == 49900


class TestApproveReject:
    async def test_approve_creates_placement_and_invalidates_search(self):
        from app.services.payments.featured import approve_payment

        payment = Payment(
            id=uuid.uuid4(),
            business_id=uuid.uuid4(),
            merchant_user_id=uuid.uuid4(),
            provider="mock",
            provider_order_id="order_ok",
            status=PaymentStatus.PAID,
            amount_paise=29900,
            currency="INR",
            sku_code="featured_7d",
            duration_days=7,
        )
        db = FakeFlushDB()
        with patch("app.services.payments.featured.cache_delete_pattern", new_callable=AsyncMock) as cache:
            with patch(
                "app.services.payments.featured.get_active_placement_for_business",
                new_callable=AsyncMock,
                return_value=None,
            ):
                placement = await approve_payment(db, payment)
        assert payment.approved_at is not None
        assert placement.payment_id == payment.id
        assert db.added
        cache.assert_awaited_once_with("search:*")

    async def test_approve_created_is_not_paid(self):
        from app.services.payments.featured import approve_payment

        payment = Payment(
            id=uuid.uuid4(),
            business_id=uuid.uuid4(),
            merchant_user_id=uuid.uuid4(),
            provider="mock",
            provider_order_id="order_created",
            status=PaymentStatus.CREATED,
            amount_paise=29900,
            currency="INR",
            sku_code="featured_7d",
            duration_days=7,
        )
        with pytest.raises(ValueError, match="not_paid"):
            await approve_payment(FakeFlushDB(), payment)

    async def test_reject_does_not_place(self):
        from app.services.payments.featured import reject_payment

        payment = Payment(
            id=uuid.uuid4(),
            business_id=uuid.uuid4(),
            merchant_user_id=uuid.uuid4(),
            provider="mock",
            provider_order_id="order_rej",
            status=PaymentStatus.PAID,
            amount_paise=29900,
            currency="INR",
            sku_code="featured_7d",
            duration_days=7,
        )
        db = FakeFlushDB()
        result = await reject_payment(db, payment)
        assert result.rejected_at is not None
        assert db.added == []

    async def test_admin_approve_requires_admin(self):
        checker = require_roles(UserRole.ADMIN)
        with pytest.raises(HTTPException) as exc:
            await checker(user=_make_user(UserRole.MERCHANT))
        assert exc.value.status_code == 403


class TestPaymentsStartup:
    def test_mock_needs_no_razorpay_keys(self, monkeypatch):
        from app.config import get_settings
        from app.services.payments import validate_startup_config

        monkeypatch.setenv("PAYMENTS_PROVIDER", "mock")
        get_settings.cache_clear()
        try:
            validate_startup_config()
        finally:
            get_settings.cache_clear()

    def test_razorpay_without_keys_fails_startup(self, monkeypatch):
        from app.config import get_settings
        from app.services.payments import validate_startup_config

        monkeypatch.setenv("PAYMENTS_PROVIDER", "razorpay")
        monkeypatch.setenv("RAZORPAY_KEY_ID", "")
        monkeypatch.setenv("RAZORPAY_KEY_SECRET", "")
        monkeypatch.setenv("RAZORPAY_WEBHOOK_SECRET", "")
        get_settings.cache_clear()
        try:
            with pytest.raises(RuntimeError, match="RAZORPAY"):
                validate_startup_config()
        finally:
            get_settings.cache_clear()

    def test_unregistered_provider_fails_startup(self, monkeypatch):
        from app.config import get_settings
        from app.services.payments import validate_startup_config

        monkeypatch.setenv("PAYMENTS_PROVIDER", "stripe")
        get_settings.cache_clear()
        try:
            with pytest.raises(RuntimeError, match="not a registered provider"):
                validate_startup_config()
        finally:
            get_settings.cache_clear()


class TestAlembicPaymentStatusEnum:
    def test_migration_creates_enum_once(self):
        from pathlib import Path

        text = Path(__file__).resolve().parents[1].joinpath(
            "alembic/versions/20260815_1037-d5e6f7a8b9c0_add_payments_and_featured_placements.py"
        ).read_text(encoding="utf-8")
        assert "create_type=False" in text
        assert "checkfirst=True" in text
        assert text.count("payment_status.create(") == 1
