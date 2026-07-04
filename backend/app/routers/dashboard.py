from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.dependencies import require_roles
from app.models import Business, BusinessStatus, Merchant, Review, ReviewStatus, User, UserRole
from app.schemas import DashboardStats, PlatformAnalytics, ReviewResponse, UserResponse
from app.routers.reviews import _review_response

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/merchant/{business_id}", response_model=DashboardStats)
async def merchant_dashboard(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> DashboardStats:
    """
    Merchant analytics dashboard data.

    **Response:** total reviews, average rating, sentiment breakdown, recent reviews, monthly volume
    """
    business = await db.get(Business, business_id)
    if not business:
        raise HTTPException(status_code=404, detail="Business not found")

    if user.role == UserRole.MERCHANT:
        m = await db.execute(select(Merchant).where(Merchant.user_id == user.id))
        merchant = m.scalar_one_or_none()
        if not merchant or business.merchant_id != merchant.id:
            raise HTTPException(status_code=403, detail="Not your business")

    from app.models import AIAnalysis, Sentiment

    sentiment_result = await db.execute(
        select(AIAnalysis.sentiment, func.count(AIAnalysis.id))
        .join(Review, Review.id == AIAnalysis.review_id)
        .where(Review.business_id == business_id, AIAnalysis.sentiment.isnot(None))
        .group_by(AIAnalysis.sentiment)
    )
    sentiment_breakdown = {"positive": 0, "neutral": 0, "negative": 0}
    for sentiment, count in sentiment_result.all():
        if sentiment:
            sentiment_breakdown[sentiment.value] = count

    recent = await db.execute(
        select(Review)
        .options(
            selectinload(Review.author),
            selectinload(Review.ai_analysis),
            selectinload(Review.photos),
        )
        .where(Review.business_id == business_id)
        .order_by(Review.created_at.desc())
        .limit(10)
    )

    volume_result = await db.execute(
        select(
            func.to_char(Review.created_at, "YYYY-MM").label("month"),
            func.count(Review.id),
        )
        .where(Review.business_id == business_id)
        .group_by("month")
        .order_by("month")
    )

    return DashboardStats(
        total_reviews=business.review_count,
        average_rating=business.average_rating,
        sentiment_breakdown=sentiment_breakdown,
        recent_reviews=[_review_response(r) for r in recent.scalars().all()],
        review_volume_by_month=[{"month": m, "count": c} for m, c in volume_result.all()],
    )


@router.get("/admin/platform", response_model=PlatformAnalytics)
async def platform_analytics(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> PlatformAnalytics:
    """Admin platform-wide analytics."""
    from app.models import ReviewReport

    users = await db.execute(select(func.count(User.id)))
    businesses = await db.execute(select(func.count(Business.id)))
    pending = await db.execute(select(func.count(Business.id)).where(Business.status == BusinessStatus.PENDING))
    reviews = await db.execute(select(func.count(Review.id)))
    reported = await db.execute(select(func.count(Review.id)).where(Review.status == ReviewStatus.REPORTED))

    return PlatformAnalytics(
        total_users=users.scalar() or 0,
        total_businesses=businesses.scalar() or 0,
        pending_businesses=pending.scalar() or 0,
        total_reviews=reviews.scalar() or 0,
        reported_reviews=reported.scalar() or 0,
    )
