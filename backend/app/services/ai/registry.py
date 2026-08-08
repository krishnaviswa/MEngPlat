"""Provider registry.

Adding a provider means adding one module under `providers/` that calls
`register_provider`. Nothing here, in config.py, or in the factory needs editing.
"""

from __future__ import annotations

import importlib
import pkgutil
from collections.abc import Callable

from app.services.ai.base import AIProvider

ProviderFactory = Callable[[], AIProvider]


class UnknownAIProviderError(LookupError):
    """Raised when AI_PROVIDER names a provider that was never registered."""


_REGISTRY: dict[str, ProviderFactory] = {}
_loaded = False


def register_provider(name: str, factory: ProviderFactory | None = None):
    """Register a provider. Usable as a decorator or called directly.

        @register_provider("mock")
        class MockAIProvider(AIProvider): ...

        register_provider("deepseek", partial(OpenAICompatibleProvider, spec=spec))
    """
    key = name.strip().lower()

    def bind(target: ProviderFactory) -> ProviderFactory:
        if key in _REGISTRY:
            raise ValueError(f"AI provider {key!r} is already registered")
        _REGISTRY[key] = target
        return target

    return bind(factory) if factory is not None else bind


def load_providers() -> None:
    """Import every module under `providers/` so registrations happen.

    Deliberately not wrapped in try/except: a provider module that fails to
    import should break the process loudly at startup, not disappear and leave
    the app silently degraded to a different provider in production.
    """
    global _loaded
    if _loaded:
        return
    _loaded = True

    from app.services.ai import providers

    for module in sorted(pkgutil.iter_modules(providers.__path__), key=lambda m: m.name):
        importlib.import_module(f"{providers.__name__}.{module.name}")


def available_providers() -> list[str]:
    load_providers()
    return sorted(_REGISTRY)


def create_provider(name: str) -> AIProvider:
    load_providers()
    key = (name or "").strip().lower()
    try:
        factory = _REGISTRY[key]
    except KeyError:
        raise UnknownAIProviderError(
            f"Unknown AI provider {name!r}. Registered: {', '.join(sorted(_REGISTRY))}"
        ) from None
    return factory()
