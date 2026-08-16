"""Provider registry.

Adding a provider means adding one module under `providers/` that calls
`register_provider`. Nothing here or in config.py needs editing. Copied
verbatim (shape-wise) from `app/services/ai/registry.py` for consistency.
"""

from __future__ import annotations

import importlib
import pkgutil
from collections.abc import Callable

from app.services.review_sources.base import ReviewSourceProvider

ProviderFactory = Callable[[], ReviewSourceProvider]


class UnknownReviewSourceProviderError(LookupError):
    """Raised when a provider name was never registered."""


_REGISTRY: dict[str, ProviderFactory] = {}
_loaded = False


def register_provider(name: str, factory: ProviderFactory | None = None):
    """Register a provider. Usable as a decorator or called directly.

        @register_provider("mock")
        class MockReviewSourceProvider(ReviewSourceProvider): ...
    """
    key = name.strip().lower()

    def bind(target: ProviderFactory) -> ProviderFactory:
        if key in _REGISTRY:
            raise ValueError(f"Review source provider {key!r} is already registered")
        _REGISTRY[key] = target
        return target

    return bind(factory) if factory is not None else bind


def load_providers() -> None:
    """Import every module under `providers/` so registrations happen.

    Deliberately not wrapped in try/except: a provider module that fails to
    import should break the process loudly at startup, not disappear.
    """
    global _loaded
    if _loaded:
        return
    _loaded = True

    from app.services.review_sources import providers

    for module in sorted(pkgutil.iter_modules(providers.__path__), key=lambda m: m.name):
        importlib.import_module(f"{providers.__name__}.{module.name}")


def available_providers() -> list[str]:
    load_providers()
    return sorted(_REGISTRY)


def create_provider(name: str) -> ReviewSourceProvider:
    load_providers()
    key = (name or "").strip().lower()
    try:
        factory = _REGISTRY[key]
    except KeyError:
        raise UnknownReviewSourceProviderError(
            f"Unknown review source provider {name!r}. Registered: {', '.join(sorted(_REGISTRY))}"
        ) from None
    return factory()
