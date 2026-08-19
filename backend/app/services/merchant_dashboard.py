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

from sqlalchemy import Select, and_, exists, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import AIAnalysis, Reply, Review, ReviewStatus

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
        .where(Review.business_id == business_id, Review.status == ReviewStatus.ACTIVE)
        .order_by(Review.created_at.desc())
        .limit(limit)
    )
    return list(result.scalars().all())


async def get_review_volume_by_month(db: AsyncSession, business_id: UUID, date_range: DateRange) -> list[dict[str, Any]]:
    month = func.to_char(func.timezone("UTC", Review.created_at), "YYYY-MM").label("month")
    stmt = _in_range(select(month, func.count(Review.id)), business_id, date_range).group_by("month").order_by("month")
    result = await db.execute(stmt)
    return [{"month": m, "count": c} for m, c in result.all()]


async def get_reviews_for_export(db: AsyncSession, business_id: UUID, date_range: DateRange) -> list[Review]:
    stmt = _in_range(
        select(Review).options(selectinload(Review.author), selectinload(Review.reply)), business_id, date_range
    ).order_by(Review.created_at.desc())
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def get_dashboard_aggregates(db: AsyncSession, business_id: UUID, date_range: DateRange) -> dict[str, Any]:
    """Range-filtered fields only (volume, rating mix, reply-rate). Callers add
    the all-time sentiment/recent/total/average fields separately.

    Two round trips, not eight: month volume still needs GROUP BY month; rating
    mix, counts, and reply rates share one COUNT(*) FILTER query. Same session
    cannot safely asyncio.gather concurrent statements.
    """
    volume = await get_review_volume_by_month(db, business_id, date_range)
    kpis = await _range_kpis(db, business_id, date_range)
    return {"review_volume_by_month": volume, **kpis}


def _and(*parts: Any) -> Any:
    live = [p for p in parts if p is not None]
    if not live:
        return None
    if len(live) == 1:
        return live[0]
    return and_(*live)


async def _range_kpis(db: AsyncSession, business_id: UUID, date_range: DateRange) -> dict[str, Any]:
    """Rating mix, in-range counts, and reply rates in a single statement."""
    cutoff = _range_cutoff(date_range)
    current_bound = Review.created_at >= cutoff if cutoff is not None else None
    prev_bound = None
    if cutoff is not None:
        days = int(date_range)
        now = datetime.now(timezone.utc)
        prev_bound = and_(Review.created_at >= now - timedelta(days=days * 2), Review.created_at < cutoff)

    has_reply = exists(select(Reply.id).where(Reply.review_id == Review.id))

    def cnt(*parts: Any):
        clause = _and(*parts)
        if clause is None:
            return func.count(Review.id)
        return func.count(Review.id).filter(clause)

    columns = [
        cnt(current_bound).label("count_in_range"),
        cnt(current_bound, Review.rating == 1).label("r1"),
        cnt(current_bound, Review.rating == 2).label("r2"),
        cnt(current_bound, Review.rating == 3).label("r3"),
        cnt(current_bound, Review.rating == 4).label("r4"),
        cnt(current_bound, Review.rating == 5).label("r5"),
        cnt(current_bound, has_reply).label("replied"),
    ]
    if prev_bound is not None:
        columns.extend(
            [
                cnt(prev_bound).label("count_previous"),
                cnt(prev_bound, has_reply).label("replied_previous"),
            ]
        )

    row = (await db.execute(select(*columns).where(Review.business_id == business_id))).one()
    total = int(row.count_in_range or 0)
    replied = int(row.replied or 0)
    result: dict[str, Any] = {
        "rating_distribution": {key: int(getattr(row, f"r{key}") or 0) for key in RATING_KEYS},
        "reply_rate": None if total == 0 else replied / total,
        "review_count_in_range": total,
        "review_count_previous": None,
        "reply_rate_previous": None,
    }
    if prev_bound is not None:
        prev_total = int(row.count_previous or 0)
        prev_replied = int(row.replied_previous or 0)
        result["review_count_previous"] = prev_total
        result["reply_rate_previous"] = None if prev_total == 0 else prev_replied / prev_total
    return result
