import csv
import io
from datetime import timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import require_roles
from app.models import Business, BusinessStatus, Merchant, Review, ReviewStatus, User, UserRole
from app.schemas import DashboardStats, PlatformAnalytics, PlatformAnalyticsSeries, ReviewResponse, UserResponse
from app.routers.reviews import _review_response
from app.services import merchant_dashboard as merchant_dashboard_service
from app.services import platform_analytics as platform_analytics_service
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
