from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.dependencies import get_current_user, require_roles
from app.models import (
    AIAnalysis,
    Business,
    BusinessStatus,
    Merchant,
    Notification,
    NotificationType,
    Photo,
    Reply,
    Review,
    ReviewLike,
    ReviewReport,
    ReviewStatus,
    Sentiment,
    User,
    UserRole,
)
from app.schemas import (
    MessageResponse,
    ReplyCreate,
    ReplyResponse,
    ReviewCreate,
    ReviewReportCreate,
    ReviewResponse,
    ReviewUpdate,
    UserResponse,
)
from app.services.ai import get_ai_provider
from app.services.business_service import refresh_merchant_ai_summary, update_business_rating
from app.services.cache import cache_delete_pattern

router = APIRouter(prefix="/reviews", tags=["Reviews"])


def _review_response(review: Review) -> ReviewResponse:
    return ReviewResponse(
        id=review.id,
        business_id=review.business_id,
        author_id=review.author_id,
        rating=review.rating,
        title=review.title,
        body=review.body,
        status=review.status,
        like_count=review.like_count,
        created_at=review.created_at,
        author=UserResponse.model_validate(review.author) if review.author else None,
        ai_analysis=review.ai_analysis,
        reply=ReplyResponse.model_validate(review.reply) if review.reply else None,
        photo_urls=[p.url for p in review.photos],
    )


@router.get("/business/{business_id}", response_model=list[ReviewResponse])
async def list_business_reviews(business_id: UUID, db: AsyncSession = Depends(get_db)) -> list[ReviewResponse]:
    """
    List active reviews for a business.

    **Path:** business_id
    **Response:** Reviews with AI analysis, replies, and photo URLs
    """
    result = await db.execute(
        select(Review)
        .options(
            selectinload(Review.author),
            selectinload(Review.ai_analysis),
            selectinload(Review.reply),
            selectinload(Review.photos),
        )
        .where(Review.business_id == business_id, Review.status == ReviewStatus.ACTIVE)
        .order_by(Review.created_at.desc())
    )
    return [_review_response(r) for r in result.scalars().all()]


@router.post("", response_model=ReviewResponse, status_code=status.HTTP_201_CREATED)
async def create_review(
    payload: ReviewCreate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.CUSTOMER, UserRole.MERCHANT, UserRole.ADMIN)),
) -> ReviewResponse:
    """
    Submit a review — triggers automatic AI text analysis.

    **Request:** business_id, rating (1-5), title, body (min 10 chars)
    **Response:** Review with AI analysis attached
    """
    business = await db.get(Business, payload.business_id)
    if not business or business.status != BusinessStatus.APPROVED:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found or not approved")

    review = Review(
        business_id=payload.business_id,
        author_id=user.id,
        rating=payload.rating,
        title=payload.title,
        body=payload.body,
    )
    db.add(review)
    await db.flush()

    provider = get_ai_provider()
    analysis_result = await provider.analyze_review_text(payload.body, {"business_id": str(payload.business_id)})

    ai = AIAnalysis(
        review_id=review.id,
        analysis_type="text",
        sentiment=Sentiment(analysis_result.sentiment),
        summary=analysis_result.summary,
        positives=analysis_result.positives,
        complaints=analysis_result.complaints,
        suggested_response=analysis_result.suggested_response,
        provider=provider.provider_name if hasattr(provider, "provider_name") else "unknown",
        raw_response=analysis_result.raw_response,
    )
    db.add(ai)

    merchant_result = await db.execute(select(Merchant).where(Merchant.id == business.merchant_id))
    merchant = merchant_result.scalar_one_or_none()
    if merchant:
        db.add(
            Notification(
                user_id=merchant.user_id,
                type=NotificationType.REVIEW,
                title="New review received",
                message=f"New {payload.rating}-star review on {business.name}",
                extra_data={"review_id": str(review.id), "business_id": str(business.id)},
            )
        )

    await update_business_rating(db, business.id)
    await refresh_merchant_ai_summary(db, business.id)
    await cache_delete_pattern("search:*")

    await db.refresh(review)
    result = await db.execute(
        select(Review)
        .options(
            selectinload(Review.author),
            selectinload(Review.ai_analysis),
            selectinload(Review.photos),
        )
        .where(Review.id == review.id)
    )
    return _review_response(result.scalar_one())


