"""Seed the database with sample data for local development."""

import asyncio

from sqlalchemy import select

from app.core.security import get_password_hash
from app.database import AsyncSessionLocal, Base, engine
from app.models import Business, BusinessCategory, BusinessStatus, Category, Merchant, User, UserRole


async def seed() -> None:
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as db:
        admin = await db.execute(select(User).where(User.email == "admin@merchanthub.ai"))
        if admin.scalar_one_or_none():
            print("Database already seeded.")
            return

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

        await db.commit()
        print("Seed complete.")
        print("  Admin:    admin@merchanthub.ai / admin12345")
        print("  Merchant: merchant@example.com / merchant123")
        print("  Customer: customer@example.com / customer123")


if __name__ == "__main__":
    asyncio.run(seed())
