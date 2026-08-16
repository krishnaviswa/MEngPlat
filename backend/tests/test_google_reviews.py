"""S-048 review aggregator (Google Places): search/link/sync + public read.

Same pattern as test_dashboard.py -- real ASGI app + real database (this repo's
test DATABASE_URL), not a fake DB, since RBAC/ownership and the sync upsert
both depend on real SQL. GOOGLE_PLACES_API_KEY is unset in this environment,
so every call here exercises the deterministic `mock` provider (AC16).
"""

import uuid

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select

from app.core.rate_limit import limiter
from app.database import AsyncSessionLocal
from app.main import app
from app.models import Business, ExternalReview
from tests.auth_helpers import register_and_get_token


async def _lock_acquired(key: str, ttl: int) -> bool:
    return True


async def _lock_not_acquired(key: str, ttl: int) -> bool:
    return False


async def _release_noop(key: str) -> None:
    return None


def _patch_lock_available(monkeypatch) -> None:
    """review_sync_service.sync_google_reviews imports try_acquire_lock/
    release_lock from app.services.cache *inside* the function (same deferred-
    import technique business_service.refresh_merchant_ai_summary_bg uses),
    specifically so this patch target works. No local Redis is reachable in
    this dev environment (confirmed empirically, same as test_ai_topics.py),
    so without this, try_acquire_lock's fail-closed behavior would make every
    sync in this test file look permanently debounced for the wrong reason.
    """
    monkeypatch.setattr("app.services.cache.try_acquire_lock", _lock_acquired)
    monkeypatch.setattr("app.services.cache.release_lock", _release_noop)


def _patch_lock_unavailable(monkeypatch) -> None:
    monkeypatch.setattr("app.services.cache.try_acquire_lock", _lock_not_acquired)


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


async def _register(client: AsyncClient, role: str) -> dict:
    # This file registers 1-3 accounts per test across ~20 tests, well past
    # auth.register's 5/minute-per-IP limit (every ASGITransport request
    # shares the same synthesized 127.0.0.1 peer). Same technique
    # test_ai_topics.py / test_rate_limit.py use to isolate their own runs.
    limiter.reset()
    email = f"{role}-{uuid.uuid4().hex[:8]}@example.com"
    token = await register_and_get_token(client, email, role=role, full_name=f"Test {role.title()}")
    return {"email": email, "headers": {"Authorization": f"Bearer {token}"}}


async def _create_business(client: AsyncClient, merchant_headers: dict, **overrides) -> dict:
    payload = {
        "name": f"Google Reviews Test {uuid.uuid4().hex[:6]}",
        "address": "1 Main St",
        "city": "Chennai",
        **overrides,
    }
    res = await client.post("/api/v1/businesses", headers=merchant_headers, json=payload)
    assert res.status_code == 201, res.text
    return res.json()


def _search_url(business_id: str) -> str:
    return f"/api/v1/dashboard/merchant/{business_id}/google-reviews/search"


def _status_url(business_id: str) -> str:
    return f"/api/v1/dashboard/merchant/{business_id}/google-reviews"


def _link_url(business_id: str) -> str:
    return f"/api/v1/dashboard/merchant/{business_id}/google-reviews/link"


def _sync_url(business_id: str) -> str:
    return f"/api/v1/dashboard/merchant/{business_id}/google-reviews/sync"


def _public_url(business_id: str) -> str:
    return f"/api/v1/businesses/{business_id}/external-reviews"


# --- RBAC (AC13, AC14) --------------------------------------------------------


@pytest.mark.asyncio
async def test_search_403s_for_customer(client):
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])
    customer = await _register(client, "customer")

    res = await client.post(_search_url(business["id"]), headers=customer["headers"], json={"query": "test"})
    assert res.status_code == 403


@pytest.mark.asyncio
async def test_status_403s_for_customer(client):
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])
    customer = await _register(client, "customer")

    res = await client.get(_status_url(business["id"]), headers=customer["headers"])
    assert res.status_code == 403


