"""Payment ledger + featured placement side effects. Routers stay thin."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import Business, FeaturedPlacement, NotificationType, Payment, PaymentStatus, User
from app.services.cache import cache_delete_pattern
from app.services.notifications import (
    SCENARIO_PAYMENT_BOOST_APPROVED,
    SCENARIO_PAYMENT_CAPTURED,
    upsert_notice,
)
from app.services.payments.base import WebhookEvent
from app.services.payments.sku import FEATURED_CURRENCY, split_fees


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def is_placement_active(placement: FeaturedPlacement | None, now: datetime | None = None) -> bool:
    if placement is None:
        return False
    now = now or utcnow()
    return placement.disabled_at is None and now < placement.ends_at


def is_awaiting_boost_approval(payment: Payment | None) -> bool:
    if payment is None:
        return False
    return (
        payment.status == PaymentStatus.PAID
        and payment.approved_at is None
        and payment.rejected_at is None
    )


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


async def _listing_name(db: AsyncSession, business_id: UUID) -> str:
    business = await db.get(Business, business_id)
    return business.name if business else "your listing"


async def apply_captured_payment(db: AsyncSession, payment: Payment, event: WebhookEvent) -> bool:
    """Mark paid and split fees. Does not create a placement (admin approve does)."""
    if payment.status == PaymentStatus.PAID:
        return False

    amount = event.amount_captured_paise or payment.amount_paise
    platform_fee, gateway_fee = split_fees(amount, event.gateway_fee_paise)
    payment.status = PaymentStatus.PAID
    payment.amount_paise = amount
    payment.currency = payment.currency or FEATURED_CURRENCY
    payment.platform_fee_paise = platform_fee
    payment.gateway_fee_paise = gateway_fee
    if event.provider_payment_id:
        payment.provider_payment_id = event.provider_payment_id
    name = await _listing_name(db, payment.business_id)
    await upsert_notice(
        db,
        user_id=payment.merchant_user_id,
        scenario=SCENARIO_PAYMENT_CAPTURED,
        ntype=NotificationType.SYSTEM,
        title="Featured payment received",
        message=f"Payment for a featured boost on {name} is recorded. Search placement starts after admin approval.",
        extra_data={"business_id": str(payment.business_id), "payment_id": str(payment.id)},
    )
    await db.flush()
    return False


async def approve_payment(db: AsyncSession, payment: Payment) -> FeaturedPlacement:
    """Create the featured window after money is captured. Idempotent if already approved."""
    if payment.status != PaymentStatus.PAID:
        raise ValueError("not_paid")
    if payment.rejected_at is not None:
        raise ValueError("rejected")
    existing = await db.execute(select(FeaturedPlacement).where(FeaturedPlacement.payment_id == payment.id))
    placement = existing.scalar_one_or_none()
    if placement is not None and payment.approved_at is not None:
        return placement
    active = await get_active_placement_for_business(db, payment.business_id)
    if active is not None:
        raise ValueError("already_featured")
    now = utcnow()
    payment.approved_at = now
    days = payment.duration_days or 7
    placement = FeaturedPlacement(
        business_id=payment.business_id,
        payment_id=payment.id,
        starts_at=now,
        ends_at=now + timedelta(days=days),
    )
    db.add(placement)
    name = await _listing_name(db, payment.business_id)
    await upsert_notice(
        db,
        user_id=payment.merchant_user_id,
        scenario=SCENARIO_PAYMENT_BOOST_APPROVED,
        ntype=NotificationType.SYSTEM,
        title="Featured boost is live",
        message=f"Your featured search placement for {name} is on.",
        extra_data={"business_id": str(payment.business_id), "payment_id": str(payment.id)},
    )
    await cache_delete_pattern("search:*")
    await db.flush()
    return placement


async def reject_payment(db: AsyncSession, payment: Payment) -> Payment:
    """Refuse the boost. Does not refund (admin uses refund separately)."""
    if payment.status != PaymentStatus.PAID:
        raise ValueError("not_paid")
    if payment.approved_at is not None:
        raise ValueError("already_approved")
    if payment.rejected_at is None:
        payment.rejected_at = utcnow()
        await db.flush()
    return payment


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


async def list_admin_payments(db: AsyncSession, page: int, page_size: int) -> list[Payment]:
    result = await db.execute(
        select(Payment)
        .options(selectinload(Payment.business), selectinload(Payment.placement))
        .order_by(Payment.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    return list(result.scalars().all())


async def merchant_payment_counts(db: AsyncSession, merchant_ids: list[UUID]) -> dict[UUID, int]:
    if not merchant_ids:
        return {}
    result = await db.execute(
        select(Payment.merchant_user_id, func.count(Payment.id))
        .where(Payment.merchant_user_id.in_(merchant_ids))
        .group_by(Payment.merchant_user_id)
    )
    return {row[0]: int(row[1]) for row in result.all()}


async def load_users_by_id(db: AsyncSession, user_ids: list[UUID]) -> dict[UUID, User]:
    if not user_ids:
        return {}
    result = await db.execute(select(User).where(User.id.in_(user_ids)))
    return {u.id: u for u in result.scalars().all()}


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
