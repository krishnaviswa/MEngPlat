from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.dependencies import require_roles
from app.models import AIAnalysis, Business, Merchant, Review, User, UserRole
from app.schemas import AIAnalysisResponse, MerchantInsightsResponse
from app.services.ai import get_ai_provider
from app.services.business_service import refresh_merchant_ai_summary

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
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> MerchantInsightsResponse:
    """
    Get aggregated AI insights for a merchant's business.

    **Path:** business_id
    **Response:** Merchant summary, themes, trends, suggested responses
    **Auth:** Merchant (own business) or Admin
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
        await refresh_merchant_ai_summary(db, business_id)
        await db.refresh(business)

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
    )


@router.post("/businesses/{business_id}/refresh", response_model=MerchantInsightsResponse)
async def refresh_insights(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> MerchantInsightsResponse:
    """Manually trigger AI summary refresh for a business."""
    await refresh_merchant_ai_summary(db, business_id)
    return await get_merchant_insights(business_id, db, user)
