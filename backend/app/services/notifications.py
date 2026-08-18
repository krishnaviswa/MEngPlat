"""One in-app notice per workflow scenario per user (S-065).

Does not create or mutate businesses, photos, or addresses.
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Notification, NotificationType

# Stable keys — unique with user_id. Keep in lockstep with tests/test_notification_scenarios.py
# and README §5 “Notification scenarios”.
SCENARIO_LISTING_APPROVED = "listing_approved"
SCENARIO_NEW_REVIEW = "new_review"
SCENARIO_WHATSAPP_APPLIED = "whatsapp_applied"
SCENARIO_WHATSAPP_REJECTED = "whatsapp_rejected"
SCENARIO_PAYMENT_CAPTURED = "payment_captured"
SCENARIO_PAYMENT_BOOST_APPROVED = "payment_boost_approved"

SCENARIOS: tuple[str, ...] = (
    SCENARIO_LISTING_APPROVED,
    SCENARIO_NEW_REVIEW,
    SCENARIO_WHATSAPP_APPLIED,
    SCENARIO_WHATSAPP_REJECTED,
    SCENARIO_PAYMENT_CAPTURED,
    SCENARIO_PAYMENT_BOOST_APPROVED,
)


async def upsert_notice(
    db: AsyncSession,
    *,
    user_id: UUID,
    scenario: str,
    ntype: NotificationType,
    title: str,
    message: str,
    extra_data: dict[str, Any] | None = None,
) -> Notification:
    """Create or refresh the single notice for this user + scenario. Marks unread."""
    result = await db.execute(
        select(Notification).where(Notification.user_id == user_id, Notification.scenario == scenario)
    )
    row = result.scalar_one_or_none()
    payload = dict(extra_data or {})
    payload["scenario"] = scenario
    now = datetime.now(timezone.utc)
    if row is not None:
        row.type = ntype
        row.title = title
        row.message = message
        row.extra_data = payload
        row.is_read = False
        row.created_at = now
        return row
    row = Notification(
        user_id=user_id,
        scenario=scenario,
        type=ntype,
        title=title,
        message=message,
        extra_data=payload,
        is_read=False,
        created_at=now,
    )
    db.add(row)
    return row
