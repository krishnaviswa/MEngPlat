from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.dependencies import get_current_user, get_optional_user, require_roles, slugify
from app.models import (
    Business,
    BusinessCategory,
    BusinessStatus,
    Category,
    Merchant,
    NotificationType,
    Review,
    ReviewStatus,
    User,
    UserRole,
)
from app.schemas import (
    BusinessCreate,
    BusinessReportCreate,
    BusinessReportResponse,
    BusinessResponse,
    BusinessUpdate,
    CategoryCreate,
    CategoryResponse,
    ExternalReviewResponse,
    MessageResponse,
    PublicPlatformStats,
)
from app.services import business_reports as reports_service
from app.services import review_sync_service
from app.services.cache import cache_delete_pattern
from app.services.email import try_send_listing_approved
from app.services.notifications import SCENARIO_LISTING_APPROVED, upsert_notice
from app.services.payments.featured import load_active_featured_ends
from app.services.phone_otp import consume_otp, issue_otp
from app.services.sms import get_sms_provider

router = APIRouter(prefix="/businesses", tags=["Businesses"])

# S-073: address-bearing fields that trigger the re-verification gate on 2nd+ edit.
_ADDRESS_FIELDS = ("address", "city", "state", "postal_code", "country")


def _address_bizkey(business_id: UUID) -> str:
    return f"bizaddr:{business_id}"


def _to_response(business: Business, *, is_featured: bool = False) -> BusinessResponse:
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
        is_featured=is_featured,
    )


async def _to_responses(db: AsyncSession, rows: list[Business]) -> list[BusinessResponse]:
    featured = await load_active_featured_ends(db)
    return [_to_response(b, is_featured=b.id in featured) for b in rows]


@router.get("", response_model=list[BusinessResponse])
async def list_businesses(
    city: str | None = None,
    slugs: str | None = None,
    status_filter: BusinessStatus | None = BusinessStatus.APPROVED,
    db: AsyncSession = Depends(get_db),
    user: User | None = Depends(get_optional_user),
) -> list[BusinessResponse]:
    """List businesses with optional city/slugs filter. Non-approved status filters require admin."""
    if status_filter and status_filter != BusinessStatus.APPROVED:
        if not user or user.role != UserRole.ADMIN:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admin only")
    query = select(Business).options(selectinload(Business.categories).selectinload(BusinessCategory.category))
    if status_filter:
        query = query.where(Business.status == status_filter)
    if city:
        query = query.where(Business.city.ilike(f"%{city}%"))
    if slugs:
        slug_list = [s.strip() for s in slugs.split(",") if s.strip()]
        if slug_list:
            query = query.where(Business.slug.in_(slug_list))
    query = query.order_by(Business.average_rating.desc()).limit(50)
    result = await db.execute(query)
    return await _to_responses(db, list(result.scalars().all()))


@router.get("/categories/all", response_model=list[CategoryResponse])
async def list_categories(q: str | None = None, db: AsyncSession = Depends(get_db)) -> list[CategoryResponse]:
    """List business categories. Optional `q` filters by case-insensitive name substring (S-081)."""
    query = select(Category).order_by(Category.name)
    if q:
        query = query.where(Category.name.ilike(f"%{q}%"))
    result = await db.execute(query)
    return list(result.scalars().all())


@router.get("/cities", response_model=list[str])
async def list_cities(db: AsyncSession = Depends(get_db)) -> list[str]:
    """Distinct city names for approved businesses (search filter chips)."""
    result = await db.execute(
        select(Business.city)
        .where(
            Business.status == BusinessStatus.APPROVED,
            Business.city.isnot(None),
            Business.city != "",
        )
        .distinct()
        .order_by(Business.city.asc())
    )
    return [city for city in result.scalars().all() if city]


@router.get("/stats/summary", response_model=PublicPlatformStats)
async def public_stats_summary(db: AsyncSession = Depends(get_db)) -> PublicPlatformStats:
    """
    Public platform counts for the home page.
    Excludes admin-only signals (users, pending, reported).
    """
    businesses_count = await db.scalar(
        select(func.count()).select_from(Business).where(Business.status == BusinessStatus.APPROVED)
    )
    reviews_count = await db.scalar(
        select(func.count()).select_from(Review).where(Review.status == ReviewStatus.ACTIVE)
    )
    categories_count = await db.scalar(select(func.count()).select_from(Category))
    cities_count = await db.scalar(
        select(func.count(func.distinct(Business.city))).where(
            Business.status == BusinessStatus.APPROVED,
            Business.city.isnot(None),
            Business.city != "",
        )
    )
    return PublicPlatformStats(
        total_businesses=int(businesses_count or 0),
        total_reviews=int(reviews_count or 0),
        total_categories=int(categories_count or 0),
        total_cities=int(cities_count or 0),
    )


