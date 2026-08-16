"""Deterministic provider for local development, tests, and graceful degradation.

Note for callers: this fabricates plausible-looking analysis. When it serves a
call as a fallback rather than as the configured provider, the result's
`meta.degraded` flag is what distinguishes invented output from a real model's.
"""

import hashlib
from typing import Any

from app.services.ai.base import (
    AICallMeta,
    AIProvider,
    BusinessProfileExtractResult,
    ImageAnalysisResult,
    MerchantSummaryResult,
    ReviewAnalysisResult,
    TopicClusterResult,
    coerce_sentiment,
)
from app.services.ai.registry import register_provider

NEGATIVE_WORDS = ["bad", "slow", "dirty", "rude", "expensive", "disappoint"]
POSITIVE_WORDS = ["great", "excellent", "friendly", "clean", "love", "amazing", "fast"]


@register_provider("mock")
class MockAIProvider(AIProvider):
    """Keyword-scoring stand-in. No network, no API key, fully deterministic."""

    provider_name = "mock"
    supports_vision = True  # not real vision, but it never fails on an image

    def _meta(self) -> AICallMeta:
        return AICallMeta(provider=self.provider_name, model="deterministic")

    async def analyze_review_text(
        self, text: str, context: dict[str, Any] | None = None
    ) -> ReviewAnalysisResult:
        lower = text.lower()
        neg_score = sum(1 for w in NEGATIVE_WORDS if w in lower)
        pos_score = sum(1 for w in POSITIVE_WORDS if w in lower)

        if neg_score > pos_score:
            sentiment = "negative"
        elif pos_score > neg_score:
            sentiment = "positive"
        else:
            sentiment = "neutral"

        summary = f"This review appears {sentiment}. AI-generated summary based on customer feedback."

        positives = ["Friendly staff", "Good value"] if sentiment != "negative" else []
        complaints = ["Wait times", "Cleanliness concerns"] if sentiment != "positive" else []

        suggested = (
            "Thank you for your feedback! We're glad you enjoyed your visit."
            if sentiment == "positive"
            else "Thank you for sharing your experience. We're working to improve."
        )

        return ReviewAnalysisResult(
            sentiment=coerce_sentiment(sentiment),
            summary=summary,
            positives=positives,
            complaints=complaints,
            suggested_response=suggested,
            raw_response={"provider": self.provider_name, "text_length": len(text)},
            meta=self._meta(),
        )

    async def analyze_image(
        self, image_url: str, context: dict[str, Any] | None = None
    ) -> ImageAnalysisResult:
        seed = int(hashlib.md5(image_url.encode()).hexdigest(), 16) % 3
        level = ["low", "moderate", "high"][seed]

        insights = {
            "store_cleanliness": f"Appears {level} cleanliness (suggestion — verify in person)",
            "queue_length": "Not clearly visible in this image (suggestion)",
            "product_visibility": "Products appear reasonably visible (suggestion)",
            "damaged_products": "No obvious damage detected (suggestion — may not be visible)",
            "outdoor_appearance": f"Exterior suggests {level} upkeep (suggestion)",
            "storefront_quality": f"Storefront quality appears {level} (suggestion)",
            "safety_issues": "No obvious safety concerns detected (suggestion)",
            "disclaimer": "AI suggestions only — not definitive judgments.",
        }
        return ImageAnalysisResult(
            insights=insights,
            raw_response={"provider": self.provider_name},
            meta=self._meta(),
        )

    async def generate_merchant_summary(
        self, reviews: list[dict[str, Any]], context: dict[str, Any] | None = None
    ) -> MerchantSummaryResult:
        sentiments = [r.get("sentiment", "neutral") for r in reviews]
        pos = sentiments.count("positive")
        neg = sentiments.count("negative")
        neu = sentiments.count("neutral")

        summary = (
            f"Based on {len(reviews)} recent reviews: "
            f"{pos} positive, {neu} neutral, {neg} negative sentiment signals (AI suggestion)."
        )

        return MerchantSummaryResult(
            summary=summary,
            positives=["Friendly service", "Good product selection", "Convenient location"],
            complaints=["Occasional wait times", "Parking availability"],
            monthly_trends=[
                {"month": "2026-01", "positive": 12, "neutral": 4, "negative": 2},
                {"month": "2026-02", "positive": 15, "neutral": 3, "negative": 1},
                {"month": "2026-03", "positive": 18, "neutral": 5, "negative": 3},
            ],
            suggested_responses=[
                "Thank you for supporting our local business!",
                "We appreciate your honest feedback and are always improving.",
            ],
            raw_response={"provider": self.provider_name, "review_count": len(reviews)},
            meta=self._meta(),
        )

    async def generate_topic_clusters(
        self, reviews: list[dict[str, Any]], context: dict[str, Any] | None = None
    ) -> TopicClusterResult:
        buckets = [
            ("Service speed", ["slow", "fast", "wait"]),
            ("Staff friendliness", ["friendly", "rude", "helpful"]),
            ("Cleanliness", ["clean", "dirty"]),
            ("Value for money", ["expensive", "cheap", "value"]),
        ]
        topics: list[dict[str, Any]] = []
        for label, keywords in buckets:
            matches = [
                r for r in reviews if any(k in str(r.get("body", "")).lower() for k in keywords)
            ]
            if not matches:
                continue
            neg = sum(1 for r in matches if r.get("sentiment") == "negative")
            pos = sum(1 for r in matches if r.get("sentiment") == "positive")
            sentiment = "mixed" if neg and pos else ("negative" if neg else "positive")
            example = next((str(r.get("body", "")) for r in matches if r.get("body")), "")
            topics.append(
                {
                    "label": label,
                    "count": len(matches),
                    "sentiment": sentiment,
                    "example_quote": example[:200],
                }
            )
        if not topics:
            topics = [
                {
                    "label": "General experience",
                    "count": len(reviews),
                    "sentiment": "mixed",
                    "example_quote": next((str(r.get("body", "")) for r in reviews if r.get("body")), ""),
                }
            ]
        return TopicClusterResult(
            topics=topics,
            raw_response={"provider": self.provider_name, "review_count": len(reviews)},
            meta=self._meta(),
        )

    async def extract_business_profile(
        self, text: str, context: dict[str, Any] | None = None
    ) -> BusinessProfileExtractResult:
        lower = text.lower()
        hours = {"mon-sat": "9-9"} if any(w in lower for w in ("open", "am", "pm", "hours")) else None
        address = text if any(w in lower for w in ("near", "street", "road", "stand", "nagar")) else None
        description = text[:500] if text.strip() else None
        return BusinessProfileExtractResult(
            description=description,
            address=address[:512] if address else None,
            business_hours=hours,
            phone=None,
            website=None,
            raw_response={"provider": self.provider_name, "text_length": len(text)},
            meta=self._meta(),
        )
