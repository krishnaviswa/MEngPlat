import math

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.models import AIAnalysis, Business, BusinessCategory, BusinessStatus, Category, Review, Sentiment
from app.schemas import BusinessResponse, CategoryResponse
from app.services.cache import cache_get, cache_set

router = APIRouter(prefix="/search", tags=["Search"])


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


@router.get("/businesses", response_model=list[BusinessResponse])
async def search_businesses(
    q: str | None = Query(default=None, description="Search query"),
    city: str | None = None,
    category: str | None = None,
    min_rating: float | None = None,
    sentiment: Sentiment | None = None,
    lat: float | None = None,
    lng: float | None = None,
    radius_km: float = 10.0,
    page: int = 1,
    page_size: int = 20,
    db: AsyncSession = Depends(get_db),
) -> list[BusinessResponse]:
    """
    Search and filter businesses.

    **Query params:** q, city, category (slug), min_rating, sentiment, lat, lng, radius_km, page, page_size
    **Response:** Paginated business list (cached in Redis)
    """
    cache_key = f"search:{q}:{city}:{category}:{min_rating}:{sentiment}:{lat}:{lng}:{page}"
    cached = await cache_get(cache_key)
    if cached:
        return [BusinessResponse.model_validate(b) for b in cached]

    query = (
        select(Business)
        .options(selectinload(Business.categories).selectinload(BusinessCategory.category))
        .where(Business.status == BusinessStatus.APPROVED)
    )

    if q:
        query = query.where(
            or_(Business.name.ilike(f"%{q}%"), Business.description.ilike(f"%{q}%"), Business.city.ilike(f"%{q}%"))
        )
    if city:
        query = query.where(Business.city.ilike(f"%{city}%"))
    if min_rating:
        query = query.where(Business.average_rating >= min_rating)
    if category:
        query = query.join(BusinessCategory).join(Category).where(Category.slug == category)
    if sentiment:
        query = (
            query.join(Review, Review.business_id == Business.id)
            .join(AIAnalysis, AIAnalysis.review_id == Review.id)
            .where(AIAnalysis.sentiment == sentiment)
        )

    query = query.order_by(Business.average_rating.desc())
    offset = (page - 1) * page_size
    result = await db.execute(query.offset(offset).limit(page_size))
    businesses = result.scalars().unique().all()

    if lat is not None and lng is not None:
        businesses = [
            b
            for b in businesses
            if b.latitude and b.longitude and _haversine_km(lat, lng, b.latitude, b.longitude) <= radius_km
        ]

    responses = [
        BusinessResponse(
            id=b.id,
            name=b.name,
            slug=b.slug,
            description=b.description,
            address=b.address,
            city=b.city,
            state=b.state,
            postal_code=b.postal_code,
            country=b.country,
            latitude=b.latitude,
            longitude=b.longitude,
            phone=b.phone,
            email=b.email,
            website=b.website,
            logo_url=b.logo_url,
            storefront_url=b.storefront_url,
            business_hours=b.business_hours,
            status=b.status,
            average_rating=b.average_rating,
            review_count=b.review_count,
            ai_merchant_summary=b.ai_merchant_summary,
            categories=[CategoryResponse.model_validate(bc.category) for bc in b.categories],
        )
        for b in businesses
    ]

    await cache_set(cache_key, [r.model_dump(mode="json") for r in responses])
    return responses
