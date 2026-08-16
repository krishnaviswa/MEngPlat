"""Public entry point for the review-source layer (S-048)."""

from app.config import get_settings
from app.services.review_sources.base import (
    ExternalReviewResult,
    PlaceCandidate,
    ReviewSourceProvider,
)
from app.services.review_sources.registry import (
    UnknownReviewSourceProviderError,
    available_providers,
    create_provider,
    register_provider,
)


def get_review_source_provider() -> ReviewSourceProvider:
    """Return the `google` provider if a key is configured, else `mock`.

    No gateway/fallback wrapper (unlike `AIGateway`) -- a search or sync call
    either serves from the configured provider or surfaces a clear error;
    silently degrading review *content* the way AI degrades to
    fabricated-but-labeled output is not appropriate for third-party review
    text.
    """
    settings = get_settings()
    name = "google" if settings.google_places_api_key else "mock"
    return create_provider(name)


__all__ = [
    "ExternalReviewResult",
    "PlaceCandidate",
    "ReviewSourceProvider",
    "UnknownReviewSourceProviderError",
    "available_providers",
    "create_provider",
    "get_review_source_provider",
    "register_provider",
]
