"""Shared photo persist path used by web upload and WhatsApp ingest (S-051)."""

from __future__ import annotations

from io import BytesIO
from uuid import UUID

from fastapi import HTTPException, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from starlette.datastructures import Headers

from app.models import AIAnalysis, Business, Photo
from app.services.ai import get_ai_provider
from app.services.storage import get_storage_provider

ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif"}
MAX_UPLOAD_BYTES = 5 * 1024 * 1024


def upload_from_bytes(data: bytes, filename: str, content_type: str) -> UploadFile:
    return UploadFile(
        file=BytesIO(data),
        filename=filename,
        headers=Headers({"content-type": content_type}),
    )


async def save_business_photo(
    db: AsyncSession,
    *,
    business_id: UUID,
    data: bytes,
    content_type: str,
    filename: str,
    uploaded_by: UUID,
    photo_type: str = "general",
    caption: str | None = None,
) -> Photo:
    if content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported file type '{content_type}'. Allowed: {', '.join(sorted(ALLOWED_CONTENT_TYPES))}",
        )
    if len(data) > MAX_UPLOAD_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File too large. Max size is {MAX_UPLOAD_BYTES // (1024 * 1024)}MB.",
        )

    upload = upload_from_bytes(data, filename, content_type)
    storage = get_storage_provider()
    url = await storage.save(upload, f"businesses/{business_id}")

    photo = Photo(
        business_id=business_id,
        review_id=None,
        uploaded_by=uploaded_by,
        url=url,
        caption=caption,
        photo_type=photo_type,
    )
    db.add(photo)
    await db.flush()

    provider = get_ai_provider()
    image_result = await provider.analyze_image(url, {"photo_type": photo_type})
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

    if photo_type == "logo":
        business = await db.get(Business, business_id)
        if business:
            business.logo_url = url
    elif photo_type == "storefront":
        business = await db.get(Business, business_id)
        if business:
            business.storefront_url = url

    result = await db.execute(select(Photo).options(selectinload(Photo.ai_analysis)).where(Photo.id == photo.id))
    return result.scalar_one()
