"""Seed the database with sample data for local development.

Gated by SEED_MODE / SEED_VERSION (see app.config.Settings):
  off          — no-op (default; Railway production boots must not re-upsert)
  if_empty     — run only when there are zero approved businesses
  if_outdated  — run only when seed_runs lacks the current SEED_VERSION
  force        — always upsert, then record the marker
"""

from __future__ import annotations

import asyncio
from datetime import datetime, timezone
from typing import Any, Literal

from sqlalchemy import func, select

from app.config import get_settings
from app.core.security import get_password_hash
from app.database import AsyncSessionLocal
from app.models import (
    Business,
    BusinessCategory,
    BusinessStatus,
    Category,
    Merchant,
    SeedRun,
    User,
    UserRole,
)
from app.services.mfa import enable_demo_totp
from scripts.seed_chennai import CHENNAI_CUSTOMER_PASSWORD, seed_chennai
from scripts.seed_us import seed_us

SeedMode = Literal["off", "if_empty", "if_outdated", "force"]

# Shared category catalog — first-run creates all; re-runs insert any missing slugs.
_SEED_CATEGORIES: list[tuple[str, str, str]] = [
    ("Restaurant", "restaurant", "🍽️"),
    ("Grocery", "grocery", "🛒"),
    ("Salon", "salon", "💇"),
    ("Pharmacy", "pharmacy", "💊"),
    ("Café", "cafe", "☕"),
    ("Auto Repair", "auto_repair", "🔧"),
    ("Hospital", "hospital", "🏥"),
]


def should_run_seed(
    mode: str,
    *,
    has_current_version: bool,
    approved_business_count: int,
) -> tuple[bool, str]:
    """Decide whether to run the demo upsert. Pure helper for tests + seed()."""
    normalized = (mode or "off").strip().lower()
    if normalized == "off":
        return False, "SEED_MODE=off — skipping seed"
    if normalized == "force":
        return True, "SEED_MODE=force — running seed"
    if normalized == "if_empty":
        if approved_business_count > 0:
            return False, f"SEED_MODE=if_empty — {approved_business_count} approved businesses already present"
        return True, "SEED_MODE=if_empty — catalog empty, running seed"
    if normalized == "if_outdated":
        if has_current_version:
            return False, "SEED_MODE=if_outdated — current SEED_VERSION already applied"
        return True, "SEED_MODE=if_outdated — marker missing or outdated, running seed"
    return False, f"Unknown SEED_MODE={mode!r} — treating as off"


async def _ensure_categories(db, categories: list[Category]) -> list[Category]:
    """Insert any missing Category rows from `_SEED_CATEGORIES` (idempotent)."""
    by_slug = {c.slug: c for c in categories}
    added = False
    for name, slug, icon in _SEED_CATEGORIES:
        if slug in by_slug:
            continue
        cat = Category(name=name, slug=slug, icon=icon)
        db.add(cat)
        by_slug[slug] = cat
        added = True
    if added:
        await db.flush()
    # Preserve a stable order matching the catalog, then any extras.
    ordered = [by_slug[slug] for _, slug, _ in _SEED_CATEGORIES if slug in by_slug]
    extras = [c for c in categories if c.slug not in {s for _, s, _ in _SEED_CATEGORIES}]
    return ordered + extras


async def _seed_base(db) -> tuple[Merchant, list[Category]]:
    """Phase 1: Portland demo users, merchant, categories, and one café."""
    admin_user = User(
        email="admin@merchanthub.ai",
        full_name="Platform Admin",
        hashed_password=get_password_hash("admin12345ok"),
        role=UserRole.ADMIN,
    )
    merchant_user = User(
        email="merchant@example.com",
        full_name="Maria Santos",
        hashed_password=get_password_hash("merchant1234"),
        role=UserRole.MERCHANT,
    )
    customer_user = User(
        email="customer@example.com",
        full_name="Alex Johnson",
        hashed_password=get_password_hash("customer1234"),
        role=UserRole.CUSTOMER,
    )
    for u in (admin_user, merchant_user, customer_user):
        enable_demo_totp(u)
    db.add_all([admin_user, merchant_user, customer_user])
    await db.flush()

    merchant = Merchant(user_id=merchant_user.id, phone="+1-555-0100")
    db.add(merchant)
    await db.flush()

    categories = [
        Category(name=name, slug=slug, icon=icon) for name, slug, icon in _SEED_CATEGORIES
    ]
    db.add_all(categories)
    await db.flush()

    business = Business(
        merchant_id=merchant.id,
        name="Sunrise Corner Café",
        slug="sunrise-corner-cafe",
        description="Neighborhood café serving locally roasted coffee and fresh pastries.",
        address="123 Main Street",
        city="Portland",
        state="OR",
        postal_code="97201",
        latitude=45.5231,
        longitude=-122.6765,
        phone="+1-555-0199",
        email="hello@sunrisecafe.example",
        business_hours={"mon-fri": "7am-6pm", "sat-sun": "8am-5pm"},
        status=BusinessStatus.APPROVED,
    )
    db.add(business)
    await db.flush()
    cafe = next(c for c in categories if c.slug == "cafe")
    db.add(BusinessCategory(business_id=business.id, category_id=cafe.id))

    return merchant, list(categories)


