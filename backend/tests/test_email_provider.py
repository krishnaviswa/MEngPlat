"""S-035 email port (ADR-007): mock provider, factory, startup validation,
and the try_send_* catch-all-and-log helpers review-create / business-approve
call (AC 1, AC 6).

Mirrors test_ai_startup_validation.py's env-var monkeypatch convention for
validate_startup_config, and test_cache_lock.py's fake-collaborator
convention for exercising fail-closed/fail-open-style contracts without a
real network dependency. AI_PROVIDER=mock-equivalent here is EMAIL_PROVIDER
mock -- no vendor HTTP call in any test in this file.
"""

import logging

import httpx
import pytest

import app.services.email as email_module
from app.config import get_settings
from app.services.email.mock import MockEmailProvider
from app.services.email.resend import ResendEmailProvider


@pytest.fixture(autouse=True)
def _clear_settings_cache():
    yield
    get_settings.cache_clear()


# ---------------------------------------------------------------------------
# Mock provider: logs only, no vendor network call (AC 1, AC 6).
# ---------------------------------------------------------------------------
async def test_mock_provider_logs_to_from_subject_and_body(caplog):
    provider = MockEmailProvider()
    with caplog.at_level(logging.INFO, logger="app.email.mock"):
        await provider.send("owner@example.com", "Subject line", "Body text")

    assert len(caplog.records) == 1
    message = caplog.records[0].getMessage()
    assert "owner@example.com" in message
    assert "Subject line" in message
    assert "Body text" in message


async def test_mock_provider_never_touches_httpx(monkeypatch):
    """No vendor network call is required when EMAIL_PROVIDER=mock (AC 1)."""

    def _fail_if_called(*args, **kwargs):
        raise AssertionError("MockEmailProvider must never open an HTTP client")

    monkeypatch.setattr(httpx, "AsyncClient", _fail_if_called)
    provider = MockEmailProvider()
    await provider.send("a@example.com", "Subject", "Body")  # must not raise


# ---------------------------------------------------------------------------
# Factory + startup validation.
# ---------------------------------------------------------------------------
def test_get_email_provider_defaults_to_mock(monkeypatch):
    monkeypatch.delenv("EMAIL_PROVIDER", raising=False)
    get_settings.cache_clear()
    assert isinstance(email_module.get_email_provider(), MockEmailProvider)


def test_get_email_provider_returns_resend_when_configured(monkeypatch):
    monkeypatch.setenv("EMAIL_PROVIDER", "resend")
    monkeypatch.setenv("RESEND_API_KEY", "test-key")
    monkeypatch.setenv("EMAIL_FROM", "noreply@example.com")
    get_settings.cache_clear()
    assert isinstance(email_module.get_email_provider(), ResendEmailProvider)


def test_validate_startup_config_passes_for_default_mock(monkeypatch):
    monkeypatch.setenv("EMAIL_PROVIDER", "mock")
    get_settings.cache_clear()
    email_module.validate_startup_config()  # must not raise


def test_validate_startup_config_rejects_unregistered_provider(monkeypatch):
    monkeypatch.setenv("EMAIL_PROVIDER", "sendgrid")
    get_settings.cache_clear()
    with pytest.raises(RuntimeError, match="not a registered provider"):
        email_module.validate_startup_config()


def test_validate_startup_config_rejects_resend_missing_both_key_and_from(monkeypatch):
    monkeypatch.setenv("EMAIL_PROVIDER", "resend")
    monkeypatch.setenv("RESEND_API_KEY", "")
    monkeypatch.setenv("EMAIL_FROM", "")
    get_settings.cache_clear()
    with pytest.raises(RuntimeError, match="RESEND_API_KEY and EMAIL_FROM"):
        email_module.validate_startup_config()


def test_validate_startup_config_rejects_resend_missing_from_only(monkeypatch):
    monkeypatch.setenv("EMAIL_PROVIDER", "resend")
    monkeypatch.setenv("RESEND_API_KEY", "test-key")
    monkeypatch.setenv("EMAIL_FROM", "")
    get_settings.cache_clear()
    with pytest.raises(RuntimeError, match="RESEND_API_KEY and EMAIL_FROM"):
        email_module.validate_startup_config()


def test_validate_startup_config_passes_for_resend_with_key_and_from(monkeypatch):
    monkeypatch.setenv("EMAIL_PROVIDER", "resend")
    monkeypatch.setenv("RESEND_API_KEY", "test-key")
    monkeypatch.setenv("EMAIL_FROM", "noreply@example.com")
    get_settings.cache_clear()
    email_module.validate_startup_config()  # must not raise


# ---------------------------------------------------------------------------
# try_send_* -- best-effort contract review-create / business-approve rely on
# (AC 1): must never raise, must always log on failure.
# ---------------------------------------------------------------------------
class RaisingProvider:
    async def send(self, to, subject, text, html=None):
        raise RuntimeError("vendor unreachable")


