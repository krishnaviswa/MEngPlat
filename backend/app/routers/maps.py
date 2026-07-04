from fastapi import APIRouter

from app.config import get_settings
from app.schemas import BusinessResponse, MessageResponse, NearbyBusinessRequest

router = APIRouter(prefix="/maps", tags=["Maps"])
settings = get_settings()


@router.post("/nearby", response_model=list[BusinessResponse])
async def nearby_businesses(payload: NearbyBusinessRequest) -> list[BusinessResponse]:
    """
    Google Maps nearby search placeholder.

    **Request:** lat, lng, radius_km
    **Response:** Empty list with message to use /search/businesses?lat=&lng= instead

    In production, integrate Google Places API or proxy to /search/businesses.
    """
    return []


@router.get("/geocode", response_model=MessageResponse)
async def geocode_address(address: str) -> MessageResponse:
    """
    Geocode an address to lat/lng — placeholder.

    **Query:** address
    **Response:** Placeholder message

    Set GOOGLE_MAPS_API_KEY and implement Google Geocoding API in production.
    """
    if settings.google_maps_api_key == "placeholder":
        return MessageResponse(
            message=f"Maps placeholder: would geocode '{address}'. Configure GOOGLE_MAPS_API_KEY."
        )
    return MessageResponse(message="Geocoding not yet implemented")


@router.get("/config", response_model=dict)
async def maps_config() -> dict:
    """Return public maps configuration for frontend."""
    return {
        "provider": "google_maps",
        "api_key_configured": settings.google_maps_api_key != "placeholder",
        "placeholder": True,
    }
