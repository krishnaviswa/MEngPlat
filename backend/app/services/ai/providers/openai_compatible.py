"""OpenAI-compatible chat-completions provider.

Phase 1a keeps this behaviourally identical to the previous single hardcoded
client so the refactor is verifiable on its own. Phase 1b replaces the
constructor with declarative per-vendor specs (DeepSeek, Groq, Gemini, Qwen,
GLM, Kimi) and adds the Anthropic native adapter alongside it.
"""

import json
from typing import Any

import httpx

from app.config import get_settings
from app.services.ai import prompts
from app.services.ai.base import (
    AICallMeta,
    AIProvider,
    ImageAnalysisResult,
    MerchantSummaryResult,
    ReviewAnalysisResult,
    TokenUsage,
    coerce_sentiment,
)
from app.services.ai.registry import register_provider


class OpenAICompatibleProvider(AIProvider):
    """Works with OpenAI, DeepSeek, and other OpenAI-compatible APIs."""

    #: Unchanged from before the registry existed -- this string is persisted on
    #: every ai_analyses row, so changing it would split historical data.
    provider_name = "openai_compatible"

    def __init__(self) -> None:
        # Read settings here, not at import time. get_settings() is lru_cached,
        # so a module-level read freezes config before tests can override it.
        settings = get_settings()
        self.api_key = settings.ai_api_key
        self.base_url = settings.ai_base_url.rstrip("/")
        self.model = settings.ai_model

    async def _chat(self, system: str, user: str) -> tuple[dict[str, Any], AICallMeta]:
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
            payload = response.json()

        content = payload["choices"][0]["message"]["content"]

        # The usage block used to be parsed past and dropped on the floor. It is
        # the only source of truth for what a call actually cost.
        raw_usage = payload.get("usage") or {}
        meta = AICallMeta(
            provider=self.provider_name,
            model=payload.get("model") or self.model,
            usage=TokenUsage(
                prompt_tokens=raw_usage.get("prompt_tokens", 0),
                completion_tokens=raw_usage.get("completion_tokens", 0),
                total_tokens=raw_usage.get("total_tokens", 0),
            ),
            attempts=1,
        )
        return json.loads(content), meta

    async def analyze_review_text(
        self, text: str, context: dict[str, Any] | None = None
    ) -> ReviewAnalysisResult:
        data, meta = await self._chat(prompts.REVIEW_TEXT_SYSTEM, text)
        return ReviewAnalysisResult(
            # Models return "Positive", "mixed", or nothing at all. Normalising
            # here keeps an unexpected value from reaching Sentiment(...) and
            # rolling back the review the caller is in the middle of saving.
            sentiment=coerce_sentiment(data.get("sentiment")),
            summary=data.get("summary", ""),
            positives=data.get("positives", []),
            complaints=data.get("complaints", []),
            suggested_response=data.get("suggested_response", ""),
            raw_response=data,
            meta=meta,
        )

    async def analyze_image(
        self, image_url: str, context: dict[str, Any] | None = None
    ) -> ImageAnalysisResult:
        data, meta = await self._chat(prompts.IMAGE_SYSTEM, f"Analyze image at URL: {image_url}")
        return ImageAnalysisResult(insights=data.get("insights", {}), raw_response=data, meta=meta)

    async def generate_merchant_summary(
        self, reviews: list[dict[str, Any]], context: dict[str, Any] | None = None
    ) -> MerchantSummaryResult:
        data, meta = await self._chat(prompts.MERCHANT_SUMMARY_SYSTEM, json.dumps(reviews))
        return MerchantSummaryResult(
            summary=data.get("summary", ""),
            positives=data.get("positives", []),
            complaints=data.get("complaints", []),
            monthly_trends=data.get("monthly_trends", []),
            suggested_responses=data.get("suggested_responses", []),
            raw_response=data,
            meta=meta,
        )


# Both names resolve to the same client today; they differ only by the
# AI_BASE_URL/AI_MODEL configured against them. Phase 1b gives each its own spec.
register_provider("openai", OpenAICompatibleProvider)
register_provider("deepseek", OpenAICompatibleProvider)
