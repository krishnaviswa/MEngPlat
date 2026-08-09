"""get_current_user's blocklist check -- the highest-value test in this set:
a blocklisted token must be rejected before the database is ever touched, and
a non-blocklisted token must still reach the normal user lookup rather than
the blocklist check silently denying everything.
"""

import uuid

import pytest
from fastapi import HTTPException
from fastapi.security import HTTPAuthorizationCredentials

import app.dependencies as dependencies_module
from app.core.security import create_access_token


def _creds(token: str) -> HTTPAuthorizationCredentials:
    return HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)


class _ExplodingDB:
    async def execute(self, *args, **kwargs):
        raise AssertionError("blocklisted token must not reach the database")


async def test_get_current_user_rejects_blocklisted_token_without_hitting_db(monkeypatch):
    async def always_blocklisted(jti):
        return True

    monkeypatch.setattr(dependencies_module, "is_token_blocklisted", always_blocklisted)

    token = create_access_token(str(uuid.uuid4()))

    with pytest.raises(HTTPException) as exc_info:
        await dependencies_module.get_current_user(_creds(token), _ExplodingDB())

    assert exc_info.value.status_code == 401
    assert "revoked" in exc_info.value.detail.lower()


async def test_get_current_user_proceeds_to_db_when_not_blocklisted(monkeypatch):
    async def never_blocklisted(jti):
        return False

    monkeypatch.setattr(dependencies_module, "is_token_blocklisted", never_blocklisted)

    class _EmptyResult:
        def scalar_one_or_none(self):
            return None

    class _EmptyDB:
        async def execute(self, *args, **kwargs):
            return _EmptyResult()

    token = create_access_token(str(uuid.uuid4()))

    with pytest.raises(HTTPException) as exc_info:
        await dependencies_module.get_current_user(_creds(token), _EmptyDB())

    # Reaches the "user not found" branch (the DB was actually queried)
    # rather than the blocklist branch -- proves the check isn't a blanket
    # denial, only triggered when the jti is actually found.
    assert exc_info.value.status_code == 401
    assert "user not found" in exc_info.value.detail.lower()
