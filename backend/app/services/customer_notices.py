"""Customer-facing in-app notices (S-126): review reply, review moderation, shop details edited.

Rules live here so routers stay thin. Every function returns without writing when the notice
does not apply (see the slice's ACs); all writes share the caller's transaction.
Notices are keyed per entity (review id / business id) via `dedupe_key`, so a customer who
reviewed several shops keeps one notice per review / shop. Ids only in `extra_data`.
"""

from __future__ import annotations

import logging
import re
from typing import Any
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Business, BusinessStatus, NotificationType, Review, ReviewStatus
from app.services.notifications import (
    SCENARIO_REVIEW_MODERATION,
    SCENARIO_REVIEW_REPLY,
    SCENARIO_SHOP_DETAILS_UPDATED,
    upsert_notice,
)

logger = logging.getLogger("app.customer_notices")

MAX_SHOP_EDIT_FANOUT = 200
PARTNER_SOURCE = "partner"  # login-less shadow users: nobody can open their bell

_WS = re.compile(r"\s+")

# --- normalisers: used only to decide "did anything really change?" (stored values are untouched) ---


def normalise_text(value: Any) -> str:
    if value is None:
        return ""
    return _WS.sub(" ", str(value)).strip()


def normalise_phone(value: Any) -> str:
    if value is None:
        return ""
    raw = str(value).strip()
    digits = re.sub(r"\D", "", raw)
    return ("+" if raw.startswith("+") else "") + digits


def _norm_hours_value(value: Any) -> Any:
    if isinstance(value, dict):
        out = {}
        for k, v in value.items():
            if v is None or v == "":
                continue
            out[normalise_text(k).casefold()] = _norm_hours_value(v)
        return out
    if isinstance(value, list):
        return [_norm_hours_value(v) for v in value]
    if isinstance(value, str):
        return normalise_text(value).casefold()
    return value


def normalise_hours(value: Any) -> dict:
    if not value:
        return {}
    result = _norm_hours_value(value)
    return result if isinstance(result, dict) else {}


_ADDRESS_FIELDS = ("address", "city", "state", "postal_code", "country")


def snapshot_shop_details(business: Business) -> dict[str, object]:
    """Normalised view of the four field groups that notify reviewers when they change."""
    return {
        "description": normalise_text(business.description),
        "phone": normalise_phone(business.phone),
        "hours": normalise_hours(business.business_hours),
        "address": tuple(normalise_text(getattr(business, f)).casefold() for f in _ADDRESS_FIELDS),
    }


def changed_groups(before: dict[str, object], after: dict[str, object]) -> list[str]:
    return [name for name in ("description", "phone", "hours", "address") if before.get(name) != after.get(name)]


# --- notifiers ---------------------------------------------------------------------------------


async def notify_review_reply(
    db: AsyncSession,
    *,
    review: Review,
    business: Business,
    actor_id: UUID,
    previous_body: str | None,
    new_body: str,
) -> bool:
    if review.source == PARTNER_SOURCE or review.status != ReviewStatus.ACTIVE:
        return False
    if review.author_id == actor_id:
        return False
    if previous_body is not None and normalise_text(previous_body) == normalise_text(new_body):
        return False
    await upsert_notice(
        db,
        user_id=review.author_id,
        scenario=SCENARIO_REVIEW_REPLY,
        ntype=NotificationType.REPLY,
        title="Reply to your review",
        message=f"{business.name} replied to your review.",
        extra_data={"review_id": str(review.id), "business_id": str(business.id)},
        dedupe_key=str(review.id),
    )
    return True


_MODERATION_COPY = {
    "hide": ("Your review was hidden", "Your review of {shop} was hidden by our moderators."),
    "remove": ("Your review was removed", "Your review of {shop} was removed by our moderators."),
    "restore": ("Your review is visible again", "Your review of {shop} is visible again."),
}


async def notify_review_moderation(
    db: AsyncSession,
    *,
    review: Review,
    business: Business | None,
    admin_id: UUID,
    previous_status: ReviewStatus,
    action: str,
) -> bool:
    if business is None or action not in _MODERATION_COPY:
        return False
    if review.source == PARTNER_SOURCE or review.author_id == admin_id:
        return False
    if review.status == previous_status:
        return False  # repeat action: nothing changed
    if action == "restore" and previous_status not in (ReviewStatus.HIDDEN, ReviewStatus.REMOVED):
        return False
    title, message = _MODERATION_COPY[action]
    await upsert_notice(
        db,
        user_id=review.author_id,
        scenario=SCENARIO_REVIEW_MODERATION,
        ntype=NotificationType.MODERATION,
        title=title,
        message=message.format(shop=business.name),
        extra_data={"review_id": str(review.id), "business_id": str(business.id), "action": action},
        dedupe_key=str(review.id),
    )
    return True


async def _active_reviewer_ids(db: AsyncSession, business_id: UUID, exclude_user_id: UUID, limit: int) -> list[UUID]:
    """Authors of active, non-partner reviews of this shop, newest review first (one per author)."""
    result = await db.execute(
        select(Review.author_id)
        .where(
            Review.business_id == business_id,
            Review.status == ReviewStatus.ACTIVE,
            Review.source != PARTNER_SOURCE,
            Review.author_id != exclude_user_id,
        )
        .order_by(Review.created_at.desc())
        .limit(limit)
    )
    return list(result.scalars().all())


async def notify_shop_details_changed(
    db: AsyncSession,
    *,
    business: Business,
    before: dict[str, object],
    actor_id: UUID,
) -> int:
    """Tell active reviewers an approved shop changed description / phone / hours / address."""
    if business.status != BusinessStatus.APPROVED:
        return 0
    changed = changed_groups(before, snapshot_shop_details(business))
    if not changed:
        return 0
    recipients = await _active_reviewer_ids(db, business.id, actor_id, MAX_SHOP_EDIT_FANOUT + 1)
    if len(recipients) > MAX_SHOP_EDIT_FANOUT:
        logger.warning("shop edit fan-out truncated business_id=%s cap=%s", business.id, MAX_SHOP_EDIT_FANOUT)
        recipients = recipients[:MAX_SHOP_EDIT_FANOUT]
    for user_id in recipients:
        await upsert_notice(
            db,
            user_id=user_id,
            scenario=SCENARIO_SHOP_DETAILS_UPDATED,
            ntype=NotificationType.SYSTEM,
            title="Shop details updated",
            message=f"{business.name} updated its details (description, phone, hours or address).",
            extra_data={"business_id": str(business.id), "changed": changed},
            dedupe_key=str(business.id),
        )
    return len(recipients)
