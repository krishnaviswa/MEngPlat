"""Registry behaviour: discovery, lookup, and failure modes.

These tests need no database and no network.
"""

import pytest

from app.config import get_settings
from app.services.ai import (
    UnknownAIProviderError,
    available_providers,
    create_provider,
    get_ai_provider,
    register_provider,
)
from app.services.ai.providers.mock import MockAIProvider
from app.services.ai.registry import _REGISTRY


def test_autoload_discovers_every_provider_module():
    names = available_providers()
    assert "mock" in names
    # Registered by providers/openai_compatible.py purely as a side effect of
    # the module existing -- nothing imports it explicitly.
    assert "openai" in names
    assert "deepseek" in names


def test_create_provider_returns_the_registered_class():
    assert isinstance(create_provider("mock"), MockAIProvider)


def test_lookup_is_case_and_whitespace_insensitive():
    assert isinstance(create_provider("  MoCk "), MockAIProvider)


def test_unknown_provider_names_the_registered_ones():
    with pytest.raises(UnknownAIProviderError) as excinfo:
        create_provider("definitely-not-a-provider")

    message = str(excinfo.value)
    assert "definitely-not-a-provider" in message
    # The error has to be actionable -- a typo'd AI_PROVIDER should tell the
    # operator what the valid values are.
    assert "mock" in message


def test_duplicate_registration_is_rejected():
    with pytest.raises(ValueError, match="already registered"):
        register_provider("mock", MockAIProvider)


def test_registering_a_new_provider_needs_no_edits_elsewhere():
    """The whole point of the registry: one call is enough to make it resolvable."""
    try:
        register_provider("temp-test-provider", MockAIProvider)
        assert "temp-test-provider" in available_providers()
        assert isinstance(create_provider("temp-test-provider"), MockAIProvider)
    finally:
        _REGISTRY.pop("temp-test-provider", None)


def test_get_ai_provider_follows_the_ai_provider_setting(monkeypatch):
    monkeypatch.setenv("AI_PROVIDER", "mock")
    get_settings.cache_clear()
    try:
        assert isinstance(get_ai_provider(), MockAIProvider)
    finally:
        get_settings.cache_clear()


def test_settings_are_read_per_call_not_at_import(monkeypatch):
    """Regression guard for the lru_cache trap.

    This module used to bind `settings = get_settings()` at import time, which
    made AI configuration unchangeable once anything had imported it. Switching
    AI_PROVIDER between two calls has to actually change what comes back.
    """
    monkeypatch.setenv("AI_PROVIDER", "mock")
    get_settings.cache_clear()
    try:
        assert get_ai_provider().provider_name == "mock"

        monkeypatch.setenv("AI_PROVIDER", "openai")
        get_settings.cache_clear()
        assert get_ai_provider().provider_name == "openai"
    finally:
        get_settings.cache_clear()


def test_unregistered_provider_name_is_rejected_at_creation(monkeypatch):
    """AI_PROVIDER is a plain str now (was Literal["mock","openai","deepseek"]),
    so create_provider(), not pydantic, is what rejects a typo."""
    monkeypatch.setenv("AI_PROVIDER", "definitely-not-a-provider")
    get_settings.cache_clear()
    try:
        with pytest.raises(UnknownAIProviderError):
            get_ai_provider()
    finally:
        get_settings.cache_clear()
