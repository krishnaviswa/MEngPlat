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
