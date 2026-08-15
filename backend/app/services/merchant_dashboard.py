"""Aggregations for the merchant dashboard (S-033).

All range-filtered queries use `Review.created_at` (a timestamptz column) as
the sole source of truth -- never LLM/AI JSON. Month bucketing is computed in
UTC (`func.timezone("UTC", ...)`) so labels stay consistent with the UTC
range cutoff regardless of the DB session timezone.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any, Literal
from uuid import UUID

from sqlalchemy import Select, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import AIAnalysis, Review, Reply

DateRange = Literal["30", "90", "all"]
RATING_KEYS = ("1", "2", "3", "4", "5")


def _range_cutoff(date_range: DateRange) -> datetime | None:
    if date_range == "all":
        return None
    return datetime.now(timezone.utc) - timedelta(days=int(date_range))


def _in_range(stmt: Select, business_id: UUID, date_range: DateRange) -> Select:
    stmt = stmt.where(Review.business_id == business_id)
    cutoff = _range_cutoff(date_range)
    if cutoff is not None:
        stmt = stmt.where(Review.created_at >= cutoff)
    return stmt


async def get_sentiment_breakdown(db: AsyncSession, business_id: UUID) -> dict[str, int]:
    """All-time sentiment mix (not range-filtered; preserves current tile meaning)."""
    result = await db.execute(
        select(AIAnalysis.sentiment, func.count(AIAnalysis.id))
        .join(Review, Review.id == AIAnalysis.review_id)
        .where(Review.business_id == business_id, AIAnalysis.sentiment.isnot(None))
        .group_by(AIAnalysis.sentiment)
    )
    breakdown = {"positive": 0, "neutral": 0, "negative": 0}
    for sentiment, count in result.all():
        if sentiment:
            breakdown[sentiment.value] = count
    return breakdown


async def get_recent_reviews(db: AsyncSession, business_id: UUID, limit: int = 10) -> list[Review]:
    """All-time most recent reviews (not range-filtered; preserves current tile meaning)."""
    result = await db.execute(
        select(Review)
        .options(
            selectinload(Review.author),
            selectinload(Review.business),
            selectinload(Review.ai_analysis),
            selectinload(Review.reply),
            selectinload(Review.photos),
        )
        .where(Review.business_id == business_id)
        .order_by(Review.created_at.desc())
        .limit(limit)
    )
    return list(result.scalars().all())


async def get_review_volume_by_month(db: AsyncSession, business_id: UUID, date_range: DateRange) -> list[dict[str, Any]]:
    month = func.to_char(func.timezone("UTC", Review.created_at), "YYYY-MM").label("month")
    stmt = _in_range(select(month, func.count(Review.id)), business_id, date_range).group_by("month").order_by("month")
    result = await db.execute(stmt)
    return [{"month": m, "count": c} for m, c in result.all()]


async def get_rating_distribution(db: AsyncSession, business_id: UUID, date_range: DateRange) -> dict[str, int]:
    stmt = _in_range(select(Review.rating, func.count(Review.id)), business_id, date_range).group_by(Review.rating)
    result = await db.execute(stmt)
    distribution = {key: 0 for key in RATING_KEYS}
    for rating, count in result.all():
        distribution[str(rating)] = count
    return distribution


async def get_reply_rate(db: AsyncSession, business_id: UUID, date_range: DateRange) -> float | None:
    total_stmt = _in_range(select(func.count(Review.id)), business_id, date_range)
    total = (await db.execute(total_stmt)).scalar() or 0
    if total == 0:
        return None

    replied_stmt = _in_range(
        select(func.count(Review.id)).join(Reply, Reply.review_id == Review.id), business_id, date_range
    )
    replied = (await db.execute(replied_stmt)).scalar() or 0
    return replied / total


async def get_reviews_for_export(db: AsyncSession, business_id: UUID, date_range: DateRange) -> list[Review]:
    stmt = _in_range(
        select(Review).options(selectinload(Review.author), selectinload(Review.reply)), business_id, date_range
    ).order_by(Review.created_at.desc())
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_dashboard_aggregates(db: AsyncSession, business_id: UUID, date_range: DateRange) -> dict[str, Any]:
    """Range-filtered fields only (volume, rating mix, reply-rate). Callers add
    the all-time sentiment/recent/total/average fields separately."""
    return {
        "review_volume_by_month": await get_review_volume_by_month(db, business_id, date_range),
        "rating_distribution": await get_rating_distribution(db, business_id, date_range),
        "reply_rate": await get_reply_rate(db, business_id, date_range),
        "review_count_in_range": await _count_reviews(db, business_id, date_range, previous=False),
        "review_count_previous": await _count_reviews(db, business_id, date_range, previous=True),
        "reply_rate_previous": await _reply_rate_previous(db, business_id, date_range),
    }


async def _count_reviews(db: AsyncSession, business_id: UUID, date_range: DateRange, *, previous: bool) -> int | None:
    if date_range == "all":
        if previous:
            return None
        stmt = select(func.count(Review.id)).where(Review.business_id == business_id)
        return (await db.execute(stmt)).scalar() or 0
    days = int(date_range)
    now = datetime.now(timezone.utc)
    if previous:
        start = now - timedelta(days=days * 2)
        end = now - timedelta(days=days)
        stmt = select(func.count(Review.id)).where(
            Review.business_id == business_id, Review.created_at >= start, Review.created_at < end
        )
    else:
        stmt = _in_range(select(func.count(Review.id)), business_id, date_range)
    return (await db.execute(stmt)).scalar() or 0


async def _reply_rate_previous(db: AsyncSession, business_id: UUID, date_range: DateRange) -> float | None:
    if date_range == "all":
        return None
    days = int(date_range)
    now = datetime.now(timezone.utc)
    start = now - timedelta(days=days * 2)
    end = now - timedelta(days=days)
    total_stmt = select(func.count(Review.id)).where(
        Review.business_id == business_id, Review.created_at >= start, Review.created_at < end
    )
    total = (await db.execute(total_stmt)).scalar() or 0
    if total == 0:
        return None
    replied_stmt = (
        select(func.count(Review.id))
        .join(Reply, Reply.review_id == Review.id)
        .where(Review.business_id == business_id, Review.created_at >= start, Review.created_at < end)
    )
    replied = (await db.execute(replied_stmt)).scalar() or 0
    return replied / total
