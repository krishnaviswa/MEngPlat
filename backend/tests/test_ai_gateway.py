"""AIGateway: retry, degrade-to-fallback, and the deadline.

Two layers of test here. FakeProvider tests drive AIGateway directly against
controlled exceptions -- no network, precise attempt counting, fast (backoff
is patched to zero). The end-to-end test at the bottom goes through the real
public factory with respx, proving the wiring in __init__.py actually
connects a real provider's failure to a real fallback.
"""

import asyncio

import httpx
import pytest
import respx

from app.config import get_settings
from app.services.ai import get_ai_provider
from app.services.ai.base import AICallMeta, AIProvider, ReviewAnalysisResult
from app.services.ai.gateway import AIGateway
from app.services.ai.providers.mock import MockAIProvider


class FakeProvider(AIProvider):
    """Raises a scripted sequence of exceptions, then a scripted result."""

    provider_name = "fake"

    def __init__(self, script: list[Exception | ReviewAnalysisResult]):
        self.script = list(script)
        self.calls = 0

    async def analyze_review_text(self, text, context=None):
        self.calls += 1
        outcome = self.script.pop(0)
        if isinstance(outcome, Exception):
            raise outcome
        return outcome

    async def analyze_image(self, image_url, context=None):
        raise NotImplementedError

    async def generate_merchant_summary(self, reviews, context=None):
        raise NotImplementedError

    async def generate_topic_clusters(self, reviews, context=None):
        raise NotImplementedError

    async def extract_business_profile(self, text, context=None):
        raise NotImplementedError


def _ok_result(sentiment="positive"):
    return ReviewAnalysisResult(sentiment=sentiment, summary="s", meta=AICallMeta(provider="fake"))


def _retryable_error():
    request = httpx.Request("POST", "https://fake.example/chat/completions")
    return httpx.HTTPStatusError("rate limited", request=request, response=httpx.Response(429, request=request))


def _auth_error():
    request = httpx.Request("POST", "https://fake.example/chat/completions")
    return httpx.HTTPStatusError("unauthorized", request=request, response=httpx.Response(401, request=request))


@pytest.fixture(autouse=True)
def _no_real_sleep(monkeypatch):
    """Backoff sleeps for real seconds by design -- not in a test suite.

    Captures the real asyncio.sleep in a closure before patching: a
    replacement that calls asyncio.sleep(0) directly would call itself once
    the attribute is patched, recursing until RecursionError.
    """
    original_sleep = asyncio.sleep

    async def instant_sleep(*_args, **_kwargs):
        await original_sleep(0)

    monkeypatch.setattr(asyncio, "sleep", instant_sleep)


class TestRetry:
    async def test_succeeds_without_retry_on_first_try(self):
        primary = FakeProvider([_ok_result()])
        gateway = AIGateway(primary, MockAIProvider(), max_retries=2)
        result = await gateway.analyze_review_text("x")
        assert primary.calls == 1
        assert result.meta.attempts == 1
        assert result.meta.degraded is False

    async def test_retries_a_429_then_succeeds(self):
        primary = FakeProvider([_retryable_error(), _ok_result()])
        gateway = AIGateway(primary, MockAIProvider(), max_retries=2)
        result = await gateway.analyze_review_text("x")
        assert primary.calls == 2
        assert result.meta.attempts == 2
        assert result.meta.degraded is False

    async def test_exhausting_retries_degrades_to_fallback(self):
        primary = FakeProvider([_retryable_error(), _retryable_error(), _retryable_error()])
        gateway = AIGateway(primary, MockAIProvider(), max_retries=2)
        result = await gateway.analyze_review_text("x")
        assert primary.calls == 3  # 1 initial + 2 retries, all exhausted
        assert result.meta.degraded is True
        assert result.meta.status == "degraded"
        assert result.meta.provider == "mock"

    async def test_auth_error_skips_retry_and_degrades_immediately(self):
        """A 401 is a config error, not a flake -- retrying it wastes time for
        the identical failure. Straight to fallback on the first attempt."""
        primary = FakeProvider([_auth_error(), _ok_result()])
        gateway = AIGateway(primary, MockAIProvider(), max_retries=2)
        result = await gateway.analyze_review_text("x")
        assert primary.calls == 1, "must not have consumed the second scripted response via retry"
        assert result.meta.degraded is True

    async def test_degrade_disabled_propagates_the_exception(self):
        primary = FakeProvider([_auth_error()])
        gateway = AIGateway(primary, MockAIProvider(), max_retries=0, degrade_on_failure=False)
        with pytest.raises(httpx.HTTPStatusError):
            await gateway.analyze_review_text("x")


