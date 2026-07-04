from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user, require_roles
from app.models import AIAnalysis, Business, Merchant, Photo, Review, Sentiment, User, UserRole
from app.schemas import PhotoResponse
from app.services.ai import get_ai_provider
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

    storage = get_storage_provider()
    folder = f"businesses/{business_id}" if business_id else f"reviews/{review_id}"
    url = await storage.save(file, folder)

    photo = Photo(
        business_id=business_id,
        review_id=review_id,
        uploaded_by=user.id,
        url=url,
        caption=caption,
        photo_type=photo_type,
    )
    db.add(photo)
    await db.flush()

    provider = get_ai_provider()
    image_result = await provider.analyze_image(url, {"photo_type": photo_type})
    ai = AIAnalysis(
        photo_id=photo.id,
        analysis_type="image",
        image_insights=image_result.insights,
        provider=getattr(provider, "provider_name", "unknown"),
        raw_response=image_result.raw_response,
    )
    db.add(ai)

    if photo_type == "logo" and business_id:
        business = await db.get(Business, business_id)
        if business:
            business.logo_url = url
    elif photo_type == "storefront" and business_id:
        business = await db.get(Business, business_id)
        if business:
            business.storefront_url = url

    await db.refresh(photo)
    result_photo = await db.get(Photo, photo.id)
    return PhotoResponse.model_validate(result_photo)


@router.get("/business/{business_id}", response_model=list[PhotoResponse])
async def list_business_photos(business_id: UUID, db: AsyncSession = Depends(get_db)) -> list[PhotoResponse]:
    """List gallery photos for a business."""
    from sqlalchemy import select

    result = await db.execute(
        select(Photo).where(Photo.business_id == business_id, Photo.review_id.is_(None)).order_by(Photo.created_at.desc())
    )
    return [PhotoResponse.model_validate(p) for p in result.scalars().all()]


@router.delete("/{photo_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_photo(
    photo_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(require_roles(UserRole.MERCHANT, UserRole.ADMIN)),
) -> None:
    """Delete a photo. Merchants can delete their business photos."""
    from sqlalchemy import select

    photo = await db.get(Photo, photo_id)
    if not photo:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Photo not found")

    if user.role == UserRole.MERCHANT and photo.business_id:
        m_result = await db.execute(select(Merchant).where(Merchant.user_id == user.id))
        merchant_obj = m_result.scalar_one_or_none()
        business = await db.get(Business, photo.business_id)
        if not merchant_obj or not business or business.merchant_id != merchant_obj.id:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized")

    storage = get_storage_provider()
    await storage.delete(photo.url)
    await db.delete(photo)
