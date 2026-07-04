from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import require_roles
from app.models import Business, Merchant, User, UserRole
from app.schemas import MerchantInsightsResponse
from app.routers.ai import get_merchant_insights

router = APIRouter(prefix="/analytics", tags=["Merchant Analytics"])


@router.get("/merchant/{business_id}", response_model=MerchantInsightsResponse)
async def merchant_analytics(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> MerchantInsightsResponse:
    """
    Merchant analytics endpoint — alias for AI insights with KPI context.

    **Path:** business_id
    **Response:** Full merchant insights package
    """
    return await get_merchant_insights(business_id, db, user)


@router.get("/merchant/{business_id}/summary")
async def analytics_summary(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> dict:
    """Quick KPI summary for merchant header widgets."""
    business = await db.get(Business, business_id)
    if not business:
        raise HTTPException(status_code=404, detail="Business not found")

    if user.role == UserRole.MERCHANT:
        m = await db.execute(select(Merchant).where(Merchant.user_id == user.id))
        merchant = m.scalar_one_or_none()
        if not merchant or business.merchant_id != merchant.id:
            raise HTTPException(status_code=403, detail="Not your business")

    return {
        "business_id": str(business_id),
        "average_rating": business.average_rating,
        "review_count": business.review_count,
        "ai_summary_preview": (business.ai_merchant_summary or "")[:200],
    }
