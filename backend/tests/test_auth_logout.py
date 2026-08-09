"""POST /auth/logout -- calls the route handler directly with real JWTs and a
monkeypatched blocklist_token, following test_reviews.py's convention of
bypassing ASGI + a real database (none is reachable in this environment).

auth.py imports blocklist_token/is_token_blocklisted at module load time
(`from app.services.cache import ...`), so patches target `auth_module`, not
`app.services.cache` -- patching the source module wouldn't reach the name
already bound into auth.py's namespace.
"""

import uuid

import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

from app.core.security import create_access_token, create_refresh_token
from app.routers import auth as auth_module
from app.schemas import LogoutRequest


def _creds(token: str) -> HTTPAuthorizationCredentials:
    return HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)


async def test_logout_blocklists_access_and_refresh_tokens(monkeypatch):
    calls: list[str] = []

    async def fake_blocklist_token(jti, exp):
        calls.append(jti)

    monkeypatch.setattr(auth_module, "blocklist_token", fake_blocklist_token)

    subject = str(uuid.uuid4())
    access = create_access_token(subject)
    refresh = create_refresh_token(subject)

    result = await auth_module.logout(LogoutRequest(refresh_token=refresh), _creds(access))

    assert "Logged out" in result.message
    assert len(calls) == 2


async def test_logout_without_refresh_token_only_blocklists_access(monkeypatch):
    calls: list[str] = []

    async def fake_blocklist_token(jti, exp):
        calls.append(jti)

    monkeypatch.setattr(auth_module, "blocklist_token", fake_blocklist_token)

    access = create_access_token(str(uuid.uuid4()))

    result = await auth_module.logout(None, _creds(access))

    assert "Logged out" in result.message
    assert len(calls) == 1


async def test_logout_without_credentials_returns_401():
    with pytest.raises(HTTPException) as exc_info:
        await auth_module.logout(None, None)

    assert exc_info.value.status_code == 401


async def test_logout_ignores_garbage_refresh_token(monkeypatch):
    calls: list[str] = []

    async def fake_blocklist_token(jti, exp):
        calls.append(jti)

    monkeypatch.setattr(auth_module, "blocklist_token", fake_blocklist_token)

    access = create_access_token(str(uuid.uuid4()))

    result = await auth_module.logout(LogoutRequest(refresh_token="not-a-real-jwt"), _creds(access))

    # Malformed bonus field is ignored, not fatal -- only the access token's
    # jti gets blocklisted.
    assert "Logged out" in result.message
    assert len(calls) == 1


async def test_logout_rejects_refresh_token_used_as_access_token():
    refresh = create_refresh_token(str(uuid.uuid4()))

    with pytest.raises(HTTPException) as exc_info:
        await auth_module.logout(None, _creds(refresh))

    assert exc_info.value.status_code == 401
