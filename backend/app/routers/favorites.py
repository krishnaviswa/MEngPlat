from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.dependencies import require_roles
from app.models import Business, BusinessCategory, BusinessStatus, Favorite, User, UserRole
from app.schemas import BusinessResponse, CategoryResponse, FavoriteCreate, FavoriteResponse

router = APIRouter(prefix="/favorites", tags=["Favorites"])


def _business_response(business: Business) -> BusinessResponse:
    return BusinessResponse(
        id=business.id,
        name=business.name,
        slug=business.slug,
        description=business.description,
        address=business.address,
        city=business.city,
        state=business.state,
        postal_code=business.postal_code,
        country=business.country,
        latitude=business.latitude,
        longitude=business.longitude,
        phone=business.phone,
        email=business.email,
        website=business.website,
        logo_url=business.logo_url,
        storefront_url=business.storefront_url,
        business_hours=business.business_hours,
        status=business.status,
        average_rating=business.average_rating,
        review_count=business.review_count,
        ai_merchant_summary=business.ai_merchant_summary,
        categories=[CategoryResponse.model_validate(bc.category) for bc in business.categories],
    )


@router.get("", response_model=list[BusinessResponse])
async def list_favorites(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.CUSTOMER)),
) -> list[BusinessResponse]:
    """List the current customer's favorited businesses (newest first)."""
    result = await db.execute(
        select(Business)
        .join(Favorite, Favorite.business_id == Business.id)
        .options(selectinload(Business.categories).selectinload(BusinessCategory.category))
        .where(Favorite.user_id == user.id)
        .order_by(Favorite.created_at.desc())
    )
    return [_business_response(b) for b in result.scalars().all()]


@router.post("", response_model=FavoriteResponse, status_code=status.HTTP_201_CREATED)
async def create_favorite(
    payload: FavoriteCreate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.CUSTOMER)),
) -> FavoriteResponse:
    """Favorite an approved business (idempotent). 404 if missing or not approved."""
    business = await db.get(Business, payload.business_id)
    if not business or business.status != BusinessStatus.APPROVED:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found or not approved")

    existing = await db.execute(
        select(Favorite).where(Favorite.user_id == user.id, Favorite.business_id == payload.business_id)
    )
    if not existing.scalar_one_or_none():
        db.add(Favorite(user_id=user.id, business_id=payload.business_id))

    return FavoriteResponse(favorited=True, business_id=payload.business_id)


@router.delete("/{business_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_favorite(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.CUSTOMER)),
) -> Response:
    """Un-favorite a business (idempotent)."""
    existing = await db.execute(
        select(Favorite).where(Favorite.user_id == user.id, Favorite.business_id == business_id)
    )
    favorite = existing.scalar_one_or_none()
    if favorite:
        await db.delete(favorite)

    return Response(status_code=status.HTTP_204_NO_CONTENT)
