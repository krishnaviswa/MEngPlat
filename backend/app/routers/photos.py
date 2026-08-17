from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.dependencies import get_current_user, require_roles
from app.models import Business, Merchant, Photo, User, UserRole
from app.schemas import PhotoResponse
from app.services.photo_service import save_business_photo
from app.services.storage import get_storage_provider

router = APIRouter(prefix="/photos", tags=["Photos"])


@router.post("/upload", response_model=PhotoResponse, status_code=status.HTTP_201_CREATED)
async def upload_photo(
    file: UploadFile = File(...),
    business_id: UUID | None = Form(default=None),
    review_id: UUID | None = Form(default=None),
    photo_type: str = Form(default="gallery"),
    caption: str | None = Form(default=None),
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> PhotoResponse:
    """
    Upload a photo for a business gallery or review. Triggers AI image analysis.

    **Request:** multipart form — file, business_id OR review_id, photo_type, caption
    **Response:** Photo with AI image insights (suggestions only)
    """
    if not business_id and not review_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="business_id or review_id required")

    if review_id and not business_id:
        # Review attachments stay on the original inline path (WhatsApp ingest
        # only writes business gallery photos).
        from app.services.photo_service import ALLOWED_CONTENT_TYPES, MAX_UPLOAD_BYTES

        if file.content_type not in ALLOWED_CONTENT_TYPES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported file type '{file.content_type}'. Allowed: {', '.join(sorted(ALLOWED_CONTENT_TYPES))}",
            )
        content = await file.read()
        if len(content) > MAX_UPLOAD_BYTES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"File too large. Max size is {MAX_UPLOAD_BYTES // (1024 * 1024)}MB.",
            )
        await file.seek(0)
        storage = get_storage_provider()
        url = await storage.save(file, f"reviews/{review_id}")
        from app.models import AIAnalysis
        from app.services.ai import get_ai_provider

        photo = Photo(
            business_id=None,
            review_id=review_id,
            uploaded_by=user.id,
            url=url,
            caption=caption,
            photo_type=photo_type,
        )
        db.add(photo)
        await db.flush()
        image_result = await get_ai_provider().analyze_image(url, {"photo_type": photo_type})
        db.add(
            AIAnalysis(
                photo_id=photo.id,
                analysis_type="image",
                image_insights=image_result.insights,
                provider=image_result.meta.provider,
                raw_response=image_result.raw_response,
                degraded=image_result.meta.degraded,
            )
        )
        result = await db.execute(select(Photo).options(selectinload(Photo.ai_analysis)).where(Photo.id == photo.id))
        return PhotoResponse.model_validate(result.scalar_one())

    # business_id path: writing to a business gallery (and possibly its logo/storefront
    # image) requires ownership, unlike the review-attachment path above.
    business = await db.get(Business, business_id)
    if not business:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Business not found")
    if user.role == UserRole.MERCHANT:
        m_result = await db.execute(select(Merchant).where(Merchant.user_id == user.id))
        merchant_obj = m_result.scalar_one_or_none()
        if not merchant_obj or business.merchant_id != merchant_obj.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")
    elif user.role != UserRole.ADMIN:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")

    content = await file.read()
    photo = await save_business_photo(
        db,
        business_id=business_id,
        data=content,
        content_type=file.content_type or "application/octet-stream",
        filename=file.filename or "upload.jpg",
        uploaded_by=user.id,
        photo_type=photo_type,
        caption=caption,
    )
    return PhotoResponse.model_validate(photo)


@router.get("/business/{business_id}", response_model=list[PhotoResponse])
async def list_business_photos(business_id: UUID, db: AsyncSession = Depends(get_db)) -> list[PhotoResponse]:
    """List gallery photos for a business."""
    result = await db.execute(
        select(Photo)
        .options(selectinload(Photo.ai_analysis))
        .where(Photo.business_id == business_id, Photo.review_id.is_(None))
        .order_by(Photo.created_at.desc())
    )
    return [PhotoResponse.model_validate(p) for p in result.scalars().all()]


@router.delete("/{photo_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_photo(
    photo_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> None:
    """Delete a photo. Merchants can delete their business photos."""
    photo = await db.get(Photo, photo_id)
    if not photo:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Photo not found")

    if user.role == UserRole.MERCHANT and photo.business_id:
        m_result = await db.execute(select(Merchant).where(Merchant.user_id == user.id))
        merchant_obj = m_result.scalar_one_or_none()
        from app.models import Business

        business = await db.get(Business, photo.business_id)
        if not merchant_obj or not business or business.merchant_id != merchant_obj.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")

    storage = get_storage_provider()
    await storage.delete(photo.url)
    await db.delete(photo)
