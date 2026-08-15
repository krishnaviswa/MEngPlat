"""Featured listing checkout, webhooks, mock complete, admin disable/refund."""

from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, Header, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.database import get_db
from app.dependencies import get_merchant_for_user, get_owned_business, require_roles
from app.models import BusinessStatus, FeaturedPlacement, Payment, PaymentStatus, User, UserRole
from app.schemas import (
    FeaturedCheckoutRequest,
    FeaturedCheckoutResponse,
    CheckoutFields,
    FeaturedSku,
    MockCompleteRequest,
    PaymentLedger,
    PaymentRefundResponse,
    PlacementDisableResponse,
    PlacementResponse,
    PlacementWindow,
    WebhookAck,
)
from app.services.payments import get_payment_provider
from app.services.payments.base import WebhookEvent
from app.services.payments.featured import (
    apply_captured_payment,
    disable_placement,
    get_active_placement_for_business,
    get_business,
    get_payment_by_order_id,
    is_placement_active,
    mark_payment_failed,
    refund_payment,
)
from app.services.payments.sku import (
    FEATURED_AMOUNT_PAISE,
    FEATURED_CURRENCY,
    sku_payload,
)

router = APIRouter(prefix="/payments", tags=["Payments"])


def _sku() -> FeaturedSku:
    return FeaturedSku(**sku_payload())


def _placement_window(p: FeaturedPlacement) -> PlacementWindow:
    return PlacementWindow(
        id=p.id,
        starts_at=p.starts_at,
        ends_at=p.ends_at,
        disabled_at=p.disabled_at,
        payment_id=p.payment_id,
    )


def _ledger(payment: Payment) -> PaymentLedger:
    return PaymentLedger(
        id=payment.id,
        status=payment.status.value,
        amount_paise=payment.amount_paise,
        currency=payment.currency,
        platform_fee_paise=payment.platform_fee_paise,
        gateway_fee_paise=payment.gateway_fee_paise,
        provider=payment.provider,
        provider_order_id=payment.provider_order_id,
        created_at=payment.created_at,
    )


@router.post("/featured/checkout", response_model=FeaturedCheckoutResponse)
async def featured_checkout(
    body: FeaturedCheckoutRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT)),
) -> FeaturedCheckoutResponse:
    """Start ₹499 / 7-day featured checkout for an owned approved listing. Auth: merchant."""
    merchant = await get_merchant_for_user(db, user)
    business = await get_owned_business(db, body.business_id, merchant)
    if business.status != BusinessStatus.APPROVED:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Listing is not approved")
    active = await get_active_placement_for_business(db, business.id)
    if active is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Active featured placement already exists")

    provider = get_payment_provider()
    order = await provider.create_order(
        FEATURED_AMOUNT_PAISE,
        FEATURED_CURRENCY,
        receipt=f"featured-{business.id.hex[:12]}",
        notes={"business_id": str(business.id), "sku": sku_payload()["code"]},
    )
    payment = Payment(
        id=uuid4(),
        business_id=business.id,
        merchant_user_id=user.id,
        provider=provider.name,
        provider_order_id=order.provider_order_id,
        status=PaymentStatus.CREATED,
        amount_paise=FEATURED_AMOUNT_PAISE,
        currency=FEATURED_CURRENCY,
    )
    db.add(payment)
    await db.flush()

    return FeaturedCheckoutResponse(
        payment_id=payment.id,
        provider=provider.name,
        provider_order_id=order.provider_order_id,
        amount_paise=FEATURED_AMOUNT_PAISE,
        currency=FEATURED_CURRENCY,
        sku=_sku(),
        checkout=CheckoutFields(
            key_id=order.key_id,
            order_id=order.provider_order_id,
            amount=FEATURED_AMOUNT_PAISE,
            currency=FEATURED_CURRENCY,
            name="MerchantHub AI",
            description="Featured listing boost — 7 days",
            prefill={"email": user.email, "name": user.full_name},
        ),
    )


@router.post("/webhooks/razorpay", response_model=WebhookAck)
async def razorpay_webhook(
    request: Request,
    db: AsyncSession = Depends(get_db),
    x_razorpay_signature: str | None = Header(default=None),
) -> WebhookAck:
    """Razorpay (or signed mock) webhook. Unauthenticated; HMAC required."""
    body = await request.body()
    if not x_razorpay_signature:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Missing signature")
    provider = get_payment_provider()
    event = provider.verify_webhook(body, x_razorpay_signature)
    if event is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid signature")
    return await _apply_webhook_event(db, event)


