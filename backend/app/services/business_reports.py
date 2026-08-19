"""Shop-level reports and message thread (S-089)."""

from __future__ import annotations

from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import Business, BusinessReport, BusinessReportMessage, Merchant, User

REPORT_STATUSES = frozenset({"open", "in_progress", "resolved"})
REPEAT_THRESHOLD = 3


class ReportNotFoundError(Exception):
    pass


class OwnShopReportError(Exception):
    pass


class NotReporterError(Exception):
    pass


class InvalidReportStatusError(Exception):
    pass


async def create_report(db: AsyncSession, *, business_id: UUID, reporter: User, reason: str) -> BusinessReport:
    business = await db.get(Business, business_id)
    if not business:
        raise ReportNotFoundError()
    merchant = await db.get(Merchant, business.merchant_id)
    if merchant and merchant.user_id == reporter.id:
        raise OwnShopReportError()
    report = BusinessReport(
        business_id=business_id,
        reporter_id=reporter.id,
        reason=reason.strip(),
        status="open",
    )
    db.add(report)
    await db.flush()
    return report


async def _load_report(db: AsyncSession, report_id: UUID) -> BusinessReport:
    result = await db.execute(
        select(BusinessReport)
        .options(selectinload(BusinessReport.messages), selectinload(BusinessReport.business))
        .where(BusinessReport.id == report_id)
    )
    report = result.scalar_one_or_none()
    if not report:
        raise ReportNotFoundError()
    return report


async def list_mine(db: AsyncSession, user: User) -> list[BusinessReport]:
    result = await db.execute(
        select(BusinessReport)
        .options(selectinload(BusinessReport.messages), selectinload(BusinessReport.business))
        .where(BusinessReport.reporter_id == user.id)
        .order_by(BusinessReport.created_at.desc())
    )
    return list(result.scalars().all())


async def counts_by_business(db: AsyncSession) -> dict[UUID, int]:
    result = await db.execute(
        select(BusinessReport.business_id, func.count(BusinessReport.id)).group_by(BusinessReport.business_id)
    )
    return {row[0]: int(row[1]) for row in result.all()}


async def list_admin(db: AsyncSession, status_filter: str | None = None) -> list[BusinessReport]:
    stmt = (
        select(BusinessReport)
        .options(selectinload(BusinessReport.messages), selectinload(BusinessReport.business))
        .order_by(BusinessReport.created_at.asc())
    )
    if status_filter:
        if status_filter not in REPORT_STATUSES:
            raise InvalidReportStatusError()
        stmt = stmt.where(BusinessReport.status == status_filter)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def add_message(
    db: AsyncSession,
    report_id: UUID,
    author: User,
    body: str,
    *,
    as_admin: bool,
) -> BusinessReportMessage:
    report = await db.get(BusinessReport, report_id)
    if not report:
        raise ReportNotFoundError()
    if not as_admin and report.reporter_id != author.id:
        raise NotReporterError()
    msg = BusinessReportMessage(report_id=report_id, author_id=author.id, body=body.strip())
    db.add(msg)
    await db.flush()
    return msg


async def update_status(db: AsyncSession, report_id: UUID, status: str) -> BusinessReport:
    if status not in REPORT_STATUSES:
        raise InvalidReportStatusError()
    report = await db.get(BusinessReport, report_id)
    if not report:
        raise ReportNotFoundError()
    report.status = status
    await db.flush()
    return report
