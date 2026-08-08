"""The contract every AI provider implements, and the value types it returns."""

from __future__ import annotations

import abc
import enum
from dataclasses import dataclass, field
from decimal import Decimal
from typing import Any, ClassVar


class Operation(str, enum.Enum):
    """The three things this application asks a model to do."""

    REVIEW_TEXT = "review_text"
    IMAGE = "image"
    MERCHANT_SUMMARY = "merchant_summary"


@dataclass
class TokenUsage:
    prompt_tokens: int = 0
    completion_tokens: int = 0
    total_tokens: int = 0


@dataclass
class AICallMeta:
    """What actually happened on a call, as opposed to what was requested.

    This rides on the result rather than being read off the provider object,
    because after a fallback the configured provider is not the one that served
    the call -- `provider` here is always the one that really answered.
    """

    provider: str = "unknown"
    model: str = ""
    usage: TokenUsage | None = None
    estimated_cost_usd: Decimal | None = None
    latency_ms: int = 0
    attempts: int = 0
    cached: bool = False
    #: True when a fallback served this call. Callers must be able to tell
    #: fabricated analysis apart from a real model's output.
    degraded: bool = False
    #: ok | cached | degraded | capped | error
    status: str = "ok"


@dataclass
class ReviewAnalysisResult:
    sentiment: str
    summary: str
    positives: list[str] = field(default_factory=list)
    complaints: list[str] = field(default_factory=list)
    suggested_response: str = ""
    raw_response: dict[str, Any] = field(default_factory=dict)
    meta: AICallMeta = field(default_factory=AICallMeta)


@dataclass
class ImageAnalysisResult:
    insights: dict[str, str]
    raw_response: dict[str, Any] = field(default_factory=dict)
    meta: AICallMeta = field(default_factory=AICallMeta)


@dataclass
class MerchantSummaryResult:
    summary: str
    positives: list[str]
    complaints: list[str]
    monthly_trends: list[dict[str, Any]]
    suggested_responses: list[str]
    raw_response: dict[str, Any] = field(default_factory=dict)
    meta: AICallMeta = field(default_factory=AICallMeta)


_VALID_SENTIMENTS = frozenset({"positive", "neutral", "negative"})


def coerce_sentiment(value: object) -> str:
    """Map whatever a model returned onto the three values the DB enum accepts.

    Real models do not reliably answer with the exact token asked for -- they
    return "Positive", "MIXED", "very negative", or nothing at all. The value
    used to be passed straight into `Sentiment(...)`, where anything unexpected
    raised ValueError, which rolled back the request session and destroyed the
    customer's review along with it. Never raise from here.
    """
    text = str(value or "").strip().lower()
    if text in _VALID_SENTIMENTS:
        return text
    if "pos" in text:
        return "positive"
    if "neg" in text:
        return "negative"
    return "neutral"


class AIProvider(abc.ABC):
    """Base class for AI providers.

    Subclasses that are themselves abstract (shared bases, not usable providers)
    must pass `abstract=True` so the provider_name check is skipped.
    """

    #: Recorded on every AIAnalysis row, so it must be stable across releases.
    provider_name: ClassVar[str]
    supports_vision: ClassVar[bool] = False

    def __init_subclass__(cls, abstract: bool = False, **kwargs: Any) -> None:
        super().__init_subclass__(**kwargs)
        if not abstract and not getattr(cls, "provider_name", None):
            raise TypeError(
                f"{cls.__name__} must define a non-empty provider_name "
                f"(or be declared with abstract=True)"
            )

    @abc.abstractmethod
    async def analyze_review_text(
        self, text: str, context: dict[str, Any] | None = None
    ) -> ReviewAnalysisResult: ...

    @abc.abstractmethod
    async def analyze_image(
        self, image_url: str, context: dict[str, Any] | None = None
    ) -> ImageAnalysisResult: ...

    @abc.abstractmethod
    async def generate_merchant_summary(
        self, reviews: list[dict[str, Any]], context: dict[str, Any] | None = None
    ) -> MerchantSummaryResult: ...
