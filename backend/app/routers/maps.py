import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.config import get_settings
from app.database import get_db
from app.models import Business, BusinessCategory, BusinessStatus
from app.routers.businesses import _to_response
from app.schemas import AddressSuggestion, BusinessResponse, GeocodeResponse, NearbyBusinessRequest
from app.services.geo import bounding_box, haversine_km, search_addresses

router = APIRouter(prefix="/maps", tags=["Maps"])
settings = get_settings()

NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"
NOMINATIM_USER_AGENT = f"MerchantHubAI/{settings.app_version} (local-dev)"


async def _approved_businesses_in_radius(
    db: AsyncSession,
    lat: float,
    lng: float,
    radius_km: float,
) -> list[Business]:
    min_lat, max_lat, min_lng, max_lng = bounding_box(lat, lng, radius_km)
    query = (
        select(Business)
        .options(selectinload(Business.categories).selectinload(BusinessCategory.category))
        .where(
            Business.status == BusinessStatus.APPROVED,
            Business.latitude.isnot(None),
            Business.longitude.isnot(None),
            Business.latitude >= min_lat,
            Business.latitude <= max_lat,
            Business.longitude >= min_lng,
            Business.longitude <= max_lng,
        )
    )
    result = await db.execute(query)
    candidates = result.scalars().unique().all()
    nearby = [
        b
        for b in candidates
        if b.latitude is not None
        and b.longitude is not None
        and haversine_km(lat, lng, b.latitude, b.longitude) <= radius_km
    ]
    nearby.sort(key=lambda b: haversine_km(lat, lng, b.latitude, b.longitude))  # type: ignore[arg-type]
    return nearby


@router.post("/nearby", response_model=list[BusinessResponse])
async def nearby_businesses(
    payload: NearbyBusinessRequest,
    db: AsyncSession = Depends(get_db),
) -> list[BusinessResponse]:
    """
    Approved businesses within radius of a point (OpenStreetMap / Haversine).

    **Request:** lat, lng, radius_km
    **Response:** Businesses sorted by distance
    """
    businesses = await _approved_businesses_in_radius(db, payload.lat, payload.lng, payload.radius_km)
    return [_to_response(b) for b in businesses]


@router.get("/geocode", response_model=GeocodeResponse)
async def geocode_address(address: str) -> GeocodeResponse:
    """
    Geocode an address via Nominatim (OpenStreetMap).

    **Query:** address
    **Response:** lat/lng when found; message explains failures
    """
    address = address.strip()
    if not address:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Address is required")

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                NOMINATIM_URL,
                params={"q": address, "format": "json", "limit": 1},
                headers={"User-Agent": NOMINATIM_USER_AGENT},
            )
            response.raise_for_status()
            results = response.json()
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Geocoding service unavailable",
        ) from exc

    if not results:
        return GeocodeResponse(message=f"No results for '{address}'")

    hit = results[0]
    lat = float(hit["lat"])
    lng = float(hit["lon"])
    display_name = hit.get("display_name")
    return GeocodeResponse(
        message="OK",
        latitude=lat,
        longitude=lng,
        display_name=display_name,
    )


@router.get("/autocomplete", response_model=list[AddressSuggestion])
async def autocomplete_address(q: str) -> list[AddressSuggestion]:
    """
    Live address suggestions via Nominatim (S-073). Up to 5 results with
    city/postal code parsed out; [] when none (client falls back to manual
    entry / the "Look up address" button, never a dead end).
    """
    suggestions = await search_addresses(q, NOMINATIM_USER_AGENT)
    return [AddressSuggestion(**s) for s in suggestions]


@router.get("/config", response_model=dict)
async def maps_config() -> dict:
    """Return public maps configuration for frontend."""
    return {
        "provider": "osm",
        "api_key_configured": False,
        "placeholder": False,
        "tile_url": "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
        "attribution": '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }
