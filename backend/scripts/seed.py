"""Seed the database with sample data for local development."""

import asyncio

from sqlalchemy import select

from app.core.security import get_password_hash
from app.database import AsyncSessionLocal
from app.models import Business, BusinessCategory, BusinessStatus, Category, Merchant, User, UserRole
from scripts.seed_chennai import CHENNAI_CUSTOMER_PASSWORD, seed_chennai
from scripts.seed_us import seed_us

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
        hashed_password=get_password_hash("admin12345"),
        role=UserRole.ADMIN,
    )
    merchant_user = User(
        email="merchant@example.com",
        full_name="Maria Santos",
        hashed_password=get_password_hash("merchant123"),
        role=UserRole.MERCHANT,
    )
    customer_user = User(
        email="customer@example.com",
        full_name="Alex Johnson",
        hashed_password=get_password_hash("customer123"),
        role=UserRole.CUSTOMER,
    )
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


async def seed() -> None:
    # Tables are created by `alembic upgrade head`, which the start command runs
    # before this script. Seeding no longer creates schema of its own.
    # Chrompet/Radha Nagar and US real-business data are upserted on every run so
    # image/review refreshes land on already-seeded databases (not only on empty volumes).
    async with AsyncSessionLocal() as db:
        admin = await db.execute(select(User).where(User.email == "admin@merchanthub.ai"))
        if not admin.scalar_one_or_none():
            merchant, categories = await _seed_base(db)
        else:
            merchant_result = await db.execute(
                select(Merchant).join(User, Merchant.user_id == User.id).where(User.email == "merchant@example.com")
            )
            merchant = merchant_result.scalar_one()
            categories = list((await db.execute(select(Category))).scalars().all())

        categories = await _ensure_categories(db, categories)

        counts_chennai = await seed_chennai(db, merchant, categories)
        counts_us = await seed_us(db, merchant, categories)
        await db.commit()

        print("Seed complete.")
        print("  Admin:    admin@merchanthub.ai / admin12345")
        print("  Merchant: merchant@example.com / merchant123")
        print("  Customer: customer@example.com / customer123")
        print(
            f"  Chennai demo customers: demo.customer1@example.com … "
            f"demo.customer{counts_chennai['customers']}@example.com / {CHENNAI_CUSTOMER_PASSWORD}"
        )
        print(
            f"  Chrompet / Radha Nagar: {counts_chennai['businesses']} businesses "
            f"(created={counts_chennai.get('created', 0)}, refreshed={counts_chennai.get('refreshed', 0)}), "
            f"new reviews this run={counts_chennai['reviews']}"
        )
        print(
            f"  US real businesses: {counts_us['businesses']} businesses across "
            f"{counts_us.get('cities', 0)} cities "
            f"(created={counts_us.get('created', 0)}, refreshed={counts_us.get('refreshed', 0)}), "
            f"new reviews this run={counts_us['reviews']}"
        )


if __name__ == "__main__":
    asyncio.run(seed())
