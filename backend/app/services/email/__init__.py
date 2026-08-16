"""Public entry point for the email layer. Routers/services call these, never a provider class directly."""

import logging

from app.config import get_settings
from app.services.email.base import EmailProvider
from app.services.email.mock import MockEmailProvider
from app.services.email.resend import ResendEmailProvider
from app.services.email.templates import (
    listing_approved_email,
    new_review_email,
    password_reset_email,
    whatsapp_draft_approved_email,
)

logger = logging.getLogger("app.email")

REGISTERED_PROVIDERS = ("mock", "resend")


def validate_startup_config() -> None:
    """Fail fast on bad EMAIL_PROVIDER config, at boot rather than on first send."""
    settings = get_settings()
    name = settings.email_provider.strip().lower()

    if name not in REGISTERED_PROVIDERS:
        raise RuntimeError(
            f"EMAIL_PROVIDER={settings.email_provider!r} is not a registered provider. "
            f"Registered: {', '.join(REGISTERED_PROVIDERS)}"
        )

    if name == "resend" and (not settings.resend_api_key or not settings.email_from):
        raise RuntimeError(
            "EMAIL_PROVIDER=resend requires RESEND_API_KEY and EMAIL_FROM to be set."
        )


def get_email_provider() -> EmailProvider:
    settings = get_settings()
    if settings.email_provider.strip().lower() == "resend":
        return ResendEmailProvider()
    return MockEmailProvider()


async def _try_send(to: str, subject: str, text: str) -> None:
    """Catches all send exceptions, logs, returns -- callers must never fail on this."""
    try:
        provider = get_email_provider()
        await provider.send(to, subject, text)
    except Exception:
        logger.exception("Email send failed to=%s subject=%r", to, subject)


async def try_send_password_reset(to: str, token: str) -> None:
    subject, text = password_reset_email(token)
    await _try_send(to, subject, text)


async def try_send_listing_approved(to: str, business_name: str) -> None:
    subject, text = listing_approved_email(business_name)
    await _try_send(to, subject, text)


async def try_send_new_review(to: str, business_name: str, rating: int | None = None) -> None:
    subject, text = new_review_email(business_name, rating)
    await _try_send(to, subject, text)


async def try_send_whatsapp_draft_approved(to: str, business_name: str) -> None:
    subject, text = whatsapp_draft_approved_email(business_name)
    await _try_send(to, subject, text)


__all__ = [
    "EmailProvider",
    "get_email_provider",
    "validate_startup_config",
    "try_send_password_reset",
    "try_send_listing_approved",
    "try_send_new_review",
    "try_send_whatsapp_draft_approved",
]
