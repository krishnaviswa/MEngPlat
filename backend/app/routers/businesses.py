from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.dependencies import require_roles, slugify
from app.models import Business, BusinessCategory, BusinessStatus, Category, Merchant, User, UserRole
from app.schemas import (
    BusinessCreate,
    BusinessResponse,
    BusinessUpdate,
    CategoryCreate,
    CategoryResponse,
    MessageResponse,
)

router = APIRouter(prefix="/businesses", tags=["Businesses"])


def _to_response(business: Business) -> BusinessResponse:
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
async def list_businesses(
    city: str | None = None,
    status_filter: BusinessStatus | None = BusinessStatus.APPROVED,
    db: AsyncSession = Depends(get_db),
) -> list[BusinessResponse]:
    """List businesses with optional city filter."""
    query = select(Business).options(selectinload(Business.categories).selectinload(BusinessCategory.category))
    if status_filter:
        query = query.where(Business.status == status_filter)
    if city:
        query = query.where(Business.city.ilike(f"%{city}%"))
    query = query.order_by(Business.average_rating.desc()).limit(50)
    result = await db.execute(query)
    return [_to_response(b) for b in result.scalars().all()]


@router.get("/categories/all", response_model=list[CategoryResponse])
async def list_categories(db: AsyncSession = Depends(get_db)) -> list[CategoryResponse]:
    """List all business categories."""
    result = await db.execute(select(Category).order_by(Category.name))
    return list(result.scalars().all())


@router.post("/categories", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
async def create_category(
    payload: CategoryCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> CategoryResponse:
    """Admin: create a new category."""
    category = Category(**payload.model_dump())
    db.add(category)
    await db.refresh(category)
    return category


@router.get("/{slug}", response_model=BusinessResponse)
async def get_business(slug: str, db: AsyncSession = Depends(get_db)) -> BusinessResponse:
    """Get business profile by slug."""
    result = await db.execute(
        select(Business)
        .options(selectinload(Business.categories).selectinload(BusinessCategory.category))
        .where(Business.slug == slug)
    )
    business = result.scalar_one_or_none()
    if not business:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
    return _to_response(business)


@router.post("", response_model=BusinessResponse, status_code=status.HTTP_201_CREATED)
async def create_business(
    payload: BusinessCreate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT)),
) -> BusinessResponse:
    """Register a new business (merchant only). Status starts as pending."""
    merchant = await db.execute(select(Merchant).where(Merchant.user_id == user.id))
    merchant_obj = merchant.scalar_one_or_none()
    if not merchant_obj:
        merchant_obj = Merchant(user_id=user.id)
        db.add(merchant_obj)
        await db.flush()

    business = Business(
        merchant_id=merchant_obj.id,
        name=payload.name,
        slug=slugify(payload.name),
        description=payload.description,
        address=payload.address,
        city=payload.city,
        state=payload.state,
        postal_code=payload.postal_code,
        country=payload.country,
        latitude=payload.latitude,
        longitude=payload.longitude,
        phone=payload.phone,
        email=payload.email,
        website=payload.website,
        business_hours=payload.business_hours,
        status=BusinessStatus.PENDING,
    )
    db.add(business)
    await db.flush()

    for cat_id in payload.category_ids:
        db.add(BusinessCategory(business_id=business.id, category_id=cat_id))

    result = await db.execute(
        select(Business)
        .options(selectinload(Business.categories).selectinload(BusinessCategory.category))
        .where(Business.id == business.id)
    )
    return _to_response(result.scalar_one())


@router.patch("/{business_id}", response_model=BusinessResponse)
async def update_business(
    business_id: UUID,
    payload: BusinessUpdate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> BusinessResponse:
    """Update business details."""
    business = await db.get(Business, business_id)
    if not business:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")

    if user.role == UserRole.MERCHANT:
        merchant = await db.execute(select(Merchant).where(Merchant.user_id == user.id))
        m = merchant.scalar_one_or_none()
        if not m or business.merchant_id != m.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your business")

    for field, value in payload.model_dump(exclude_unset=True, exclude={"category_ids"}).items():
        setattr(business, field, value)

    if payload.category_ids is not None:
        await db.execute(BusinessCategory.__table__.delete().where(BusinessCategory.business_id == business_id))
        for cat_id in payload.category_ids:
            db.add(BusinessCategory(business_id=business_id, category_id=cat_id))

    result = await db.execute(
        select(Business)
        .options(selectinload(Business.categories).selectinload(BusinessCategory.category))
        .where(Business.id == business_id)
    )
    return _to_response(result.scalar_one())


@router.post("/{business_id}/approve", response_model=BusinessResponse)
async def approve_business(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> BusinessResponse:
    """Admin: approve a pending business."""
    from app.models import AuditLog

    business = await db.get(Business, business_id)
    if not business:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
    business.status = BusinessStatus.APPROVED
    db.add(AuditLog(admin_id=admin.id, action="approve", entity_type="business", entity_id=str(business_id)))
    result = await db.execute(
        select(Business)
        .options(selectinload(Business.categories).selectinload(BusinessCategory.category))
        .where(Business.id == business_id)
    )
    return _to_response(result.scalar_one())


@router.post("/{business_id}/suspend", response_model=MessageResponse)
async def suspend_business(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> MessageResponse:
    """Admin: suspend a business."""
    from app.models import AuditLog

    business = await db.get(Business, business_id)
    if not business:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
    business.status = BusinessStatus.SUSPENDED
    db.add(AuditLog(admin_id=admin.id, action="suspend", entity_type="business", entity_id=str(business_id)))
    return MessageResponse(message="Business suspended")
