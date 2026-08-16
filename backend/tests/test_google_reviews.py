"""S-048 review aggregator (Google Places): search/link/sync + public read.

Calls route handlers and `review_sync_service` with fake db/provider objects,
not ASGI + the remote DATABASE_URL. Same rationale as `test_ai_topics.py` /
`test_admin_browse.py`: an ASGI+real-Postgres pass of this file hit the known
Railway-proxy flake (`InterfaceError: another operation is in progress` plus
`nationalidtype: "PAN"` bind corruption) on the first registration. Not
chased here. GOOGLE_PLACES_API_KEY is unset, so the live factory selects
`mock` (AC16); tests that need empty/error providers monkeypatch
`app.services.review_sync_service.get_review_source_provider`.
"""

from __future__ import annotations

import uuid
from datetime import UTC, datetime

import pytest
from fastapi import HTTPException

from app.dependencies import get_current_user, require_roles
from app.models import Business, BusinessStatus, ExternalReview, Merchant, User, UserRole
from app.routers import businesses as businesses_router
from app.routers import dashboard as dashboard_router
from app.schemas import GooglePlaceLinkRequest, GooglePlacesSearchRequest
from app.services import review_sync_service
from app.services.review_sources import get_review_source_provider
from app.services.review_sources.base import ExternalReviewResult, PlaceCandidate
from app.services.review_sources.providers.mock import MockReviewSourceProvider


class FakeScalars:
    def __init__(self, rows):
        self._rows = rows

    def all(self):
        return self._rows


class FakeResult:
    def __init__(self, *, one_tuple=None, rows=None, scalar=None):
        self._one = one_tuple
        self._rows = rows if rows is not None else []
        self._scalar = scalar

    def one(self):
        return self._one

    def scalars(self):
        return FakeScalars(self._rows)

    def scalar_one_or_none(self):
        return self._scalar


class InMemoryDB:
    """Enough of AsyncSession for `_load_owned_business` + review_sync_service."""

    def __init__(self, business: Business | None, merchant: Merchant | None = None):
        self.business = business
        self.merchant = merchant
        self.rows: list[ExternalReview] = []
        self.commits = 0

    async def get(self, model, id_):
        if model is Business and self.business and self.business.id == id_:
            return self.business
        return None

    async def execute(self, stmt):
        compiled = str(stmt.compile(compile_kwargs={"render_postcompile": True})).lower()
        if "merchants" in compiled:
            return FakeResult(scalar=self.merchant)
        if "count(" in compiled:
            last = max((r.updated_at for r in self.rows if r.updated_at is not None), default=None)
            return FakeResult(one_tuple=(len(self.rows), last), rows=list(self.rows))
        # SELECT ExternalReview ... (existing-row lookup or public list)
        return FakeResult(one_tuple=(len(self.rows), None), rows=list(self.rows))

    def add(self, obj):
        self.rows.append(obj)

    async def flush(self):
        now = datetime.now(UTC)
        for row in self.rows:
            if getattr(row, "updated_at", None) is None:
                row.updated_at = now
            if getattr(row, "created_at", None) is None:
                row.created_at = now
            if getattr(row, "id", None) is None:
                row.id = uuid.uuid4()

    async def commit(self):
        self.commits += 1


def _make_user(role: UserRole = UserRole.CUSTOMER) -> User:
    return User(
        id=uuid.uuid4(),
        email=f"{uuid.uuid4().hex[:8]}@example.com",
        full_name="U",
        role=role,
        is_active=True,
    )


def _make_business(**overrides) -> Business:
    defaults = dict(
        id=uuid.uuid4(),
        merchant_id=uuid.uuid4(),
        name="Google Reviews Test",
        slug=f"google-reviews-{uuid.uuid4().hex[:8]}",
        address="1 Main St",
        city="Chennai",
        status=BusinessStatus.APPROVED,
        average_rating=4.5,
        review_count=10,
        external_platform_refs=None,
        latitude=13.0827,
        longitude=80.2707,
    )
    defaults.update(overrides)
    return Business(**defaults)


def _owning(business: Business) -> tuple[User, Merchant]:
    user = _make_user(UserRole.MERCHANT)
    merchant = Merchant(id=business.merchant_id, user_id=user.id)
    return user, merchant


async def _lock_acquired(key: str, ttl: int) -> bool:
    return True


async def _lock_not_acquired(key: str, ttl: int) -> bool:
    return False


async def _release_noop(key: str) -> None:
    return None


def _patch_lock_available(monkeypatch) -> None:
    monkeypatch.setattr("app.services.cache.try_acquire_lock", _lock_acquired)
    monkeypatch.setattr("app.services.cache.release_lock", _release_noop)


def _patch_lock_unavailable(monkeypatch) -> None:
    monkeypatch.setattr("app.services.cache.try_acquire_lock", _lock_not_acquired)


