"""Chrompet / Radha Nagar demo businesses, reviews, and customers."""

from __future__ import annotations

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
    Reply,
    Review,
    Sentiment,
    User,
    UserRole,
)
from app.services.business_service import update_business_rating
from app.services.mfa import enable_demo_totp

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession

CHENNAI_CUSTOMER_PASSWORD = "demo12345abc"

# Kept in PENDING status (never force-approved on refresh) to demonstrate the admin
# approval queue without needing a separate business just for that purpose.
_PENDING_SLUG = "sunshine-cafe-radha-nagar"

# Chrompet corridor anchor (~12.95°N, 80.14°E) with small per-business jitter.
_CHENNAI_BASE_LAT = 12.9516
_CHENNAI_BASE_LNG = 80.1412

_CHENNAI_BUSINESSES: list[dict] = [
    {
        "name": "Saravana Bhavan Chrompet",
        "slug": "saravana-bhavan-chrompet",
        "category": "restaurant",
        "address": "12 GST Road, Chrompet",
        "postal_code": "600044",
        "description": "South Indian vegetarian meals and tiffin counter near Chrompet bus stand.",
        "phone": "+91-44-2223-1101",
        "jitter": (0.0012, -0.0008),
    },
    {
        "name": "Krishna Sweets & Snacks",
        "slug": "krishna-sweets-chrompet",
        "category": "grocery",
        "address": "45 Radha Nagar Main Road, Chrompet",
        "postal_code": "600044",
        "description": "Fresh sweets, savouries, and festival snack boxes.",
        "phone": "+91-44-2223-2202",
        "jitter": (-0.0009, 0.0011),
    },
    {
        "name": "Radha Nagar Medical Store",
        "slug": "radha-nagar-medical-store",
        "category": "pharmacy",
        "address": "8 Radha Nagar 2nd Cross, Chrompet",
        "postal_code": "600044",
        "description": "Neighborhood pharmacy with OTC medicines and basic health supplies.",
        "phone": "+91-44-2223-3303",
        "jitter": (0.0005, 0.0004),
    },
    {
        "name": "Lakshmi Hair Studio",
        "slug": "lakshmi-hair-studio-chrompet",
        "category": "salon",
        "address": "22 Radha Nagar 1st Main, Chrompet",
        "postal_code": "600044",
        "description": "Unisex salon for cuts, colouring, and bridal styling.",
        "phone": "+91-44-2223-4404",
        "jitter": (-0.0014, -0.0006),
    },
    {
        "name": "Murugan Coffee Bar",
        "slug": "murugan-coffee-bar",
        "category": "cafe",
        "address": "3 Chrompet High Road, Chrompet",
        "postal_code": "600044",
        "description": "Filter coffee, bun butter jam, and evening tea snacks.",
        "phone": "+91-44-2223-5505",
        "jitter": (0.0008, -0.0012),
    },
    {
        "name": "Chrompet Fresh Mart",
        "slug": "chrompet-fresh-mart",
        "category": "grocery",
        "address": "67 GST Road, Chrompet",
        "postal_code": "600044",
        "description": "Daily vegetables, staples, and household essentials.",
        "phone": "+91-44-2223-6606",
        "jitter": (-0.0004, 0.0015),
    },
    {
        "name": "Anna Pharmacy",
        "slug": "anna-pharmacy-chrompet",
        "category": "pharmacy",
        "address": "14 Radha Nagar 3rd Cross, Chrompet",
        "postal_code": "600044",
        "description": "Prescription dispensing and home delivery within Chrompet.",
        "phone": "+91-44-2223-7707",
        "jitter": (0.0016, 0.0002),
    },
    {
        "name": "Sree Anandha Bhavan",
        "slug": "sree-anandha-bhavan-chrompet",
        "category": "restaurant",
        "address": "29 Radha Nagar Main Road, Chrompet",
        "postal_code": "600044",
        "description": "Budget meals, dosas, and parcel orders for office lunch.",
        "phone": "+91-44-2223-8808",
        "jitter": (-0.0011, -0.0010),
    },
    {
        "name": "Style Zone Salon",
        "slug": "style-zone-salon-radha-nagar",
        "category": "salon",
        "address": "5 Radha Nagar 4th Cross, Chrompet",
        "postal_code": "600044",
        "description": "Kids and adult haircuts with walk-in availability most evenings.",
        "phone": "+91-44-2223-9909",
        "jitter": (0.0003, -0.0005),
    },
    {
        "name": "Radha Nagar Tea Stall",
        "slug": "radha-nagar-tea-stall",
        "category": "cafe",
        "address": "1 Radha Nagar Bus Stop, Chrompet",
        "postal_code": "600044",
        "description": "Strong tea, vadai, and quick breakfast before the commute.",
        "phone": "+91-44-2223-1010",
        "jitter": (-0.0007, 0.0009),
    },
    {
        "name": "Chennai Biryani House",
        "slug": "chennai-biryani-house-chrompet",
        "category": "restaurant",
        "address": "88 GST Road, Chrompet",
        "postal_code": "600044",
        "description": "Chicken and mutton biryani with evening parcel service.",
        "phone": "+91-44-2223-1111",
        "jitter": (0.0010, 0.0013),
    },
    {
        "name": "Ganesh Provision Store",
        "slug": "ganesh-provision-store",
        "category": "grocery",
        "address": "33 Radha Nagar 2nd Main, Chrompet",
        "postal_code": "600044",
        "description": "Rice, dal, oil, and monthly ration packs for local families.",
        "phone": "+91-44-2223-1212",
        "jitter": (-0.0013, 0.0006),
    },
    {
        "name": "Metro Electronics & Mobile",
        "slug": "metro-electronics-chrompet",
        "category": "grocery",
        "address": "51 Chrompet High Road, Chrompet",
        "postal_code": "600044",
        "description": "Mobile accessories, chargers, and small appliance repairs.",
        "phone": "+91-44-2223-1313",
        "jitter": (0.0006, -0.0003),
    },
    {
        "name": "Priya Boutique",
        "slug": "priya-boutique-radha-nagar",
        "category": "salon",
        "address": "19 Radha Nagar 1st Cross, Chrompet",
        "postal_code": "600044",
        "description": "Cotton sarees, churidars, and alteration service.",
        "phone": "+91-44-2223-1414",
        "jitter": (-0.0002, -0.0014),
    },
    {
        "name": "Nataraja Bakery",
        "slug": "nataraja-bakery-chrompet",
        "category": "cafe",
        "address": "76 Radha Nagar Main Road, Chrompet",
        "postal_code": "600044",
        "description": "Fresh bread, puffs, and birthday cakes to order.",
        "phone": "+91-44-2223-1515",
        "jitter": (0.0014, 0.0007),
    },
    {
        "name": "Royal Spice Restaurant",
        "slug": "royal-spice-restaurant",
        "category": "restaurant",
        "address": "102 GST Road, Chrompet",
        "postal_code": "600044",
        "description": "North Indian and Chettinad dishes for family dining.",
        "phone": "+91-44-2223-1616",
        "jitter": (-0.0010, 0.0010),
    },
    {
        "name": "Green Leaf Organic Store",
        "slug": "green-leaf-organic-chrompet",
        "category": "grocery",
        "address": "41 Radha Nagar 3rd Main, Chrompet",
        "postal_code": "600044",
        "description": "Organic vegetables, millets, and chemical-free staples.",
        "phone": "+91-44-2223-1717",
        "jitter": (0.0009, -0.0009),
    },
    {
        "name": "Chrompet Dental Care",
        "slug": "chrompet-dental-care",
        "category": "pharmacy",
        "address": "60 Chrompet High Road, Chrompet",
        "postal_code": "600044",
        "description": "General dentistry, cleaning, and basic orthodontic consults.",
        "phone": "+91-44-2223-1818",
        "jitter": (-0.0006, -0.0004),
    },
    {
        "name": "Vel Murugan Tiffin Centre",
        "slug": "vel-murugan-tiffin-centre",
        "category": "restaurant",
        "address": "24 Radha Nagar 4th Main, Chrompet",
        "postal_code": "600044",
        "description": "Morning idli-vada and evening dosa counter.",
        "phone": "+91-44-2223-1919",
        "jitter": (0.0004, 0.0012),
    },
    {
        "name": "Sunshine Café Radha Nagar",
        "slug": "sunshine-cafe-radha-nagar",
        "category": "cafe",
        "address": "9 Radha Nagar 2nd Cross, Chrompet",
        "postal_code": "600044",
        "description": "Cold coffee, sandwiches, and study-friendly seating.",
        "phone": "+91-44-2223-2020",
        "jitter": (-0.0015, 0.0001),
    },
]

