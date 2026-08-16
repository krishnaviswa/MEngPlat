"""Provider registry — same shape as `app/services/review_sources/registry.py`."""

from __future__ import annotations

import importlib
import pkgutil
from collections.abc import Callable

from app.services.whatsapp.base import WhatsAppProvider

ProviderFactory = Callable[[], WhatsAppProvider]

_REGISTRY: dict[str, ProviderFactory] = {}
_loaded = False


class UnknownWhatsAppProviderError(LookupError):
    """Raised when a provider name was never registered."""


def register_provider(name: str, factory: ProviderFactory | None = None):
    key = name.strip().lower()

    def bind(target: ProviderFactory) -> ProviderFactory:
        if key in _REGISTRY:
            raise ValueError(f"WhatsApp provider {key!r} is already registered")
        _REGISTRY[key] = target
        return target

    return bind(factory) if factory is not None else bind


def load_providers() -> None:
    global _loaded
    if _loaded:
        return
    _loaded = True

    from app.services.whatsapp import providers

    for module in sorted(pkgutil.iter_modules(providers.__path__), key=lambda m: m.name):
        importlib.import_module(f"{providers.__name__}.{module.name}")


def create_provider(name: str) -> WhatsAppProvider:
    load_providers()
    key = (name or "").strip().lower()
    try:
        factory = _REGISTRY[key]
    except KeyError:
        raise UnknownWhatsAppProviderError(
            f"Unknown WhatsApp provider {name!r}. Registered: {', '.join(sorted(_REGISTRY))}"
        ) from None
    return factory()
