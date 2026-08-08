"""Credential resolution precedence.

AI_PROVIDERS__<NAME>__<FIELD> > vendor-native env alias > legacy AI_API_KEY
triple (active provider only) > the spec's own default.
"""

from dataclasses import dataclass

from app.config import get_settings
from app.services.ai.provider_config import resolve_provider_config


@dataclass(frozen=True)
class FakeSpec:
    name: str = "fakevendor"
    base_url: str = "https://fake.example/v1"
    default_model: str = "fake-default-model"
    default_vision_model: str | None = None
    api_key_env: tuple[str, ...] = ("FAKEVENDOR_API_KEY",)


def _reload():
    get_settings.cache_clear()
    return get_settings()


class TestPrecedence:
    def test_falls_back_to_spec_defaults_with_no_config_at_all(self, monkeypatch):
        monkeypatch.setenv("AI_PROVIDER", "something-else")
        _reload()
        cfg = resolve_provider_config(FakeSpec())
        assert cfg.api_key == ""
        assert cfg.base_url == "https://fake.example/v1"
        assert cfg.model == "fake-default-model"
        get_settings.cache_clear()

    def test_vendor_native_env_alias_wins_over_spec_default(self, monkeypatch):
        monkeypatch.setenv("AI_PROVIDER", "something-else")
        monkeypatch.setenv("FAKEVENDOR_API_KEY", "from-native-alias")
        _reload()
        cfg = resolve_provider_config(FakeSpec())
        assert cfg.api_key == "from-native-alias"
        get_settings.cache_clear()

    def test_legacy_triple_applies_only_to_the_active_provider(self, monkeypatch):
        """The bug this guards: AI_API_KEY used to apply globally regardless
        of which provider was actually selected."""
        monkeypatch.setenv("AI_PROVIDER", "some-other-provider")
        monkeypatch.setenv("AI_API_KEY", "leaked-legacy-key")
        _reload()
        cfg = resolve_provider_config(FakeSpec())
        assert cfg.api_key == "", "legacy key must not leak into a provider that isn't active"
        get_settings.cache_clear()

    def test_legacy_triple_applies_when_this_provider_is_active(self, monkeypatch):
        monkeypatch.setenv("AI_PROVIDER", "fakevendor")
        monkeypatch.setenv("AI_API_KEY", "active-legacy-key")
        monkeypatch.setenv("AI_BASE_URL", "https://legacy.example/v1")
        monkeypatch.setenv("AI_MODEL", "legacy-model")
        _reload()
        cfg = resolve_provider_config(FakeSpec())
        assert cfg.api_key == "active-legacy-key"
        assert cfg.base_url == "https://legacy.example/v1"
        assert cfg.model == "legacy-model"
        get_settings.cache_clear()

    def test_per_provider_override_beats_everything(self, monkeypatch):
        monkeypatch.setenv("AI_PROVIDER", "fakevendor")
        monkeypatch.setenv("AI_API_KEY", "active-legacy-key")
        monkeypatch.setenv("FAKEVENDOR_API_KEY", "from-native-alias")
        monkeypatch.setenv("AI_PROVIDERS__FAKEVENDOR__API_KEY", "explicit-override")
        monkeypatch.setenv("AI_PROVIDERS__FAKEVENDOR__MODEL", "explicit-model")
        _reload()
        cfg = resolve_provider_config(FakeSpec())
        assert cfg.api_key == "explicit-override"
        assert cfg.model == "explicit-model"
        # Untouched fields still fall through the chain.
        assert cfg.base_url == "https://fake.example/v1"
        get_settings.cache_clear()

    def test_dict_key_lookup_is_case_insensitive(self, monkeypatch):
        """env_nested_delimiter parsing doesn't guarantee the dict key comes
        through lowercased -- the lookup has to tolerate either case."""
        monkeypatch.setenv("AI_PROVIDER", "something-else")
        monkeypatch.setenv("AI_PROVIDERS__FAKEVENDOR__API_KEY", "case-insensitive-hit")
        _reload()
        cfg = resolve_provider_config(FakeSpec(name="FakeVendor"))
        assert cfg.api_key == "case-insensitive-hit"
        get_settings.cache_clear()

    def test_vision_model_falls_back_to_text_model(self, monkeypatch):
        monkeypatch.setenv("AI_PROVIDER", "something-else")
        _reload()
        cfg = resolve_provider_config(FakeSpec(default_vision_model=None))
        assert cfg.vision_model == cfg.model
        get_settings.cache_clear()


class TestDoubleUnderscoreDoesNotBreakOrdinaryVars:
    """env_nested_delimiter="__" is a global parsing change -- confirm the
    ordinary single-underscore settings this app already depends on are
    unaffected."""

    def test_plain_settings_unaffected(self, monkeypatch):
        monkeypatch.setenv("SECRET_KEY", "some-secret")
        monkeypatch.setenv("AI_PROVIDER", "mock")
        settings = _reload()
        assert settings.secret_key == "some-secret"
        assert settings.ai_provider == "mock"
        get_settings.cache_clear()