@pytest.mark.asyncio
async def test_link_and_sync_403_for_non_owning_merchant(client):
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])
    other = await _register(client, "merchant")

    link_res = await client.post(
        _link_url(business["id"]), headers=other["headers"], json={"place_id": "mock-place-1"}
    )
    assert link_res.status_code == 403

    sync_res = await client.post(_sync_url(business["id"]), headers=other["headers"])
    assert sync_res.status_code == 403


@pytest.mark.asyncio
async def test_public_external_reviews_requires_no_auth(client):
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])

    res = await client.get(_public_url(business["id"]))
    assert res.status_code == 200
    assert res.json() == []


# --- Search (AC1, AC2, AC4, AC16) --------------------------------------------


@pytest.mark.asyncio
async def test_search_returns_deterministic_mock_candidates(client):
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])

    res = await client.post(
        _search_url(business["id"]), headers=owner["headers"], json={"query": "My Cafe"}
    )
    assert res.status_code == 200, res.text
    candidates = res.json()["candidates"]
    assert len(candidates) == 2
    place_ids = {c["place_id"] for c in candidates}
    assert place_ids == {"mock-place-1", "mock-place-2"}
    # First candidate echoes the query (mock provider contract).
    echoed = next(c for c in candidates if c["place_id"] == "mock-place-1")
    assert echoed["name"] == "My Cafe (Demo Location)"


@pytest.mark.asyncio
async def test_search_query_too_short_422(client):
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])

    res = await client.post(_search_url(business["id"]), headers=owner["headers"], json={"query": "a"})
    assert res.status_code == 422


# --- Link (AC3, AC6, AC9's precondition) -------------------------------------


@pytest.mark.asyncio
async def test_status_unlinked_by_default(client):
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])

    res = await client.get(_status_url(business["id"]), headers=owner["headers"])
    assert res.status_code == 200
    body = res.json()
    assert body == {"linked": False, "place_id": None, "review_count": 0, "last_synced_at": None}


@pytest.mark.asyncio
async def test_link_then_status_reflects_linked_state(client):
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])

    link_res = await client.post(
        _link_url(business["id"]), headers=owner["headers"], json={"place_id": "mock-place-1"}
    )
    assert link_res.status_code == 200, link_res.text
    assert link_res.json() == {"linked": True, "place_id": "mock-place-1"}

    status_res = await client.get(_status_url(business["id"]), headers=owner["headers"])
    assert status_res.status_code == 200
    body = status_res.json()
    assert body["linked"] is True
    assert body["place_id"] == "mock-place-1"
    assert body["review_count"] == 0  # linked but not yet synced


@pytest.mark.asyncio
async def test_relink_returns_409(client):
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])

    first = await client.post(
        _link_url(business["id"]), headers=owner["headers"], json={"place_id": "mock-place-1"}
    )
    assert first.status_code == 200

    second = await client.post(
        _link_url(business["id"]), headers=owner["headers"], json={"place_id": "mock-place-2"}
    )
    assert second.status_code == 409


# --- Sync (AC7, AC8, AC9, AC12) ----------------------------------------------


@pytest.mark.asyncio
async def test_sync_without_link_returns_400(client):
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])

    res = await client.post(_sync_url(business["id"]), headers=owner["headers"])
    assert res.status_code == 400


@pytest.mark.asyncio
async def test_sync_creates_external_reviews_and_updates_status(client, monkeypatch):
    _patch_lock_available(monkeypatch)
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])
    await client.post(_link_url(business["id"]), headers=owner["headers"], json={"place_id": "mock-place-1"})

    sync_res = await client.post(_sync_url(business["id"]), headers=owner["headers"])
    assert sync_res.status_code == 200, sync_res.text
    body = sync_res.json()
    assert body["synced_count"] == 3  # mock provider's fixed fixture set
    assert body["debounced"] is False
    assert body["last_synced_at"] is not None

    status_res = await client.get(_status_url(business["id"]), headers=owner["headers"])
    assert status_res.json()["review_count"] == 3


