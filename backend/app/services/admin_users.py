"""Admin user list + suspend/reactivate (S-034). Router owns RBAC/validation;
this module owns the self/admin-target rule and the AuditLog side effect."""

from __future__ import annotations

from uuid import UUID

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import AuditLog, User, UserRole


class SelfOrAdminTargetError(Exception):
    """Suspend/reactivate refused: target is the caller or another admin."""


async def list_users(db: AsyncSession, page: int, page_size: int, q: str | None = None) -> list[User]:
    stmt = select(User).order_by(User.created_at.desc())
    if q:
        like = f"%{q}%"
        stmt = stmt.where(or_(User.email.ilike(like), User.full_name.ilike(like)))
    stmt = stmt.offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(stmt)
    users = list(result.scalars().all())
    from app.services.national_id import apply_admin_national_id_mask

    return [apply_admin_national_id_mask(u) for u in users]


async def _load_target(db: AsyncSession, user_id: UUID, admin: User) -> User | None:
    target = await db.get(User, user_id)
    if not target:
        return None
    if target.id == admin.id or target.role == UserRole.ADMIN:
        raise SelfOrAdminTargetError()
    return target


async def suspend_user(db: AsyncSession, user_id: UUID, admin: User) -> User | None:
    target = await _load_target(db, user_id, admin)
    if not target:
        return None
    if target.is_active:
        target.is_active = False
        db.add(
            AuditLog(
                admin_id=admin.id,
                action="suspend",
                entity_type="user",
                entity_id=str(target.id),
                details={"previous_is_active": True},
            )
        )
        await db.flush()
    from app.services.national_id import apply_admin_national_id_mask

    return apply_admin_national_id_mask(target)


async def reactivate_user(db: AsyncSession, user_id: UUID, admin: User) -> User | None:
    target = await _load_target(db, user_id, admin)
    if not target:
        return None
    if not target.is_active:
        target.is_active = True
        db.add(
            AuditLog(
                admin_id=admin.id,
                action="reactivate",
                entity_type="user",
                entity_id=str(target.id),
                details={"previous_is_active": False},
            )
        )
        await db.flush()
    from app.services.national_id import apply_admin_national_id_mask

    return apply_admin_national_id_mask(target)
