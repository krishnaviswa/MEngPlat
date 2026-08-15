"""Admin platform time-series aggregations (S-034).

Every series is derived from a stored timestamp column -- never a mock/AI
series. Buckets are zero-filled across the full `[now - days, now]` window so
the frontend can treat "all four series all zeros" as the empty-chart case
(AC 8) instead of guessing from a short array.
"""

from __future__ import annotations

from datetime import date, datetime, timedelta, timezone
from typing import Any, Literal

from sqlalchemy import ColumnElement, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import AuditLog, Review, ReviewReport, User

Granularity = Literal["day", "week"]


def _week_start(d: date) -> date:
    return d - timedelta(days=d.weekday())


def _zero_fill_buckets(cutoff: datetime, now: datetime, granularity: Granularity) -> list[str]:
    if granularity == "week":
        start, end, step = _week_start(cutoff.date()), _week_start(now.date()), timedelta(weeks=1)
    else:
        start, end, step = cutoff.date(), now.date(), timedelta(days=1)

    buckets: list[str] = []
    current = start
    while current <= end:
        buckets.append(current.isoformat())
        current += step
    return buckets


async def _bucketed_counts(
    db: AsyncSession,
    column: ColumnElement,
    cutoff: datetime,
    granularity: Granularity,
    *extra_where: ColumnElement,
) -> dict[str, int]:
    ts = func.timezone("UTC", column)
    bucket_expr = func.to_char(func.date_trunc("week", ts) if granularity == "week" else ts, "YYYY-MM-DD")
    bucket = bucket_expr.label("bucket")
    stmt = select(bucket, func.count()).where(column >= cutoff, *extra_where).group_by("bucket")
    result = await db.execute(stmt)
    return {b: c for b, c in result.all()}


async def get_platform_series(
    db: AsyncSession, granularity: Granularity, days: int
) -> dict[str, list[dict[str, Any]]]:
    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(days=days)
    buckets = _zero_fill_buckets(cutoff, now, granularity)

    async def series_for(column: ColumnElement, *extra_where: ColumnElement) -> list[dict[str, Any]]:
        counts = await _bucketed_counts(db, column, cutoff, granularity, *extra_where)
        return [{"bucket": b, "count": counts.get(b, 0)} for b in buckets]

    return {
        "new_users": await series_for(User.created_at),
        "businesses_approved": await series_for(
            AuditLog.created_at, AuditLog.action == "approve", AuditLog.entity_type == "business"
        ),
        "new_reviews": await series_for(Review.created_at),
        "new_reports": await series_for(ReviewReport.created_at),
    }
