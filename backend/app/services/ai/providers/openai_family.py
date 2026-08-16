"""Every vendor that speaks OpenAI's /chat/completions shape.

Adding one is a new OpenAISpec entry in SPECS below -- no new class, no edit to
the registry, no edit to config.py. Anthropic is the one provider that does NOT
belong here: different auth header, different path, different request/response
shape entirely -- see providers/anthropic.py.

Base URLs, model IDs, and json_object support were checked against each
vendor's current docs while building this (see commit message) rather than
assumed from general knowledge -- these details churn, particularly for the
newer entries, and get this wrong silently rather than loudly.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from functools import partial
from typing import Any

from app.services.ai import prompts
from app.services.ai.base import (
    AICallMeta,
    AIProvider,
    ImageAnalysisResult,
    MerchantSummaryResult,
    ReviewAnalysisResult,
    TokenUsage,
    TopicClusterResult,
    coerce_sentiment,
    coerce_topic_sentiment,
)
from app.services.ai.http_client import get_shared_client
from app.services.ai.provider_config import resolve_provider_config
from app.services.ai.registry import register_provider


@dataclass(frozen=True)
class OpenAISpec:
    name: str
    base_url: str
    default_model: str
    default_vision_model: str | None = None
    #: Whether to send response_format: {"type": "json_object"}. Where a
    #: vendor's support for this isn't clearly documented, this is left False
    #: and JSON is enforced by prompt instruction instead -- a request that
    #: fails outright is worse than one that occasionally needs a text-JSON
    #: cleanup pass.
    supports_json_mode: bool = True
    supports_vision: bool = False
    #: Vendor-native env vars, checked before AI_PROVIDERS__<NAME>__API_KEY.
    api_key_env: tuple[str, ...] = ()


SPECS: list[OpenAISpec] = [
    OpenAISpec(
        name="openai",
        base_url="https://api.openai.com/v1",
        default_model="gpt-4o-mini",
        default_vision_model="gpt-4o-mini",
        supports_vision=True,
        api_key_env=("OPENAI_API_KEY",),
    ),
    OpenAISpec(
        # "deepseek-chat" was retired 2026-07-24; deepseek-v4-flash is the
        # documented same-base-URL, same-key replacement.
        name="deepseek",
        base_url="https://api.deepseek.com/v1",
        default_model="deepseek-v4-flash",
        api_key_env=("DEEPSEEK_API_KEY",),
    ),
    OpenAISpec(
        # llama-3.3-70b-versatile / llama-3.1-8b-instant were deprecated
        # 2026-06-17; Groq's own migration guidance points at gpt-oss.
        name="groq",
        base_url="https://api.groq.com/openai/v1",
        default_model="openai/gpt-oss-120b",
        api_key_env=("GROQ_API_KEY",),
    ),
    OpenAISpec(
        name="gemini",
        base_url="https://generativelanguage.googleapis.com/v1beta/openai",
        default_model="gemini-2.5-flash",
        default_vision_model="gemini-2.5-flash",
        supports_vision=True,
        api_key_env=("GEMINI_API_KEY", "GOOGLE_API_KEY"),
    ),
    OpenAISpec(
        # International DashScope endpoint (no mainland account needed). For a
        # mainland account, override AI_PROVIDERS__QWEN__BASE_URL to
        # https://dashscope.aliyuncs.com/compatible-mode/v1. DashScope requires
        # the word "json" to appear in the prompt for json_object mode, which
        # the shared system prompts in prompts.py already do.
        name="qwen",
        base_url="https://dashscope-intl.aliyuncs.com/compatible-mode/v1",
        default_model="qwen-plus",
        api_key_env=("DASHSCOPE_API_KEY",),
    ),
    OpenAISpec(
        # Z.ai international endpoint; mainland accounts use
        # https://open.bigmodel.cn/api/paas/v4. json_object support isn't
        # clearly documented for this vendor -- see supports_json_mode above.
        name="glm",
        base_url="https://api.z.ai/api/paas/v4",
        default_model="glm-4.5-flash",
        supports_json_mode=False,
        api_key_env=("ZHIPU_API_KEY", "ZAI_API_KEY"),
    ),
    OpenAISpec(
        # International Moonshot endpoint; mainland accounts use
        # api.moonshot.cn. Kimi's model lineup (K2.x -> K3) has moved fast --
        # confirm kimi-k2.5 is still current before relying on it in production.
        name="kimi",
        base_url="https://api.moonshot.ai/v1",
        default_model="kimi-k2.5",
        api_key_env=("MOONSHOT_API_KEY",),
    ),
]


class OpenAICompatibleProvider(AIProvider):
    """One client, parameterised by OpenAISpec, serving all of SPECS above.

    provider_name below is a class-level placeholder only so the ABC's
    __init_subclass__ check passes at class-definition time -- each instance
    overrides it with its spec's name, which is what actually gets persisted
    and what AICallMeta.provider reports.
    """

    provider_name = "openai_compatible"

    def __init__(self, spec: OpenAISpec) -> None:
        self.spec = spec
        self.provider_name = spec.name
        self.supports_vision = spec.supports_vision
        cfg = resolve_provider_config(spec)
        self.api_key = cfg.api_key
        self.base_url = cfg.base_url
        self.model = cfg.model
        self.vision_model = cfg.vision_model

    async def _chat(self, system: str, user: str, *, model: str | None = None) -> tuple[dict[str, Any], AICallMeta]:
        body: dict[str, Any] = {
            "model": model or self.model,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
        }
        if self.spec.supports_json_mode:
            body["response_format"] = {"type": "json_object"}

        client = get_shared_client()
        response = await client.post(
            f"{self.base_url}/chat/completions",
            headers={"Authorization": f"Bearer {self.api_key}"},
            json=body,
        )
        response.raise_for_status()
        payload = response.json()

        content = payload["choices"][0]["message"]["content"]
        raw_usage = payload.get("usage") or {}
        meta = AICallMeta(
            provider=self.provider_name,
            model=payload.get("model") or body["model"],
            usage=TokenUsage(
                prompt_tokens=raw_usage.get("prompt_tokens", 0),
                completion_tokens=raw_usage.get("completion_tokens", 0),
                total_tokens=raw_usage.get("total_tokens", 0),
            ),
            attempts=1,
        )
        return _extract_json(content), meta

    async def analyze_review_text(
        self, text: str, context: dict[str, Any] | None = None
    ) -> ReviewAnalysisResult:
        data, meta = await self._chat(prompts.REVIEW_TEXT_SYSTEM, text)
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
        if not self.spec.supports_vision:
            # Calling a text-only model with "analyze this image" produces a
            # confident, fabricated description of an image it never saw.
            # Failing loudly is safer than paying for a guaranteed-wrong answer.
            raise NotImplementedError(f"{self.provider_name} does not support image analysis")
        data, meta = await self._chat(
            prompts.IMAGE_SYSTEM,
            f"Analyze image at URL: {image_url}",
            model=self.vision_model,
        )
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

    async def generate_topic_clusters(
        self, reviews: list[dict[str, Any]], context: dict[str, Any] | None = None
    ) -> TopicClusterResult:
        data, meta = await self._chat(prompts.TOPIC_CLUSTERING_SYSTEM, json.dumps(reviews))
        topics = [
            {
                "label": t.get("label", ""),
                "count": t.get("count", 0),
                "sentiment": coerce_topic_sentiment(t.get("sentiment")),
                "example_quote": t.get("example_quote", ""),
            }
            for t in data.get("topics", [])
        ]
        return TopicClusterResult(topics=topics, raw_response=data, meta=meta)


def _extract_json(content: str) -> dict[str, Any]:
    """Parse a model's reply as JSON, tolerating providers without JSON mode.

    With response_format enforced, `content` is already a clean JSON object.
    Without it (glm today; any future spec with supports_json_mode=False), a
    model frequently wraps the object in a sentence or a ```json fence.
    """
    try:
        return json.loads(content)
    except json.JSONDecodeError:
        pass
    start, end = content.find("{"), content.rfind("}")
    if start != -1 and end != -1 and end > start:
        return json.loads(content[start : end + 1])
    raise


for _spec in SPECS:
    register_provider(_spec.name, partial(OpenAICompatibleProvider, spec=_spec))
