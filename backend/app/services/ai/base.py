from dataclasses import dataclass, field
from typing import Any, Protocol


@dataclass
class ReviewAnalysisResult:
    sentiment: str
    summary: str
    positives: list[str] = field(default_factory=list)
    complaints: list[str] = field(default_factory=list)
    suggested_response: str = ""
    raw_response: dict[str, Any] = field(default_factory=dict)


@dataclass
class ImageAnalysisResult:
    insights: dict[str, str]
    raw_response: dict[str, Any] = field(default_factory=dict)


@dataclass
class MerchantSummaryResult:
    summary: str
    positives: list[str]
    complaints: list[str]
    monthly_trends: list[dict[str, Any]]
    suggested_responses: list[str]


class AIProvider(Protocol):
    async def analyze_review_text(self, text: str, context: dict[str, Any] | None = None) -> ReviewAnalysisResult: ...

    async def analyze_image(self, image_url: str, context: dict[str, Any] | None = None) -> ImageAnalysisResult: ...

    async def generate_merchant_summary(
        self, reviews: list[dict[str, Any]], context: dict[str, Any] | None = None
    ) -> MerchantSummaryResult: ...
