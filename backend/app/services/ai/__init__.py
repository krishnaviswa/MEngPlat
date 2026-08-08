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


def validate_startup_config() -> None:
    """Fail fast on bad AI configuration, at boot rather than on first request.

    A production deploy silently serving mock analysis because of a typo'd
    AI_PROVIDER, or 500ing on every review because a key was never set, is
    worse than the process refusing to start. `mock` always passes -- it needs
    no configuration by design.
    """
    settings = get_settings()
    registered = available_providers()
    name = settings.ai_provider.strip().lower()

    if name not in registered:
        raise RuntimeError(
            f"AI_PROVIDER={settings.ai_provider!r} is not a registered provider. "
            f"Registered: {', '.join(registered)}"
        )

    fallback = settings.ai_fallback_provider.strip().lower()
    if fallback not in registered:
        raise RuntimeError(
            f"AI_FALLBACK_PROVIDER={settings.ai_fallback_provider!r} is not a registered provider. "
            f"Registered: {', '.join(registered)}"
        )

    if name == "mock":
        return

    provider = create_provider(name)
    if not getattr(provider, "api_key", None):
        raise RuntimeError(
            f"AI_PROVIDER={name!r} has no resolvable API key. Set "
            f"AI_PROVIDERS__{name.upper()}__API_KEY, a vendor-native env var "
            f"(e.g. {name.upper()}_API_KEY), or the legacy AI_API_KEY."
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
    "validate_startup_config",
]
