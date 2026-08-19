from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.models import Business, BusinessCategory, BusinessStatus
from app.routers.businesses import _to_response
from app.schemas import BusinessResponse, NearbyBusinessRequest
from app.services.geo import bounding_box, haversine_km

router = APIRouter(prefix="/maps", tags=["Maps"])


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
