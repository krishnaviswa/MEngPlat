"""Anthropic's Messages API.

Does not belong in openai_family.py: auth is `x-api-key` + `anthropic-version`
rather than `Authorization: Bearer`, the endpoint is /v1/messages rather than
/v1/chat/completions, `system` is a top-level request field rather than a
message with role "system", the reply text is at content[0].text rather than
choices[0].message.content, usage keys are input_tokens/output_tokens rather
than prompt_tokens/completion_tokens, and there is no response_format --
JSON is requested by instruction and enforced by prefilling the assistant
turn with "{" so the model continues a JSON object instead of prose.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from typing import Any

import httpx

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
from app.services.ai.provider_config import resolve_provider_config
from app.services.ai.registry import register_provider

@dataclass(frozen=True)
class _AnthropicSpec:
    """Just enough to satisfy provider_config.SpecLike -- no json_mode or
    supports_vision fields, since those are OpenAI-family-specific knobs this
    provider doesn't use."""

    name: str = "anthropic"
    base_url: str = "https://api.anthropic.com"
    default_model: str = "claude-sonnet-5"
    default_vision_model: str | None = "claude-sonnet-5"
    api_key_env: tuple[str, ...] = ("ANTHROPIC_API_KEY",)


_SPEC = _AnthropicSpec()

ANTHROPIC_VERSION = "2023-06-01"
MAX_OUTPUT_TOKENS = 4096


@register_provider("anthropic")
class AnthropicProvider(AIProvider):
    provider_name = "anthropic"
    supports_vision = True

    def __init__(self) -> None:
        cfg = resolve_provider_config(_SPEC)
        self.api_key = cfg.api_key
        self.base_url = cfg.base_url
        self.model = cfg.model
        self.vision_model = cfg.vision_model

    async def _messages(
        self, system: str, user_content: str | list[dict[str, Any]], *, model: str | None = None
    ) -> tuple[dict[str, Any], AICallMeta]:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                f"{self.base_url}/v1/messages",
                headers={
                    "x-api-key": self.api_key,
                    "anthropic-version": ANTHROPIC_VERSION,
                    "content-type": "application/json",
                },
                json={
                    "model": model or self.model,
                    "max_tokens": MAX_OUTPUT_TOKENS,
                    "system": system + " Respond with a single JSON object and nothing else.",
                    "messages": [
                        {"role": "user", "content": user_content},
                        # Prefilling the assistant turn is Anthropic's documented
                        # way to force a JSON-only reply without a JSON mode flag.
                        {"role": "assistant", "content": "{"},
                    ],
                },
            )
            response.raise_for_status()
            payload = response.json()

        text = "{" + payload["content"][0]["text"]
        usage = payload.get("usage") or {}
        prompt_tokens = usage.get("input_tokens", 0)
        completion_tokens = usage.get("output_tokens", 0)
        meta = AICallMeta(
            provider=self.provider_name,
            model=payload.get("model") or (model or self.model),
            usage=TokenUsage(
                prompt_tokens=prompt_tokens,
                completion_tokens=completion_tokens,
                total_tokens=prompt_tokens + completion_tokens,
            ),
            attempts=1,
        )
        return json.loads(text), meta

    async def analyze_review_text(
        self, text: str, context: dict[str, Any] | None = None
    ) -> ReviewAnalysisResult:
        data, meta = await self._messages(prompts.REVIEW_TEXT_SYSTEM, text)
        return ReviewAnalysisResult(
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
        # Anthropic's vision content-part needs image bytes (base64 or a
        # fetchable URL), not a text mention of one. The storage layer today
        # returns a relative /uploads/... path that isn't fetchable from
        # Anthropic's servers -- wiring real image bytes through is phase 1c /
        # phase 7 (vision), tracked there rather than faked here.
        raise NotImplementedError(
            "Anthropic image analysis needs image bytes wired through from storage (see phase 1c)"
        )

    async def generate_merchant_summary(
        self, reviews: list[dict[str, Any]], context: dict[str, Any] | None = None
    ) -> MerchantSummaryResult:
        data, meta = await self._messages(prompts.MERCHANT_SUMMARY_SYSTEM, json.dumps(reviews))
        return MerchantSummaryResult(
            summary=data.get("summary", ""),
            positives=data.get("positives", []),
            complaints=data.get("complaints", []),
            monthly_trends=data.get("monthly_trends", []),
            suggested_responses=data.get("suggested_responses", []),
            raw_response=data,
            meta=meta,
        )