@router.get("/mine", response_model=list[BusinessResponse])
async def list_my_businesses(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT)),
) -> list[BusinessResponse]:
    """List businesses owned by the current merchant (any status)."""
    merchant = await db.execute(select(Merchant).where(Merchant.user_id == user.id))
    merchant_obj = merchant.scalar_one_or_none()
    if not merchant_obj:
        return []
    result = await db.execute(
        select(Business)
        .options(selectinload(Business.categories).selectinload(BusinessCategory.category))
        .where(Business.merchant_id == merchant_obj.id)
        .order_by(Business.name)
    )
    return await _to_responses(db, list(result.scalars().all()))


@router.get("/admin/all", response_model=list[BusinessResponse])
async def list_all_businesses_admin(
    page: int = 1,
    page_size: int = 20,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> list[BusinessResponse]:
    """
    Admin: browse businesses of every status (approved, pending, rejected,
    suspended), newest-registered first.

    **Query:** page (default 1), page_size (default 20, cap 100)
    **Response:** Businesses of every status — distinct from the public
    `GET /businesses`, which defaults to approved-only.
    """
    page_size = min(page_size, 100)
    result = await db.execute(
        select(Business)
        .options(selectinload(Business.categories).selectinload(BusinessCategory.category))
        .order_by(Business.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    return await _to_responses(db, list(result.scalars().all()))


@router.post("/categories", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
async def create_category(
    payload: CategoryCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> CategoryResponse:
    """Admin: create a new category. 409 if name or slug already exists."""
    category = Category(**payload.model_dump())
    db.add(category)
    try:
        await db.flush()
    except IntegrityError as exc:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="Category name or slug already exists"
        ) from exc
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
    from app.services.national_id import merchant_national_id_required

    if merchant_national_id_required(user):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="National ID is required for merchants before creating a listing",
        )
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

    payload_fields = payload.model_dump(exclude_unset=True, exclude={"category_ids", "address_otp_code"})
    address_changed = any(
        field in payload_fields and payload_fields[field] != getattr(business, field)
        for field in _ADDRESS_FIELDS
    )

    if address_changed:
        # Admin edits bypass re-verification (ADR-014 Risks: no single merchant
        # phone to send an admin-initiated OTP to) -- but the count still
        # advances so a later merchant edit isn't treated as the free first
        # edit just because an admin touched the address in between.
        if user.role == UserRole.MERCHANT and business.address_edit_count >= 1:
            if not payload.address_otp_code:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Verification code required to confirm this address change",
                )
            if not await consume_otp(_address_bizkey(business_id), payload.address_otp_code):
                raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired code")
        business.address_edit_count += 1

    for field, value in payload_fields.items():
        setattr(business, field, value)

    if payload.category_ids is not None:
        await db.execute(BusinessCategory.__table__.delete().where(BusinessCategory.business_id == business_id))
        for cat_id in payload.category_ids:
            db.add(BusinessCategory(business_id=business_id, category_id=cat_id))

    await cache_delete_pattern("search:*")

    result = await db.execute(
        select(Business)
        .options(selectinload(Business.categories).selectinload(BusinessCategory.category))
        .where(Business.id == business_id)
    )
    return _to_response(result.scalar_one())


@router.post("/{business_id}/address-verify/request", response_model=MessageResponse)
async def request_address_verify(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT)),
) -> MessageResponse:
    """
    Send an OTP to confirm a 2nd+ address edit (S-073/ADR-014). Owner-only;
    409 if this business has no prior address edit to re-verify.
    """
    business = await db.get(Business, business_id)
    if not business:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")

    merchant = await db.execute(select(Merchant).where(Merchant.user_id == user.id))
    m = merchant.scalar_one_or_none()
    if not m or business.merchant_id != m.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your business")

    if business.address_edit_count < 1:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="No prior address edit to re-verify")

    phone = business.phone or user.phone
    if not phone:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Add a phone number to your business or profile before editing your address again",
        )

    code = await issue_otp(_address_bizkey(business_id))
    await get_sms_provider().send_otp(phone, code)
    return MessageResponse(message="If that number can receive SMS, we sent a confirmation code.")