# Hand-authored synthetic reviews per business slug (1 each — enough to exercise the
# review + AI-analysis + photo-upload pipeline per business without duplicate noise).
_CHENNAI_REVIEWS: dict[str, list[dict]] = {
    "saravana-bhavan-chrompet": [
        {"rating": 5, "title": "Consistently good meals", "body": "The mini meals are filling and the sambar tastes fresh every visit."},
    ],
    "krishna-sweets-chrompet": [
        {"rating": 5, "title": "Fresh mysore pak", "body": "Sweets are made daily and the cashew burfi melts in your mouth."},
    ],
    "radha-nagar-medical-store": [
        {"rating": 4, "title": "Helpful pharmacist", "body": "They explained dosage clearly and had the generic option in stock."},
    ],
    "lakshmi-hair-studio-chrompet": [
        {"rating": 5, "title": "Great trim", "body": "Stylist listened to what I wanted and the layered cut looks natural."},
    ],
    "murugan-coffee-bar": [
        {"rating": 5, "title": "Best filter coffee", "body": "Strong decoction and they serve it piping hot even at 6 AM."},
    ],
    "chrompet-fresh-mart": [
        {"rating": 4, "title": "Fresh vegetables", "body": "Morning produce looks good and they weigh accurately at the counter."},
    ],
    "anna-pharmacy-chrompet": [
        {"rating": 4, "title": "Home delivery works", "body": "Ordered medicines for my parents and delivery reached Radha Nagar same day."},
    ],
    "sree-anandha-bhavan-chrompet": [
        {"rating": 4, "title": "Value meals", "body": "Thali price is fair and they refill rice once without fuss."},
    ],
    "style-zone-salon-radha-nagar": [
        {"rating": 4, "title": "Kids cut done well", "body": "They were patient with my son and the fade looks neat."},
    ],
    "radha-nagar-tea-stall": [
        {"rating": 5, "title": "Perfect morning tea", "body": "Strong tea and hot vadai before the bus to Tambaram."},
    ],
    "chennai-biryani-house-chrompet": [
        {"rating": 5, "title": "Flavorful biryani", "body": "Chicken pieces were tender and the rice had a nice aroma."},
    ],
    "ganesh-provision-store": [
        {"rating": 4, "title": "Monthly ration easy", "body": "They keep our usual rice and dal brands in stock."},
    ],
    "metro-electronics-chrompet": [
        {"rating": 4, "title": "Fixed my charging port", "body": "Phone charging issue resolved same day at a fair repair quote."},
    ],
    "priya-boutique-radha-nagar": [
        {"rating": 5, "title": "Beautiful saree drape", "body": "Staff helped pick a cotton saree and altered the blouse in two days."},
    ],
    "nataraja-bakery-chrompet": [
        {"rating": 5, "title": "Fresh puffs", "body": "Vegetable puff straight from the oven in the evening is excellent."},
    ],
    "royal-spice-restaurant": [
        {"rating": 4, "title": "Family dinner spot", "body": "Naan and paneer butter masala were crowd pleasers for our group."},
    ],
    "green-leaf-organic-chrompet": [
        {"rating": 5, "title": "Good organic greens", "body": "Spinach and greens looked fresh with clear sourcing labels."},
    ],
    "chrompet-dental-care": [
        {"rating": 4, "title": "Gentle cleaning", "body": "Hygienist explained each step and the scaling was not painful."},
    ],
    "vel-murugan-tiffin-centre": [
        {"rating": 5, "title": "Soft idlis", "body": "Morning idli plate with chutney and sambar is consistently good."},
    ],
    "sunshine-cafe-radha-nagar": [
        {"rating": 4, "title": "Nice cold coffee", "body": "Frappe was balanced and not overly sweet."},
    ],
}

