"""v1 transactional templates -- factual event copy only, no AI-derived text (AC 7)."""

from app.config import get_settings


def password_reset_email(token: str) -> tuple[str, str]:
    settings = get_settings()
    link = f"{settings.public_app_url}/reset-password?token={token}"
    subject = "Reset your MerchantHub AI password"
    text = (
        "We received a request to reset your MerchantHub AI password.\n\n"
        f"Reset it here: {link}\n\n"
        "This link expires in 1 hour and can only be used once. "
        "If you didn't request this, you can safely ignore this email."
    )
    return subject, text


def listing_approved_email(business_name: str) -> tuple[str, str]:
    subject = f"{business_name} is now live on MerchantHub AI"
    text = (
        f'Good news -- your listing "{business_name}" has been approved and is now live on MerchantHub AI. '
        "Customers can now find and review it."
    )
    return subject, text


def new_review_email(business_name: str, rating: int | None = None) -> tuple[str, str]:
    subject = f"New review for {business_name}"
    rating_note = f" ({rating}-star)" if rating is not None else ""
    text = (
        f"You have a new review{rating_note} on {business_name}. "
        "Sign in to your merchant dashboard to read it and respond."
    )
    return subject, text
