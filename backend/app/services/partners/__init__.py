"""Public entry for the partner review channel port (S-123).

Routers/services call ``get_partner_provider()``, never a provider class.
Default ``PARTNERS_PROVIDER=mock`` -- verifies HMAC for real, logs callbacks.
An ``http`` adapter with retry/backoff is a later slice (ADR-019).
"""

from app.config import get_settings
from app.services.partners.base import PartnerProvider
from app.services.partners.mock import MockPartnerProvider

REGISTERED_PROVIDERS = ("mock",)


def validate_startup_config() -> None:
    """Fail fast on a bad PARTNERS_PROVIDER at boot, not on the first partner call."""
    settings = get_settings()
    name = settings.partners_provider.strip().lower()
    if name not in REGISTERED_PROVIDERS:
        raise RuntimeError(
            f"PARTNERS_PROVIDER={settings.partners_provider!r} is not a registered provider. "
            f"Registered: {', '.join(REGISTERED_PROVIDERS)}"
        )


def get_partner_provider() -> PartnerProvider:
    # Only ``mock`` is registered today; the check above keeps this honest.
    return MockPartnerProvider()


__all__ = [
    "PartnerProvider",
    "get_partner_provider",
    "validate_startup_config",
]
