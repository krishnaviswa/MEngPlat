import csv
import io
from datetime import timezone
from dataclasses import asdict
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import require_roles
from app.models import Business, BusinessStatus, Merchant, Review, ReviewStatus, User, UserRole
from app.schemas import (
    BenchmarkResponse,
    DashboardStats,
    GooglePlaceLinkRequest,
    GooglePlaceLinkResponse,
    GooglePlacesSearchRequest,
    GooglePlacesSearchResponse,
    GoogleReviewsStatusResponse,
    GoogleReviewsSyncResponse,
    PlatformAnalytics,
    PlatformAnalyticsSeries,
    ReviewResponse,
    UserResponse,
    WhatsAppDraftApplyRequest,
    WhatsAppDraftResponse,
    WhatsAppLinkResponse,
)
from app.routers.reviews import _review_response
from app.services import benchmark as benchmark_service
from app.services import merchant_dashboard as merchant_dashboard_service
from app.services import platform_analytics as platform_analytics_service
from app.services import review_sync_service
from app.services import whatsapp_ingest_service
from app.services.merchant_dashboard import DateRange
from app.services.platform_analytics import Granularity

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

RANGE_QUERY = Query("all", alias="range", pattern="^(30|90|all)$")
GRANULARITY_QUERY = Query("day", alias="granularity", pattern="^(day|week)$")


async def _load_owned_business(db: AsyncSession, business_id: UUID, user: User) -> Business:
    business = await db.get(Business, business_id)
    if not business:
        raise HTTPException(status_code=404, detail="Business not found")

    if user.role == UserRole.MERCHANT:
        m = await db.execute(select(Merchant).where(Merchant.user_id == user.id))
        merchant = m.scalar_one_or_none()
        if not merchant or business.merchant_id != merchant.id:
            raise HTTPException(status_code=403, detail="Not your business")

    return business


