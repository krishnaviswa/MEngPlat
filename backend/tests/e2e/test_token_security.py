"""JWT claim shape, refresh-as-access, logout blocklist (TP-S-010)."""

from __future__ import annotations

from uuid import uuid4

import pytest
from jose import jwt

from tests.e2e.api_client import Api

pytestmark = pytest.mark.e2e


def test_access_token_claims(api: Api) -> None:
    email = f"e2e-jwt-{uuid4().hex[:10]}@example.com"
    user = api.register(email, role="customer")
    tokens = api.tokens(email)
    claims = jwt.get_unverified_claims(tokens.access_token)
    assert claims.get("type") == "access"
    assert claims.get("role") == "customer"
    assert claims.get("exp")
    assert str(claims.get("sub")) == str(user.id)


def test_refresh_token_rejected_on_protected_route(api: Api) -> None:
    email = f"e2e-ref-{uuid4().hex[:10]}@example.com"
    api.register(email)
    tokens = api.tokens(email)
    res = api.get("auth/me", token=tokens.refresh_token)
    assert res.status == 401


def test_logout_blocklists_token(api: Api) -> None:
    email = f"e2e-lo-{uuid4().hex[:10]}@example.com"
    api.register(email)
    tokens = api.tokens(email)
    out = api.post("auth/logout", token=tokens.access_token, json={"refresh_token": tokens.refresh_token})
    assert out.status == 200
    me = api.get("auth/me", token=tokens.access_token)
    assert me.status == 401
