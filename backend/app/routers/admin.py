from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import require_roles
from app.models import User, UserRole
from app.schemas import (
    AdminWhatsAppDraftApproveRequest,
    AdminWhatsAppDraftQueueResponse,
    AdminWhatsAppDraftResponse,
    UserResponse,
    WhatsAppDraftResponse,
)
from app.services import admin_users as admin_users_service
from app.services import whatsapp_ingest_service
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


@router.get("/whatsapp/drafts", response_model=AdminWhatsAppDraftQueueResponse)
async def list_admin_whatsapp_drafts(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> AdminWhatsAppDraftQueueResponse:
    """
    Admin: global, cross-business queue of pending WhatsApp-derived profile
    drafts, oldest first (S-053). This is the sole surface a WhatsApp draft can
    be approved or rejected from -- merchants can view but no longer act.
    """
    rows, total = await whatsapp_ingest_service.list_pending_drafts_admin(db, page, page_size)
    items = [
        AdminWhatsAppDraftResponse(
            id=draft.id,
            source=draft.source,
            extracted_fields=draft.extracted_fields,
            status=draft.status,
            degraded=draft.degraded,
            created_at=draft.created_at,
            business_id=draft.business_id,
            business_name=business_name,
        )
        for draft, business_name in rows
    ]
    return AdminWhatsAppDraftQueueResponse(items=items, total=total, page=page, page_size=page_size)


@router.post("/whatsapp/drafts/{draft_id}/approve", response_model=WhatsAppDraftResponse)
async def approve_admin_whatsapp_draft(
    draft_id: UUID,
    payload: AdminWhatsAppDraftApproveRequest | None = None,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> WhatsAppDraftResponse:
    """
    Admin: approve a WhatsApp draft, writing the (optionally edited) fields to
    the live Business row. Omitted/absent fields fall back to the raw AI
    extraction. `404` unknown draft; `409` already resolved (S-053).
    """
    fields = payload.fields if payload else None
    draft = await whatsapp_ingest_service.admin_approve_draft(db, draft_id, admin.id, fields)
    return WhatsAppDraftResponse.model_validate(draft)


@router.post("/whatsapp/drafts/{draft_id}/reject", response_model=WhatsAppDraftResponse)
async def reject_admin_whatsapp_draft(
    draft_id: UUID,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> WhatsAppDraftResponse:
    """Admin: reject a WhatsApp draft. The live Business row is left untouched (S-053)."""
    draft = await whatsapp_ingest_service.admin_reject_draft(db, draft_id, admin.id)
    return WhatsAppDraftResponse.model_validate(draft)