async def _record_seed_run(db, version: str, notes: str | None = None) -> None:
    """Upsert seed_runs row for this version (refresh applied_at on force)."""
    existing = (
        await db.execute(select(SeedRun).where(SeedRun.version == version))
    ).scalar_one_or_none()
    now = datetime.now(timezone.utc)
    if existing:
        existing.applied_at = now
        existing.notes = notes
    else:
        db.add(SeedRun(version=version, applied_at=now, notes=notes))


async def seed() -> None:
    # Tables are created by `alembic upgrade head`, which the start command runs
    # before this script. Seeding no longer creates schema of its own.
    # Chrompet/Radha Nagar is committed before US so a US seed failure cannot roll
    # back Chennai shops.
    settings = get_settings()
    mode: str = settings.seed_mode
    version: str = settings.seed_version

    async with AsyncSessionLocal() as db:
        marker = (
            await db.execute(select(SeedRun).where(SeedRun.version == version))
        ).scalar_one_or_none()
        approved_count = int(
            await db.scalar(
                select(func.count())
                .select_from(Business)
                .where(Business.status == BusinessStatus.APPROVED)
            )
            or 0
        )

        run, reason = should_run_seed(
            mode,
            has_current_version=marker is not None,
            approved_business_count=approved_count,
        )
        print(reason)
        if not run:
            return

        admin = await db.execute(select(User).where(User.email == "admin@merchanthub.ai"))
        if not admin.scalar_one_or_none():
            merchant, categories = await _seed_base(db)
        else:
            # Keep demo password accounts on the shared authenticator secret when re-seeding.
            demo_passwords = {
                "admin@merchanthub.ai": "admin12345ok",
                "merchant@example.com": "merchant1234",
                "customer@example.com": "customer1234",
            }
            for email, password in demo_passwords.items():
                existing = (
                    await db.execute(select(User).where(User.email == email))
                ).scalar_one_or_none()
                if existing:
                    existing.hashed_password = get_password_hash(password)
                    if not existing.totp_enabled:
                        enable_demo_totp(existing)
            merchant_result = await db.execute(
                select(Merchant).join(User, Merchant.user_id == User.id).where(User.email == "merchant@example.com")
            )
            merchant = merchant_result.scalar_one()
            categories = list((await db.execute(select(Category))).scalars().all())

        categories = await _ensure_categories(db, categories)

        counts_chennai = await seed_chennai(db, merchant, categories)
        await db.commit()

        counts_us: dict[str, Any] | None = None
        try:
            counts_us = await seed_us(db, merchant, categories)
            await db.commit()
        except Exception as exc:  # noqa: BLE001 — never wipe Chennai for US seed
            await db.rollback()
            print(f"WARNING: US seed skipped ({type(exc).__name__}: {exc})")
            print("  Chrompet / Radha Nagar data from this run was already committed.")

        async with AsyncSessionLocal() as marker_db:
            await _record_seed_run(
                marker_db,
                version,
                notes=f"mode={mode}; chennai={counts_chennai.get('businesses')}; "
                f"us={None if counts_us is None else counts_us.get('businesses')}",
            )
            await marker_db.commit()

        print("Seed complete.")
        print(f"  SEED_VERSION marker: {version}")
        print("  Admin:    admin@merchanthub.ai / admin12345ok")
        print("  Merchant: merchant@example.com / merchant1234")
        print("  Customer: customer@example.com / customer1234")
        print("  Demo TOTP secret (authenticator): JBSWY3DPEHPK3PXP")
        print(
            f"  Chennai demo customers: demo.customer1@example.com … "
            f"demo.customer{counts_chennai['customers']}@example.com / {CHENNAI_CUSTOMER_PASSWORD}"
        )
        print(
            f"  Chrompet / Radha Nagar: {counts_chennai['businesses']} businesses "
            f"(created={counts_chennai.get('created', 0)}, refreshed={counts_chennai.get('refreshed', 0)}), "
            f"new reviews this run={counts_chennai['reviews']}"
        )
        if counts_us is not None:
            print(
                f"  US real businesses: {counts_us['businesses']} businesses across "
                f"{counts_us.get('cities', 0)} cities "
                f"(created={counts_us.get('created', 0)}, refreshed={counts_us.get('refreshed', 0)}), "
                f"new reviews this run={counts_us['reviews']}"
            )
        else:
            print("  US real businesses: skipped (see WARNING above)")


if __name__ == "__main__":
    asyncio.run(seed())