async def _apply_webhook_event(db: AsyncSession, event: WebhookEvent) -> WebhookAck:
    payment = await get_payment_by_order_id(db, event.provider_order_id)
    if payment is None:
        return WebhookAck(ok=True, duplicate=False)

    if event.event == "payment.captured" or (event.event == "" and event.amount_captured_paise):
        if payment.status == PaymentStatus.PAID:
            return WebhookAck(ok=True, duplicate=True)
        await apply_captured_payment(db, payment, event)
        return WebhookAck(ok=True, duplicate=False)

    if event.event in {"payment.failed", "payment.cancelled"}:
        await mark_payment_failed(db, payment)
        return WebhookAck(ok=True, duplicate=False)

    return WebhookAck(ok=True, duplicate=False)


@router.post("/mock/complete", response_model=WebhookAck)
async def mock_complete(
    body: MockCompleteRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.ADMIN)),
) -> WebhookAck:
    """DEBUG-only: admin completes a mock order. 404 when DEBUG is false."""
    settings = get_settings()
    if not settings.debug:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")
    payment = await get_payment_by_order_id(db, body.provider_order_id)
    if payment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Unknown order")
    if body.outcome == "failed":
        await mark_payment_failed(db, payment)
        return WebhookAck(ok=True, duplicate=False)
    event = WebhookEvent(
        event="payment.captured",
        provider_order_id=payment.provider_order_id,
        provider_payment_id=payment.provider_payment_id,
        amount_captured_paise=payment.amount_paise,
        gateway_fee_paise=None,
        raw={},
    )
    if payment.status == PaymentStatus.PAID:
        return WebhookAck(ok=True, duplicate=True)
    await apply_captured_payment(db, payment, event)
    return WebhookAck(ok=True, duplicate=False)


@router.get("/businesses/{business_id}/placement", response_model=PlacementResponse)
async def get_placement(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> PlacementResponse:
    """Active/expiry for a listing. Fee split is admin-only."""
    if user.role == UserRole.MERCHANT:
        merchant = await get_merchant_for_user(db, user)
        await get_owned_business(db, business_id, merchant)
    else:
        business = await get_business(db, business_id)
        if business is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")

    placement = await get_active_placement_for_business(db, business_id)
    if placement is None:
        result = await db.execute(
            select(FeaturedPlacement)
            .where(FeaturedPlacement.business_id == business_id)
            .order_by(FeaturedPlacement.starts_at.desc())
            .limit(1)
        )
        latest = result.scalar_one_or_none()
        window = _placement_window(latest) if latest else None
        active = False
        payment_id = latest.payment_id if latest else None
    else:
        window = _placement_window(placement)
        active = is_placement_active(placement)
        payment_id = placement.payment_id

    ledger = None
    if user.role == UserRole.ADMIN:
        if payment_id:
            payment = await db.get(Payment, payment_id)
        else:
            pay_result = await db.execute(
                select(Payment).where(Payment.business_id == business_id).order_by(Payment.created_at.desc()).limit(1)
            )
            payment = pay_result.scalar_one_or_none()
        if payment:
            ledger = _ledger(payment)

    return PlacementResponse(
        business_id=business_id,
        active=active,
        placement=window if active or (window and window.disabled_at) else (window if not active else None),
        sku=_sku(),
        payment=ledger,
    )


@router.post("/admin/placements/{placement_id}/disable", response_model=PlacementDisableResponse)
async def admin_disable_placement(
    placement_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.ADMIN)),
) -> PlacementDisableResponse:
    """Admin: drop featured rank without refund."""
    placement = await db.get(FeaturedPlacement, placement_id)
    if placement is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Placement not found")
    placement = await disable_placement(db, placement)
    assert placement.disabled_at is not None
    return PlacementDisableResponse(id=placement.id, disabled_at=placement.disabled_at)


@router.post("/admin/payments/{payment_id}/refund", response_model=PaymentRefundResponse)
async def admin_refund_payment(
    payment_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.ADMIN)),
) -> PaymentRefundResponse:
    """Admin: refund provider charge and disable linked placement."""
    payment = await db.get(Payment, payment_id)
    if payment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment not found")
    try:
        payment = await refund_payment(db, payment)
    except ValueError:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Payment is not paid") from None
    return PaymentRefundResponse(id=payment.id, status=payment.status.value)
