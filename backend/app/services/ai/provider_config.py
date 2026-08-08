"""Resolve a provider's credentials from Settings.

Precedence, highest first:
  1. AI_PROVIDERS__<NAME>__<FIELD>        -- explicit per-provider config
  2. A vendor-native env alias             -- e.g. GROQ_API_KEY, ANTHROPIC_API_KEY
  3. AI_API_KEY / AI_BASE_URL / AI_MODEL   -- legacy triple, active provider only
  4. The spec's own default

The active-provider guard on step 3 is what keeps an existing deployment that
only ever set the legacy triple working unchanged: those three variables mean
"config for whichever provider AI_PROVIDER names," not "config for every
provider," so they must not leak into a provider that merely happens to be
registered but isn't selected.
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from typing import Protocol

from app.config import get_settings


class SpecLike(Protocol):
    """The subset of OpenAISpec (or an equivalent) this module needs.

    A Protocol rather than importing OpenAISpec directly, so provider modules
    can import this module without a cycle back through them.
    """

    name: str
    base_url: str
    default_model: str
    default_vision_model: str | None
    api_key_env: tuple[str, ...]


@dataclass(frozen=True)
class ResolvedProviderConfig:
    api_key: str
    base_url: str
    model: str
    vision_model: str


def _first_set_env(names: tuple[str, ...]) -> str:
    for name in names:
        if value := os.environ.get(name):
            return value
    return ""


def _credentials_for(spec: SpecLike):
    """Case-insensitive lookup into settings.ai_providers.

    Env-var segment casing for dict keys under env_nested_delimiter is not
    guaranteed to come through lowercased (only declared field names get that
    treatment), so AI_PROVIDERS__DEEPSEEK__... may land as the key "DEEPSEEK"
    rather than "deepseek". Compare case-insensitively rather than assume one.
    """
    providers = get_settings().ai_providers
    target = spec.name.strip().lower()
    for key, value in providers.items():
        if key.strip().lower() == target:
            return value
    return None


def resolve_provider_config(spec: SpecLike) -> ResolvedProviderConfig:
    settings = get_settings()  # called inside the function -- see note in __init__.py
    entry = _credentials_for(spec)
    is_active = spec.name.strip().lower() == settings.ai_provider.strip().lower()

    api_key = (
        (entry.api_key if entry else "")
        or _first_set_env(spec.api_key_env)
        or (settings.ai_api_key if is_active else "")
    )
    base_url = (
        (entry.base_url if entry else "")
        or (settings.ai_base_url if is_active else "")
        or spec.base_url
    ).rstrip("/")
    model = (
        (entry.model if entry else "")
        or (settings.ai_model if is_active else "")
        or spec.default_model
    )
    vision_model = (
        (entry.vision_model if entry else "")
        or (settings.ai_vision_model if is_active else "")
        or spec.default_vision_model
        or model
    )
    return ResolvedProviderConfig(api_key=api_key, base_url=base_url, model=model, vision_model=vision_model)