class RecordingProvider:
    def __init__(self):
        self.sent: list[dict] = []

    async def send(self, to, subject, text, html=None):
        self.sent.append({"to": to, "subject": subject, "text": text, "html": html})


async def test_try_send_swallows_provider_send_exception_and_logs(monkeypatch, caplog):
    monkeypatch.setattr(email_module, "get_email_provider", lambda: RaisingProvider())

    with caplog.at_level(logging.ERROR, logger="app.email"):
        await email_module.try_send_password_reset("a@example.com", "sometoken")  # must not raise

    assert any("Email send failed" in r.getMessage() for r in caplog.records)


async def test_try_send_swallows_get_email_provider_exception_itself(monkeypatch, caplog):
    def _raise():
        raise RuntimeError("misconfigured provider")

    monkeypatch.setattr(email_module, "get_email_provider", _raise)

    with caplog.at_level(logging.ERROR, logger="app.email"):
        await email_module.try_send_listing_approved("owner@example.com", "Biz")  # must not raise

    assert any("Email send failed" in r.getMessage() for r in caplog.records)


async def test_try_send_password_reset_calls_provider_with_rendered_template(monkeypatch):
    provider = RecordingProvider()
    monkeypatch.setattr(email_module, "get_email_provider", lambda: provider)

    await email_module.try_send_password_reset("a@example.com", "raw-token-123")

    assert len(provider.sent) == 1
    assert provider.sent[0]["to"] == "a@example.com"
    assert "raw-token-123" in provider.sent[0]["text"]


async def test_try_send_listing_approved_calls_provider_with_business_name(monkeypatch):
    provider = RecordingProvider()
    monkeypatch.setattr(email_module, "get_email_provider", lambda: provider)

    await email_module.try_send_listing_approved("owner@example.com", "Joe's Diner")

    assert len(provider.sent) == 1
    assert provider.sent[0]["to"] == "owner@example.com"
    assert "Joe's Diner" in provider.sent[0]["subject"]


async def test_try_send_new_review_calls_provider_with_rating(monkeypatch):
    provider = RecordingProvider()
    monkeypatch.setattr(email_module, "get_email_provider", lambda: provider)

    await email_module.try_send_new_review("owner@example.com", "Joe's Diner", 5)

    assert len(provider.sent) == 1
    assert "5-star" in provider.sent[0]["text"]


# ---------------------------------------------------------------------------
# Resend adapter: HTTP shape (never exercised unless EMAIL_PROVIDER=resend).
# ---------------------------------------------------------------------------
class _FakeResponse:
    def __init__(self, status_code=200):
        self.status_code = status_code

    def raise_for_status(self):
        if self.status_code >= 400:
            raise httpx.HTTPStatusError("boom", request=None, response=self)


class _FakeAsyncClient:
    last_instance = None

    def __init__(self, *args, **kwargs):
        self.posts: list[dict] = []
        self._response = _FakeResponse()
        _FakeAsyncClient.last_instance = self

    async def __aenter__(self):
        return self

    async def __aexit__(self, *exc):
        return False

    async def post(self, url, json=None, headers=None):
        self.posts.append({"url": url, "json": json, "headers": headers})
        return self._response


async def test_resend_provider_posts_to_resend_api_with_bearer_auth(monkeypatch):
    monkeypatch.setenv("EMAIL_PROVIDER", "resend")
    monkeypatch.setenv("RESEND_API_KEY", "secret-key")
    monkeypatch.setenv("EMAIL_FROM", "noreply@example.com")
    get_settings.cache_clear()
    monkeypatch.setattr(httpx, "AsyncClient", _FakeAsyncClient)

    provider = ResendEmailProvider()
    await provider.send("owner@example.com", "Subject", "Body text")

    call = _FakeAsyncClient.last_instance.posts[0]
    assert call["url"] == "https://api.resend.com/emails"
    assert call["headers"]["Authorization"] == "Bearer secret-key"
    assert call["json"]["to"] == ["owner@example.com"]
    assert call["json"]["from"] == "noreply@example.com"
    assert call["json"]["subject"] == "Subject"


async def test_resend_provider_raises_on_http_error_so_try_send_catches_it(monkeypatch):
    monkeypatch.setenv("EMAIL_PROVIDER", "resend")
    monkeypatch.setenv("RESEND_API_KEY", "secret-key")
    monkeypatch.setenv("EMAIL_FROM", "noreply@example.com")
    get_settings.cache_clear()

    class _FailingClient(_FakeAsyncClient):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)
            self._response = _FakeResponse(status_code=500)

    monkeypatch.setattr(httpx, "AsyncClient", _FailingClient)

    provider = ResendEmailProvider()
    with pytest.raises(httpx.HTTPStatusError):
        await provider.send("owner@example.com", "Subject", "Body")