_SENTIMENT_FOR_RATING = {
    5: Sentiment.POSITIVE,
    4: Sentiment.POSITIVE,
    3: Sentiment.NEUTRAL,
    2: Sentiment.NEGATIVE,
    1: Sentiment.NEGATIVE,
}

# Freely hotlinkable Unsplash photos (stock) — category-themed so listings look like a local map directory.
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
    "pharmacy": [
        "https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1587854692159-eb1d381c3c48?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=1200&h=800&q=80",
    ],
    "grocery": [
        "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1604719312566-8912e9227c6a?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&w=1200&h=800&q=80",
        "https://images.unsplash.com/photo-1534723452862-4c874018d66d?auto=format&fit=crop&w=1200&h=800&q=80",
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
    "pharmacy": [
        "https://images.unsplash.com/photo-1585435557343-3b092031a831?auto=format&fit=crop&w=800&h=600&q=80",
        "https://images.unsplash.com/photo-1471864190281-a93a3070b6de?auto=format&fit=crop&w=800&h=600&q=80",
    ],
    "grocery": [
        "https://images.unsplash.com/photo-1604719312566-8912e9227c6a?auto=format&fit=crop&w=800&h=600&q=80",
        "https://images.unsplash.com/photo-1610348725531-843dff563e2c?auto=format&fit=crop&w=800&h=600&q=80",
    ],
}


