"""validate_startup_config() -- the fail-fast gate main.py's lifespan runs
before serving traffic."""

import pytest

from app.config import get_settings
from app.services.ai import validate_startup_config


@pytest.fixture(autouse=True)
def _clear_settings_cache():
    yield
    get_settings.cache_clear()


def test_mock_needs_zero_configuration(monkeypatch):
    monkeypatch.setenv("AI_PROVIDER", "mock")
    get_settings.cache_clear()
    validate_startup_config()  # must not raise


def test_unregistered_provider_name_fails_startup(monkeypatch):
    monkeypatch.setenv("AI_PROVIDER", "not-a-real-provider")
    get_settings.cache_clear()
    with pytest.raises(RuntimeError, match="not a registered provider"):
        validate_startup_config()


def test_unregistered_fallback_provider_fails_startup(monkeypatch):
    monkeypatch.setenv("AI_PROVIDER", "mock")
    monkeypatch.setenv("AI_FALLBACK_PROVIDER", "not-a-real-provider")
    get_settings.cache_clear()
    with pytest.raises(RuntimeError, match="AI_FALLBACK_PROVIDER"):
        validate_startup_config()


def test_real_provider_with_no_key_fails_startup(monkeypatch):
    """A silently mock-degraded production deploy is worse than refusing to boot."""
    monkeypatch.setenv("AI_PROVIDER", "groq")
    get_settings.cache_clear()
    with pytest.raises(RuntimeError, match="no resolvable API key"):
        validate_startup_config()


def test_real_provider_with_a_key_passes(monkeypatch):
    monkeypatch.setenv("AI_PROVIDER", "groq")
    monkeypatch.setenv("AI_PROVIDERS__GROQ__API_KEY", "test-key")
    get_settings.cache_clear()
    validate_startup_config()  # must not raise


def test_real_provider_with_key_from_vendor_native_alias_passes(monkeypatch):
    monkeypatch.setenv("AI_PROVIDER", "deepseek")
    monkeypatch.setenv("DEEPSEEK_API_KEY", "test-key")
    get_settings.cache_clear()
    validate_startup_config()  # must not raise
