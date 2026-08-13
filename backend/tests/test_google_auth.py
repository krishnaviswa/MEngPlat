"""POST /auth/google (new-user creation, sub-based lookup, verified-email
account linking) and the /auth/login guard against password-less Google
accounts.

Calls the route handlers directly with a fake db rather than going through
ASGI + a real database (none is reachable in this environment -- see
test_business_service_summary.py for the same constraint). The fake
introspects the SQLAlchemy select().where() clause well enough to resolve
User.<column> == value lookups, which is all these handlers issue.
"""

import uuid
from unittest.mock import AsyncMock

import pytest
from fastapi import HTTPException

from app.models import User, UserRole
from app.routers.auth import google_auth, login
from app.schemas import GoogleAuthRequest, UserLogin
from app.services.google_auth import GoogleIdentity, InvalidGoogleTokenError, verify_google_id_token
from tests.auth_helpers import fake_request


class FakeScalarResult:
    def __init__(self, value):
        self._value = value

    def scalar_one_or_none(self):
        return self._value


class FakeDB:
    def __init__(self, users: list[User]):
        self._users = users
        self.added: list[User] = []
        self.flushed = False

    async def execute(self, stmt):
        wc = stmt.whereclause
        attr, value = wc.left.key, wc.right.value
        match = next((u for u in self._users if getattr(u, attr) == value), None)
        return FakeScalarResult(match)

    def add(self, obj):
        # is_active has a Python-side column default (True) that SQLAlchemy
        # only applies on a real flush -- replicate that here so a freshly
        # constructed User() looks the same as it would post-flush.
        if isinstance(obj, User) and obj.is_active is None:
            obj.is_active = True
        self.added.append(obj)
        self._users.append(obj)

    async def flush(self):
        self.flushed = True


def make_identity(**overrides) -> GoogleIdentity:
    defaults = dict(
        sub="google-sub-1",
        email="new.user@example.com",
        email_verified=True,
        name="New User",
        picture="https://example.com/pic.jpg",
    )
    defaults.update(overrides)
    return GoogleIdentity(**defaults)


@pytest.fixture(autouse=True)
def _patch_verify(monkeypatch):
    """Each test sets app.routers.auth.verify_google_id_token to whatever
    identity (or error) it needs -- default here just fails loudly so a test
    that forgets to patch it doesn't silently pass."""

    async def _unset(*a, **kw):
        raise AssertionError("verify_google_id_token was not patched for this test")

    import app.routers.auth as auth_module

    monkeypatch.setattr(auth_module, "verify_google_id_token", _unset)
    yield


def _patch_identity(monkeypatch, identity: GoogleIdentity | None = None, error: Exception | None = None):
    import app.routers.auth as auth_module

    async def fake_verify(credential, client_id):
        if error:
            raise error
        return identity

    monkeypatch.setattr(auth_module, "verify_google_id_token", fake_verify)


class TestNewAndReturningUsers:
    async def test_new_user_is_created_on_first_google_signin(self, monkeypatch):
        identity = make_identity()
        _patch_identity(monkeypatch, identity=identity)
        db = FakeDB(users=[])

        tokens = await google_auth(GoogleAuthRequest(credential="tok"), db)

        assert len(db.added) == 1
        created = db.added[0]
        assert created.email == identity.email
        assert created.google_sub == identity.sub
        assert created.auth_provider == "google"
        assert created.hashed_password is None
        assert created.role == UserRole.CUSTOMER
        assert created.avatar_url == identity.picture
        assert tokens.access_token and tokens.refresh_token

    async def test_returning_google_user_is_recognized_by_sub(self, monkeypatch):
        identity = make_identity(sub="existing-sub")
        _patch_identity(monkeypatch, identity=identity)
        existing = User(
            id=uuid.uuid4(),
            email=identity.email,
            full_name="Existing",
            hashed_password=None,
            role=UserRole.CUSTOMER,
            is_active=True,
            auth_provider="google",
            google_sub="existing-sub",
            email_verified=True,
        )
        db = FakeDB(users=[existing])

        await google_auth(GoogleAuthRequest(credential="tok"), db)

        assert db.added == []


