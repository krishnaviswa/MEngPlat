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
    Review,
    Sentiment,
    User,
    UserRole,
)
from app.services.business_service import update_business_rating

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession

CHENNAI_CUSTOMER_PASSWORD = "demo12345"

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

# Hand-authored synthetic reviews per business slug (3–5 each, varied sentiment).
_CHENNAI_REVIEWS: dict[str, list[dict]] = {
    "saravana-bhavan-chrompet": [
        {"rating": 5, "title": "Consistently good meals", "body": "The mini meals are filling and the sambar tastes fresh every visit."},
        {"rating": 4, "title": "Busy but worth it", "body": "Queue moves quickly even on weekends. Filter coffee after lunch is a nice touch."},
        {"rating": 3, "title": "Crowded at peak hours", "body": "Food quality is fine but seating is tight during the lunch rush near Chrompet."},
        {"rating": 5, "title": "Reliable vegetarian spot", "body": "We order parcels for office lunch often and portions are always generous."},
    ],
    "krishna-sweets-chrompet": [
        {"rating": 5, "title": "Fresh mysore pak", "body": "Sweets are made daily and the cashew burfi melts in your mouth."},
        {"rating": 4, "title": "Good festival orders", "body": "Placed a Diwali mix box last year and everything arrived neatly packed."},
        {"rating": 4, "title": "Nice evening snacks", "body": "Murukku and mixture are crisp. Staff helped pick a combo for guests."},
    ],
    "radha-nagar-medical-store": [
        {"rating": 4, "title": "Helpful pharmacist", "body": "They explained dosage clearly and had the generic option in stock."},
        {"rating": 5, "title": "Quick service", "body": "Walked in with a prescription and was out in ten minutes."},
        {"rating": 3, "title": "Limited parking", "body": "Medicines were available but finding a spot on the narrow lane took time."},
        {"rating": 4, "title": "Fair prices", "body": "Basic OTC items are priced reasonably compared to bigger chains."},
    ],
    "lakshmi-hair-studio-chrompet": [
        {"rating": 5, "title": "Great trim", "body": "Stylist listened to what I wanted and the layered cut looks natural."},
        {"rating": 4, "title": "Clean salon", "body": "Tools looked sanitized and the waiting area is comfortable."},
        {"rating": 4, "title": "Bridal trial went well", "body": "They did a trial bun and flowers arrangement ahead of our function."},
    ],
    "murugan-coffee-bar": [
        {"rating": 5, "title": "Best filter coffee", "body": "Strong decoction and they serve it piping hot even at 6 AM."},
        {"rating": 4, "title": "Classic bun butter", "body": "Simple menu but everything tastes fresh. Good stop before the train."},
        {"rating": 5, "title": "Friendly owner", "body": "Remembers regular orders and the vadai is crispy when it is hot."},
        {"rating": 3, "title": "Small seating", "body": "Coffee is excellent but only a few chairs inside."},
    ],
    "chrompet-fresh-mart": [
        {"rating": 4, "title": "Fresh vegetables", "body": "Morning produce looks good and they weigh accurately at the counter."},
        {"rating": 4, "title": "Convenient location", "body": "Easy to pick up staples on the way back from GST Road."},
        {"rating": 3, "title": "Billing queue", "body": "Quality is fine but checkout can slow down after office hours."},
        {"rating": 5, "title": "Good monthly packs", "body": "They assembled a ration bundle with brands we requested."},
    ],
    "anna-pharmacy-chrompet": [
        {"rating": 4, "title": "Home delivery works", "body": "Ordered medicines for my parents and delivery reached Radha Nagar same day."},
        {"rating": 5, "title": "Stocked well", "body": "Found the inhaler refill without visiting multiple shops."},
        {"rating": 3, "title": "Wait on phone orders", "body": "Had to call twice to confirm availability but pickup was smooth."},
    ],
    "sree-anandha-bhavan-chrompet": [
        {"rating": 4, "title": "Value meals", "body": "Thali price is fair and they refill rice once without fuss."},
        {"rating": 5, "title": "Crispy dosas", "body": "Paper roast dosa was thin and served with flavorful chutney."},
        {"rating": 4, "title": "Quick parcels", "body": "Office parcel boxes are packed tight and do not leak."},
        {"rating": 3, "title": "Noisy at noon", "body": "Food is good but the dining hall gets loud when schools break for lunch."},
    ],
    "style-zone-salon-radha-nagar": [
        {"rating": 4, "title": "Kids cut done well", "body": "They were patient with my son and the fade looks neat."},
        {"rating": 5, "title": "Walk-in friendly", "body": "Got a slot within twenty minutes on a weekday evening."},
        {"rating": 4, "title": "Reasonable rates", "body": "Basic cut price is lower than malls and quality matched expectations."},
    ],
    "radha-nagar-tea-stall": [
        {"rating": 5, "title": "Perfect morning tea", "body": "Strong tea and hot vadai before the bus to Tambaram."},
        {"rating": 4, "title": "Reliable stop", "body": "Open early and the owner keeps the counter clean."},
        {"rating": 4, "title": "Good value", "body": "Two teas and a snack for less than a café chain charges."},
    ],
    "chennai-biryani-house-chrompet": [
        {"rating": 5, "title": "Flavorful biryani", "body": "Chicken pieces were tender and the rice had a nice aroma."},
        {"rating": 4, "title": "Large portions", "body": "Single serving was enough for two light eaters."},
        {"rating": 3, "title": "Spicy for some", "body": "Taste is authentic Chettinad heat; ask for mild if you prefer less spice."},
        {"rating": 5, "title": "Late parcel service", "body": "Ordered after 9 PM and the parcel was still hot at home."},
    ],
    "ganesh-provision-store": [
        {"rating": 4, "title": "Monthly ration easy", "body": "They keep our usual rice and dal brands in stock."},
        {"rating": 4, "title": "Credit for regulars", "body": "Neighborhood shop trust — settle at month end as promised."},
        {"rating": 5, "title": "Home delivery", "body": "Heavy bags delivered to our flat without extra charge nearby."},
    ],
    "metro-electronics-chrompet": [
        {"rating": 4, "title": "Fixed my charging port", "body": "Phone charging issue resolved same day at a fair repair quote."},
        {"rating": 3, "title": "Accessory selection", "body": "Covers available for popular models but fewer options for older phones."},
        {"rating": 4, "title": "Honest advice", "body": "Suggested a cable instead of pushing a costly replacement."},
    ],
    "priya-boutique-radha-nagar": [
        {"rating": 5, "title": "Beautiful saree drape", "body": "Staff helped pick a cotton saree and altered the blouse in two days."},
        {"rating": 4, "title": "Good collection", "body": "Decent range for daily wear at prices suited to the neighborhood."},
        {"rating": 4, "title": "Alterations on time", "body": "Churidar stitching finished before the promised date."},
    ],
    "nataraja-bakery-chrompet": [
        {"rating": 5, "title": "Fresh puffs", "body": "Vegetable puff straight from the oven in the evening is excellent."},
        {"rating": 4, "title": "Birthday cake", "body": "Ordered a small chocolate cake and writing matched our note."},
        {"rating": 4, "title": "Morning bread", "body": "Milk bread is soft and stays fresh through the next morning."},
    ],
    "royal-spice-restaurant": [
        {"rating": 4, "title": "Family dinner spot", "body": "Naan and paneer butter masala were crowd pleasers for our group."},
        {"rating": 5, "title": "Chettinad chicken", "body": "Spicy and flavorful — one of the better versions on GST Road."},
        {"rating": 3, "title": "Service delay", "body": "Food quality good but mains arrived ten minutes apart."},
        {"rating": 4, "title": "Clean dining room", "body": "Tables wiped promptly and air conditioning worked well."},
    ],
    "green-leaf-organic-chrompet": [
        {"rating": 5, "title": "Good organic greens", "body": "Spinach and greens looked fresh with clear sourcing labels."},
        {"rating": 4, "title": "Millet selection", "body": "Found foxtail and kodo millet packs not available at regular stores."},
        {"rating": 4, "title": "Premium but worth it", "body": "Prices are higher than market but quality matches for organic."},
    ],
    "chrompet-dental-care": [
        {"rating": 4, "title": "Gentle cleaning", "body": "Hygienist explained each step and the scaling was not painful."},
        {"rating": 5, "title": "Clear billing", "body": "Estimate shared before treatment with no surprise add-ons."},
        {"rating": 3, "title": "Appointment wait", "body": "Walk-in took forty minutes but the consult itself was thorough."},
    ],
    "vel-murugan-tiffin-centre": [
        {"rating": 5, "title": "Soft idlis", "body": "Morning idli plate with chutney and sambar is consistently good."},
        {"rating": 4, "title": "Quick breakfast", "body": "In and out in fifteen minutes before work."},
        {"rating": 4, "title": "Crisp vada", "body": "Medhu vada was hot and not oily."},
        {"rating": 3, "title": "Limited menu", "body": "Few items after 10 AM but what they serve is tasty."},
    ],
    "sunshine-cafe-radha-nagar": [
        {"rating": 4, "title": "Nice cold coffee", "body": "Frappe was balanced and not overly sweet."},
        {"rating": 5, "title": "Study friendly", "body": "Quiet corner tables and Wi‑Fi worked fine for an hour of work."},
        {"rating": 4, "title": "Good sandwiches", "body": "Grilled veg sandwich portion was filling for the price."},
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

    target_customers = 10
    for n in range(len(customers) + 1, target_customers + 1):
        customer = User(
            email=f"demo.customer{n}@example.com",
            full_name=f"Demo Customer {n}",
            hashed_password=get_password_hash(CHENNAI_CUSTOMER_PASSWORD),
            role=UserRole.CUSTOMER,
        )
        db.add(customer)
        customers.append(customer)
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
                status=BusinessStatus.APPROVED,
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

        await update_business_rating(db, business.id)

    return {
        "businesses": business_count,
        "reviews": review_count,
        "customers": len(customers),
        "created": created,
        "refreshed": refreshed,
    }
