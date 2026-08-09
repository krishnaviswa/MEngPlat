"""Verifies Google Identity Services ID tokens ("credential" in GSI's own
terminology). Isolated behind verify_google_id_token so tests can monkeypatch
verification without a network call to Google's live JWKS endpoint, and so a
malformed or forged token becomes one typed exception instead of whatever
google-auth happens to raise internally (ValueError, GoogleAuthError, a
requests exception fetching certs, ...).
"""

import asyncio
from dataclasses import dataclass

from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token

_request = google_requests.Request()


@dataclass(frozen=True)
class GoogleIdentity:
    sub: str
    email: str
    email_verified: bool
    name: str
    picture: str | None


class InvalidGoogleTokenError(Exception):
    pass


async def verify_google_id_token(credential: str, client_id: str) -> GoogleIdentity:
    """Verifies signature, expiry, issuer, and audience against client_id.

    Raises InvalidGoogleTokenError on any failure -- expired, wrong audience,
    bad signature, or a credential that isn't a Google ID token at all.

    verify_oauth2_token is synchronous and does a blocking network call to
    fetch Google's JWKS certs (cached afterwards, but the first call and
    every eventual cache refresh still hit the network) -- run it off the
    event loop rather than stalling every other in-flight request on it.
    """
    try:
        claims = await asyncio.to_thread(
            google_id_token.verify_oauth2_token, credential, _request, client_id
        )
    except Exception as exc:
        raise InvalidGoogleTokenError(str(exc)) from exc

    return GoogleIdentity(
        sub=claims["sub"],
        email=claims.get("email", ""),
        email_verified=bool(claims.get("email_verified", False)),
        name=claims.get("name") or claims.get("email", ""),
        picture=claims.get("picture"),
    )
