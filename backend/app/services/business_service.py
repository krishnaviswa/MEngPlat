import logging

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.models import Business, Review, ReviewStatus

logger = logging.getLogger(__name__)


async def update_business_rating(db: AsyncSession, business_id) -> None:
    result = await db.execute(
        select(func.avg(Review.rating), func.count(Review.id)).where(
            Review.business_id == business_id,
            Review.status == ReviewStatus.ACTIVE,
        )
    )
    avg_rating, count = result.one()
    business = await db.get(Business, business_id)
    if business:
        business.average_rating = float(avg_rating or 0)
        business.review_count = int(count or 0)


async def refresh_merchant_ai_summary(db: AsyncSession, business_id) -> None:
    from app.models import AIAnalysis
    from app.services.ai import get_ai_provider

    settings = get_settings()

    result = await db.execute(
        select(Review, AIAnalysis)
        .join(AIAnalysis, AIAnalysis.review_id == Review.id, isouter=True)
        .where(Review.business_id == business_id, Review.status == ReviewStatus.ACTIVE)
        .order_by(Review.created_at.desc())
        .limit(settings.ai_max_reviews_per_summary)
    )
    rows = result.all()
    # Unbounded review bodies here means unbounded prompt size -- this used to
    # json.dumps up to 50 full review bodies on every single review
    # submission, since this function ran synchronously on every create.
    reviews_data = [
        {
            "rating": review.rating,
            "body": review.body[: settings.ai_max_review_chars],
            "sentiment": analysis.sentiment.value if analysis and analysis.sentiment else "neutral",
        }
        for review, analysis in rows
    ]

    if not reviews_data:
        return

    provider = get_ai_provider()
    summary = await provider.generate_merchant_summary(reviews_data)
    business = await db.get(Business, business_id)
    if business:
        business.ai_merchant_summary = summary.summary
        business.ai_positives = summary.positives
        business.ai_complaints = summary.complaints
        business.ai_monthly_trends = summary.monthly_trends
        business.ai_degraded = summary.meta.degraded


async def refresh_merchant_ai_summary_bg(business_id) -> None:
    """BackgroundTasks entry point, debounced via a Redis lock.

    Without this, a burst of N reviews in a short window triggered N
    synchronous LLM calls -- one per review create, each blocking the
    response on two sequential round-trips (review analysis, then this).
    Now: N review creates each schedule this as a background task, but only
    the first one to acquire the lock actually runs it; the rest are no-ops
    for the lock's TTL.

    Opens its own session because by the time a background task runs, the
    request's session -- and get_db's implicit commit -- has already closed.
    """
    from app.database import AsyncSessionLocal
    from app.services.cache import try_acquire_lock

    settings = get_settings()
    acquired = await try_acquire_lock(
        f"ai:summary-lock:{business_id}", ttl=settings.ai_summary_debounce_seconds
    )
    if not acquired:
        return

    try:
        async with AsyncSessionLocal() as db:
            await refresh_merchant_ai_summary(db, business_id)
            await db.commit()
    except Exception:
        # FastAPI swallows BackgroundTasks exceptions silently -- without this
        # log, a broken summary refresh just stops happening with no signal.
        logger.exception(
            "merchant_ai_summary_background_refresh_failed", extra={"business_id": str(business_id)}
        )
