"""Public entry for the WhatsApp port (S-050)."""

from app.config import get_settings
from app.services.whatsapp.base import InboundMessage, WhatsAppProvider
from app.services.whatsapp.registry import (
    UnknownWhatsAppProviderError,
    create_provider,
    register_provider,
)


def get_whatsapp_provider() -> WhatsAppProvider:
    settings = get_settings()
    name = (settings.whatsapp_provider or "mock").strip().lower()
    if name == "meta_cloud" and not settings.meta_whatsapp_access_token:
        name = "mock"
    return create_provider(name)


__all__ = [
    "InboundMessage",
    "UnknownWhatsAppProviderError",
    "WhatsAppProvider",
    "create_provider",
    "get_whatsapp_provider",
    "register_provider",
]