class _EmptyProvider:
    provider_name = "empty"

    async def search_places(self, query, lat, lng):
        return []

    async def fetch_reviews(self, place_id):
        return []


class _FailingProvider:
    provider_name = "failing"

    async def search_places(self, query, lat, lng):
        raise TimeoutError("places timed out")

    async def fetch_reviews(self, place_id):
        raise TimeoutError("place details timed out")


# --- RBAC (AC13, AC14) --------------------------------------------------------


class TestRBAC:
    async def test_search_401s_unauthenticated(self):
        with pytest.raises(HTTPException) as exc_info:
            await get_current_user(credentials=None, db=None)
        assert exc_info.value.status_code == 401

    async def test_search_403s_for_customer(self):
        checker = require_roles(UserRole.MERCHANT, UserRole.ADMIN)
        with pytest.raises(HTTPException) as exc_info:
            await checker(user=_make_user(UserRole.CUSTOMER))
        assert exc_info.value.status_code == 403

    async def test_status_403s_for_customer(self):
        checker = require_roles(UserRole.MERCHANT, UserRole.ADMIN)
        with pytest.raises(HTTPException) as exc_info:
            await checker(user=_make_user(UserRole.CUSTOMER))
        assert exc_info.value.status_code == 403

    async def test_link_and_sync_403_for_non_owning_merchant(self):
        business = _make_business()
        other = _make_user(UserRole.MERCHANT)
        other_merchant = Merchant(id=uuid.uuid4(), user_id=other.id)
        db = InMemoryDB(business, other_merchant)

        with pytest.raises(HTTPException) as exc_info:
            await dashboard_router.link_google_place(
                business.id, GooglePlaceLinkRequest(place_id="mock-place-1"), db, other
            )
        assert exc_info.value.status_code == 403

        with pytest.raises(HTTPException) as exc_info:
            await dashboard_router.sync_google_reviews(business.id, db, other)
        assert exc_info.value.status_code == 403

    async def test_public_external_reviews_requires_no_auth(self):
        business = _make_business()
        db = InMemoryDB(business)
        rows = await businesses_router.list_external_reviews(business.id, db)
        assert rows == []


# --- Search (AC1, AC2, AC4, AC5, AC16) ----------------------------------------


class TestSearch:
    async def test_search_returns_deterministic_mock_candidates(self):
        business = _make_business()
        user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)

        res = await dashboard_router.search_google_places(
            business.id, GooglePlacesSearchRequest(query="My Cafe"), db, user
        )
        candidates = res.candidates
        assert {c.place_id for c in candidates} == {"mock-place-1", "mock-place-2"}
        echoed = next(c for c in candidates if c.place_id == "mock-place-1")
        assert echoed.name == "My Cafe (Demo Location)"

    async def test_search_empty_candidates_is_200(self, monkeypatch):
        monkeypatch.setattr(
            "app.services.review_sync_service.get_review_source_provider",
            lambda: _EmptyProvider(),
        )
        business = _make_business()
        user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)

        res = await dashboard_router.search_google_places(
            business.id, GooglePlacesSearchRequest(query="zzzz-no-match"), db, user
        )
        assert res.candidates == []

    async def test_search_provider_error_returns_502_and_leaves_link_untouched(self, monkeypatch):
        business = _make_business(external_platform_refs={"google": "mock-place-1"})
        user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)
        monkeypatch.setattr(
            "app.services.review_sync_service.get_review_source_provider",
            lambda: _FailingProvider(),
        )

        with pytest.raises(HTTPException) as exc_info:
            await dashboard_router.search_google_places(
                business.id, GooglePlacesSearchRequest(query="Cafe"), db, user
            )
        assert exc_info.value.status_code == 502
        assert exc_info.value.detail == "Couldn't reach Google Places right now"
        assert business.external_platform_refs == {"google": "mock-place-1"}


# --- Link / status (AC3, AC6) -------------------------------------------------


class TestLink:
    async def test_status_unlinked_by_default(self):
        business = _make_business()
        user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)

        res = await dashboard_router.get_google_reviews_status(business.id, db, user)
        assert res.linked is False
        assert res.place_id is None
        assert res.review_count == 0
        assert res.last_synced_at is None

    async def test_link_then_status_reflects_linked_state(self):
        business = _make_business()
        user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)

        link_res = await dashboard_router.link_google_place(
            business.id, GooglePlaceLinkRequest(place_id="mock-place-1"), db, user
        )
        assert link_res.linked is True
        assert link_res.place_id == "mock-place-1"
        assert db.commits == 1

        status = await dashboard_router.get_google_reviews_status(business.id, db, user)
        assert status.linked is True
        assert status.place_id == "mock-place-1"
        assert status.review_count == 0

    async def test_relink_returns_409(self):
        business = _make_business(external_platform_refs={"google": "mock-place-1"})
        user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)

        with pytest.raises(HTTPException) as exc_info:
            await dashboard_router.link_google_place(
                business.id, GooglePlaceLinkRequest(place_id="mock-place-2"), db, user
            )
        assert exc_info.value.status_code == 409


