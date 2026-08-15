"""Payment ledger + featured placement side effects. Routers stay thin."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Business, FeaturedPlacement, Payment, PaymentStatus
from app.services.cache import cache_delete_pattern
from app.services.payments.base import WebhookEvent
from app.services.payments.sku import FEATURED_AMOUNT_PAISE, FEATURED_CURRENCY, FEATURED_DURATION_DAYS, split_fees


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def is_placement_active(placement: FeaturedPlacement | None, now: datetime | None = None) -> bool:
    if placement is None:
        return False
    now = now or utcnow()
    return placement.disabled_at is None and now < placement.ends_at


async def load_active_featured_ends(db: AsyncSession) -> dict[UUID, datetime]:
    now = utcnow()
    result = await db.execute(
        select(FeaturedPlacement.business_id, FeaturedPlacement.ends_at).where(
            FeaturedPlacement.disabled_at.is_(None),
            FeaturedPlacement.ends_at > now,
        )
    )
    return {row[0]: row[1] for row in result.all()}


async def get_active_placement_for_business(db: AsyncSession, business_id: UUID) -> FeaturedPlacement | None:
    now = utcnow()
    result = await db.execute(
        select(FeaturedPlacement)
        .where(
            FeaturedPlacement.business_id == business_id,
            FeaturedPlacement.disabled_at.is_(None),
            FeaturedPlacement.ends_at > now,
        )
        .order_by(FeaturedPlacement.ends_at.desc())
        .limit(1)
    )
    return result.scalar_one_or_none()


async def get_payment_by_order_id(db: AsyncSession, provider_order_id: str) -> Payment | None:
    result = await db.execute(select(Payment).where(Payment.provider_order_id == provider_order_id))
    return result.scalar_one_or_none()


async def apply_captured_payment(db: AsyncSession, payment: Payment, event: WebhookEvent) -> bool:
    """Mark paid, split fees, insert placement if none active. Returns True if newly activated."""
    if payment.status == PaymentStatus.PAID:
        return False

    amount = event.amount_captured_paise or payment.amount_paise or FEATURED_AMOUNT_PAISE
    platform_fee, gateway_fee = split_fees(amount, event.gateway_fee_paise)
    payment.status = PaymentStatus.PAID
    payment.amount_paise = amount
    payment.currency = payment.currency or FEATURED_CURRENCY
    payment.platform_fee_paise = platform_fee
    payment.gateway_fee_paise = gateway_fee
    if event.provider_payment_id:
        payment.provider_payment_id = event.provider_payment_id

    existing = await get_active_placement_for_business(db, payment.business_id)
    activated = False
    if existing is None:
        now = utcnow()
        db.add(
            FeaturedPlacement(
                business_id=payment.business_id,
                payment_id=payment.id,
                starts_at=now,
                ends_at=now + timedelta(days=FEATURED_DURATION_DAYS),
            )
        )
        activated = True
        await cache_delete_pattern("search:*")

    await db.flush()
    return activated


async def mark_payment_failed(db: AsyncSession, payment: Payment) -> None:
    if payment.status == PaymentStatus.PAID:
        return
    payment.status = PaymentStatus.FAILED
    await db.flush()


async def disable_placement(db: AsyncSession, placement: FeaturedPlacement) -> FeaturedPlacement:
    if placement.disabled_at is None:
        placement.disabled_at = utcnow()
        await cache_delete_pattern("search:*")
        await db.flush()
    return placement


async def refund_payment(db: AsyncSession, payment: Payment) -> Payment:
    if payment.status == PaymentStatus.REFUNDED:
        return payment
    if payment.status != PaymentStatus.PAID:
        raise ValueError("not_paid")
    from app.services.payments import get_payment_provider

    provider = get_payment_provider()
    await provider.refund(payment.provider_order_id, payment.provider_payment_id)
    payment.status = PaymentStatus.REFUNDED
    result = await db.execute(select(FeaturedPlacement).where(FeaturedPlacement.payment_id == payment.id))
    placement = result.scalar_one_or_none()
    if placement is not None:
        await disable_placement(db, placement)
    else:
        await db.flush()
    return payment


def latest_payment_for_business_query(business_id: UUID):
    return (
        select(Payment)
        .where(Payment.business_id == business_id)
        .order_by(Payment.created_at.desc())
        .limit(1)
    )


async def get_business(db: AsyncSession, business_id: UUID) -> Business | None:
    result = await db.execute(select(Business).where(Business.id == business_id))
    return result.scalar_one_or_none()
