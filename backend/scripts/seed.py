"""Seed the database with sample data for local development."""

import asyncio

from sqlalchemy import select

from app.core.security import get_password_hash
from app.database import AsyncSessionLocal
from app.models import Business, BusinessCategory, BusinessStatus, Category, Merchant, User, UserRole
from scripts.seed_chennai import CHENNAI_CUSTOMER_PASSWORD, seed_chennai


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
        Category(name="Restaurant", slug="restaurant", icon="🍽️"),
        Category(name="Grocery", slug="grocery", icon="🛒"),
        Category(name="Salon", slug="salon", icon="💇"),
        Category(name="Pharmacy", slug="pharmacy", icon="💊"),
        Category(name="Café", slug="cafe", icon="☕"),
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
    db.add(BusinessCategory(business_id=business.id, category_id=categories[4].id))

    return merchant, list(categories)


async def seed() -> None:
    # Tables are created by `alembic upgrade head`, which the start command runs
    # before this script. Seeding no longer creates schema of its own.
    # Chrompet/Radha Nagar data is upserted on every run so image/review refreshes land
    # on already-seeded databases (not only on empty volumes).
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

        counts = await seed_chennai(db, merchant, categories)
        await db.commit()

        print("Seed complete.")
        print("  Admin:    admin@merchanthub.ai / admin12345")
        print("  Merchant: merchant@example.com / merchant123")
        print("  Customer: customer@example.com / customer123")
        print(
            f"  Chennai demo customers: demo.customer1@example.com … "
            f"demo.customer{counts['customers']}@example.com / {CHENNAI_CUSTOMER_PASSWORD}"
        )
        print(
            f"  Chrompet / Radha Nagar: {counts['businesses']} businesses "
            f"(created={counts.get('created', 0)}, refreshed={counts.get('refreshed', 0)}), "
            f"new reviews this run={counts['reviews']}"
        )


if __name__ == "__main__":
    asyncio.run(seed())