# --- Sync (AC5, AC7, AC8, AC9, AC12) ------------------------------------------


class TestSync:
    async def test_sync_without_link_returns_400(self):
        business = _make_business()
        user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)

        with pytest.raises(HTTPException) as exc_info:
            await dashboard_router.sync_google_reviews(business.id, db, user)
        assert exc_info.value.status_code == 400

    async def test_sync_creates_external_reviews_and_updates_status(self, monkeypatch):
        _patch_lock_available(monkeypatch)
        business = _make_business(external_platform_refs={"google": "mock-place-1"})
        user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)

        res = await dashboard_router.sync_google_reviews(business.id, db, user)
        assert res.synced_count == 3
        assert res.debounced is False
        assert res.last_synced_at is not None
        assert len(db.rows) == 3
        assert all(row.source == "google" for row in db.rows)

        status = await dashboard_router.get_google_reviews_status(business.id, db, user)
        assert status.review_count == 3

    async def test_sync_is_idempotent_no_duplicate_rows(self, monkeypatch):
        _patch_lock_available(monkeypatch)
        business = _make_business(external_platform_refs={"google": "mock-place-1"})
        user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)

        first = await dashboard_router.sync_google_reviews(business.id, db, user)
        second = await dashboard_router.sync_google_reviews(business.id, db, user)
        assert first.synced_count == 3
        assert second.synced_count == 3
        assert len(db.rows) == 3

    async def test_concurrent_sync_is_debounced(self, monkeypatch):
        _patch_lock_unavailable(monkeypatch)
        business = _make_business(external_platform_refs={"google": "mock-place-1"})
        user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)

        res = await dashboard_router.sync_google_reviews(business.id, db, user)
        assert res.debounced is True
        assert res.synced_count == 0
        assert db.rows == []

    async def test_sync_provider_error_returns_502_and_leaves_rows(self, monkeypatch):
        _patch_lock_available(monkeypatch)
        business = _make_business(external_platform_refs={"google": "mock-place-1"})
        user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)

        first = await dashboard_router.sync_google_reviews(business.id, db, user)
        assert first.synced_count == 3
        existing_ids = [row.external_review_id for row in db.rows]

        monkeypatch.setattr(
            "app.services.review_sync_service.get_review_source_provider",
            lambda: _FailingProvider(),
        )
        with pytest.raises(HTTPException) as exc_info:
            await dashboard_router.sync_google_reviews(business.id, db, user)
        assert exc_info.value.status_code == 502
        assert exc_info.value.detail == "Couldn't reach Google Places right now"
        assert [row.external_review_id for row in db.rows] == existing_ids

    async def test_sync_does_not_change_average_rating_or_review_count(self, monkeypatch):
        _patch_lock_available(monkeypatch)
        business = _make_business(
            external_platform_refs={"google": "mock-place-1"},
            average_rating=4.5,
            review_count=10,
        )
        user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)

        await dashboard_router.sync_google_reviews(business.id, db, user)
        assert business.average_rating == 4.5
        assert business.review_count == 10


# --- Public read (AC10, AC11) -------------------------------------------------


class TestPublicRead:
    async def test_public_external_reviews_empty_when_never_synced(self):
        business = _make_business()
        db = InMemoryDB(business)
        assert await businesses_router.list_external_reviews(business.id, db) == []

    async def test_public_external_reviews_lists_synced_rows(self, monkeypatch):
        _patch_lock_available(monkeypatch)
        business = _make_business(external_platform_refs={"google": "mock-place-1"})
        user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)
        await dashboard_router.sync_google_reviews(business.id, db, user)

        rows = await businesses_router.list_external_reviews(business.id, db)
        assert len(rows) == 3
        assert any(row.body is None for row in rows)
        assert all(row.source == "google" for row in rows)


# --- Provider selection (AC16) ------------------------------------------------


def test_unset_api_key_selects_mock_provider():
    provider = get_review_source_provider()
    assert provider.provider_name == "mock"
    assert isinstance(provider, MockReviewSourceProvider)


async def test_mock_search_places_shape():
    provider = MockReviewSourceProvider()
    candidates = await provider.search_places("Query Cafe", 12.97, 77.59)
    assert len(candidates) == 2
    assert all(isinstance(c, PlaceCandidate) for c in candidates)


async def test_mock_fetch_reviews_includes_nullable_body():
    provider = MockReviewSourceProvider()
    reviews = await provider.fetch_reviews("mock-place-1")
    assert len(reviews) == 3
    assert all(isinstance(r, ExternalReviewResult) for r in reviews)
    assert any(r.body is None for r in reviews)
