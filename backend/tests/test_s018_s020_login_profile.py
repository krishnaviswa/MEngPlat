"""Integration coverage for three slices that share the same login/profile
code paths and were built together: S-018 (secure logout), S-019 (profile
enrichment), S-020 (mandatory TOTP on password login).

Unlike test_mfa.py / test_google_auth.py (router functions called directly
with a fake DB), this file goes through ASGITransport + app.main:app against
the real database configured for this environment (see backend/.env) --
following the same pattern already used by test_api.py, test_businesses_mine.py
and test_s011_s016_batch.py. Each scenario is one flow in a single test
function (register -> login -> enroll/verify -> profile -> logout) rather
than split across many small test functions, because this environment's
pytest-asyncio uses a function-scoped event loop while the SQLAlchemy async
engine/connection pool is created once at import time: interleaving many
separate async DB-touching test *functions* in one run is what reproduces the
"another operation is in progress" / cross-loop asyncpg errors seen when the
full suite runs together (a pre-existing condition, not introduced here) --
keeping each flow to one test function/one event loop avoids adding to it.
Emails are uuid-suffixed so reruns against the persistent dev DB don't 409.
"""

import uuid

import pyotp
import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app
from app.routers import auth as auth_module
from app.services.google_auth import GoogleIdentity


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_password_login_totp_and_profile_enrichment_flow(client):
    email = f"totp-{uuid.uuid4().hex[:8]}@example.com"
    password = "testpass1234"

    # --- register: no tokens issued at registration time ---
    register = await client.post(
        "/api/v1/auth/register",
        json={"email": email, "full_name": "Totp User", "password": password, "role": "customer"},
    )
    assert register.status_code == 201, register.text

    # --- S-020 AC1: first password login requires enrollment, no tokens ---
    login1 = await client.post("/api/v1/auth/login", json={"email": email, "password": password})
    assert login1.status_code == 200, login1.text
    body1 = login1.json()
    assert body1["mfa_enrollment_required"] is True
    assert body1.get("access_token") is None
    assert body1.get("refresh_token") is None
    mfa_token = body1["mfa_token"]
    assert mfa_token

    # The interim mfa_token must not work as a session/access token.
    me_with_mfa_token = await client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {mfa_token}"})
    assert me_with_mfa_token.status_code == 401

    # --- S-020 AC1: setup returns QR/secret/URI for the authenticator app ---
    setup = await client.post("/api/v1/auth/mfa/totp/setup", json={"mfa_token": mfa_token})
    assert setup.status_code == 200, setup.text
    setup_body = setup.json()
    assert setup_body["secret"]
    assert setup_body["otpauth_uri"].startswith("otpauth://")
    assert "<svg" in setup_body["qr_svg"].lower()
    secret = setup_body["secret"]

    # --- S-020 AC4: wrong code on confirm -> 401, no tokens ---
    bad_confirm = await client.post(
        "/api/v1/auth/mfa/totp/confirm", json={"mfa_token": mfa_token, "code": "000000"}
    )
    assert bad_confirm.status_code == 401
    assert "access_token" not in bad_confirm.json()

    # --- S-020 AC1: correct code on confirm -> tokens, TOTP now enabled ---
    confirm = await client.post(
        "/api/v1/auth/mfa/totp/confirm",
        json={"mfa_token": mfa_token, "code": pyotp.TOTP(secret).now()},
    )
    assert confirm.status_code == 200, confirm.text
    tokens1 = confirm.json()
    assert tokens1["access_token"] and tokens1["refresh_token"]

    headers1 = {"Authorization": f"Bearer {tokens1['access_token']}"}
    me1 = await client.get("/api/v1/auth/me", headers=headers1)
    assert me1.status_code == 200
    assert me1.json()["totp_enabled"] is True

    # --- S-019 AC1/AC2: phone/address/national-ID fields persist via PATCH /auth/me ---
    patch = await client.patch(
        "/api/v1/auth/me",
        headers=headers1,
        json={
            "phone": "+91 98765 43210",
            "address_line1": "221B Baker Street",
            "address_line2": "Near Central Park",
            "city": "Chennai",
            "state": "TN",
            "postal_code": "600001",
            "country": "India",
            "national_id_type": "pan",
            "national_id_number": "ABCDE1234F",
        },
    )
    assert patch.status_code == 200, patch.text
    patched = patch.json()
    assert patched["phone"] == "+91 98765 43210"
    assert patched["address_line1"] == "221B Baker Street"
    assert patched["city"] == "Chennai"
    assert patched["national_id_type"] == "pan"
    assert patched["national_id_number"] == "ABCDE1234F"

    me_after_patch = await client.get("/api/v1/auth/me", headers=headers1)
    assert me_after_patch.status_code == 200
    me_after_patch_body = me_after_patch.json()
    assert me_after_patch_body["national_id_number"] == "ABCDE1234F"
    # S-019 AC3 depends on this flag being visible on the user payload the
    # frontend renders sign-in security status from.
    assert me_after_patch_body["totp_enabled"] is True

    # --- S-018 AC3: logout revokes the token; auth.me() then fails ---
    logout = await client.post(
        "/api/v1/auth/logout",
        headers=headers1,
        json={"refresh_token": tokens1["refresh_token"]},
    )
    assert logout.status_code == 200
    me_after_logout = await client.get("/api/v1/auth/me", headers=headers1)
    assert me_after_logout.status_code == 401

    # --- S-020 AC2: second password login requires verify, not re-enrollment ---
    login2 = await client.post("/api/v1/auth/login", json={"email": email, "password": password})
    assert login2.status_code == 200
    body2 = login2.json()
    assert body2["mfa_required"] is True
    assert body2["mfa_enrollment_required"] is False
    assert body2.get("access_token") is None
    mfa_token2 = body2["mfa_token"]

    # --- S-020 AC4: wrong code on verify -> 401, no tokens ---
    bad_verify = await client.post(
        "/api/v1/auth/mfa/totp/verify", json={"mfa_token": mfa_token2, "code": "000000"}
    )
    assert bad_verify.status_code == 401
    assert "access_token" not in bad_verify.json()

    # --- S-020 AC2: correct code on verify -> new session tokens ---
    verify = await client.post(
        "/api/v1/auth/mfa/totp/verify",
        json={"mfa_token": mfa_token2, "code": pyotp.TOTP(secret).now()},
    )
    assert verify.status_code == 200, verify.text
    tokens2 = verify.json()
    assert tokens2["access_token"] and tokens2["access_token"] != tokens1["access_token"]

    # The old (logged-out) token is still revoked -- confirms logout state
    # wasn't accidentally reset by the second login.
    still_revoked = await client.get("/api/v1/auth/me", headers=headers1)
    assert still_revoked.status_code == 401


