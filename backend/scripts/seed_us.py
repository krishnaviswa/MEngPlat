"""US real-business listings from data/real-businesses/ (Unsplash + synthetic reviews)."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import TYPE_CHECKING

from sqlalchemy import select

from app.core.security import get_password_hash
from app.models import (
    AIAnalysis,
    Business,
    BusinessCategory,
    BusinessStatus,
    Category,
    Merchant,
    Photo,
    Review,
    Sentiment,
    User,
    UserRole,
)
from app.services.business_service import update_business_rating
from app.services.mfa import enable_demo_totp

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession

_US_CUSTOMER_PASSWORD = "demo12345abc"

_JSON_FILES = (
    "fremont-ca.json",
    "union-city-ca.json",
    "brandon-fl.json",
    "dallas-tx.json",
)

_CITY_CENTERS: dict[str, tuple[float, float]] = {
    "Fremont": (37.5485, -121.9886),
    "Union City": (37.5958, -122.0191),
    "Brandon": (27.9378, -82.2859),
    "Dallas": (32.7767, -96.7970),
}

_DESCRIPTION_BY_CATEGORY = {
    "restaurant": "Local restaurant serving neighborhood favorites.",
    "cafe": "Café with coffee, light bites, and a welcoming atmosphere.",
    "salon": "Salon for cuts, styling, and everyday grooming.",
    "auto_repair": "Auto repair shop for maintenance and service.",
    "hospital": "Medical care and urgent services for the community.",
}

_SENTIMENT_FOR_RATING = {
    5: Sentiment.POSITIVE,
    4: Sentiment.POSITIVE,
    3: Sentiment.NEUTRAL,
    2: Sentiment.NEGATIVE,
    1: Sentiment.NEGATIVE,
}

# Freely hotlinkable Unsplash stock — category-themed (do not hotlink JSON photo_reference_url).
_CATEGORY_STOREFRONTS: dict[str, list[str]] = {
    "restaurant": [
        "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=1200&h=800&q=80",
    ],
    "cafe": [
        "https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1442512595331-e89e7384260c?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1497935586351-b67a49e012bf?auto=format&fit=crop&w=1200&h=800&q=80",
    ],
    "salon": [
        "https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1633681926022-84c23e8cb2d7?auto=format&fit=crop&w=1200&h=800&q=80",
    ],
    "auto_repair": [
        "https://images.unsplash.com/photo-1487754180451-c456f719a1fc?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1625047509248-ec889cbff17f?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1632823469850-2f77dd9c7f93?auto=format&fit=crop&w=1200&h=800&q=80",
    ],
    "hospital": [
        "https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1538104668812-f2c7abeb9c7e?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1586773860418-d37222d8fce3?auto=format&fit=crop&w=1200&h=800&q=80",
    ],
}

_CATEGORY_GALLERY: dict[str, list[str]] = {
    "restaurant": [
        "https://images.unsplash.com/photo-1565557623262-b51c2513a641?auto=format&fit=crop&w=800&h=600&q=80",
        "https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=800&h=600&q=80",
        "https://images.unsplash.com/photo-1631452180519-c014fe946bc7?auto=format&fit=crop&w=800&h=600&q=80",
    ],
    "cafe": [
        "https://images.unsplash.com/photo-1511920170033-901324e5af66?auto=format&fit=crop&w=800&h=600&q=80",
        "https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&h=600&q=80",
        "https://images.unsplash.com/photo-1485808191679-5f86510681a2?auto=format&fit=crop&w=800&h=600&q=80",
    ],
    "salon": [
        "https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?auto=format&fit=crop&w=800&h=600&q=80",
        "https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&w=800&h=600&q=80",
    ],
    "auto_repair": [
        "https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?auto=format&fit=crop&w=800&h=600&q=80",
        "https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=800&h=600&q=80",
        "https://images.unsplash.com/photo-1558618666-fcd25c85cd64?auto=format&fit=crop&w=800&h=600&q=80",
    ],
    "hospital": [
        "https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&w=800&h=600&q=80",
        "https://images.unsplash.com/photo-1666214280557-f1b5022eb634?auto=format&fit=crop&w=800&h=600&q=80",
        "https://images.unsplash.com/photo-1631217868264-e5b90bb7e133?auto=format&fit=crop&w=800&h=600&q=80",
    ],
}

# Four templates per category; each business gets 3 rotated by slug hash.
_US_REVIEW_TEMPLATES: dict[str, list[dict]] = {
    "restaurant": [
        {"rating": 5, "title": "Solid meal", "body": "Food came out hot and portions were generous. Staff checked in without hovering."},
        {"rating": 4, "title": "Good for a weeknight", "body": "Flavor was consistent and the dining room felt clean. Wait time was reasonable."},
        {"rating": 3, "title": "Busy at peak hours", "body": "Quality was fine but service slowed when the room filled up. Still worth a return."},
        {"rating": 4, "title": "Friendly service", "body": "Server helped with menu questions and the main dishes matched what we ordered."},
    ],
    "cafe": [
        {"rating": 5, "title": "Great coffee stop", "body": "Espresso was balanced and the pastry case looked fresh. Good spot to sit for a bit."},
        {"rating": 4, "title": "Quiet enough to work", "body": "Wi‑Fi worked and seating was comfortable. Drink quality was above average."},
        {"rating": 3, "title": "Line at mid-morning", "body": "Coffee itself was fine; the queue moved slowly during the rush."},
        {"rating": 5, "title": "Friendly barista", "body": "Order was made carefully and they remembered a simple preference on a return visit."},
    ],
    "salon": [
        {"rating": 5, "title": "Listened to what I wanted", "body": "Stylist confirmed the cut before starting and the finish looked polished."},
        {"rating": 4, "title": "Clean and professional", "body": "Station felt tidy and tools looked sanitized. Appointment started close to on time."},
        {"rating": 3, "title": "Slight wait", "body": "Result was good but the chair opened later than expected. Still would book again."},
        {"rating": 4, "title": "Fair pricing", "body": "Cut quality matched the quote and they offered clear aftercare tips."},
    ],
    "auto_repair": [
        {"rating": 5, "title": "Clear diagnosis", "body": "They explained the issue in plain language and finished the repair when promised."},
        {"rating": 4, "title": "Honest estimate", "body": "Quoted work upfront and called before adding anything extra. Shop floor looked organized."},
        {"rating": 3, "title": "Parts delay", "body": "Work quality was fine but waiting on a part stretched the timeline a day."},
        {"rating": 5, "title": "Trustworthy shop", "body": "Test drive after service felt solid and the invoice matched the estimate."},
    ],
    "hospital": [
        {"rating": 5, "title": "Helpful staff", "body": "Check-in was organized and nurses kept us updated while we waited."},
        {"rating": 4, "title": "Thorough visit", "body": "Provider answered questions carefully and the facility felt clean."},
        {"rating": 3, "title": "Long wait time", "body": "Care itself was fine but the waiting room stay ran longer than expected."},
        {"rating": 4, "title": "Clear next steps", "body": "Discharge instructions were easy to follow and front desk was polite."},
    ],
}


def _resolve_data_dir() -> Path:
    """Prefer packaged backend copy (Railway/Docker image), then monorepo / compose mount."""
    here = Path(__file__).resolve()
    candidates = [
        # backend/data/real-businesses — shipped via backend Dockerfile `COPY . .`
        here.parents[1] / "data" / "real-businesses",
        # monorepo root data/real-businesses (local checkout without packaging)
        here.parents[2] / "data" / "real-businesses",
        # docker-compose volume mount
        Path("/data/real-businesses"),
    ]
    for path in candidates:
        if path.is_dir() and any(path.glob("*.json")):
            return path
    raise FileNotFoundError(
        "US seed data directory not found. Expected JSON under "
        "`backend/data/real-businesses` (packaged in the image), "
        "`data/real-businesses` at the repo root, or `/data/real-businesses` "
        "(Docker Compose mount)."
    )


def _slugify(name: str, city: str) -> str:
    raw = f"{name}-{city}".lower()
    raw = re.sub(r"[^a-z0-9]+", "-", raw)
    return raw.strip("-")


def _jitter_from_slug(slug: str) -> tuple[float, float]:
    """Deterministic ~±0.008° offset so map pins do not stack."""
    h = sum(ord(c) for c in slug)
    lat_j = ((h % 17) - 8) * 0.001
    lng_j = (((h // 17) % 17) - 8) * 0.001
    return lat_j, lng_j


def _pick(pool: list[str], key: str, offset: int = 0) -> str:
    return pool[(sum(ord(c) for c in key) + offset) % len(pool)]


def _storefront_url(category: str, slug: str) -> str:
    return _pick(_CATEGORY_STOREFRONTS.get(category, _CATEGORY_STOREFRONTS["restaurant"]), slug)


def _logo_url(category: str, slug: str) -> str:
    base = _pick(_CATEGORY_STOREFRONTS.get(category, _CATEGORY_STOREFRONTS["restaurant"]), slug, offset=1)
    return base.replace("w=1200&h=800", "w=400&h=400")


def _gallery_urls(category: str, slug: str) -> list[str]:
    pool = _CATEGORY_GALLERY.get(category, _CATEGORY_GALLERY["restaurant"])
    return [_pick(pool, slug, offset=i) for i in range(min(3, len(pool)))]


def _reviews_for_slug(category: str, slug: str) -> list[dict]:
    templates = _US_REVIEW_TEMPLATES.get(category, _US_REVIEW_TEMPLATES["restaurant"])
    offset = sum(ord(c) for c in slug) % len(templates)
    return [templates[(offset + i) % len(templates)] for i in range(3)]


def _load_listings() -> list[dict]:
    data_dir = _resolve_data_dir()
    listings: list[dict] = []
    for filename in _JSON_FILES:
        path = data_dir / filename
        if not path.is_file():
            raise FileNotFoundError(f"Missing US seed file: {path}")
        payload = json.loads(path.read_text(encoding="utf-8"))
        for entry in payload.get("businesses", []):
            listings.append(entry)
    return listings


async def seed_us(
    db: AsyncSession,
    merchant: Merchant,
    categories: list[Category],
) -> dict[str, int]:
    """Upsert US listings from data/real-businesses/ (safe to re-run). Caller must commit."""
    category_by_slug = {c.slug: c for c in categories}
    listings = _load_listings()

    existing_customers = (
        await db.execute(select(User).where(User.email.like("demo.customer%@example.com")))
    ).scalars().all()
    customers: list[User] = list(existing_customers)

    target_customers = 10
    for n in range(len(customers) + 1, target_customers + 1):
        customer = User(
            email=f"demo.customer{n}@example.com",
            full_name=f"Demo Customer {n}",
            hashed_password=get_password_hash(_US_CUSTOMER_PASSWORD),
            role=UserRole.CUSTOMER,
        )
        enable_demo_totp(customer)
        db.add(customer)
        customers.append(customer)
    for customer in customers:
        customer.hashed_password = get_password_hash(_US_CUSTOMER_PASSWORD)
        if not customer.totp_enabled:
            enable_demo_totp(customer)
    await db.flush()

    primary_customer = (
        await db.execute(select(User).where(User.email == "customer@example.com"))
    ).scalar_one_or_none()
    authors: list[User] = list(customers)
    if primary_customer is not None:
        authors.append(primary_customer)

    planned_slugs = [_slugify(entry["name"], entry["city"]) for entry in listings]
    existing_by_slug = {
        b.slug: b
        for b in (
            await db.execute(select(Business).where(Business.slug.in_(planned_slugs)))
        ).scalars().all()
    }

    business_count = 0
    review_count = 0
    created = 0
    refreshed = 0
    cities: set[str] = set()

    for idx, entry in enumerate(listings):
        name = entry["name"]
        city = entry["city"]
        category = entry["category"]
        slug = _slugify(name, city)
        cities.add(city)

        if city not in _CITY_CENTERS:
            raise ValueError(f"No city-center coordinates configured for {city!r} ({slug})")

        base_lat, base_lng = _CITY_CENTERS[city]
        lat_j, lng_j = _jitter_from_slug(slug)
        storefront = _storefront_url(category, slug)
        logo = _logo_url(category, slug)
        description = f"{name} — {_DESCRIPTION_BY_CATEGORY.get(category, 'Local business.')}"
        hours_raw = entry.get("hours") or ""
        business_hours = {"raw": hours_raw}

        business = existing_by_slug.get(slug)
        if business is None:
            business = Business(
                merchant_id=merchant.id,
                name=name,
                slug=slug,
                description=description,
                address=entry.get("address") or "",
                city=city,
                state=entry.get("state") or "",
                postal_code=entry.get("zip"),
                country="US",
                latitude=base_lat + lat_j,
                longitude=base_lng + lng_j,
                phone=entry.get("phone"),
                email=f"hello@{slug}.example",
                website=entry.get("website"),
                logo_url=logo,
                storefront_url=storefront,
                business_hours=business_hours,
                status=BusinessStatus.APPROVED,
            )
            db.add(business)
            await db.flush()
            created += 1

            cat = category_by_slug.get(category)
            if cat:
                db.add(BusinessCategory(business_id=business.id, category_id=cat.id))
        else:
            business.name = name
            business.description = description
            business.address = entry.get("address") or ""
            business.city = city
            business.state = entry.get("state") or ""
            business.postal_code = entry.get("zip")
            business.country = "US"
            business.latitude = base_lat + lat_j
            business.longitude = base_lng + lng_j
            business.phone = entry.get("phone")
            business.website = entry.get("website")
            business.logo_url = logo
            business.storefront_url = storefront
            business.business_hours = business_hours
            business.status = BusinessStatus.APPROVED
            refreshed += 1

        business_count += 1

        old_photos = (
            await db.execute(select(Photo).where(Photo.business_id == business.id, Photo.review_id.is_(None)))
        ).scalars().all()
        for photo in old_photos:
            await db.delete(photo)
        await db.flush()

        for g_idx, url in enumerate(_gallery_urls(category, slug)):
            db.add(
                Photo(
                    business_id=business.id,
                    uploaded_by=authors[idx % len(authors)].id,
                    url=url,
                    caption="Storefront" if g_idx == 0 else f"Inside / service {g_idx}",
                    photo_type="storefront" if g_idx == 0 else "gallery",
                )
            )

        existing_review_authors = {
            row[0]
            for row in (
                await db.execute(select(Review.author_id).where(Review.business_id == business.id))
            ).all()
        }

        for r_idx, review_spec in enumerate(_reviews_for_slug(category, slug)):
            author = authors[(idx + r_idx) % len(authors)]
            if author.id in existing_review_authors:
                continue
            review = Review(
                business_id=business.id,
                author_id=author.id,
                rating=review_spec["rating"],
                title=review_spec["title"],
                body=review_spec["body"],
            )
            db.add(review)
            await db.flush()
            review_count += 1
            existing_review_authors.add(author.id)

            if r_idx % 2 == 0:
                db.add(
                    Photo(
                        review_id=review.id,
                        uploaded_by=author.id,
                        url=_pick(
                            _CATEGORY_GALLERY.get(category, _CATEGORY_GALLERY["restaurant"]),
                            f"{slug}-review-{r_idx}",
                        ),
                        caption="Customer photo",
                        photo_type="review",
                    )
                )

            sentiment = _SENTIMENT_FOR_RATING.get(review_spec["rating"], Sentiment.NEUTRAL)
            db.add(
                AIAnalysis(
                    review_id=review.id,
                    analysis_type="text",
                    sentiment=sentiment,
                    summary=f"Review suggests {sentiment.value} experience overall.",
                    positives=["friendly service"] if review_spec["rating"] >= 4 else [],
                    complaints=["room to improve"] if review_spec["rating"] <= 3 else [],
                    suggested_response="Thank you for sharing your feedback with us.",
                    provider="mock",
                    raw_response={"seed": True, "slug": slug},
                    degraded=False,
                )
            )

        await update_business_rating(db, business.id)

    return {
        "businesses": business_count,
        "reviews": review_count,
        "customers": len(customers),
        "created": created,
        "refreshed": refreshed,
        "cities": len(cities),
    }
