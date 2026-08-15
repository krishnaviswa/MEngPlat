"""Public entry for the payments port. Routers call get_payment_provider(), never a class."""

from app.config import get_settings
from app.services.payments.base import PaymentProvider
from app.services.payments.mock import MockPaymentProvider
from app.services.payments.razorpay import RazorpayPaymentProvider

REGISTERED_PROVIDERS = ("mock", "razorpay")


def validate_startup_config() -> None:
    settings = get_settings()
    name = settings.payments_provider.strip().lower()
    if name not in REGISTERED_PROVIDERS:
        raise RuntimeError(
            f"PAYMENTS_PROVIDER={settings.payments_provider!r} is not a registered provider. "
            f"Registered: {', '.join(REGISTERED_PROVIDERS)}"
        )
    if name == "razorpay" and (
        not settings.razorpay_key_id or not settings.razorpay_key_secret or not settings.razorpay_webhook_secret
    ):
        raise RuntimeError(
            "PAYMENTS_PROVIDER=razorpay requires RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET, "
            "and RAZORPAY_WEBHOOK_SECRET."
        )


def get_payment_provider() -> PaymentProvider:
    settings = get_settings()
    if settings.payments_provider.strip().lower() == "razorpay":
        return RazorpayPaymentProvider()
    return MockPaymentProvider()


__all__ = [
    "PaymentProvider",
    "get_payment_provider",
    "validate_startup_config",
]