@pytest.mark.asyncio
async def test_sync_is_idempotent_no_duplicate_rows(client, monkeypatch):
    """AC8: re-syncing the same (business_id, source, external_review_id) upserts in place."""
    _patch_lock_available(monkeypatch)
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])
    await client.post(_link_url(business["id"]), headers=owner["headers"], json={"place_id": "mock-place-1"})

    first = await client.post(_sync_url(business["id"]), headers=owner["headers"])
    assert first.status_code == 200
    assert first.json()["synced_count"] == 3

    second = await client.post(_sync_url(business["id"]), headers=owner["headers"])
    assert second.status_code == 200
    assert second.json()["synced_count"] == 3

    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(ExternalReview).where(ExternalReview.business_id == uuid.UUID(business["id"]))
        )
        rows = result.scalars().all()
    assert len(rows) == 3  # not 6 -- upserted in place, not duplicated


@pytest.mark.asyncio
async def test_concurrent_sync_is_debounced(client, monkeypatch):
    """AC9: a lock already held for this business (simulated: try_acquire_lock
    returns False, as it would for a second concurrent request) returns
    debounced=true, no error, no fetch."""
    _patch_lock_unavailable(monkeypatch)
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])
    await client.post(_link_url(business["id"]), headers=owner["headers"], json={"place_id": "mock-place-1"})

    res = await client.post(_sync_url(business["id"]), headers=owner["headers"])
    assert res.status_code == 200, res.text
    body = res.json()
    assert body["debounced"] is True
    assert body["synced_count"] == 0  # nothing synced yet, lock held before first real sync

    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(ExternalReview).where(ExternalReview.business_id == uuid.UUID(business["id"]))
        )
        rows = result.scalars().all()
    assert len(rows) == 0  # debounced call did not fetch/write anything


@pytest.mark.asyncio
async def test_sync_does_not_change_average_rating_or_review_count(client, monkeypatch):
    """AC12: average_rating/review_count are native-review-only, numerically
    unchanged by any sync."""
    _patch_lock_available(monkeypatch)
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])
    await client.post(_link_url(business["id"]), headers=owner["headers"], json={"place_id": "mock-place-1"})

    async with AsyncSessionLocal() as db:
        before = await db.get(Business, uuid.UUID(business["id"]))
        before_rating, before_count = before.average_rating, before.review_count

    sync_res = await client.post(_sync_url(business["id"]), headers=owner["headers"])
    assert sync_res.status_code == 200
    assert sync_res.json()["synced_count"] == 3

    async with AsyncSessionLocal() as db:
        after = await db.get(Business, uuid.UUID(business["id"]))
        assert after.average_rating == before_rating
        assert after.review_count == before_count


# --- Public read (AC10, AC11) -------------------------------------------------


@pytest.mark.asyncio
async def test_public_external_reviews_empty_when_never_synced(client):
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])

    res = await client.get(_public_url(business["id"]))
    assert res.status_code == 200
    assert res.json() == []


@pytest.mark.asyncio
async def test_public_external_reviews_lists_synced_rows(client, monkeypatch):
    _patch_lock_available(monkeypatch)
    owner = await _register(client, "merchant")
    business = await _create_business(client, owner["headers"])
    await client.post(_link_url(business["id"]), headers=owner["headers"], json={"place_id": "mock-place-1"})
    sync_res = await client.post(_sync_url(business["id"]), headers=owner["headers"])
    assert sync_res.status_code == 200

    res = await client.get(_public_url(business["id"]))
    assert res.status_code == 200
    rows = res.json()
    assert len(rows) == 3
    for row in rows:
        assert row["source"] == "google"
        assert set(row.keys()) == {
            "id",
            "author_name",
            "author_photo_url",
            "rating",
            "body",
            "source",
            "source_url",
            "external_posted_at",
        }
    # The mock provider's fixture deliberately includes one textless review.
    assert any(row["body"] is None for row in rows)