class TestAccountLinking:
    async def test_links_existing_password_account_when_email_is_verified(self, monkeypatch):
        identity = make_identity(email="shared@example.com", sub="new-sub", email_verified=True)
        _patch_identity(monkeypatch, identity=identity)
        existing = User(
            id=uuid.uuid4(),
            email="shared@example.com",
            full_name="Password User",
            hashed_password="hashed",
            role=UserRole.CUSTOMER,
            is_active=True,
            auth_provider="password",
            google_sub=None,
            email_verified=False,
        )
        db = FakeDB(users=[existing])

        await google_auth(GoogleAuthRequest(credential="tok"), db)

        assert existing.google_sub == "new-sub"
        assert existing.email_verified is True
        assert db.added == []

    async def test_rejects_linking_when_google_email_is_unverified(self, monkeypatch):
        identity = make_identity(email="shared@example.com", sub="new-sub", email_verified=False)
        _patch_identity(monkeypatch, identity=identity)
        existing = User(
            id=uuid.uuid4(),
            email="shared@example.com",
            full_name="Password User",
            hashed_password="hashed",
            role=UserRole.CUSTOMER,
            auth_provider="password",
            google_sub=None,
            email_verified=False,
        )
        db = FakeDB(users=[existing])

        with pytest.raises(HTTPException) as exc_info:
            await google_auth(GoogleAuthRequest(credential="tok"), db)

        assert exc_info.value.status_code == 403
        # Rejected before mutation -- the existing account must be untouched.
        assert existing.google_sub is None


class TestErrorPaths:
    async def test_invalid_google_token_returns_401(self, monkeypatch):
        _patch_identity(monkeypatch, error=InvalidGoogleTokenError("bad token"))
        db = FakeDB(users=[])

        with pytest.raises(HTTPException) as exc_info:
            await google_auth(GoogleAuthRequest(credential="garbage"), db)

        assert exc_info.value.status_code == 401

    async def test_suspended_account_returns_403(self, monkeypatch):
        identity = make_identity(sub="suspended-sub")
        _patch_identity(monkeypatch, identity=identity)
        existing = User(
            id=uuid.uuid4(),
            email=identity.email,
            full_name="Suspended",
            hashed_password=None,
            role=UserRole.CUSTOMER,
            is_active=False,
            auth_provider="google",
            google_sub="suspended-sub",
            email_verified=True,
        )
        db = FakeDB(users=[existing])

        with pytest.raises(HTTPException) as exc_info:
            await google_auth(GoogleAuthRequest(credential="tok"), db)

        assert exc_info.value.status_code == 403


class TestVerifyGoogleIdTokenBoundary:
    """Exercises the real google-auth library (no monkeypatching) against a
    malformed credential -- everything above this mocks verification, so
    nothing else in the suite proves verify_google_id_token itself actually
    rejects bad input rather than, say, silently returning garbage claims."""

    async def test_malformed_token_is_rejected(self):
        with pytest.raises(InvalidGoogleTokenError):
            await verify_google_id_token("not-a-real-jwt", "some-client-id")


class TestLoginGuardsGoogleOnlyAccounts:
    async def test_password_login_on_google_only_account_returns_400(self, monkeypatch):
        import app.routers.auth as auth_module

        monkeypatch.setattr(auth_module, "is_login_locked", AsyncMock(return_value=False))
        google_only = User(
            id=uuid.uuid4(),
            email="google.only@example.com",
            full_name="Google Only",
            hashed_password=None,
            role=UserRole.CUSTOMER,
            auth_provider="google",
            google_sub="sub-1",
            email_verified=True,
        )
        db = FakeDB(users=[google_only])

        with pytest.raises(HTTPException) as exc_info:
            await login(fake_request(), UserLogin(email="google.only@example.com", password="whatever123"), db)

        assert exc_info.value.status_code == 400
