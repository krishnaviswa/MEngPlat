from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Business, Review, ReviewStatus, Sentiment


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

    result = await db.execute(
        select(Review, AIAnalysis)
        .join(AIAnalysis, AIAnalysis.review_id == Review.id, isouter=True)
        .where(Review.business_id == business_id, Review.status == ReviewStatus.ACTIVE)
        .order_by(Review.created_at.desc())
        .limit(50)
    )
    rows = result.all()
    reviews_data = [
        {
            "rating": review.rating,
            "body": review.body,
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