class TestDeadline:
    async def test_zero_deadline_degrades_without_attempting_a_call(self):
        """No time budget at all -- not even a first attempt -- still
        degrades cleanly rather than raising an unbound-variable error."""
        primary = FakeProvider([_retryable_error()] * 10)
        gateway = AIGateway(primary, MockAIProvider(), max_retries=10, total_deadline_seconds=0.0)
        result = await gateway.analyze_review_text("x")
        assert primary.calls == 0
        assert result.meta.degraded is True

    async def test_deadline_cuts_off_retries_that_would_otherwise_continue(self, monkeypatch):
        """With retry budget remaining but no time left after the first
        failure, a slow vendor must not turn into a hung request via
        repeated retries.

        Real wall-clock timing here would be flaky (both the "failure" and
        the patched backoff sleep complete in microseconds, so a real 11-call
        retry loop can easily fit inside even a millisecond-scale deadline on
        a fast machine). A fake monotonic clock makes this deterministic:
        deadline is set at t=0, the loop's first remaining-time check also
        reads t=0 (still inside budget), and the check right after the first
        failure reads t=0.02 -- past the 0.01s deadline -- so no retry fires.
        """
        import app.services.ai.gateway as gateway_module

        clock = iter([0.0, 0.0, 0.02])
        monkeypatch.setattr(gateway_module.time, "monotonic", lambda: next(clock, 0.02))

        primary = FakeProvider([_retryable_error()] * 10)
        gateway = AIGateway(primary, MockAIProvider(), max_retries=10, total_deadline_seconds=0.01)
        result = await gateway.analyze_review_text("x")
        assert primary.calls == 1
        assert result.meta.degraded is True


class TestProviderNameReporting:
    def test_reports_the_configured_primary_not_gateway_or_fallback(self):
        gateway = AIGateway(FakeProvider([]), MockAIProvider())
        assert gateway.provider_name == "fake"

    async def test_result_meta_reports_who_actually_answered(self):
        """The distinction that matters: provider_name is static config,
        meta.provider is what really served this specific call."""
        primary = FakeProvider([_auth_error()])
        gateway = AIGateway(primary, MockAIProvider())
        assert gateway.provider_name == "fake"
        result = await gateway.analyze_review_text("x")
        assert result.meta.provider == "mock"


@respx.mock
async def test_end_to_end_through_get_ai_provider_survives_a_revoked_key(monkeypatch):
    """The actual production wiring: AI_PROVIDER=openai, key gets rejected,
    AI_FALLBACK_PROVIDER=mock (the default) serves the call instead. This is
    the checkpoint from the plan: revoke the key mid-flight, the caller still
    gets a usable result rather than an exception."""
    monkeypatch.setenv("AI_PROVIDER", "openai")
    monkeypatch.setenv("AI_PROVIDERS__OPENAI__API_KEY", "revoked-key")
    get_settings.cache_clear()

    respx.post("https://api.openai.com/v1/chat/completions").mock(
        return_value=httpx.Response(401, json={"error": "invalid_api_key"})
    )

    provider = get_ai_provider()
    assert isinstance(provider, AIGateway)
    assert provider.provider_name == "openai"

    result = await provider.analyze_review_text("Great service")

    assert result.meta.degraded is True
    assert result.meta.provider == "mock"
    assert result.sentiment in {"positive", "neutral", "negative"}

    get_settings.cache_clear()
