"""Small curated business set with real shop photos, for the homepage social-proof rail.

Reuses the Unsplash stock-photo pools already established in seed_chennai.py / seed_us.py
(merged, since between them they cover every category this rail needs) rather than
inventing a new image source.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from sqlalchemy import select

from app.models import Business, BusinessCategory, BusinessStatus, Category, Merchant, Photo
from scripts.seed_chennai import _CATEGORY_GALLERY as _CHENNAI_GALLERY
from scripts.seed_chennai import _CATEGORY_STOREFRONTS as _CHENNAI_STOREFRONTS
from scripts.seed_us import _CATEGORY_GALLERY as _US_GALLERY
from scripts.seed_us import _CATEGORY_STOREFRONTS as _US_STOREFRONTS
from scripts.seed_us import _pick

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession

# Union of both seed modules' pools: Chennai has "grocery", US has "auto_repair"/"hospital".
_CATEGORY_STOREFRONTS: dict[str, list[str]] = {**_US_STOREFRONTS, **_CHENNAI_STOREFRONTS}
_CATEGORY_GALLERY: dict[str, list[str]] = {**_US_GALLERY, **_CHENNAI_GALLERY}


def _storefront_url(image_category: str, slug: str) -> str:
    return _pick(_CATEGORY_STOREFRONTS.get(image_category, _CATEGORY_STOREFRONTS["restaurant"]), slug)


def _logo_url(image_category: str, slug: str) -> str:
    base = _pick(_CATEGORY_STOREFRONTS.get(image_category, _CATEGORY_STOREFRONTS["restaurant"]), slug, offset=1)
    return base.replace("w=1200&h=800", "w=400&h=400")


def _gallery_urls(image_category: str, slug: str) -> list[str]:
    pool = _CATEGORY_GALLERY.get(image_category, _CATEGORY_GALLERY["restaurant"])
    return [_pick(pool, slug, offset=i) for i in range(min(3, len(pool)))]


# Order here is the display order on the homepage rail.
SOCIAL_PROOF_SLUGS: list[str] = [
    "copper-kettle-cafe",
    "bright-smile-dental",
    "chrompet-cycle-repair",
    "verde-salon-spa",
    "anand-grocers",
    "pixel-print-studio",
    "riverside-diner",
    "golden-wok-kitchen",
    "chrompet-family-hospital",
    "sunrise-urgent-care",
    "blue-ridge-pharmacy",
    "nagar-medical-store",
    "fresh-fields-grocery",
    "bandra-fresh-mart",
    "cedar-street-salon",
    "glow-beauty-bar",
    "steel-city-auto-works",
    "quick-fix-motors",
    "daily-grind-coffee-house",
    "chai-point-corner",
    "harborview-bistro",
    "curry-leaf-kitchen",
    "metro-wellness-clinic",
    "lotus-care-hospital",
    "value-mart-pharmacy",
    "everyday-essentials-grocery",
    "silver-scissors-salon",
    "trend-cutz-studio",
    "precision-auto-care",
    "neighborhood-bike-auto",
]

# "category" is the real taxonomy Category to attach (None if nothing in the seeded
# catalog fits); "image_category" picks which stock-photo pool to draw from and always
# falls back to "restaurant" when unset.
_SOCIAL_PROOF_BUSINESSES: list[dict] = [
    {
        "name": "Copper Kettle Cafe",
        "slug": "copper-kettle-cafe",
        "category": "cafe",
        "image_category": "cafe",
        "city": "Portland",
        "state": "OR",
        "country": "US",
        "address": "210 Kettle Row",
        "postal_code": "97205",
        "description": "Neighborhood coffee bar known for single-origin pour-overs and fresh pastries.",
        "phone": "+1-555-0301",
    },
    {
        "name": "Bright Smile Dental",
        "slug": "bright-smile-dental",
        # No dedicated "dental" category in the seeded catalog; "pharmacy" is the closest
        # healthcare-adjacent taxonomy slug, matching the precedent set by
        # seed_chennai.py's "Chrompet Dental Care" -> "pharmacy".
        "category": "pharmacy",
        "image_category": "pharmacy",
        "city": "Portland",
        "state": "OR",
        "country": "US",
        "address": "88 Bright Ave",
        "postal_code": "97209",
        "description": "Family dental practice offering cleanings, whitening, and routine checkups.",
        "phone": "+1-555-0302",
    },
    {
        "name": "Chrompet Cycle Repair",
        "slug": "chrompet-cycle-repair",
        "category": "auto_repair",
        "image_category": "auto_repair",
        "city": "Chennai",
        "state": "TN",
        "country": "IN",
        "address": "18 GST Road, Chrompet",
        "postal_code": "600044",
        "description": "Bicycle and two-wheeler repair, tune-ups, and spare parts near Chrompet.",
        "phone": "+91-44-2223-3030",
    },
    {
        "name": "Verde Salon & Spa",
        "slug": "verde-salon-spa",
        "category": "salon",
        "image_category": "salon",
        "city": "Fremont",
        "state": "CA",
        "country": "US",
        "address": "455 Verde Lane",
        "postal_code": "94536",
        "description": "Full-service salon and spa offering cuts, color, and relaxation treatments.",
        "phone": "+1-555-0303",
    },
    {
        "name": "Anand Grocers",
        "slug": "anand-grocers",
        "category": "grocery",
        "image_category": "grocery",
        "city": "Chennai",
        "state": "TN",
        "country": "IN",
        "address": "5 Radha Nagar Main Road, Chrompet",
        "postal_code": "600044",
        "description": "Daily groceries, staples, and household essentials for the neighborhood.",
        "phone": "+91-44-2223-4040",
    },
    {
        "name": "Pixel Print Studio",
        "slug": "pixel-print-studio",
        # No print/retail category exists in the seeded catalog — leave uncategorized
        # rather than mistag it under an unrelated taxonomy slug.
        "category": None,
        "image_category": "restaurant",
        "city": "Dallas",
        "state": "TX",
        "country": "US",
        "address": "1200 Pixel Blvd",
        "postal_code": "75201",
        "description": "Print shop for business cards, banners, and same-day photo prints.",
        "phone": "+1-555-0304",
    },
    {
        "name": "Riverside Diner",
        "slug": "riverside-diner",
        "category": "restaurant",
        "image_category": "restaurant",
        "city": "Austin",
        "state": "TX",
        "country": "US",
        "address": "310 Riverside Dr",
        "postal_code": "78701",
        "description": "Classic American diner serving breakfast all day and hearty plates.",
        "phone": "+1-555-0305",
    },
    {
        "name": "Golden Wok Kitchen",
        "slug": "golden-wok-kitchen",
        "category": "restaurant",
        "image_category": "restaurant",
        "city": "Seattle",
        "state": "WA",
        "country": "US",
        "address": "77 Wok Alley",
        "postal_code": "98101",
        "description": "Family-run Chinese kitchen known for wok-fried noodles and dumplings.",
        "phone": "+1-555-0306",
    },
    {
        "name": "Chrompet Family Hospital",
        "slug": "chrompet-family-hospital",
        "category": "hospital",
        "image_category": "hospital",
        "city": "Chennai",
        "state": "TN",
        "country": "IN",
        "address": "22 GST Road, Chrompet",
        "postal_code": "600044",
        "description": "General and family medicine clinic with outpatient consultations.",
        "phone": "+91-44-2223-5050",
    },
    {
        "name": "Sunrise Urgent Care",
        "slug": "sunrise-urgent-care",
        "category": "hospital",
        "image_category": "hospital",
        "city": "Portland",
        "state": "OR",
        "country": "US",
        "address": "60 Sunrise Ave",
        "postal_code": "97210",
        "description": "Walk-in urgent care clinic for minor injuries and same-day visits.",
        "phone": "+1-555-0307",
    },
    {
        "name": "Blue Ridge Pharmacy",
        "slug": "blue-ridge-pharmacy",
        "category": "pharmacy",
        "image_category": "pharmacy",
        "city": "Austin",
        "state": "TX",
        "country": "US",
        "address": "145 Blue Ridge Rd",
        "postal_code": "78702",
        "description": "Neighborhood pharmacy offering prescriptions and health essentials.",
        "phone": "+1-555-0308",
    },
    {
        "name": "Nagar Medical Store",
        "slug": "nagar-medical-store",
        "category": "pharmacy",
        "image_category": "pharmacy",
        "city": "Bangalore",
        "state": "KA",
        "country": "IN",
        "address": "9 MG Road",
        "postal_code": "560001",
        "description": "Local medical store stocking everyday medicines and health supplies.",
        "phone": "+91-80-4112-1010",
    },
    {
        "name": "Fresh Fields Grocery",
        "slug": "fresh-fields-grocery",
        "category": "grocery",
        "image_category": "grocery",
        "city": "Fremont",
        "state": "CA",
        "country": "US",
        "address": "500 Fields Ave",
        "postal_code": "94537",
        "description": "Produce-forward grocery store with fresh, locally sourced staples.",
        "phone": "+1-555-0309",
    },
    {
        "name": "Bandra Fresh Mart",
        "slug": "bandra-fresh-mart",
        "category": "grocery",
        "image_category": "grocery",
        "city": "Mumbai",
        "state": "MH",
        "country": "IN",
        "address": "14 Hill Road, Bandra",
        "postal_code": "400050",
        "description": "Everyday grocery mart for household staples and fresh produce.",
        "phone": "+91-22-6612-1010",
    },
    {
        "name": "Cedar Street Salon",
        "slug": "cedar-street-salon",
        "category": "salon",
        "image_category": "salon",
        "city": "Seattle",
        "state": "WA",
        "country": "US",
        "address": "220 Cedar St",
        "postal_code": "98102",
        "description": "Full-service hair salon offering cuts, color, and styling.",
        "phone": "+1-555-0310",
    },
    {
        "name": "Glow Beauty Bar",
        "slug": "glow-beauty-bar",
        "category": "salon",
        "image_category": "salon",
        "city": "Dallas",
        "state": "TX",
        "country": "US",
        "address": "88 Glow Plaza",
        "postal_code": "75202",
        "description": "Beauty bar offering facials, waxing, and skincare treatments.",
        "phone": "+1-555-0311",
    },
    {
        "name": "Steel City Auto Works",
        "slug": "steel-city-auto-works",
        "category": "auto_repair",
        "image_category": "auto_repair",
        "city": "Austin",
        "state": "TX",
        "country": "US",
        "address": "410 Steel City Rd",
        "postal_code": "78703",
        "description": "Full-service auto repair shop for tune-ups, brakes, and diagnostics.",
        "phone": "+1-555-0312",
    },
    {
        "name": "Quick Fix Motors",
        "slug": "quick-fix-motors",
        "category": "auto_repair",
        "image_category": "auto_repair",
        "city": "Bangalore",
        "state": "KA",
        "country": "IN",
        "address": "31 Brigade Road",
        "postal_code": "560002",
        "description": "Two-wheeler and car repair shop with same-day service.",
        "phone": "+91-80-4112-2020",
    },
    {
        "name": "Daily Grind Coffee House",
        "slug": "daily-grind-coffee-house",
        "category": "cafe",
        "image_category": "cafe",
        "city": "Seattle",
        "state": "WA",
        "country": "US",
        "address": "12 Grind St",
        "postal_code": "98103",
        "description": "Cozy coffee house with house-roasted beans and fresh pastries.",
        "phone": "+1-555-0313",
    },
    {
        "name": "Chai Point Corner",
        "slug": "chai-point-corner",
        "category": "cafe",
        "image_category": "cafe",
        "city": "Mumbai",
        "state": "MH",
        "country": "IN",
        "address": "5 Linking Road",
        "postal_code": "400051",
        "description": "Corner chai stall serving tea, snacks, and quick bites.",
        "phone": "+91-22-6612-2020",
    },
    {
        "name": "Harborview Bistro",
        "slug": "harborview-bistro",
        "category": "restaurant",
        "image_category": "restaurant",
        "city": "Fremont",
        "state": "CA",
        "country": "US",
        "address": "70 Harborview Way",
        "postal_code": "94538",
        "description": "Casual bistro with seasonal menus and a lively patio.",
        "phone": "+1-555-0314",
    },
    {
        "name": "Curry Leaf Kitchen",
        "slug": "curry-leaf-kitchen",
        "category": "restaurant",
        "image_category": "restaurant",
        "city": "Chennai",
        "state": "TN",
        "country": "IN",
        "address": "2 Anna Salai",
        "postal_code": "600045",
        "description": "South Indian kitchen known for dosas, curries, and thalis.",
        "phone": "+91-44-2223-6060",
    },
    {
        "name": "Metro Wellness Clinic",
        "slug": "metro-wellness-clinic",
        "category": "hospital",
        "image_category": "hospital",
        "city": "Dallas",
        "state": "TX",
        "country": "US",
        "address": "150 Metro Wellness Dr",
        "postal_code": "75203",
        "description": "Multi-specialty wellness clinic offering primary care and checkups.",
        "phone": "+1-555-0315",
    },
    {
        "name": "Lotus Care Hospital",
        "slug": "lotus-care-hospital",
        "category": "hospital",
        "image_category": "hospital",
        "city": "Bangalore",
        "state": "KA",
        "country": "IN",
        "address": "18 Residency Road",
        "postal_code": "560003",
        "description": "Multi-specialty hospital offering outpatient and diagnostic services.",
        "phone": "+91-80-4112-3030",
    },
    {
        "name": "Value Mart Pharmacy",
        "slug": "value-mart-pharmacy",
        "category": "pharmacy",
        "image_category": "pharmacy",
        "city": "Seattle",
        "state": "WA",
        "country": "US",
        "address": "300 Value Mart Blvd",
        "postal_code": "98104",
        "description": "Discount pharmacy for prescriptions and everyday health needs.",
        "phone": "+1-555-0316",
    },
    {
        "name": "Everyday Essentials Grocery",
        "slug": "everyday-essentials-grocery",
        "category": "grocery",
        "image_category": "grocery",
        "city": "Austin",
        "state": "TX",
        "country": "US",
        "address": "95 Essentials Way",
        "postal_code": "78704",
        "description": "Neighborhood grocery for everyday essentials and pantry staples.",
        "phone": "+1-555-0317",
    },
    {
        "name": "Silver Scissors Salon",
        "slug": "silver-scissors-salon",
        "category": "salon",
        "image_category": "salon",
        "city": "Portland",
        "state": "OR",
        "country": "US",
        "address": "40 Scissors Ln",
        "postal_code": "97211",
        "description": "Classic barbershop-style salon for cuts, shaves, and styling.",
        "phone": "+1-555-0318",
    },
    {
        "name": "Trend Cutz Studio",
        "slug": "trend-cutz-studio",
        "category": "salon",
        "image_category": "salon",
        "city": "Mumbai",
        "state": "MH",
        "country": "IN",
        "address": "27 Carter Road",
        "postal_code": "400052",
        "description": "Trendy hair and grooming studio for cuts, color, and styling.",
        "phone": "+91-22-6612-3030",
    },
    {
        "name": "Precision Auto Care",
        "slug": "precision-auto-care",
        "category": "auto_repair",
        "image_category": "auto_repair",
        "city": "Fremont",
        "state": "CA",
        "country": "US",
        "address": "60 Precision Pkwy",
        "postal_code": "94539",
        "description": "Precision auto care shop for maintenance, brakes, and diagnostics.",
        "phone": "+1-555-0319",
    },
    {
        "name": "Neighborhood Bike & Auto",
        "slug": "neighborhood-bike-auto",
        "category": "auto_repair",
        "image_category": "auto_repair",
        "city": "Dallas",
        "state": "TX",
        "country": "US",
        "address": "18 Neighborhood Ct",
        "postal_code": "75204",
        "description": "Bike and auto repair shop serving the neighborhood since day one.",
        "phone": "+1-555-0320",
    },
]


async def seed_social_proof(
    db: AsyncSession,
    merchant: Merchant,
    categories: list[Category],
) -> dict[str, int]:
    """Upsert the homepage social-proof rail businesses (safe to re-run). Caller must commit."""
    category_by_slug = {c.slug: c for c in categories}

    existing_by_slug = {
        b.slug: b
        for b in (
            await db.execute(select(Business).where(Business.slug.in_(SOCIAL_PROOF_SLUGS)))
        ).scalars().all()
    }

    created = 0
    refreshed = 0

    for spec in _SOCIAL_PROOF_BUSINESSES:
        slug = spec["slug"]
        image_category = spec["image_category"]
        storefront = _storefront_url(image_category, slug)
        logo = _logo_url(image_category, slug)

        business = existing_by_slug.get(slug)
        if business is None:
            business = Business(
                merchant_id=merchant.id,
                name=spec["name"],
                slug=slug,
                description=spec["description"],
                address=spec["address"],
                city=spec["city"],
                state=spec["state"],
                postal_code=spec["postal_code"],
                country=spec["country"],
                phone=spec["phone"],
                email=f"hello@{slug}.example",
                logo_url=logo,
                storefront_url=storefront,
                business_hours={"mon-sat": "9am-7pm"},
                status=BusinessStatus.APPROVED,
            )
            db.add(business)
            await db.flush()
            created += 1

            cat_slug = spec["category"]
            cat = category_by_slug.get(cat_slug) if cat_slug else None
            if cat:
                db.add(BusinessCategory(business_id=business.id, category_id=cat.id))
        else:
            business.name = spec["name"]
            business.description = spec["description"]
            business.address = spec["address"]
            business.city = spec["city"]
            business.state = spec["state"]
            business.postal_code = spec["postal_code"]
            business.country = spec["country"]
            business.phone = spec["phone"]
            business.logo_url = logo
            business.storefront_url = storefront
            business.status = BusinessStatus.APPROVED
            refreshed += 1

        # Replace gallery photos so re-seeding refreshes stale URLs.
        old_photos = (
            await db.execute(
                select(Photo).where(Photo.business_id == business.id, Photo.review_id.is_(None))
            )
        ).scalars().all()
        for photo in old_photos:
            await db.delete(photo)
        await db.flush()

        for g_idx, url in enumerate(_gallery_urls(image_category, slug)):
            db.add(
                Photo(
                    business_id=business.id,
                    uploaded_by=merchant.user_id,
                    url=url,
                    caption="Storefront" if g_idx == 0 else f"Inside / product {g_idx}",
                    photo_type="storefront" if g_idx == 0 else "gallery",
                )
            )

    return {
        "businesses": len(_SOCIAL_PROOF_BUSINESSES),
        "created": created,
        "refreshed": refreshed,
    }
