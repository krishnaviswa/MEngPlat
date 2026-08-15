"""Featured listing checkout, webhooks, mock complete, admin approve/reject/refund."""

from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.database import get_db
from app.dependencies import get_merchant_for_user, get_owned_business, require_roles
from app.models import BusinessStatus, FeaturedPlacement, Payment, PaymentStatus, User, UserRole
from app.schemas import (
    AdminPaymentRow,
    CheckoutFields,
    FeaturedCheckoutRequest,
    FeaturedCheckoutResponse,
    FeaturedSku,
    MockCompleteRequest,
    PaymentApproveResponse,
    PaymentLedger,
    PaymentRefundResponse,
    PaymentRejectResponse,
    PlacementDisableResponse,
    PlacementResponse,
    PlacementWindow,
    WebhookAck,
)
from app.services.payments import get_payment_provider
from app.services.payments.base import WebhookEvent
from app.services.payments.featured import (
    apply_captured_payment,
    approve_payment,
    disable_placement,
    get_active_placement_for_business,
    get_business,
    get_payment_by_order_id,
    is_awaiting_boost_approval,
    is_placement_active,
    list_admin_payments,
    load_users_by_id,
    mark_payment_failed,
    merchant_payment_counts,
    refund_payment,
    reject_payment,
)
from app.services.payments.sku import (
    FEATURED_CURRENCY,
    UnknownSkuError,
    catalog,
    get_sku,
    sku_payload,
)

router = APIRouter(prefix="/payments", tags=["Payments"])


def _sku_model(code: str | None = None) -> FeaturedSku:
    try:
        payload = sku_payload(code) if code else sku_payload()
    except UnknownSkuError:
        payload = sku_payload()
    amount = get_sku(payload["code"])["amount_paise"]
    return FeaturedSku(**payload, amount_paise=amount)


def _catalog() -> list[FeaturedSku]:
    return [
        FeaturedSku(
            code=s["code"],
            duration_days=s["duration_days"],
            listed_price_inr=s["listed_price_inr"],
            amount_paise=s["amount_paise"],
        )
        for s in catalog()
    ]


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
        sku_code=payment.sku_code,
        duration_days=payment.duration_days,
        platform_fee_paise=payment.platform_fee_paise,
        gateway_fee_paise=payment.gateway_fee_paise,
        provider=payment.provider,
        provider_order_id=payment.provider_order_id,
        created_at=payment.created_at,
        approved_at=payment.approved_at,
        rejected_at=payment.rejected_at,
    )


