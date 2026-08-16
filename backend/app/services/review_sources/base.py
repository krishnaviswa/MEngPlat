"""The contract every review-source provider implements, and the value types it returns.

Mirrors `app/services/ai/base.py`'s shape so a future provider (if a
ToS-compliant Zomato/Justdial API ever appears) is a drop-in module, not a
rewrite.
"""

from __future__ import annotations

import abc
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, ClassVar


@dataclass
class PlaceCandidate:
    place_id: str
    name: str
    address: str
    latitude: float
    longitude: float


@dataclass
class ExternalReviewResult:
    external_review_id: str
    author_name: str
    rating: int
    author_photo_url: str | None = None
    body: str | None = None
    language: str | None = None
    external_posted_at: datetime | None = None
    source_url: str | None = None
    raw_response: dict[str, Any] = field(default_factory=dict)


class ReviewSourceProvider(abc.ABC):
    """Base class for review-source providers."""

    #: Recorded on every ExternalReview row, so it must be stable across releases.
    provider_name: ClassVar[str]

    @abc.abstractmethod
    async def search_places(
        self, query: str, lat: float | None, lng: float | None
    ) -> list[PlaceCandidate]: ...

    @abc.abstractmethod
    async def fetch_reviews(self, place_id: str) -> list[ExternalReviewResult]: ...
