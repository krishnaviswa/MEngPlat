"""Google Places review search / link / sync + public external-reviews read.

Routers stay thin: `app/routers/dashboard.py`'s four `google-reviews*` routes
and `app/routers/businesses.py`'s public `GET .../external-reviews` route call
into this module, translating its domain exceptions into HTTPExceptions.

Non-negotiable (AC12): `Business.average_rating` / `review_count` are never
touched here. No function in this module may call `update_business_rating` or
write those two fields.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.models import Business, ExternalReview
from app.services.review_sources import get_review_source_provider
from app.services.review_sources.base import PlaceCandidate

logger = logging.getLogger(__name__)

GOOGLE_SOURCE = "google"
#: Google's Place Details API caps at 5 most-relevant reviews per place -- a
#: real vendor limitation (see the slice's Risks section), not a design choice.
PUBLIC_EXTERNAL_REVIEWS_LIMIT = 5


class GoogleReviewsProviderError(Exception):
    """The configured review-source provider failed to search or fetch (-> 502)."""


class GooglePlaceAlreadyLinkedError(Exception):
    """`Business.external_platform_refs.google` is already set (-> 409)."""


class GooglePlaceNotLinkedError(Exception):
    """Sync attempted before a Google place has been linked (-> 400)."""


def _sync_lock_key(business_id: UUID) -> str:
    return f"google-reviews:sync-lock:{business_id}"


async def search_google_places(business: Business, query: str) -> list[PlaceCandidate]:
    """Proxy a Text Search call through the configured provider (AC1-5)."""
    provider = get_review_source_provider()
    try:
        return await provider.search_places(query, business.latitude, business.longitude)
    except Exception as exc:  # noqa: BLE001 -- any provider/network failure -> readable 502
        raise GoogleReviewsProviderError(str(exc)) from exc


@dataclass
class GoogleReviewsStatus:
    linked: bool
    place_id: str | None
    review_count: int
    last_synced_at: datetime | None


async def get_google_reviews_status(db: AsyncSession, business: Business) -> GoogleReviewsStatus:
    """Powers the dashboard card's unlinked/linked/synced states (AC3, AC6, AC7).

    `last_synced_at` is computed on read (MAX(updated_at)), not stored
    redundantly on `Business` -- consistent with how average_rating/
    review_count are the only denormalized aggregates this codebase keeps,
    and those are explicitly walled off from this feature (AC12).
    """
    place_id = (business.external_platform_refs or {}).get("google")
    if not place_id:
        return GoogleReviewsStatus(linked=False, place_id=None, review_count=0, last_synced_at=None)

    result = await db.execute(
        select(func.count(ExternalReview.id), func.max(ExternalReview.updated_at)).where(
            ExternalReview.business_id == business.id,
            ExternalReview.source == GOOGLE_SOURCE,
        )
    )
    count, last_synced = result.one()
    return GoogleReviewsStatus(
        linked=True,
        place_id=place_id,
        review_count=int(count or 0),
        last_synced_at=last_synced,
    )


async def link_google_place(db: AsyncSession, business: Business, place_id: str) -> None:
    """Set `external_platform_refs.google`. Rejects a second link (AC3, out-of-scope re-link)."""
    if (business.external_platform_refs or {}).get("google"):
        raise GooglePlaceAlreadyLinkedError()
    refs = dict(business.external_platform_refs or {})
    refs["google"] = place_id
    business.external_platform_refs = refs


@dataclass
class GoogleSyncResult:
    synced_count: int
    last_synced_at: datetime
    debounced: bool


async def sync_google_reviews(db: AsyncSession, business: Business) -> GoogleSyncResult:
    """Fetch up to 5 reviews and upsert them (AC7, AC8), debounced via a Redis lock (AC9).

    Select-then-update upsert (no `ON CONFLICT`) keyed on
    `(business_id, source, external_review_id)`, consistent with every other
    write path in this backend. Unlike `refresh_merchant_ai_summary_bg`
    (fire-and-forget, never releases early), this endpoint is synchronous --
    the client is waiting on `synced_count` -- so the lock is released
    explicitly in a `finally` block once the fetch+upsert completes; the TTL
    is only a crash/timeout safety net.
    """
    # Deferred import (mirrors business_service.refresh_merchant_ai_summary_bg)
    # so tests can monkeypatch "app.services.cache.try_acquire_lock"/"release_lock".
    from app.services.cache import release_lock, try_acquire_lock

    place_id = (business.external_platform_refs or {}).get("google")
    if not place_id:
        raise GooglePlaceNotLinkedError()

    settings = get_settings()
    lock_key = _sync_lock_key(business.id)
    acquired = await try_acquire_lock(lock_key, ttl=settings.google_reviews_sync_debounce_seconds)
    if not acquired:
        # A sync is already in flight -- return current state, no error, no
        # duplicate work (AC9).
        status = await get_google_reviews_status(db, business)
        return GoogleSyncResult(
            synced_count=status.review_count,
            last_synced_at=status.last_synced_at or datetime.now(timezone.utc),
            debounced=True,
        )

    try:
        provider = get_review_source_provider()
        try:
            fetched = await provider.fetch_reviews(place_id)
        except Exception as exc:  # noqa: BLE001
            raise GoogleReviewsProviderError(str(exc)) from exc

        fetched_ids = [item.external_review_id for item in fetched]
        existing_rows: dict[str, ExternalReview] = {}
        if fetched_ids:
            existing_result = await db.execute(
                select(ExternalReview).where(
                    ExternalReview.business_id == business.id,
                    ExternalReview.source == GOOGLE_SOURCE,
                    ExternalReview.external_review_id.in_(fetched_ids),
                )
            )
            existing_rows = {row.external_review_id: row for row in existing_result.scalars().all()}

        now = datetime.now(timezone.utc)
        for item in fetched:
            row = existing_rows.get(item.external_review_id)
            if row is not None:
                row.author_name = item.author_name
                row.author_photo_url = item.author_photo_url
                row.rating = item.rating
                row.body = item.body
                row.language = item.language
                row.source_url = item.source_url
                row.external_posted_at = item.external_posted_at
                row.raw_response = item.raw_response
            else:
                db.add(
                    ExternalReview(
                        business_id=business.id,
                        source=GOOGLE_SOURCE,
                        external_review_id=item.external_review_id,
                        author_name=item.author_name,
                        author_photo_url=item.author_photo_url,
                        rating=item.rating,
                        body=item.body,
                        language=item.language,
                        source_url=item.source_url,
                        external_posted_at=item.external_posted_at,
                        raw_response=item.raw_response,
                    )
                )
        await db.flush()
        return GoogleSyncResult(synced_count=len(fetched), last_synced_at=now, debounced=False)
    finally:
        await release_lock(lock_key)


async def list_external_reviews(db: AsyncSession, business_id: UUID) -> list[ExternalReview]:
    """Public read for `GET /businesses/{id}/external-reviews` (AC10, AC11).

    Rows can accumulate beyond 5 over many syncs (Google's "5 most relevant"
    can shift); this caps display at the freshest 5 by `updated_at`, per the
    slice's documented Risk -- not a bug if the table holds more.
    """
    result = await db.execute(
        select(ExternalReview)
        .where(ExternalReview.business_id == business_id)
        .order_by(ExternalReview.updated_at.desc())
        .limit(PUBLIC_EXTERNAL_REVIEWS_LIMIT)
    )
    return list(result.scalars().all())
