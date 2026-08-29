"""Partner review channel business logic (S-123, ADR-019).

The login-free path is unlocked only by a single-use, short-TTL token the
partner minted for one real transaction -- the customer controls nothing about
it. Organic `/collect/{businessId}` (login required) is untouched.
"""

from __future__ import annotations

import hashlib
import logging
import secrets
from datetime import UTC, datetime, timedelta
from uuid import UUID

from fastapi import BackgroundTasks, HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.config import get_settings
from app.models import (
    Business,
    BusinessStatus,
    Merchant,
    NotificationType,
    Partner,
    PartnerMerchantLink,
    PartnerReviewRequest,
    Review,
    ReviewStatus,
    User,
    UserRole,
)
from app.schemas import PartnerReviewRequestCreate
from app.services.business_service import refresh_merchant_ai_summary_bg, update_business_rating
from app.services.cache import cache_delete_pattern
from app.services.content_moderation import contains_disallowed_language
from app.services.email import try_send_new_review
from app.services.notifications import SCENARIO_NEW_REVIEW, upsert_notice
from app.services.partners import get_partner_provider
from app.services.review_pipeline import build_review_ai_analysis

logger = logging.getLogger("app.partners")

SHADOW_USER_NAME = "Verified customer"


def _utcnow() -> datetime:
    return datetime.now(UTC)


def hash_api_key(raw_key: str) -> str:
    """sha256 hex of a partner API key -- the only form we ever store or compare."""
    return hashlib.sha256(raw_key.encode("utf-8")).hexdigest()


def hash_customer_ref(phone_e164: str | None) -> str | None:
    """Salted one-way hash of a customer phone, or None. The raw phone is never persisted."""
    phone = (phone_e164 or "").strip()
    if not phone:
        return None
    salt = get_settings().secret_key
    return hashlib.sha256(f"{salt}:{phone}".encode()).hexdigest()


async def resolve_partner(db: AsyncSession, raw_api_key: str | None) -> Partner:
    """Look a partner up by API-key hash. 401 on missing / unknown / suspended."""
    if not raw_api_key:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing partner API key")
    result = await db.execute(
        select(Partner).where(Partner.api_key_hash == hash_api_key(raw_api_key))
    )
    partner = result.scalar_one_or_none()
    if partner is None or partner.status != "active":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid partner API key")
    return partner


async def _resolve_business(db: AsyncSession, partner: Partner, merchant_ref: str) -> Business:
    """partner_merchant_links first, then a bare business slug. 404 if neither resolves
    to an APPROVED business (auto-provision is a later slice)."""
    link_result = await db.execute(
        select(PartnerMerchantLink).where(
            PartnerMerchantLink.partner_id == partner.id,
            PartnerMerchantLink.partner_merchant_ref == merchant_ref,
        )
    )
    link = link_result.scalar_one_or_none()
    if link is not None:
        business = await db.get(Business, link.business_id)
    else:
        slug_result = await db.execute(select(Business).where(Business.slug == merchant_ref))
        business = slug_result.scalar_one_or_none()

    if business is None or business.status != BusinessStatus.APPROVED:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="merchant_not_onboarded")
    return business


async def create_review_request(
    db: AsyncSession, partner: Partner, payload: PartnerReviewRequestCreate
) -> tuple[PartnerReviewRequest, bool]:
    """Create (or idempotently return) the review request for one transaction.

    Returns ``(request, created)``. A repeat call with the same
    ``(partner_id, transaction_ref)`` returns the existing row untouched.
    """
    existing_result = await db.execute(
        select(PartnerReviewRequest).where(
            PartnerReviewRequest.partner_id == partner.id,
            PartnerReviewRequest.partner_txn_ref == payload.transaction_ref,
        )
    )
    existing = existing_result.scalar_one_or_none()
    if existing is not None:
        return existing, False

    business = await _resolve_business(db, partner, payload.merchant_ref)
    settings = get_settings()
    request = PartnerReviewRequest(
        partner_id=partner.id,
        business_id=business.id,
        partner_merchant_ref=payload.merchant_ref,
        partner_txn_ref=payload.transaction_ref,
        partner_customer_ref=hash_customer_ref(payload.customer_phone),
        token=secrets.token_urlsafe(32),
        channel=payload.channel,
        status="pending",
        expires_at=_utcnow() + timedelta(hours=settings.partner_review_token_ttl_hours),
    )
    db.add(request)
    try:
        await db.flush()
    except IntegrityError:
        # Lost a race on uq_partner_txn_ref -- re-read and return the winner.
        await db.rollback()
        again = await db.execute(
            select(PartnerReviewRequest).where(
                PartnerReviewRequest.partner_id == partner.id,
                PartnerReviewRequest.partner_txn_ref == payload.transaction_ref,
            )
        )
        return again.scalar_one(), False
    return request, True


