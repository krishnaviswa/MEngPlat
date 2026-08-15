"""National ID helpers — stored on the user, not government-verified KYC."""

from app.models import User, UserRole


def has_national_id(user: User) -> bool:
    number = (user.national_id_number or "").strip()
    return user.national_id_type is not None and bool(number)


def merchant_national_id_required(user: User) -> bool:
    return user.role == UserRole.MERCHANT and not has_national_id(user)


def mask_national_id_number(value: str | None) -> str | None:
    if value is None:
        return None
    digits = value.strip()
    if not digits:
        return None
    if len(digits) <= 4:
        return "••••"
    return "•" * (len(digits) - 4) + digits[-4:]


def apply_admin_national_id_mask(user: User) -> User:
    """Mutate a user about to be serialized for an admin list — never send full ID."""
    user.national_id_number = mask_national_id_number(user.national_id_number)
    return user
