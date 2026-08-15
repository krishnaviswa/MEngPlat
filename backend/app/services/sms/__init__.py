"""Public SMS port. Factory selected by SMS_PROVIDER=mock|msg91."""

from app.config import get_settings
from app.services.sms.base import SmsProvider
from app.services.sms.mock import MockSmsProvider
from app.services.sms.msg91 import Msg91SmsProvider

REGISTERED_PROVIDERS = ("mock", "msg91")


def validate_startup_config() -> None:
    settings = get_settings()
    name = settings.sms_provider.strip().lower()
    if name not in REGISTERED_PROVIDERS:
        raise RuntimeError(
            f"SMS_PROVIDER={settings.sms_provider!r} is not a registered provider. "
            f"Registered: {', '.join(REGISTERED_PROVIDERS)}"
        )
    if name == "msg91" and (not settings.msg91_auth_key or not settings.msg91_template_id):
        raise RuntimeError("SMS_PROVIDER=msg91 requires MSG91_AUTH_KEY and MSG91_TEMPLATE_ID.")


def get_sms_provider() -> SmsProvider:
    settings = get_settings()
    if settings.sms_provider.strip().lower() == "msg91":
        return Msg91SmsProvider()
    return MockSmsProvider()