@router.get("/featured/skus", response_model=list[FeaturedSku])
async def featured_skus(
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> list[FeaturedSku]:
    """Catalog of featured listing SKUs. Auth: merchant or admin."""
    return _catalog()


@router.post("/featured/checkout", response_model=FeaturedCheckoutResponse)
async def featured_checkout(
    body: FeaturedCheckoutRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT)),
) -> FeaturedCheckoutResponse:
    """Start featured checkout for an owned approved listing. Auth: merchant. sku_code required."""
    try:
        sku = get_sku(body.sku_code)
    except UnknownSkuError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Unknown SKU") from None
    merchant = await get_merchant_for_user(db, user)
    business = await get_owned_business(db, body.business_id, merchant)
    if business.status != BusinessStatus.APPROVED:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Listing is not approved")
    active = await get_active_placement_for_business(db, business.id)
    if active is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Active featured placement already exists")

    amount = sku["amount_paise"]
    provider = get_payment_provider()
    order = await provider.create_order(
        amount,
        FEATURED_CURRENCY,
        receipt=f"featured-{business.id.hex[:12]}",
        notes={"business_id": str(business.id), "sku": sku["code"]},
    )
    payment = Payment(
        id=uuid4(),
        business_id=business.id,
        merchant_user_id=user.id,
        provider=provider.name,
        provider_order_id=order.provider_order_id,
        status=PaymentStatus.CREATED,
        amount_paise=amount,
        currency=FEATURED_CURRENCY,
        sku_code=sku["code"],
        duration_days=sku["duration_days"],
    )
    db.add(payment)
    await db.flush()

    return FeaturedCheckoutResponse(
        payment_id=payment.id,
        provider=provider.name,
        provider_order_id=order.provider_order_id,
        amount_paise=amount,
        currency=FEATURED_CURRENCY,
        sku=_sku_model(sku["code"]),
        checkout=CheckoutFields(
            key_id=order.key_id,
            order_id=order.provider_order_id,
            amount=amount,
            currency=FEATURED_CURRENCY,
            name="MerchantHub AI",
            description=f"Featured listing boost — {sku['duration_days']} days",
            prefill={"email": user.email or "", "name": user.full_name},
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
    """DEBUG-only: admin completes a mock order (ledger only). 404 when DEBUG is false."""
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
    """Active/expiry for a listing. Fee split is admin-only. Catalog always included."""
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

    pay_result = await db.execute(
        select(Payment).where(Payment.business_id == business_id).order_by(Payment.created_at.desc()).limit(1)
    )
    latest_payment = pay_result.scalar_one_or_none()
    if payment_id:
        payment = await db.get(Payment, payment_id)
        if payment is None:
            payment = latest_payment
    else:
        payment = latest_payment

    ledger = None
    if user.role == UserRole.ADMIN and payment:
        ledger = _ledger(payment)
    elif user.role == UserRole.MERCHANT and payment and is_awaiting_boost_approval(payment):
        ledger = PaymentLedger(
            id=payment.id,
            status=payment.status.value,
            amount_paise=payment.amount_paise,
            currency=payment.currency,
            sku_code=payment.sku_code,
            duration_days=payment.duration_days,
            platform_fee_paise=None,
            gateway_fee_paise=None,
            provider=payment.provider,
            provider_order_id=payment.provider_order_id,
            created_at=payment.created_at,
            approved_at=payment.approved_at,
            rejected_at=payment.rejected_at,
        )

    sku_code = payment.sku_code if payment else None
    return PlacementResponse(
        business_id=business_id,
        active=active,
        placement=window if active or (window and window.disabled_at) else (window if not active else None),
        sku=_sku_model(sku_code) if sku_code else _sku_model(),
        skus=_catalog(),
        awaiting_approval=is_awaiting_boost_approval(payment) and not active,
        payment=ledger,
    )


@router.get("/admin/payments", response_model=list[AdminPaymentRow])
async def admin_list_payments(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.ADMIN)),
) -> list[AdminPaymentRow]:
    """Admin: all featured payments, newest first, with per-merchant counts."""
    rows = await list_admin_payments(db, page, page_size)
    merchant_ids = [p.merchant_user_id for p in rows]
    counts = await merchant_payment_counts(db, merchant_ids)
    users = await load_users_by_id(db, merchant_ids)
    out: list[AdminPaymentRow] = []
    for p in rows:
        merchant = users.get(p.merchant_user_id)
        biz = p.business
        out.append(
            AdminPaymentRow(
                id=p.id,
                status=p.status.value,
                amount_paise=p.amount_paise,
                currency=p.currency,
                sku_code=p.sku_code,
                duration_days=p.duration_days,
                provider=p.provider,
                provider_order_id=p.provider_order_id,
                created_at=p.created_at,
                approved_at=p.approved_at,
                rejected_at=p.rejected_at,
                platform_fee_paise=p.platform_fee_paise,
                gateway_fee_paise=p.gateway_fee_paise,
                business_id=p.business_id,
                business_name=biz.name if biz else "",
                merchant_user_id=p.merchant_user_id,
                merchant_email=merchant.email if merchant and merchant.email else "",
                merchant_name=merchant.full_name if merchant else "",
                merchant_payment_count=counts.get(p.merchant_user_id, 0),
                awaiting_approval=is_awaiting_boost_approval(p),
            )
        )
    return out


@router.post("/admin/payments/{payment_id}/approve", response_model=PaymentApproveResponse)
async def admin_approve_payment(
    payment_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.ADMIN)),
) -> PaymentApproveResponse:
    """Admin: after capture, create the featured placement window."""
    payment = await db.get(Payment, payment_id)
    if payment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment not found")
    try:
        placement = await approve_payment(db, payment)
    except ValueError as exc:
        code = str(exc)
        if code == "not_paid":
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Payment is not paid") from None
        if code == "rejected":
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Payment was rejected") from None
        if code == "already_featured":
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Active featured placement already exists") from None
        raise
    assert payment.approved_at is not None
    return PaymentApproveResponse(
        id=payment.id,
        approved_at=payment.approved_at,
        placement_id=placement.id,
        ends_at=placement.ends_at,
    )


@router.post("/admin/payments/{payment_id}/reject", response_model=PaymentRejectResponse)
async def admin_reject_payment(
    payment_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.ADMIN)),
) -> PaymentRejectResponse:
    """Admin: refuse the boost. Does not refund."""
    payment = await db.get(Payment, payment_id)
    if payment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment not found")
    try:
        payment = await reject_payment(db, payment)
    except ValueError as exc:
        code = str(exc)
        if code == "not_paid":
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Payment is not paid") from None
        if code == "already_approved":
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Payment already approved") from None
        raise
    assert payment.rejected_at is not None
    return PaymentRejectResponse(id=payment.id, rejected_at=payment.rejected_at)


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
