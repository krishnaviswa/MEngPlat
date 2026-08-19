"""Support ticket create/list/respond (S-088)."""

from __future__ import annotations

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Business, SupportTicket, User

TICKET_STATUSES = frozenset({"open", "in_progress", "resolved"})


class TicketNotFoundError(Exception):
    pass


class InvalidTicketStatusError(Exception):
    pass


class InvalidBusinessRefError(Exception):
    pass


async def create_ticket(
    db: AsyncSession,
    *,
    name: str,
    phone: str,
    issue: str,
    business_id: UUID | None,
    reporter: User | None,
) -> SupportTicket:
    if business_id is not None:
        business = await db.get(Business, business_id)
        if not business:
            raise InvalidBusinessRefError()
    ticket = SupportTicket(
        name=name.strip(),
        phone=phone.strip(),
        issue=issue.strip(),
        business_id=business_id,
        reporter_id=reporter.id if reporter else None,
        status="open",
    )
    db.add(ticket)
    await db.flush()
    return ticket


async def list_mine(db: AsyncSession, user: User) -> list[SupportTicket]:
    result = await db.execute(
        select(SupportTicket).where(SupportTicket.reporter_id == user.id).order_by(SupportTicket.created_at.desc())
    )
    return list(result.scalars().all())


async def list_admin(db: AsyncSession, status_filter: str | None = None) -> list[SupportTicket]:
    stmt = select(SupportTicket).order_by(SupportTicket.created_at.asc())
    if status_filter:
        if status_filter not in TICKET_STATUSES:
            raise InvalidTicketStatusError()
        stmt = stmt.where(SupportTicket.status == status_filter)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def update_admin(
    db: AsyncSession,
    ticket_id: UUID,
    *,
    status: str | None,
    admin_response: str | None,
) -> SupportTicket:
    ticket = await db.get(SupportTicket, ticket_id)
    if not ticket:
        raise TicketNotFoundError()
    if status is not None:
        if status not in TICKET_STATUSES:
            raise InvalidTicketStatusError()
        ticket.status = status
    if admin_response is not None:
        ticket.admin_response = admin_response.strip() or None
    await db.flush()
    await db.refresh(ticket)
    return ticket
