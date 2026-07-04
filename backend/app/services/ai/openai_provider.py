import json
from typing import Any

import httpx

from app.config import get_settings
from app.services.ai.base import ImageAnalysisResult, MerchantSummaryResult, ReviewAnalysisResult

settings = get_settings()


class OpenAICompatibleProvider:
    """Works with OpenAI, DeepSeek, and other OpenAI-compatible APIs."""

    provider_name = "openai_compatible"

    def __init__(self) -> None:
        self.api_key = settings.ai_api_key
        self.base_url = settings.ai_base_url.rstrip("/")
        self.model = settings.ai_model

    async def _chat(self, system: str, user: str) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{self.base_url}/chat/completions",
                headers={"Authorization": f"Bearer {self.api_key}"},
                json={
                    "model": self.model,
                    "messages": [
                        {"role": "system", "content": system},
                        {"role": "user", "content": user},
                    ],
                    "response_format": {"type": "json_object"},
                },
            )
            response.raise_for_status()
            content = response.json()["choices"][0]["message"]["content"]
            return json.loads(content)

    async def analyze_review_text(self, text: str, context: dict[str, Any] | None = None) -> ReviewAnalysisResult:
        system = (
            "You analyze customer reviews for local businesses. "
            "Return JSON with: sentiment (positive|neutral|negative), summary, positives (array), "
            "complaints (array), suggested_response. Frame outputs as suggestions, not facts."
        )
        data = await self._chat(system, text)
        return ReviewAnalysisResult(
            sentiment=data.get("sentiment", "neutral"),
            summary=data.get("summary", ""),
            positives=data.get("positives", []),
            complaints=data.get("complaints", []),
            suggested_response=data.get("suggested_response", ""),
            raw_response=data,
        )

    async def analyze_image(self, image_url: str, context: dict[str, Any] | None = None) -> ImageAnalysisResult:
        system = (
            "Analyze store photos. Return JSON with insights object containing suggested observations for: "
            "store_cleanliness, queue_length, product_visibility, damaged_products, outdoor_appearance, "
            "storefront_quality, safety_issues. Prefix each value with 'Appears' or 'Suggestion:'."
        )
        data = await self._chat(system, f"Analyze image at URL: {image_url}")
        return ImageAnalysisResult(insights=data.get("insights", {}), raw_response=data)

    async def generate_merchant_summary(
        self, reviews: list[dict[str, Any]], context: dict[str, Any] | None = None
    ) -> MerchantSummaryResult:
        system = (
            "Summarize merchant reviews. Return JSON: summary, positives (array), complaints (array), "
            "monthly_trends (array of {month, positive, neutral, negative}), suggested_responses (array)."
        )
        data = await self._chat(system, json.dumps(reviews))
        return MerchantSummaryResult(
            summary=data.get("summary", ""),
            positives=data.get("positives", []),
            complaints=data.get("complaints", []),
            monthly_trends=data.get("monthly_trends", []),
            suggested_responses=data.get("suggested_responses", []),
        )
