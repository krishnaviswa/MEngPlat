"""Shared geospatial helpers for search and maps."""

import math

import httpx

NOMINATIM_SEARCH_URL = "https://nominatim.openstreetmap.org/search"


def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Great-circle distance in kilometres between two WGS-84 points."""
    r = 6371.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def bounding_box(lat: float, lng: float, radius_km: float) -> tuple[float, float, float, float]:
    """Approximate lat/lng bounds for a circle (min_lat, max_lat, min_lng, max_lng)."""
    delta_lat = radius_km / 111.0
    cos_lat = max(math.cos(math.radians(lat)), 0.01)
    delta_lng = radius_km / (111.0 * cos_lat)
    return lat - delta_lat, lat + delta_lat, lng - delta_lng, lng + delta_lng


async def search_addresses(query: str, user_agent: str, limit: int = 5) -> list[dict]:
    """
    Live address suggestions via Nominatim (S-073/ADR-014) -- same provider as
    the existing single-result geocode, but with addressdetails so city/postal
    code can be pre-filled without a second lookup. Returns [] on no results or
    provider failure (AC8 fallback to manual entry, no dead end).
    """
    query = query.strip()
    if not query:
        return []

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                NOMINATIM_SEARCH_URL,
                params={"q": query, "format": "json", "limit": limit, "addressdetails": 1},
                headers={"User-Agent": user_agent},
            )
            response.raise_for_status()
            results = response.json()
    except httpx.HTTPError:
        return []

    suggestions = []
    for hit in results:
        addr = hit.get("address", {})
        suggestions.append(
            {
                "display_name": hit.get("display_name", ""),
                "latitude": float(hit["lat"]),
                "longitude": float(hit["lon"]),
                "city": addr.get("city") or addr.get("town") or addr.get("village"),
                "postal_code": addr.get("postcode"),
                "state": addr.get("state"),
            }
        )
    return suggestions