def _pick(pool: list[str], key: str, offset: int = 0) -> str:
    return pool[(sum(ord(c) for c in key) + offset) % len(pool)]


def _storefront_url(category: str, slug: str) -> str:
    return _pick(_CATEGORY_STOREFRONTS.get(category, _CATEGORY_STOREFRONTS["restaurant"]), slug)


def _logo_url(category: str, slug: str) -> str:
    # Smaller crop of a related storefront for card thumbnails.
    base = _pick(_CATEGORY_STOREFRONTS.get(category, _CATEGORY_STOREFRONTS["restaurant"]), slug, offset=1)
    return base.replace("w=1200&h=800", "w=400&h=400")


def _gallery_urls(category: str, slug: str) -> list[str]:
    pool = _CATEGORY_GALLERY.get(category, _CATEGORY_GALLERY["restaurant"])
    return [_pick(pool, slug, offset=i) for i in range(min(3, len(pool)))]


async def seed_chennai(
    db: AsyncSession,
    merchant: Merchant,
    categories: list[Category],
) -> dict[str, int]:
    """Upsert Chrompet / Radha Nagar demo data (safe to re-run). Caller must commit."""
    category_by_slug = {c.slug: c for c in categories}

    existing_customers = (
        await db.execute(select(User).where(User.email.like("demo.customer%@example.com")))
    ).scalars().all()
    customers: list[User] = list(existing_customers)

    target_customers = 2
    for n in range(len(customers) + 1, target_customers + 1):
        customer = User(
            email=f"demo.customer{n}@example.com",
            full_name=f"Demo Customer {n}",
            hashed_password=get_password_hash(CHENNAI_CUSTOMER_PASSWORD),
            role=UserRole.CUSTOMER,
        )
        enable_demo_totp(customer)
        db.add(customer)
        customers.append(customer)
    for customer in customers:
        customer.hashed_password = get_password_hash(CHENNAI_CUSTOMER_PASSWORD)
        if not customer.totp_enabled:
            enable_demo_totp(customer)
    await db.flush()

    existing_by_slug = {
        b.slug: b
        for b in (
            await db.execute(select(Business).where(Business.city == "Chennai"))
        ).scalars().all()
    }

    business_count = 0
    review_count = 0
    created = 0
    refreshed = 0

    for idx, spec in enumerate(_CHENNAI_BUSINESSES):
        lat_j, lng_j = spec["jitter"]
        slug = spec["slug"]
        category = spec["category"]
        storefront = _storefront_url(category, slug)
        logo = _logo_url(category, slug)

        business = existing_by_slug.get(slug)
        if business is None:
            business = Business(
                merchant_id=merchant.id,
                name=spec["name"],
                slug=slug,
                description=spec["description"],
                address=spec["address"],
                city="Chennai",
                state="TN",
                postal_code=spec["postal_code"],
                country="IN",
                latitude=_CHENNAI_BASE_LAT + lat_j,
                longitude=_CHENNAI_BASE_LNG + lng_j,
                phone=spec["phone"],
                email=f"hello@{slug}.example",
                logo_url=logo,
                storefront_url=storefront,
                business_hours={"mon-sat": "9am-9pm", "sun": "10am-8pm"},
                status=BusinessStatus.PENDING if slug == _PENDING_SLUG else BusinessStatus.APPROVED,
            )
            db.add(business)
            await db.flush()
            created += 1

            cat = category_by_slug.get(category)
            if cat:
                db.add(BusinessCategory(business_id=business.id, category_id=cat.id))
        else:
            business.name = spec["name"]
            business.description = spec["description"]
            business.address = spec["address"]
            business.postal_code = spec["postal_code"]
            business.latitude = _CHENNAI_BASE_LAT + lat_j
            business.longitude = _CHENNAI_BASE_LNG + lng_j
            business.phone = spec["phone"]
            business.logo_url = logo
            business.storefront_url = storefront
            if slug != _PENDING_SLUG:
                business.status = BusinessStatus.APPROVED
            refreshed += 1

        business_count += 1

        # Replace gallery photos with fresh stock URLs so re-seed upgrades picsum → Unsplash.
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
                    uploaded_by=customers[idx % len(customers)].id,
                    url=url,
                    caption="Storefront" if g_idx == 0 else f"Inside / product {g_idx}",
                    photo_type="storefront" if g_idx == 0 else "gallery",
                )
            )

        existing_review_authors = {
            row[0]
            for row in (
                await db.execute(select(Review.author_id).where(Review.business_id == business.id))
            ).all()
        }

        reviews_for_business = _CHENNAI_REVIEWS.get(slug, [])
        for r_idx, review_spec in enumerate(reviews_for_business):
            author = customers[(idx + r_idx) % len(customers)]
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

            # Attach a food/shop photo to every other review for a Maps-like feed.
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

            # One merchant reply, on the very first seeded review, to demonstrate
            # the merchant-responds-to-review flow without replying to every review.
            if slug == _CHENNAI_BUSINESSES[0]["slug"] and r_idx == 0:
                existing_reply = (
                    await db.execute(select(Reply).where(Reply.review_id == review.id))
                ).scalar_one_or_none()
                if existing_reply is None:
                    db.add(
                        Reply(
                            review_id=review.id,
                            merchant_id=merchant.id,
                            body="Thank you for the kind words — glad you enjoyed it!",
                        )
                    )

        await update_business_rating(db, business.id)

    return {
        "businesses": business_count,
        "reviews": review_count,
        "customers": len(customers),
        "created": created,
        "refreshed": refreshed,
    }
