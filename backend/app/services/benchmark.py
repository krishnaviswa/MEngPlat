"""Category + city rating medians from Business rows (S-038)."""

from __future__ import annotations

from statistics import median
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import Business, BusinessCategory, BusinessStatus

DISCLAIMER = "Directory medians from MerchantHub listings — not an AI judgment."


def _median_or_none(values: list[float]) -> float | None:
    if len(values) < 3:
        return None
    return float(median(values))


async def get_benchmark(db: AsyncSession, business: Business) -> dict:
    loaded = await db.execute(
        select(Business).options(selectinload(Business.categories)).where(Business.id == business.id)
    )
    business = loaded.scalar_one()
    cat_ids = [bc.category_id for bc in business.categories]

    city_rows = await db.execute(
        select(Business.average_rating).where(
            Business.status == BusinessStatus.APPROVED,
            Business.city == business.city,
            Business.id != business.id,
        )
    )
    city_vals = [float(r[0]) for r in city_rows.all()]

    cat_vals: list[float] = []
    if cat_ids:
        cat_rows = await db.execute(
            select(Business.average_rating)
            .join(BusinessCategory, BusinessCategory.business_id == Business.id)
            .where(
                Business.status == BusinessStatus.APPROVED,
                Business.id != business.id,
                BusinessCategory.category_id.in_(cat_ids),
            )
            .distinct()
        )
        cat_vals = [float(r[0]) for r in cat_rows.all()]

    return {
        "business_id": business.id,
        "own_rating": business.average_rating,
        "category_median": _median_or_none(cat_vals),
        "city_median": _median_or_none(city_vals),
        "category_sample_size": len(cat_vals),
        "city_sample_size": len(city_vals),
        "disclaimer": DISCLAIMER,
    }
