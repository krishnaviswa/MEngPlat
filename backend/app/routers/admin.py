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
    BusinessReportAdminUpdate,
    BusinessReportMessageCreate,
    BusinessReportMessageResponse,
    BusinessReportResponse,
    SupportTicketAdminUpdate,
    SupportTicketResponse,
    UserResponse,
    WhatsAppDraftResponse,
)
from app.services import admin_users as admin_users_service
from app.services import business_reports as reports_service
from app.services import support_tickets as tickets_service
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


def _admin_report_response(report, counts: dict) -> BusinessReportResponse:
    count = counts.get(report.business_id, 0)
    name = report.business.name if getattr(report, "business", None) else None
    return BusinessReportResponse(
        id=report.id,
        business_id=report.business_id,
        reporter_id=report.reporter_id,
        reason=report.reason,
        status=report.status,
        created_at=report.created_at,
        updated_at=report.updated_at,
        business_name=name,
        messages=[BusinessReportMessageResponse.model_validate(m) for m in (report.messages or [])],
        report_count=count,
        is_repeat=count >= reports_service.REPEAT_THRESHOLD,
    )


@router.get("/support-tickets", response_model=list[SupportTicketResponse])
async def admin_list_support_tickets(
    status_filter: str | None = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> list[SupportTicketResponse]:
    """Admin: all support tickets, oldest first (S-088)."""
    try:
        tickets = await tickets_service.list_admin(db, status_filter)
    except tickets_service.InvalidTicketStatusError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid status") from None
    return [SupportTicketResponse.model_validate(t) for t in tickets]


@router.patch("/support-tickets/{ticket_id}", response_model=SupportTicketResponse)
async def admin_update_support_ticket(
    ticket_id: UUID,
    payload: SupportTicketAdminUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> SupportTicketResponse:
    """Admin: set ticket status and/or response (S-088)."""
    try:
        ticket = await tickets_service.update_admin(
            db, ticket_id, status=payload.status, admin_response=payload.admin_response
        )
    except tickets_service.TicketNotFoundError:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ticket not found") from None
    except tickets_service.InvalidTicketStatusError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid status") from None
    return SupportTicketResponse.model_validate(ticket)


@router.get("/business-reports", response_model=list[BusinessReportResponse])
async def admin_list_business_reports(
    status_filter: str | None = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> list[BusinessReportResponse]:
    """Admin: shop-level reports with per-shop counts and repeat flag (S-089)."""
    try:
        reports = await reports_service.list_admin(db, status_filter)
    except reports_service.InvalidReportStatusError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid status") from None
    counts = await reports_service.counts_by_business(db)
    return [_admin_report_response(r, counts) for r in reports]


@router.patch("/business-reports/{report_id}", response_model=BusinessReportResponse)
async def admin_update_business_report(
    report_id: UUID,
    payload: BusinessReportAdminUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> BusinessReportResponse:
    try:
        await reports_service.update_status(db, report_id, payload.status)
        reports = await reports_service.list_admin(db, None)
    except reports_service.ReportNotFoundError:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found") from None
    except reports_service.InvalidReportStatusError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid status") from None
    counts = await reports_service.counts_by_business(db)
    report = next((r for r in reports if r.id == report_id), None)
    if not report:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found")
    return _admin_report_response(report, counts)


@router.post(
    "/business-reports/{report_id}/messages",
    response_model=BusinessReportMessageResponse,
    status_code=status.HTTP_201_CREATED,
)
async def admin_add_business_report_message(
    report_id: UUID,
    payload: BusinessReportMessageCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_roles(UserRole.ADMIN)),
) -> BusinessReportMessageResponse:
    try:
        msg = await reports_service.add_message(db, report_id, admin, payload.body, as_admin=True)
    except reports_service.ReportNotFoundError:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found") from None
    return BusinessReportMessageResponse.model_validate(msg)
