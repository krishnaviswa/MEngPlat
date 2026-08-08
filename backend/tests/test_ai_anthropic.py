"""Anthropic's Messages API has a genuinely different shape from every other
registered provider -- these tests exist specifically to prove the adapter
got each difference right, not just that it returns 200."""

import json

import httpx
import pytest
import respx

from app.config import get_settings
from app.services.ai import create_provider
from app.services.ai.providers.anthropic import ANTHROPIC_VERSION, AnthropicProvider


@pytest.fixture(autouse=True)
def _clear_settings_cache():
    yield
    get_settings.cache_clear()


def _mock_response(text_after_brace: str, input_tokens=20, output_tokens=8):
    return httpx.Response(
        200,
        json={
            "model": "claude-sonnet-5",
            "content": [{"type": "text", "text": text_after_brace}],
            "usage": {"input_tokens": input_tokens, "output_tokens": output_tokens},
        },
    )


@respx.mock
async def test_request_shape_is_anthropic_native_not_openai(monkeypatch):
    monkeypatch.setenv("AI_PROVIDERS__ANTHROPIC__API_KEY", "test-key")
    get_settings.cache_clear()

    route = respx.post("https://api.anthropic.com/v1/messages").mock(
        return_value=_mock_response('"sentiment": "positive", "summary": "great"}')
    )

    provider = AnthropicProvider()
    result = await provider.analyze_review_text("Loved it")

    assert route.called
    request = route.calls[0].request

    # Auth: x-api-key + anthropic-version, NOT Authorization: Bearer.
    assert request.headers["x-api-key"] == "test-key"
    assert request.headers["anthropic-version"] == ANTHROPIC_VERSION
    assert "authorization" not in {h.lower() for h in request.headers.keys()}

    sent = json.loads(request.content)
    # system is a top-level field, not a {"role": "system"} message.
    assert "system" in sent
    assert all(m["role"] != "system" for m in sent["messages"])
    # No response_format -- JSON is enforced by the assistant prefill instead.
    assert "response_format" not in sent
    assert sent["messages"][-1] == {"role": "assistant", "content": "{"}

    assert result.sentiment == "positive"


@respx.mock
async def test_usage_keys_are_input_output_tokens_not_prompt_completion(monkeypatch):
    monkeypatch.setenv("AI_PROVIDERS__ANTHROPIC__API_KEY", "test-key")
    get_settings.cache_clear()

    respx.post("https://api.anthropic.com/v1/messages").mock(
        return_value=_mock_response('"sentiment": "neutral", "summary": "ok"}', input_tokens=100, output_tokens=40)
    )

    result = await AnthropicProvider().analyze_review_text("It was ok")
    assert result.meta.usage.prompt_tokens == 100
    assert result.meta.usage.completion_tokens == 40
    assert result.meta.usage.total_tokens == 140
    assert result.meta.provider == "anthropic"


@respx.mock
async def test_reply_text_is_read_from_content_zero_text(monkeypatch):
    """Not choices[0].message.content -- that shape doesn't exist here."""
    monkeypatch.setenv("AI_PROVIDERS__ANTHROPIC__API_KEY", "test-key")
    get_settings.cache_clear()

    respx.post("https://api.anthropic.com/v1/messages").mock(
        return_value=_mock_response(
            '"summary": "s", "positives": ["a"], "complaints": [], '
            '"monthly_trends": [], "suggested_responses": []}'
        )
    )

    result = await AnthropicProvider().generate_merchant_summary([{"sentiment": "positive"}])
    assert result.positives == ["a"]
    assert result.raw_response  # MerchantSummaryResult carries raw_response now


async def test_image_analysis_fails_loudly_rather_than_faking_it(monkeypatch):
    """Vision needs real image bytes wired through from storage (phase 1c/7).
    Silently returning fabricated insights would be worse than an error."""
    monkeypatch.setenv("AI_PROVIDERS__ANTHROPIC__API_KEY", "test-key")
    get_settings.cache_clear()

    with pytest.raises(NotImplementedError):
        await AnthropicProvider().analyze_image("https://example.com/x.jpg")


async def test_resolves_through_the_public_factory(monkeypatch):
    monkeypatch.setenv("AI_PROVIDER", "anthropic")
    monkeypatch.setenv("AI_PROVIDERS__ANTHROPIC__API_KEY", "test-key")
    get_settings.cache_clear()

    provider = create_provider("anthropic")
    assert isinstance(provider, AnthropicProvider)
    assert provider.model == "claude-sonnet-5"
