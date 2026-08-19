"""Public support contact + customer tickets + shop-report mine/messages (S-087–S-089)."""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.database import get_db
from app.dependencies import get_current_user, get_optional_user
from app.models import User
from app.schemas import (
    BusinessReportMessageCreate,
    BusinessReportMessageResponse,
    BusinessReportResponse,
    SupportContactResponse,
    SupportTicketCreate,
    SupportTicketResponse,
)
from app.services import business_reports as reports_service
from app.services import support_tickets as tickets_service

router = APIRouter(tags=["Support"])


def _ticket_response(ticket) -> SupportTicketResponse:
    return SupportTicketResponse.model_validate(ticket)


def _report_response(report, *, counts: dict | None = None) -> BusinessReportResponse:
    count = (counts or {}).get(report.business_id)
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
        is_repeat=bool(count is not None and count >= reports_service.REPEAT_THRESHOLD),
    )


@router.get("/support/contact", response_model=SupportContactResponse)
async def support_contact() -> SupportContactResponse:
    """Public support email for footer / contact page (S-087)."""
    return SupportContactResponse(email=get_settings().support_email, support_path="/support")


@router.post("/support-tickets", response_model=SupportTicketResponse, status_code=status.HTTP_201_CREATED)
async def create_support_ticket(
    payload: SupportTicketCreate,
    db: AsyncSession = Depends(get_db),
    user: User | None = Depends(get_optional_user),
) -> SupportTicketResponse:
    """Create a support ticket. Auth optional; logged-in users can later list via /mine."""
    try:
        ticket = await tickets_service.create_ticket(
            db,
            name=payload.name,
            phone=payload.phone,
            issue=payload.issue,
            business_id=payload.business_id,
            reporter=user,
        )
    except tickets_service.InvalidBusinessRefError:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Unknown business") from None
    return _ticket_response(ticket)


@router.get("/support-tickets/mine", response_model=list[SupportTicketResponse])
async def list_my_support_tickets(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[SupportTicketResponse]:
    tickets = await tickets_service.list_mine(db, user)
    return [_ticket_response(t) for t in tickets]


@router.get("/business-reports/mine", response_model=list[BusinessReportResponse])
async def list_my_business_reports(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[BusinessReportResponse]:
    reports = await reports_service.list_mine(db, user)
    counts = await reports_service.counts_by_business(db)
    return [_report_response(r, counts=counts) for r in reports]


@router.post(
    "/business-reports/{report_id}/messages",
    response_model=BusinessReportMessageResponse,
    status_code=status.HTTP_201_CREATED,
)
async def add_report_message(
    report_id: UUID,
    payload: BusinessReportMessageCreate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user),
) -> BusinessReportMessageResponse:
    try:
        msg = await reports_service.add_message(db, report_id, user, payload.body, as_admin=False)
    except reports_service.ReportNotFoundError:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found") from None
    except reports_service.NotReporterError:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not your report") from None
    return BusinessReportMessageResponse.model_validate(msg)
