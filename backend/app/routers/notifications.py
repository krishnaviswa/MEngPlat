from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.models import Notification, User
from app.schemas import MessageResponse, NotificationResponse

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("", response_model=list[NotificationResponse])
async def list_notifications(
    unread_only: bool = False,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[NotificationResponse]:
    """
    List notifications for the current user.

    **Query:** unread_only (default false)
    **Response:** Array of notifications ordered by created_at desc
    """
    query = select(Notification).where(Notification.user_id == user.id).order_by(Notification.created_at.desc())
    if unread_only:
        query = query.where(Notification.is_read.is_(False))
    result = await db.execute(query.limit(50))
    return [NotificationResponse.model_validate(n) for n in result.scalars().all()]


@router.post("/{notification_id}/read", response_model=MessageResponse)
async def mark_read(
    notification_id: UUID,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> MessageResponse:
    """Mark a single notification as read."""
    notification = await db.get(Notification, notification_id)
    if notification and notification.user_id == user.id:
        notification.is_read = True
    return MessageResponse(message="Notification marked as read")


@router.post("/read-all", response_model=MessageResponse)
async def mark_all_read(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> MessageResponse:
    """Mark all notifications as read for current user."""
    await db.execute(
        update(Notification).where(Notification.user_id == user.id).values(is_read=True)
    )
    return MessageResponse(message="All notifications marked as read")