@router.post("/{business_id}/approve", response_model=BusinessResponse)
async def approve_business(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> BusinessResponse:
    """Admin: approve a pending business. Notifies the merchant in-app and by best-effort email."""
    from app.models import AuditLog

    business = await db.get(Business, business_id)
    if not business:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
    business.status = BusinessStatus.APPROVED
    db.add(AuditLog(admin_id=admin.id, action="approve", entity_type="business", entity_id=str(business_id)))

    merchant_result = await db.execute(select(Merchant).where(Merchant.id == business.merchant_id))
    merchant = merchant_result.scalar_one_or_none()
    if merchant:
        await upsert_notice(
            db,
            user_id=merchant.user_id,
            scenario=SCENARIO_LISTING_APPROVED,
            ntype=NotificationType.APPROVAL,
            title="Listing approved",
            message=f"{business.name} has been approved and is now live",
            extra_data={"business_id": str(business.id)},
        )
        merchant_user = await db.get(User, merchant.user_id)
        if merchant_user:
            await try_send_listing_approved(merchant_user.email, business.name)

    await cache_delete_pattern("search:*")
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
    await cache_delete_pattern("search:*")
    return MessageResponse(message="Business suspended")


@router.post("/{business_id}/start-review", response_model=BusinessResponse)
async def start_review(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> BusinessResponse:
    """Admin: mark a pending business as being actively reviewed (S-079). Visibility-only --
    does not lock the business to this admin; any admin can still act on it."""
    from app.models import AuditLog

    business = await db.get(Business, business_id)
    if not business:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
    if business.status != BusinessStatus.PENDING:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Business is not pending")
    business.status = BusinessStatus.PROCESSING
    db.add(AuditLog(admin_id=admin.id, action="start_review", entity_type="business", entity_id=str(business_id)))
    result = await db.execute(
        select(Business)
        .options(selectinload(Business.categories).selectinload(BusinessCategory.category))
        .where(Business.id == business_id)
    )
    return _to_response(result.scalar_one())


@router.post("/{business_id}/return-to-pending", response_model=BusinessResponse)
async def return_to_pending(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> BusinessResponse:
    """Admin: un-claim a business under review, returning it to the plain pending queue (S-079)."""
    from app.models import AuditLog

    business = await db.get(Business, business_id)
    if not business:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
    if business.status != BusinessStatus.PROCESSING:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Business is not being processed")
    business.status = BusinessStatus.PENDING
    db.add(
        AuditLog(admin_id=admin.id, action="return_to_pending", entity_type="business", entity_id=str(business_id))
    )
    result = await db.execute(
        select(Business)
        .options(selectinload(Business.categories).selectinload(BusinessCategory.category))
        .where(Business.id == business_id)
    )
    return _to_response(result.scalar_one())


@router.get("/{business_id}/external-reviews", response_model=list[ExternalReviewResponse])
async def list_external_reviews(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
) -> list[ExternalReviewResponse]:
    """
    Public: up to 5 synced third-party (Google) reviews for a business (S-048
    AC10, AC11). Two path segments, so this cannot collide with the
    single-segment `GET /{slug}` above regardless of registration order.

    **Response:** `[]` when the business has never linked/synced (AC11) --
    callers should not render an "Also reviewed on Google" section for an
    empty list.
    """
    rows = await review_sync_service.list_external_reviews(db, business_id)
    return [ExternalReviewResponse.model_validate(row) for row in rows]


@router.post(
    "/{business_id}/reports",
    response_model=BusinessReportResponse,
    status_code=status.HTTP_201_CREATED,
)
async def report_business(
    business_id: UUID,
    payload: BusinessReportCreate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> BusinessReportResponse:
    """Signed-in user: report a shop (not a review). Merchants cannot report their own listing (S-089)."""
    try:
        report = await reports_service.create_report(
            db, business_id=business_id, reporter=user, reason=payload.reason
        )
    except reports_service.ReportNotFoundError:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found") from None
    except reports_service.OwnShopReportError:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cannot report your own business") from None
    return BusinessReportResponse(
        id=report.id,
        business_id=report.business_id,
        reporter_id=report.reporter_id,
        reason=report.reason,
        status=report.status,
        created_at=report.created_at,
        updated_at=report.updated_at,
        messages=[],
        is_repeat=False,
    )
