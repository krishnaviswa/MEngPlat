"""Public entry point for the AI layer."""

from app.config import get_settings
from app.services.ai.base import (
    AICallMeta,
    AIProvider,
    ImageAnalysisResult,
    MerchantSummaryResult,
    Operation,
    ReviewAnalysisResult,
    TokenUsage,
    coerce_sentiment,
)
from app.services.ai.registry import (
    UnknownAIProviderError,
    available_providers,
    create_provider,
    register_provider,
)


def get_ai_provider() -> AIProvider:
    """Return the provider named by AI_PROVIDER.

    Settings are read per call rather than at import time. get_settings() is
    lru_cached, so binding `settings` at module scope -- as this module used to
    -- freezes configuration before tests get a chance to override it.

    Unlike the previous if/else, an unrecognised AI_PROVIDER now raises
    UnknownAIProviderError instead of silently falling through to OpenAI.
    """
    return create_provider(get_settings().ai_provider)


__all__ = [
    "AICallMeta",
    "AIProvider",
    "ImageAnalysisResult",
    "MerchantSummaryResult",
    "Operation",
    "ReviewAnalysisResult",
    "TokenUsage",
    "UnknownAIProviderError",
    "available_providers",
    "coerce_sentiment",
    "create_provider",
    "get_ai_provider",
    "register_provider",
]
