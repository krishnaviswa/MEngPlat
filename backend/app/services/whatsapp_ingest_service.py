"""WhatsApp session bind, inbound ingest, and draft apply/discard."""

from __future__ import annotations

import logging
import re
import secrets
from datetime import UTC, datetime, timedelta
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.config import get_settings
from app.models import (
    AuditLog,
    Business,
    BusinessUpdateDraft,
    DraftStatus,
    Merchant,
    Notification,
    NotificationType,
    User,
    WhatsAppSession,
)
from app.services.ai import get_ai_provider
from app.services.cache import cache_delete_pattern
from app.services.email import try_send_whatsapp_draft_approved
from app.services.photo_service import ALLOWED_CONTENT_TYPES, save_business_photo
from app.services.whatsapp import get_whatsapp_provider
from app.services.whatsapp.base import InboundMessage

logger = logging.getLogger(__name__)

TOKEN_RE = re.compile(r"\bMH-[A-F0-9]{8}\b", re.I)
ACK_OK = "Got it, thanks!"
ACK_PHOTO_FAIL = "We couldn't save that photo. Please send a JPG or PNG under 5MB."
ACK_UNSUPPORTED = "Please send a photo (image) or a text note about your shop — not a video or document."

# Fields an admin may approve onto the live Business row (S-052/S-053) -- same
# set the AI extraction prompt is scoped to.
ALLOWED_DRAFT_FIELDS = {"description", "address", "business_hours", "phone", "website"}


def _utcnow() -> datetime:
    return datetime.now(UTC)


async def create_link(db: AsyncSession, business: Business) -> dict:
    provider = get_whatsapp_provider()
    if not provider.is_available():
        return {
            "available": False,
            "wa_url": None,
            "token": None,
            "expires_at": None,
            "display_number": None,
        }

    settings = get_settings()
    now = _utcnow()
    await db.execute(
        update(WhatsAppSession)
        .where(WhatsAppSession.business_id == business.id, WhatsAppSession.expires_at > now)
        .values(expires_at=now)
    )

    token = f"MH-{secrets.token_hex(4).upper()}"
    expires_at = now + timedelta(hours=settings.whatsapp_session_ttl_hours)
    db.add(WhatsAppSession(business_id=business.id, token=token, expires_at=expires_at))
    await db.flush()
    return {
        "available": True,
        "wa_url": provider.click_to_chat_url(token),
        "token": token,
        "expires_at": expires_at,
        "display_number": provider.display_number(),
    }


async def list_business_drafts(db: AsyncSession, business_id: UUID) -> list[BusinessUpdateDraft]:
    """All WhatsApp drafts for a business, any status, newest first (S-053: merchant read-only view)."""
    result = await db.execute(
        select(BusinessUpdateDraft)
        .where(BusinessUpdateDraft.business_id == business_id)
        .order_by(BusinessUpdateDraft.created_at.desc())
    )
    return list(result.scalars().all())


