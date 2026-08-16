from uuid import UUID

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.config import get_settings
from app.database import get_db
from app.dependencies import require_roles
from app.models import AIAnalysis, Business, Merchant, Review, ReviewStatus, User, UserRole
from app.schemas import AIAnalysisResponse, MerchantInsightsResponse, TopicClusterResponse
from app.services.ai import get_ai_provider
from app.services.ai.prompts import PROMPT_VERSION
from app.services.business_service import refresh_merchant_ai_summary, refresh_merchant_ai_summary_bg
from app.services.cache import cache_get, cache_set

router = APIRouter(prefix="/ai", tags=["AI Analysis"])


@router.get("/reviews/{review_id}", response_model=AIAnalysisResponse)
async def get_review_analysis(review_id: UUID, db: AsyncSession = Depends(get_db)) -> AIAnalysisResponse:
    """
    Get AI analysis for a specific review.

    **Path:** review_id
    **Response:** Sentiment, summary, positives, complaints, suggested response
    """
    result = await db.execute(select(AIAnalysis).where(AIAnalysis.review_id == review_id))
    analysis = result.scalar_one_or_none()
    if not analysis:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Analysis not found")
    return AIAnalysisResponse.model_validate(analysis)


@router.get("/businesses/{business_id}/insights", response_model=MerchantInsightsResponse)
async def get_merchant_insights(
    business_id: UUID,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> MerchantInsightsResponse:
    """
    Get aggregated AI insights for a merchant's business.

    **Path:** business_id
    **Response:** Merchant summary, themes, trends, suggested responses
    **Auth:** Merchant (own business) or Admin

    If no summary has been generated yet, this schedules one in the
    background and returns immediately with merchant_summary=None, rather
    than blocking the request on a live LLM call as it used to -- a GET
    should not have unbounded latency (or cost) hiding behind it. Poll again,
    or use POST .../refresh for a summary you need synchronously.
    """
    business = await db.get(Business, business_id)
    if not business:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")

    if user.role == UserRole.MERCHANT:
        merchant = await db.execute(select(Merchant).where(Merchant.user_id == user.id))
        m = merchant.scalar_one_or_none()
        if not m or business.merchant_id != m.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your business")

    if not business.ai_merchant_summary:
        background_tasks.add_task(refresh_merchant_ai_summary_bg, business_id)

    result = await db.execute(
        select(AIAnalysis)
        .join(Review, Review.id == AIAnalysis.review_id)
        .where(Review.business_id == business_id, AIAnalysis.sentiment.isnot(None))
    )
    analyses = result.scalars().all()
    sentiment_breakdown = {"positive": 0, "neutral": 0, "negative": 0}
    suggested = []
    for a in analyses:
        if a.sentiment:
            sentiment_breakdown[a.sentiment.value] += 1
        if a.suggested_response:
            suggested.append(a.suggested_response)

    return MerchantInsightsResponse(
        business_id=business_id,
        merchant_summary=business.ai_merchant_summary,
        frequently_mentioned_positives=business.ai_positives or [],
        frequently_mentioned_complaints=business.ai_complaints or [],
        suggested_responses=list(dict.fromkeys(suggested))[:5],
        monthly_trends=business.ai_monthly_trends or [],
        sentiment_breakdown=sentiment_breakdown,
        degraded=business.ai_degraded,
    )


@router.post("/businesses/{business_id}/refresh", response_model=MerchantInsightsResponse)
async def refresh_insights(
    business_id: UUID,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> MerchantInsightsResponse:
    """Manually trigger AI summary refresh for a business. Synchronous,
    unlike GET .../insights -- this endpoint exists specifically for a caller
    that wants a fresh summary right now and is willing to wait for it."""
    await refresh_merchant_ai_summary(db, business_id)
    return await get_merchant_insights(business_id, background_tasks, db, user)


async def _assert_owns_or_admin(db: AsyncSession, business: Business, user: User) -> None:
    if user.role == UserRole.MERCHANT:
        merchant = await db.execute(select(Merchant).where(Merchant.user_id == user.id))
        m = merchant.scalar_one_or_none()
        if not m or business.merchant_id != m.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your business")


@router.get("/businesses/{business_id}/topics", response_model=TopicClusterResponse)
async def get_topic_clusters(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> TopicClusterResponse:
    """
    Get AI-suggested common themes across a business's reviews.

    **Path:** business_id
    **Response:** Named topics with mention count, sentiment, and an example quote -- suggestions, not facts.
    **Auth:** Merchant (own business) or Admin

    Synchronous, not persisted -- a business below `ai_topics_min_reviews` never
    reaches the AI provider at all (insufficient_data=True). Above threshold,
    results are cache-aside in Redis for `ai_topics_cache_ttl_seconds`; only the
    first dashboard load in that window pays for the LLM call.
    """
    settings = get_settings()
    business = await db.get(Business, business_id)
    if not business:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
    await _assert_owns_or_admin(db, business, user)

    count_result = await db.execute(
        select(func.count(Review.id)).where(
            Review.business_id == business_id,
            Review.status == ReviewStatus.ACTIVE,
            func.length(func.trim(Review.body)) > settings.ai_topics_min_review_chars,
        )
    )
    eligible_count = count_result.scalar_one()
    if eligible_count < settings.ai_topics_min_reviews:
        return TopicClusterResponse(business_id=business_id, topics=[], insufficient_data=True)

    cache_key = f"ai:topics:{business_id}:v{PROMPT_VERSION}"
    cached = await cache_get(cache_key)
    if cached is not None:
        return TopicClusterResponse(business_id=business_id, **cached)

    result = await db.execute(
        select(Review, AIAnalysis)
        .join(AIAnalysis, AIAnalysis.review_id == Review.id, isouter=True)
        .where(Review.business_id == business_id, Review.status == ReviewStatus.ACTIVE)
        .order_by(Review.created_at.desc())
        .limit(settings.ai_max_reviews_per_summary)
    )
    rows = result.all()
    reviews_data = [
        {
            "rating": review.rating,
            "body": review.body[: settings.ai_max_review_chars],
            "sentiment": analysis.sentiment.value if analysis and analysis.sentiment else "neutral",
        }
        for review, analysis in rows
    ]

    provider = get_ai_provider()
    try:
        cluster_result = await provider.generate_topic_clusters(reviews_data)
    except Exception:
        return TopicClusterResponse(business_id=business_id, topics=[], unavailable=True)

    sorted_topics = sorted(cluster_result.topics, key=lambda t: t.get("count", 0), reverse=True)
    payload = {"topics": sorted_topics, "degraded": cluster_result.meta.degraded}
    await cache_set(cache_key, payload, ttl=settings.ai_topics_cache_ttl_seconds)
    return TopicClusterResponse(business_id=business_id, **payload)