@router.patch("/{review_id}", response_model=ReviewResponse)
async def update_review(
    review_id: UUID,
    payload: ReviewUpdate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> ReviewResponse:
    """Edit own review. Re-runs AI analysis if body changes."""
    review = await db.get(Review, review_id)
    if not review or review.author_id != user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Review not found")

    body_changed = payload.body is not None and payload.body != review.body
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(review, field, value)

    if body_changed:
        provider = get_ai_provider()
        result = await provider.analyze_review_text(review.body)
        if review.ai_analysis:
            review.ai_analysis.sentiment = Sentiment(result.sentiment)
            review.ai_analysis.summary = result.summary
            review.ai_analysis.positives = result.positives
            review.ai_analysis.complaints = result.complaints
            review.ai_analysis.suggested_response = result.suggested_response

    await update_business_rating(db, review.business_id)
    result = await db.execute(
        select(Review)
        .options(selectinload(Review.author), selectinload(Review.ai_analysis), selectinload(Review.photos))
        .where(Review.id == review_id)
    )
    return _review_response(result.scalar_one())


@router.delete("/{review_id}", response_model=MessageResponse)
async def delete_review(
    review_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> MessageResponse:
    """Delete own review."""
    review = await db.get(Review, review_id)
    if not review or review.author_id != user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Review not found")
    business_id = review.business_id
    await db.delete(review)
    await update_business_rating(db, business_id)
    return MessageResponse(message="Review deleted")


@router.post("/{review_id}/like", response_model=MessageResponse)
async def like_review(
    review_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> MessageResponse:
    """Like a review (idempotent)."""
    review = await db.get(Review, review_id)
    if not review:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Review not found")

    existing = await db.execute(
        select(ReviewLike).where(ReviewLike.review_id == review_id, ReviewLike.user_id == user.id)
    )
    if not existing.scalar_one_or_none():
        db.add(ReviewLike(review_id=review_id, user_id=user.id))
        review.like_count += 1
    return MessageResponse(message="Review liked")


@router.post("/{review_id}/report", response_model=MessageResponse)
async def report_review(
    review_id: UUID,
    payload: ReviewReportCreate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> MessageResponse:
    """Report inappropriate review."""
    review = await db.get(Review, review_id)
    if not review:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Review not found")

    db.add(ReviewReport(review_id=review_id, reporter_id=user.id, reason=payload.reason))
    review.status = ReviewStatus.REPORTED
    return MessageResponse(message="Review reported for moderation")


@router.post("/{review_id}/reply", response_model=ReplyResponse, status_code=status.HTTP_201_CREATED)
async def reply_to_review(
    review_id: UUID,
    payload: ReplyCreate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT)),
) -> ReplyResponse:
    """Merchant responds to a review."""
    review = await db.get(Review, review_id)
    if not review:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Review not found")

    merchant_result = await db.execute(select(Merchant).where(Merchant.user_id == user.id))
    merchant = merchant_result.scalar_one_or_none()
    if not merchant:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Merchant profile required")

    business = await db.get(Business, review.business_id)
    if not business or business.merchant_id != merchant.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your business review")

    if review.reply:
        review.reply.body = payload.body
        await db.refresh(review.reply)
        return ReplyResponse.model_validate(review.reply)

    reply = Reply(review_id=review_id, merchant_id=merchant.id, body=payload.body)
    db.add(reply)
    await db.refresh(reply)
    return ReplyResponse.model_validate(reply)


@router.post("/{review_id}/moderate", response_model=MessageResponse)
async def moderate_review(
    review_id: UUID,
    action: str,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> MessageResponse:
    """Admin: hide or restore a review. action=hide|restore|remove"""
    from app.models import AuditLog

    review = await db.get(Review, review_id)
    if not review:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Review not found")

    if action == "hide":
        review.status = ReviewStatus.HIDDEN
    elif action == "restore":
        review.status = ReviewStatus.ACTIVE
    elif action == "remove":
        review.status = ReviewStatus.REMOVED
    else:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid action")

    db.add(AuditLog(admin_id=admin.id, action=action, entity_type="review", entity_id=str(review_id)))
    return MessageResponse(message=f"Review {action}d")