@router.get("/merchant/{business_id}", response_model=DashboardStats)
async def merchant_dashboard(
    business_id: UUID,
    date_range: DateRange = RANGE_QUERY,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> DashboardStats:
    """
    Merchant analytics dashboard data.

    **Query:** `range=30|90|all` (default `all`) filters `review_volume_by_month`,
    `rating_distribution`, and `reply_rate` by `Review.created_at` (UTC).
    `total_reviews`, `average_rating`, `sentiment_breakdown`, `recent_reviews` stay all-time.

    **Response:** total reviews, average rating, sentiment breakdown, recent reviews,
    monthly volume, 1-5 rating distribution, reply rate.
    """
    business = await _load_owned_business(db, business_id, user)

    sentiment_breakdown = await merchant_dashboard_service.get_sentiment_breakdown(db, business_id)
    recent = await merchant_dashboard_service.get_recent_reviews(db, business_id)
    aggregates = await merchant_dashboard_service.get_dashboard_aggregates(db, business_id, date_range)

    return DashboardStats(
        total_reviews=business.review_count,
        average_rating=business.average_rating,
        sentiment_breakdown=sentiment_breakdown,
        recent_reviews=[_review_response(r) for r in recent],
        **aggregates,
    )


@router.get("/merchant/{business_id}/benchmark", response_model=BenchmarkResponse)
async def merchant_benchmark(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> BenchmarkResponse:
    """Category and city rating medians from approved listings. Not an AI judgment."""
    business = await _load_owned_business(db, business_id, user)
    data = await benchmark_service.get_benchmark(db, business)
    return BenchmarkResponse(**data)


@router.get("/merchant/{business_id}/reviews.csv")
async def merchant_dashboard_reviews_csv(
    business_id: UUID,
    date_range: DateRange = RANGE_QUERY,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> StreamingResponse:
    """
    Export this business's reviews (own business only) as CSV.

    **Query:** `range=30|90|all` (default `all`), same window as the dashboard.
    **Response:** `text/csv` attachment, one row per in-range review, `created_at` desc.
    """
    business = await _load_owned_business(db, business_id, user)
    reviews = await merchant_dashboard_service.get_reviews_for_export(db, business.id, date_range)

    def generate():
        buffer = io.StringIO()
        writer = csv.writer(buffer)
        writer.writerow(
            ["id", "created_at", "rating", "title", "body", "status", "author_name", "has_reply", "reply_body"]
        )
        yield buffer.getvalue()
        for review in reviews:
            buffer.seek(0)
            buffer.truncate(0)
            writer.writerow(
                [
                    str(review.id),
                    review.created_at.astimezone(timezone.utc).isoformat(),
                    review.rating,
                    review.title or "",
                    review.body,
                    review.status.value,
                    review.author.full_name if review.author else "",
                    "true" if review.reply else "false",
                    review.reply.body if review.reply else "",
                ]
            )
            yield buffer.getvalue()

    return StreamingResponse(
        generate(),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": f'attachment; filename="reviews-{business_id}-{date_range}.csv"'},
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


@router.get("/admin/platform/series", response_model=PlatformAnalyticsSeries)
async def platform_analytics_series(
    granularity: Granularity = GRANULARITY_QUERY,
    days: int = Query(90, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> PlatformAnalyticsSeries:
    """
    Admin time-series: new users, businesses moved pending -> approved (via
    AuditLog `approve`/`business` rows, not `Business.updated_at`), new
    reviews, new reports. Each bucket is a stored-timestamp count, zero-filled
    across the full window -- operational facts, not AI output.

    **Query:** `granularity=day|week` (default `day`), `days` 1-365 (default `90`).
    """
    series = await platform_analytics_service.get_platform_series(db, granularity, days)
    return PlatformAnalyticsSeries(granularity=granularity, days=days, series=series)


# --- S-048 review aggregator (Google Places) ---------------------------------


@router.post("/merchant/{business_id}/google-reviews/search", response_model=GooglePlacesSearchResponse)
async def search_google_places(
    business_id: UUID,
    payload: GooglePlacesSearchRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> GooglePlacesSearchResponse:
    """
    Search Google Places for candidates to link (AC1-5). Lat/lng bias comes
    from the loaded `Business`, not the client.

    **Response:** `candidates` (empty list is a valid 200 -- AC4);
    `502` on provider timeout/error, existing linked state untouched (AC5).
    """
    business = await _load_owned_business(db, business_id, user)
    try:
        candidates = await review_sync_service.search_google_places(business, payload.query)
    except review_sync_service.GoogleReviewsProviderError:
        raise HTTPException(status_code=502, detail="Couldn't reach Google Places right now") from None
    return GooglePlacesSearchResponse(candidates=[asdict(c) for c in candidates])


@router.get("/merchant/{business_id}/google-reviews", response_model=GoogleReviewsStatusResponse)
async def get_google_reviews_status(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> GoogleReviewsStatusResponse:
    """Link/sync status powering the dashboard card's unlinked/linked/synced states (AC3, AC6, AC7)."""
    business = await _load_owned_business(db, business_id, user)
    status = await review_sync_service.get_google_reviews_status(db, business)
    return GoogleReviewsStatusResponse(**status.__dict__)


@router.post("/merchant/{business_id}/google-reviews/link", response_model=GooglePlaceLinkResponse)
async def link_google_place(
    business_id: UUID,
    payload: GooglePlaceLinkRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> GooglePlaceLinkResponse:
    """
    Link a Google Place ID to this business (AC3). `name`/`address` in the
    payload are UI-confirmation echoes only, not persisted.

    **Response:** `409` if already linked (v1 supports linking once).
    """
    business = await _load_owned_business(db, business_id, user)
    try:
        await review_sync_service.link_google_place(db, business, payload.place_id)
    except review_sync_service.GooglePlaceAlreadyLinkedError:
        raise HTTPException(
            status_code=409, detail="Business is already linked to a Google Business Profile"
        ) from None
    await db.commit()
    return GooglePlaceLinkResponse(linked=True, place_id=payload.place_id)


@router.post("/merchant/{business_id}/google-reviews/sync", response_model=GoogleReviewsSyncResponse)
async def sync_google_reviews(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> GoogleReviewsSyncResponse:
    """
    Fetch up to 5 reviews from Google and upsert them (AC7, AC8). Debounced
    via a Redis lock (AC9) -- a concurrent/duplicate click returns the
    current state with `debounced: true` instead of erroring or duplicating.

    **Response:** `400` if unlinked; `502` on provider failure, existing
    `ExternalReview` rows left untouched.
    """
    business = await _load_owned_business(db, business_id, user)
    try:
        result = await review_sync_service.sync_google_reviews(db, business)
    except review_sync_service.GooglePlaceNotLinkedError:
        raise HTTPException(status_code=400, detail="Link a Google Business Profile first") from None
    except review_sync_service.GoogleReviewsProviderError:
        raise HTTPException(status_code=502, detail="Couldn't reach Google Places right now") from None
    await db.commit()
    return GoogleReviewsSyncResponse(**result.__dict__)


@router.post("/merchant/{business_id}/whatsapp/link", response_model=WhatsAppLinkResponse)
async def create_whatsapp_link(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> WhatsAppLinkResponse:
    """Generate a short-lived wa.me link that binds inbound WhatsApp to this listing (S-050)."""
    business = await _load_owned_business(db, business_id, user)
    payload = await whatsapp_ingest_service.create_link(db, business)
    return WhatsAppLinkResponse(**payload)


@router.get("/merchant/{business_id}/whatsapp/drafts", response_model=list[WhatsAppDraftResponse])
async def list_whatsapp_drafts(
    business_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> list[WhatsAppDraftResponse]:
    """Pending AI-extracted profile suggestions from WhatsApp (S-052)."""
    await _load_owned_business(db, business_id, user)
    drafts = await whatsapp_ingest_service.list_pending_drafts(db, business_id)
    return [WhatsAppDraftResponse.model_validate(d) for d in drafts]


@router.post("/merchant/{business_id}/whatsapp/drafts/{draft_id}/apply", response_model=WhatsAppDraftResponse)
async def apply_whatsapp_draft(
    business_id: UUID,
    draft_id: UUID,
    payload: WhatsAppDraftApplyRequest | None = None,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> WhatsAppDraftResponse:
    """Write confirmed suggestion fields onto the live Business row."""
    business = await _load_owned_business(db, business_id, user)
    fields = payload.fields if payload else None
    draft = await whatsapp_ingest_service.apply_draft(db, business, draft_id, fields)
    return WhatsAppDraftResponse.model_validate(draft)


@router.post("/merchant/{business_id}/whatsapp/drafts/{draft_id}/discard", response_model=WhatsAppDraftResponse)
async def discard_whatsapp_draft(
    business_id: UUID,
    draft_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> WhatsAppDraftResponse:
    """Drop a pending WhatsApp suggestion without changing the live listing."""
    business = await _load_owned_business(db, business_id, user)
    draft = await whatsapp_ingest_service.discard_draft(db, business, draft_id)
    return WhatsAppDraftResponse.model_validate(draft)