@pytest.mark.asyncio
async def test_google_login_bypasses_totp(client, monkeypatch):
    """S-020 AC3: Google sign-in issues session tokens directly -- no MFA
    step, regardless of whether the account has TOTP enrolled."""
    email = f"google-{uuid.uuid4().hex[:8]}@example.com"
    identity = GoogleIdentity(
        sub=f"sub-{uuid.uuid4().hex[:8]}",
        email=email,
        email_verified=True,
        name="Google User",
        picture=None,
    )

    async def fake_verify(_credential, _client_id):
        return identity

    monkeypatch.setattr(auth_module, "verify_google_id_token", fake_verify)

    res = await client.post("/api/v1/auth/google", json={"credential": "whatever"})
    assert res.status_code == 200, res.text
    tokens = res.json()
    assert tokens["access_token"] and tokens["refresh_token"]

    me = await client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {tokens['access_token']}"})
    assert me.status_code == 200
    body = me.json()
    assert body["auth_provider"] == "google"
    assert body["totp_enabled"] is False


@pytest.mark.asyncio
async def test_auth_me_and_logout_require_authentication(client):
    """Auth/RBAC baseline (Tester required scenario): every endpoint these
    three slices touch must 401 without a Bearer token."""
    unauth_get = await client.get("/api/v1/auth/me")
    assert unauth_get.status_code == 401

    unauth_patch = await client.patch("/api/v1/auth/me", json={"phone": "123"})
    assert unauth_patch.status_code == 401

    unauth_logout = await client.post("/api/v1/auth/logout")
    assert unauth_logout.status_code == 401
