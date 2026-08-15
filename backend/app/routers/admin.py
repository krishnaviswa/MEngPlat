from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import require_roles
from app.models import User, UserRole
from app.schemas import UserResponse
from app.services import admin_users as admin_users_service
from app.services.admin_users import SelfOrAdminTargetError

router = APIRouter(prefix="/admin", tags=["Admin"])


@router.get("/users", response_model=list[UserResponse])
async def list_users(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    q: str | None = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> list[User]:
    """
    Admin: list all users, newest `created_at` first.

    **Query:** page (default 1), page_size (default 20, cap 100), optional `q`
    substring match on email or full_name (case-insensitive).
    **Response:** never includes `totp_secret`, `hashed_password`, or `google_sub`.
    """
    return await admin_users_service.list_users(db, page, page_size, q)


@router.post("/users/{user_id}/suspend", response_model=UserResponse)
async def suspend_user(
    user_id: UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> User:
    """
    Admin: suspend a non-admin user (`is_active=false`) and record an AuditLog
    row. Idempotent if already inactive. Refused (400) for the caller's own
    account or another admin.
    """
    try:
        target = await admin_users_service.suspend_user(db, user_id, admin)
    except SelfOrAdminTargetError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot suspend self or another admin"
        ) from exc
    if not target:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return target


@router.post("/users/{user_id}/reactivate", response_model=UserResponse)
async def reactivate_user(
    user_id: UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> User:
    """
    Admin: reactivate a non-admin user (`is_active=true`) and record an
    AuditLog row. Idempotent if already active. Refused (400) for the
    caller's own account or another admin.
    """
    try:
        target = await admin_users_service.reactivate_user(db, user_id, admin)
    except SelfOrAdminTargetError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot reactivate self or another admin"
        ) from exc
    if not target:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return target
