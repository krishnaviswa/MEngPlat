"""Profile avatar upload (S-085). Deliberately separate from photo_service.py's
business/review photo path: an avatar is personal profile data, not business
content, so this module never touches the Photo/AIAnalysis models and never
calls get_ai_provider() (AC10)."""

from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import User
from app.services.photo_service import ALLOWED_CONTENT_TYPES, MAX_UPLOAD_BYTES, upload_from_bytes
from app.services.storage import get_storage_provider


async def update_user_avatar(
    db: AsyncSession,
    *,
    user: User,
    data: bytes,
    content_type: str,
    filename: str,
) -> User:
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
    new_url = await storage.save(upload, f"avatars/{user.id}")

    old_url = user.avatar_url
    user.avatar_url = new_url
    await db.flush()
    await db.refresh(user)

    if old_url and old_url != new_url:
        # Best-effort cleanup. Deliberately unconditional (not gated on "does
        # this look like a URL our storage provider owns") -- both
        # LocalStorageProvider.delete() and S3StorageProvider.delete() are
        # safe no-ops on a URL/key they don't recognize (e.g. an external
        # Google picture URL, or a pre-existing manually-pasted URL), so this
        # never risks raising for those cases. The try/except is still kept
        # as defense in depth so a cleanup failure can never block the
        # avatar update itself.
        try:
            await storage.delete(old_url)
        except Exception:
            pass

    return user
