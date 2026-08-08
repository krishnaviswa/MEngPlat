"""Request shape for every OpenAI-compatible vendor, and spec sanity checks.

respx intercepts at the transport layer, so these exercise the real
httpx.AsyncClient code path with zero network traffic and no code changes to
the provider needed to make it testable.
"""

import json

import httpx
import pytest
import respx

from app.config import get_settings
from app.services.ai import create_provider
from app.services.ai.providers.openai_family import SPECS, OpenAICompatibleProvider


def _reload_settings():
    get_settings.cache_clear()
    return get_settings()


class TestSpecs:
    """These values were looked up against each vendor's current docs while
    building this -- these tests exist to catch a future edit reintroducing a
    typo or a deprecated model ID, not to re-derive the values themselves."""

    def test_every_spec_name_is_registered(self):
        registered = {"mock", "anthropic", *(s.name for s in SPECS)}
        from app.services.ai import available_providers

        assert set(available_providers()) == registered

    def test_no_two_specs_share_a_name(self):
        names = [s.name for s in SPECS]
        assert len(names) == len(set(names))

    def test_every_spec_has_an_https_base_url_and_a_model(self):
        for spec in SPECS:
            assert spec.base_url.startswith("https://"), spec.name
            assert not spec.base_url.endswith("/"), spec.name
            assert spec.default_model, spec.name

    def test_deprecated_model_ids_are_not_the_default(self):
        """Regression guard: deepseek-chat retired 2026-07-24,
        llama-3.3-70b-versatile / llama-3.1-8b-instant deprecated 2026-06-17."""
        retired = {"deepseek-chat", "llama-3.3-70b-versatile", "llama-3.1-8b-instant"}
        for spec in SPECS:
            assert spec.default_model not in retired, spec.name


@pytest.fixture
def spec(request):
    (name,) = request.param
    return next(s for s in SPECS if s.name == name)


@pytest.fixture(autouse=True)
def _clear_settings_cache():
    yield
    get_settings.cache_clear()


@respx.mock
@pytest.mark.parametrize("spec", [("openai",)], indirect=True)
async def test_bearer_auth_and_json_mode_when_supported(monkeypatch, spec):
    monkeypatch.setenv("AI_PROVIDERS__OPENAI__API_KEY", "test-key")
    _reload_settings()

    route = respx.post(f"{spec.base_url}/chat/completions").mock(
        return_value=httpx.Response(
            200,
            json={
                "model": spec.default_model,
                "choices": [{"message": {"content": json.dumps({"sentiment": "positive", "summary": "s"})}}],
                "usage": {"prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15},
            },
        )
    )

    provider = OpenAICompatibleProvider(spec=spec)
    result = await provider.analyze_review_text("Great service")

    assert route.called
    sent = json.loads(route.calls[0].request.content)
    assert route.calls[0].request.headers["Authorization"] == "Bearer test-key"
    assert sent["response_format"] == {"type": "json_object"}
    assert result.sentiment == "positive"
    assert result.meta.usage.total_tokens == 15
    assert result.meta.provider == "openai"


@respx.mock
@pytest.mark.parametrize("spec", [("glm",)], indirect=True)
async def test_json_mode_omitted_when_not_supported(monkeypatch, spec):
    monkeypatch.setenv("AI_PROVIDERS__GLM__API_KEY", "test-key")
    _reload_settings()

    respx.post(f"{spec.base_url}/chat/completions").mock(
        return_value=httpx.Response(
            200,
            json={
                "choices": [{"message": {"content": json.dumps({"sentiment": "neutral", "summary": "s"})}}],
                "usage": {},
            },
        )
    )

    provider = OpenAICompatibleProvider(spec=spec)
    await provider.analyze_review_text("It was fine")

    sent = json.loads(respx.calls[0].request.content)
    assert "response_format" not in sent


@respx.mock
@pytest.mark.parametrize("spec", [("deepseek",)], indirect=True)
async def test_tolerant_json_extraction_handles_a_prose_wrapped_reply(monkeypatch, spec):
    """A provider without json_object mode may wrap the object in commentary
    or a markdown fence instead of returning it bare."""
    monkeypatch.setenv("AI_PROVIDERS__DEEPSEEK__API_KEY", "test-key")
    _reload_settings()

    wrapped = 'Sure, here you go:\n```json\n{"sentiment": "negative", "summary": "bad"}\n```\nHope that helps!'
    respx.post(f"{spec.base_url}/chat/completions").mock(
        return_value=httpx.Response(
            200, json={"choices": [{"message": {"content": wrapped}}], "usage": {}}
        )
    )

    provider = OpenAICompatibleProvider(spec=spec)
    result = await provider.analyze_review_text("Terrible")
    assert result.sentiment == "negative"


@respx.mock
@pytest.mark.parametrize("spec", [("openai",)], indirect=True)
async def test_vision_model_used_for_image_analysis(monkeypatch, spec):
    monkeypatch.setenv("AI_PROVIDERS__OPENAI__API_KEY", "test-key")
    monkeypatch.setenv("AI_PROVIDERS__OPENAI__VISION_MODEL", "vision-specific-model")
    _reload_settings()

    respx.post(f"{spec.base_url}/chat/completions").mock(
        return_value=httpx.Response(
            200, json={"choices": [{"message": {"content": json.dumps({"insights": {}})}}], "usage": {}}
        )
    )

    provider = OpenAICompatibleProvider(spec=spec)
    await provider.analyze_image("https://example.com/x.jpg")

    sent = json.loads(respx.calls[0].request.content)
    assert sent["model"] == "vision-specific-model"


@pytest.mark.parametrize("spec", [("deepseek",)], indirect=True)
async def test_vision_on_a_non_vision_spec_fails_loudly_instead_of_faking_it(monkeypatch, spec):
    monkeypatch.setenv("AI_PROVIDERS__DEEPSEEK__API_KEY", "test-key")
    _reload_settings()
    provider = OpenAICompatibleProvider(spec=spec)
    with pytest.raises(NotImplementedError):
        await provider.analyze_image("https://example.com/x.jpg")


async def test_create_provider_resolves_every_openai_family_name(monkeypatch):
    """End-to-end through the public factory, not just the class directly."""
    for spec in SPECS:
        monkeypatch.setenv("AI_PROVIDER", spec.name)
        _reload_settings()
        provider = create_provider(spec.name)
        assert provider.provider_name == spec.name
        assert provider.base_url == spec.base_url  # no override set -> spec default