async def list_pending_drafts_admin(
    db: AsyncSession, page: int, page_size: int
) -> tuple[list[tuple[BusinessUpdateDraft, str]], int]:
    """Global, cross-business pending-drafts queue for the admin review UI (S-053), FIFO."""
    total_result = await db.execute(
        select(func.count()).select_from(BusinessUpdateDraft).where(BusinessUpdateDraft.status == DraftStatus.PENDING)
    )
    total = total_result.scalar_one()

    result = await db.execute(
        select(BusinessUpdateDraft, Business.name)
        .join(Business, Business.id == BusinessUpdateDraft.business_id)
        .where(BusinessUpdateDraft.status == DraftStatus.PENDING)
        .order_by(BusinessUpdateDraft.created_at.asc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    return list(result.all()), total


async def admin_approve_draft(
    db: AsyncSession, draft_id: UUID, admin_id: UUID, fields: dict[str, object] | None
) -> BusinessUpdateDraft:
    """Admin approves a draft, writing the (possibly edited) fields to the live Business (S-053)."""
    draft = await _load_pending_any(db, draft_id)
    business = await db.get(Business, draft.business_id)
    if not business:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")

    extracted = dict(draft.extracted_fields or {})
    overrides = fields or {}
    applied_fields: dict[str, object] = {}
    for key in ALLOWED_DRAFT_FIELDS:
        value = overrides[key] if key in overrides else extracted.get(key)
        if value in (None, "", {}):
            continue
        setattr(business, key, value)
        applied_fields[key] = value

    draft.status = DraftStatus.APPLIED
    db.add(
        AuditLog(
            admin_id=admin_id,
            action="approve",
            entity_type="business_update_draft",
            entity_id=str(draft.id),
            details={"business_id": str(business.id), "ai_fields": extracted, "applied_fields": applied_fields},
        )
    )

    merchant_result = await db.execute(select(Merchant).where(Merchant.id == business.merchant_id))
    merchant = merchant_result.scalar_one_or_none()
    if merchant:
        db.add(
            Notification(
                user_id=merchant.user_id,
                type=NotificationType.APPROVAL,
                title="WhatsApp update applied",
                message=f"Your WhatsApp suggestion for {business.name} was approved and is now live.",
                extra_data={"business_id": str(business.id), "draft_id": str(draft.id)},
            )
        )
        merchant_user = await db.get(User, merchant.user_id)
        if merchant_user and merchant_user.email:
            await try_send_whatsapp_draft_approved(merchant_user.email, business.name)

    await cache_delete_pattern("search:*")
    await db.flush()
    return draft


async def admin_reject_draft(db: AsyncSession, draft_id: UUID, admin_id: UUID) -> BusinessUpdateDraft:
    """Admin rejects a draft; the live Business row is untouched (S-053)."""
    draft = await _load_pending_any(db, draft_id)
    draft.status = DraftStatus.DISCARDED
    db.add(
        AuditLog(
            admin_id=admin_id,
            action="reject",
            entity_type="business_update_draft",
            entity_id=str(draft.id),
            details={"business_id": str(draft.business_id)},
        )
    )

    business = await db.get(Business, draft.business_id)
    if business:
        merchant_result = await db.execute(select(Merchant).where(Merchant.id == business.merchant_id))
        merchant = merchant_result.scalar_one_or_none()
        if merchant:
            db.add(
                Notification(
                    user_id=merchant.user_id,
                    type=NotificationType.SYSTEM,
                    title="WhatsApp suggestion not applied",
                    message=f"Your WhatsApp suggestion for {business.name} was reviewed and not applied.",
                    extra_data={"business_id": str(business.id), "draft_id": str(draft.id)},
                )
            )

    await db.flush()
    return draft


async def _load_pending_any(db: AsyncSession, draft_id: UUID) -> BusinessUpdateDraft:
    draft = await db.get(BusinessUpdateDraft, draft_id)
    if not draft:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Draft not found")
    if draft.status != DraftStatus.PENDING:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Draft is no longer pending")
    return draft


async def handle_inbound(db: AsyncSession, body: bytes, signature: str | None) -> dict:
    provider = get_whatsapp_provider()
    if not provider.verify_signature(body, signature):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid signature")

    messages = provider.parse_inbound(body)
    processed = 0
    for message in messages:
        try:
            await _handle_one(db, provider, message)
            processed += 1
        except HTTPException:
            raise
        except Exception:
            logger.exception("whatsapp_inbound_failed message_id=%s", message.message_id)
    return {"ok": True, "processed": processed}


async def _handle_one(db: AsyncSession, provider, message: InboundMessage) -> None:
    now = _utcnow()
    session = await _resolve_session(db, message, now)
    if session is None:
        return

    if message.type == "image":
        await _ingest_image(db, provider, session, message)
        return
    if message.type != "text":
        await provider.send_message(message.from_phone, ACK_UNSUPPORTED)
        return

    body_text = (message.text or "").strip()
    leftover = TOKEN_RE.sub("", body_text).strip()
    if leftover:
        await _ingest_text(db, session, leftover)
    await provider.send_message(message.from_phone, ACK_OK)


async def _resolve_session(
    db: AsyncSession, message: InboundMessage, now: datetime
) -> WhatsAppSession | None:
    token_match = TOKEN_RE.search(message.text or message.caption or "")
    if token_match:
        token = token_match.group(0).upper()
        result = await db.execute(select(WhatsAppSession).where(WhatsAppSession.token == token))
        session = result.scalar_one_or_none()
        if session is None or session.expires_at <= now:
            return None
        session.phone_e164 = message.from_phone
        session.redeemed_at = session.redeemed_at or now
        await db.flush()
        return session

    result = await db.execute(
        select(WhatsAppSession)
        .where(
            WhatsAppSession.phone_e164 == message.from_phone,
            WhatsAppSession.expires_at > now,
        )
        .order_by(WhatsAppSession.redeemed_at.desc().nullslast(), WhatsAppSession.created_at.desc())
        .limit(1)
    )
    return result.scalar_one_or_none()


async def _ingest_image(db: AsyncSession, provider, session: WhatsAppSession, message: InboundMessage) -> None:
    if not message.media_id:
        await provider.send_message(message.from_phone, ACK_PHOTO_FAIL)
        return
    try:
        data, content_type = await provider.download_media(message.media_id)
    except Exception:
        logger.exception("whatsapp_media_download_failed media_id=%s", message.media_id)
        await provider.send_message(message.from_phone, ACK_PHOTO_FAIL)
        return

    if content_type not in ALLOWED_CONTENT_TYPES:
        await provider.send_message(message.from_phone, ACK_UNSUPPORTED)
        return

    result = await db.execute(
        select(Business).options(selectinload(Business.merchant)).where(Business.id == session.business_id)
    )
    business = result.scalar_one_or_none()
    if not business:
        return
    uploaded_by = business.merchant.user_id
    ext = "jpg" if "jpeg" in content_type else content_type.split("/")[-1]
    try:
        await save_business_photo(
            db,
            business_id=business.id,
            data=data,
            content_type=content_type,
            filename=f"whatsapp.{ext}",
            uploaded_by=uploaded_by,
            photo_type="general",
            caption=(message.caption or None),
        )
    except HTTPException:
        await provider.send_message(message.from_phone, ACK_PHOTO_FAIL)
        return
    await provider.send_message(message.from_phone, ACK_OK)


async def _ingest_text(db: AsyncSession, session: WhatsAppSession, text: str) -> None:
    try:
        result = await get_ai_provider().extract_business_profile(text, {"source": "whatsapp"})
    except Exception:
        logger.exception("whatsapp_extract_failed business_id=%s", session.business_id)
        return

    fields = {
        "description": result.description,
        "address": result.address,
        "business_hours": result.business_hours,
        "phone": result.phone,
        "website": result.website,
    }
    if not any(v not in (None, "", {}) for v in fields.values()):
        return
    db.add(
        BusinessUpdateDraft(
            business_id=session.business_id,
            source="whatsapp",
            extracted_fields=fields,
            status=DraftStatus.PENDING,
            degraded=result.meta.degraded,
        )
    )
    await db.flush()
