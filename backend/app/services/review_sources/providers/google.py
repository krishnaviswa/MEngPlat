"""Real Google Places provider -- Text Search (search) + Place Details (reviews).

`httpx` calls, same `httpx.AsyncClient(timeout=...)` + `httpx.HTTPError` -> readable-
error pattern already used in `app/routers/maps.py`'s `geocode_address`. Callers
(review_sync_service) wrap any raised exception into a readable 502 -- this module
never talks to FastAPI/HTTPException directly.
"""

from __future__ import annotations

from datetime import UTC, datetime

import httpx

from app.config import get_settings
from app.services.review_sources.base import (
    ExternalReviewResult,
    PlaceCandidate,
    ReviewSourceProvider,
)
from app.services.review_sources.registry import register_provider

TEXT_SEARCH_URL = "https://maps.googleapis.com/maps/api/place/textsearch/json"
PLACE_DETAILS_URL = "https://maps.googleapis.com/maps/api/place/details/json"


@register_provider("google")
class GooglePlacesProvider(ReviewSourceProvider):
    provider_name = "google"

    def __init__(self) -> None:
        self.api_key = get_settings().google_places_api_key

    async def search_places(
        self, query: str, lat: float | None, lng: float | None
    ) -> list[PlaceCandidate]:
        params: dict[str, str] = {"query": query, "key": self.api_key}
        if lat is not None and lng is not None:
            # Location/radius bias only -- Text Search still searches globally,
            # this just ranks nearby results higher.
            params["location"] = f"{lat},{lng}"
            params["radius"] = "5000"

        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(TEXT_SEARCH_URL, params=params)
            response.raise_for_status()
            data = response.json()

        candidates: list[PlaceCandidate] = []
        for result in data.get("results", []):
            location = result.get("geometry", {}).get("location", {})
            if "lat" not in location or "lng" not in location:
                continue
            candidates.append(
                PlaceCandidate(
                    place_id=result["place_id"],
                    name=result.get("name", ""),
                    address=result.get("formatted_address", ""),
                    latitude=float(location["lat"]),
                    longitude=float(location["lng"]),
                )
            )
        return candidates

    async def fetch_reviews(self, place_id: str) -> list[ExternalReviewResult]:
        params = {"place_id": place_id, "fields": "name,url,reviews", "key": self.api_key}
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(PLACE_DETAILS_URL, params=params)
            response.raise_for_status()
            data = response.json()

        place_result = data.get("result", {})
        place_url = place_result.get("url")
        reviews = place_result.get("reviews", [])

        results: list[ExternalReviewResult] = []
        for review in reviews:
            # Google's Places API does not return a stable per-review ID --
            # `time` (Google's Unix timestamp of the review) plus author name
            # is the most stable available composite key.
            review_time = review.get("time")
            author_name = review.get("author_name", "")
            posted_at = datetime.fromtimestamp(review_time, tz=UTC) if review_time is not None else None
            results.append(
                ExternalReviewResult(
                    external_review_id=f"{review_time}:{author_name}",
                    author_name=author_name,
                    author_photo_url=review.get("profile_photo_url"),
                    rating=int(review.get("rating") or 0),
                    body=review.get("text") or None,
                    language=review.get("language"),
                    external_posted_at=posted_at,
                    source_url=place_url,
                    raw_response=review,
                )
            )
        return results
