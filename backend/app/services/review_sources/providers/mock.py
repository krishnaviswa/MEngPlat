"""Deterministic provider for local development, tests, and CI (AC16).

No network, no API key. `search_places` always returns the same two fixed
candidates and `fetch_reviews` always returns the same three fixed reviews,
so re-sync is naturally idempotent in tests without extra fixture wiring
(mirrors `MockAIProvider`'s determinism).
"""

from datetime import UTC, datetime

from app.services.review_sources.base import (
    ExternalReviewResult,
    PlaceCandidate,
    ReviewSourceProvider,
)
from app.services.review_sources.registry import register_provider

# Default center used when the business has no stored lat/lng: Bengaluru, India.
_DEFAULT_LAT = 12.9716
_DEFAULT_LNG = 77.5946

# ~1 degree of latitude is ~111,320 meters; used to offset demo candidates a
# small, deterministic distance from the business (or default center).
_METERS_PER_DEGREE = 111_320.0
_OFFSET_50M = 50.0 / _METERS_PER_DEGREE
_OFFSET_150M = 150.0 / _METERS_PER_DEGREE


@register_provider("mock")
class MockReviewSourceProvider(ReviewSourceProvider):
    """Fixed fixture data. No network, no key required."""

    provider_name = "mock"

    async def search_places(
        self, query: str, lat: float | None, lng: float | None
    ) -> list[PlaceCandidate]:
        center_lat = lat if lat is not None else _DEFAULT_LAT
        center_lng = lng if lng is not None else _DEFAULT_LNG

        return [
            PlaceCandidate(
                place_id="mock-place-1",
                name=f"{query} (Demo Location)",
                address="123 Demo Street, Demo City",
                latitude=center_lat + _OFFSET_50M,
                longitude=center_lng + _OFFSET_50M,
            ),
            PlaceCandidate(
                place_id="mock-place-2",
                name="Nearby Cafe (Demo)",
                address="456 Demo Avenue, Demo City",
                latitude=center_lat + _OFFSET_150M,
                longitude=center_lng - _OFFSET_150M,
            ),
        ]

    async def fetch_reviews(self, place_id: str) -> list[ExternalReviewResult]:
        return [
            ExternalReviewResult(
                external_review_id="mock-review-1",
                author_name="Asha Rao",
                author_photo_url=None,
                rating=5,
                body="Fantastic service, will be back again!",
                language="en",
                external_posted_at=datetime(2026, 6, 1, tzinfo=UTC),
                source_url="https://maps.google.com/?cid=mock-place-1",
                raw_response={"provider": self.provider_name, "place_id": place_id, "review": 1},
            ),
            ExternalReviewResult(
                external_review_id="mock-review-2",
                author_name="Vikram Singh",
                author_photo_url=None,
                rating=4,
                body="Good experience overall, friendly staff.",
                language="en",
                external_posted_at=datetime(2026, 6, 10, tzinfo=UTC),
                source_url="https://maps.google.com/?cid=mock-place-1",
                raw_response={"provider": self.provider_name, "place_id": place_id, "review": 2},
            ),
            ExternalReviewResult(
                # Rating-only review with no text -- deliberately exercises the
                # nullable-body path (Google allows textless reviews).
                external_review_id="mock-review-3",
                author_name="Priya Nair",
                author_photo_url=None,
                rating=3,
                body=None,
                language=None,
                external_posted_at=datetime(2026, 6, 15, tzinfo=UTC),
                source_url="https://maps.google.com/?cid=mock-place-1",
                raw_response={"provider": self.provider_name, "place_id": place_id, "review": 3},
            ),
        ]
