"""TOTP (authenticator app) helpers for mandatory password-login MFA."""

from __future__ import annotations

import base64
import hashlib
import io

import pyotp
import qrcode
import qrcode.image.svg
from cryptography.fernet import Fernet, InvalidToken

from app.config import get_settings


def _fernet() -> Fernet:
    # Derive a stable 32-byte Fernet key from SECRET_KEY (no extra env var).
    digest = hashlib.sha256(get_settings().secret_key.encode("utf-8")).digest()
    return Fernet(base64.urlsafe_b64encode(digest))


def encrypt_totp_secret(plain_secret: str) -> str:
    return _fernet().encrypt(plain_secret.encode("utf-8")).decode("utf-8")


def decrypt_totp_secret(cipher_text: str) -> str:
    try:
        return _fernet().decrypt(cipher_text.encode("utf-8")).decode("utf-8")
    except InvalidToken as exc:
        raise ValueError("Invalid TOTP secret") from exc


def generate_totp_secret() -> str:
    return pyotp.random_base32()


def build_otpauth_uri(secret: str, email: str) -> str:
    settings = get_settings()
    totp = pyotp.TOTP(secret)
    return totp.provisioning_uri(name=email, issuer_name=settings.app_name)


def qr_svg_for_uri(otpauth_uri: str) -> str:
    img = qrcode.make(otpauth_uri, image_factory=qrcode.image.svg.SvgPathImage)
    buf = io.BytesIO()
    img.save(buf)
    return buf.getvalue().decode("utf-8")


def verify_totp_code(secret: str, code: str) -> bool:
    cleaned = code.strip().replace(" ", "")
    if not cleaned.isdigit():
        return False
    totp = pyotp.TOTP(secret)
    # valid_window=1 tolerates ±30s clock skew
    return bool(totp.verify(cleaned, valid_window=1))


# Fixed base32 secret for seeded demo password accounts (README §1).
DEMO_TOTP_SECRET = "JBSWY3DPEHPK3PXP"


def enable_demo_totp(user: object) -> None:
    """Attach the shared demo authenticator secret to a User-like object."""
    user.totp_secret = encrypt_totp_secret(DEMO_TOTP_SECRET)  # type: ignore[attr-defined]
    user.totp_enabled = True  # type: ignore[attr-defined]