def collect_url(token: str) -> str:
    return f"{get_settings().public_app_url.rstrip('/')}/c/{token}"


def _request_status(request: PartnerReviewRequest, now: datetime) -> str:
    if request.redeemed_at is not None or request.status == "submitted":
        return "submitted"
    if request.expires_at <= now:
        return "expired"
    return "pending"


async def load_request_for_collect(
    db: AsyncSession, token: str
) -> tuple[PartnerReviewRequest, Business, str]:
    """Return ``(request, business, computed_status)`` for a token, or 404."""
    result = await db.execute(
        select(PartnerReviewRequest)
        .options(selectinload(PartnerReviewRequest.business))
        .where(PartnerReviewRequest.token == token)
    )
    request = result.scalar_one_or_none()
    if request is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Unknown or invalid review link")
    business = request.business or await db.get(Business, request.business_id)
    return request, business, _request_status(request, _utcnow())


async def _resolve_shadow_user(
    db: AsyncSession, request: PartnerReviewRequest
) -> User:
    """Reuse this customer's pseudonymous user for the business when a phone hash
    exists (so ``UNIQUE(author_id, business_id)`` still means one voice per
    customer); otherwise mint a fresh anonymous shadow user."""
    if request.partner_customer_ref:
        prior = await db.execute(
            select(Review)
            .join(PartnerReviewRequest, PartnerReviewRequest.review_id == Review.id)
            .where(
                PartnerReviewRequest.partner_customer_ref == request.partner_customer_ref,
                Review.business_id == request.business_id,
            )
        )
        prior_review = prior.scalar_one_or_none()
        if prior_review is not None:
            found = await db.get(User, prior_review.author_id)
            if found is not None:
                return found

    shadow = User(
        full_name=SHADOW_USER_NAME,
        role=UserRole.CUSTOMER,
        is_active=True,
        auth_provider="partner",
    )
    db.add(shadow)
    await db.flush()
    return shadow


async def submit_token_review(
    db: AsyncSession,
    token: str,
    payload,
    background_tasks: BackgroundTasks,
) -> tuple[Review, Business]:
    request, business, computed = await load_request_for_collect(db, token)
    now = _utcnow()
    if computed == "submitted":
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="This review link was already used")
    if computed == "expired":
        request.status = "expired"
        raise HTTPException(status_code=status.HTTP_410_GONE, detail="This review link has expired")

    author = await _resolve_shadow_user(db, request)
    flagged = contains_disallowed_language(payload.title, payload.body)
    review = Review(
        business_id=business.id,
        author_id=author.id,
        rating=payload.rating,
        title=payload.title,
        body=payload.body,
        status=ReviewStatus.REPORTED if flagged else ReviewStatus.ACTIVE,
        source="partner",
        verified_purchase=True,
    )
    db.add(review)
    try:
        await db.flush()
    except IntegrityError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="A review from this customer already exists for this business",
        ) from None

    db.add(await build_review_ai_analysis(review.id, payload.body, business_id=business.id))

    request.redeemed_at = now
    request.status = "submitted"
    request.review_id = review.id

    if not flagged:
        merchant = (
            await db.execute(select(Merchant).where(Merchant.id == business.merchant_id))
        ).scalar_one_or_none()
        if merchant:
            await upsert_notice(
                db,
                user_id=merchant.user_id,
                scenario=SCENARIO_NEW_REVIEW,
                ntype=NotificationType.REVIEW,
                title="New review received",
                message=f"New {payload.rating}-star verified-purchase review on {business.name}",
                extra_data={
                    "review_id": str(review.id),
                    "business_id": str(business.id),
                    "source": "partner",
                },
            )
            merchant_user = await db.get(User, merchant.user_id)
            if merchant_user and merchant_user.email:
                await try_send_new_review(merchant_user.email, business.name, payload.rating)

    await update_business_rating(db, business.id)
    await cache_delete_pattern("search:*")
    background_tasks.add_task(refresh_merchant_ai_summary_bg, business.id)
    background_tasks.add_task(send_partner_callback_bg, request.id)

    return review, business


async def send_partner_callback_bg(request_id: UUID) -> None:
    """BackgroundTasks entry point -- opens its own session (the request's has closed)."""
    from app.database import AsyncSessionLocal

    try:
        async with AsyncSessionLocal() as db:
            result = await db.execute(
                select(PartnerReviewRequest)
                .options(
                    selectinload(PartnerReviewRequest.partner),
                    selectinload(PartnerReviewRequest.business),
                )
                .where(PartnerReviewRequest.id == request_id)
            )
            request = result.scalar_one_or_none()
            if request is None or request.review_id is None:
                return
            partner = request.partner
            if not partner or not partner.callback_url:
                return
            review = await db.get(Review, request.review_id)
            if review is None:
                return
            held = review.status == ReviewStatus.REPORTED
            event = {
                "event": "review.captured",
                "review_request_id": str(request.id),
                "merchant_ref": request.partner_merchant_ref,
                "transaction_ref": request.partner_txn_ref,
                "rating": review.rating,
                "has_text": bool(review.body),
                "status": "held_for_moderation" if held else "published",
                "listing_url": f"{get_settings().public_app_url.rstrip('/')}/businesses/{request.business.slug}",
                "captured_at": _utcnow().isoformat(),
            }
            await get_partner_provider().send_callback(
                partner.callback_url, event, partner.hmac_secret
            )
    except Exception:
        logger.exception("partner_callback_failed request_id=%s", request_id)


# --- dev-only mock billing console -------------------------------------------------


async def _demo_partner(db: AsyncSession) -> Partner:
    settings = get_settings()
    result = await db.execute(
        select(Partner).where(Partner.api_key_hash == hash_api_key(settings.partner_demo_api_key))
    )
    partner = result.scalar_one_or_none()
    if partner is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Demo partner not seeded -- run the seed (SEED_MODE=force)",
        )
    return partner


def customer_message(business_name: str, url: str) -> str:
    """The line a partner would drop on the invoice / receipt SMS."""
    return f"Thanks for shopping at {business_name}. Rate your visit (30 sec, no login): {url}"


async def dev_dispatch(db: AsyncSession, req) -> tuple[PartnerReviewRequest, bool, str]:
    """Mock billing app 'sends a review request'. Bypasses HMAC because this
    endpoint *is* the partner -- the real /partner/review-requests stays
    signature-enforced (and is tested separately).

    Returns ``(request, created, customer_message)`` -- the message is the SMS
    line the partner would send, surfaced so the console can show it (and it is
    logged via the SMS mock when a phone was supplied)."""
    partner = await _demo_partner(db)
    txn = req.transaction_ref or f"MOCK-{secrets.token_hex(4).upper()}"
    payload = PartnerReviewRequestCreate(
        merchant_ref=req.business_slug,
        transaction_ref=txn,
        customer_phone=req.customer_phone,
    )
    request, created = await create_review_request(db, partner, payload)
    business = await db.get(Business, request.business_id)
    message = customer_message(business.name if business else "the shop", collect_url(request.token))
    if req.customer_phone:
        # Visible in `docker compose logs backend` -- the partner "posted a message".
        logger.info("MOCK partner SMS to=%s: %s", req.customer_phone, message)
    return request, created, message


async def dev_list_requests(db: AsyncSession) -> list[dict]:
    partner = await _demo_partner(db)
    result = await db.execute(
        select(PartnerReviewRequest)
        .options(selectinload(PartnerReviewRequest.business))
        .where(PartnerReviewRequest.partner_id == partner.id)
        .order_by(PartnerReviewRequest.created_at.desc())
        .limit(50)
    )
    rows = []
    for r in result.scalars().all():
        rows.append(
            {
                "token": r.token,
                "business_slug": r.business.slug if r.business else "",
                "partner_txn_ref": r.partner_txn_ref,
                "status": _request_status(r, _utcnow()),
                "review_id": r.review_id,
                "created_at": r.created_at,
            }
        )
    return rows
