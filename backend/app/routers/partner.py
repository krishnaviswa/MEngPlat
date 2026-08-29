"""Partner review channel (S-123, ADR-019).

Three surfaces in one module:
  * ``POST /partner/review-requests`` -- partner-key + HMAC; mints a collect token.
  * ``GET|POST /collect/{token}``     -- public, login-free; the token is the capability.
  * ``/partner-mock/*``               -- dev-only mock billing console helpers.

Organic ``/collect/{businessId}`` (login required) lives in ``routers/reviews.py``
and is untouched.
"""

from __future__ import annotations

import json
import logging
from collections import deque
from datetime import UTC, datetime

from fastapi import APIRouter, BackgroundTasks, Depends, Header, HTTPException, Request, Response, status
from pydantic import ValidationError
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.database import get_db
from app.schemas import (
    BusinessSummary,
    CollectTokenContext,
    CollectTokenReviewCreate,
    CollectTokenReviewResponse,
    PartnerMockDispatchRequest,
    PartnerMockRequestRow,
    PartnerReviewRequestCreate,
    PartnerReviewRequestResponse,
)
from app.services.partner_service import (
    collect_url,
    create_review_request,
    dev_dispatch,
    dev_list_requests,
    load_request_for_collect,
    resolve_partner,
    submit_token_review,
)
from app.services.partners import get_partner_provider

logger = logging.getLogger("app.partners")

router = APIRouter(tags=["Partner review channel"])


def _bearer_token(authorization: str | None) -> str | None:
    if not authorization:
        return None
    scheme, _, value = authorization.partition(" ")
    return value.strip() if scheme.lower() == "bearer" else authorization.strip()


@router.post(
    "/partner/review-requests",
    response_model=PartnerReviewRequestResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_partner_review_request(
    request: Request,
    response: Response,
    db: AsyncSession = Depends(get_db),
    authorization: str | None = Header(default=None),
    x_mh_signature: str | None = Header(default=None),
) -> PartnerReviewRequestResponse:
    """Partner pushes a closed transaction, gets back a single-use collect link.

    **Auth:** ``Authorization: Bearer <partner key>`` + ``X-MH-Signature:
    sha256=<hmac(raw_body, partner_secret)>``.
    **Body:** merchant_ref, transaction_ref, channel?, customer_phone?, occurred_at?
    **Response:** 201 (new) / 200 (idempotent): review_request_id, collect_url, expires_at
    """
    raw = await request.body()
    partner = await resolve_partner(db, _bearer_token(authorization))
    if not get_partner_provider().verify_request_signature(raw, x_mh_signature, partner.hmac_secret):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid request signature")
    try:
        payload = PartnerReviewRequestCreate.model_validate_json(raw)
    except ValidationError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Invalid request body"
        ) from exc

    req, created = await create_review_request(db, partner, payload)
    if not created:
        response.status_code = status.HTTP_200_OK
    return PartnerReviewRequestResponse(
        review_request_id=req.id,
        collect_url=collect_url(req.token),
        expires_at=req.expires_at,
    )


@router.get("/collect/{token}", response_model=CollectTokenContext)
async def get_collect_context(token: str, db: AsyncSession = Depends(get_db)) -> CollectTokenContext:
    """Public: what the login-free ``/c/{token}`` page needs. No authentication."""
    request, business, computed = await load_request_for_collect(db, token)
    return CollectTokenContext(
        business=BusinessSummary.model_validate(business),
        status=computed,
        expires_at=request.expires_at,
    )


@router.post(
    "/collect/{token}",
    response_model=CollectTokenReviewResponse,
    status_code=status.HTTP_201_CREATED,
)
async def submit_collect_review(
    token: str,
    payload: CollectTokenReviewCreate,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_db),
) -> CollectTokenReviewResponse:
    """Public: submit a review against a token. Writes a native partner review
    (``source='partner'``, ``verified_purchase=true``), burns the token, runs
    the same AI + keyword-moderation pipeline as an organic review. No login."""
    review, business = await submit_token_review(db, token, payload, background_tasks)
    return CollectTokenReviewResponse(
        review_id=review.id,
        status=review.status,
        business_slug=business.slug if business else "",
    )


# --- dev-only mock billing console ----------------------------------------------------


def _require_mock_console() -> None:
    settings = get_settings()
    if not (settings.debug and settings.partners_provider.strip().lower() == "mock"):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Not found")


# Last few callbacks MerchantHub delivered back to the (mock) partner -- so the
# console can show the loop closing. Process-local, dev-only, best-effort.
_RECEIVED_CALLBACKS: deque[dict] = deque(maxlen=20)


@router.post("/partner-mock/dispatch", dependencies=[Depends(_require_mock_console)])
async def partner_mock_dispatch(
    req: PartnerMockDispatchRequest, db: AsyncSession = Depends(get_db)
) -> dict:
    """Dev-only: stand in for a billing app calling the real push API. The server
    signs as the seeded demo partner so the browser never holds the secret."""
    request, _created, message = await dev_dispatch(db, req)
    return {
        "collect_url": collect_url(request.token),
        "token": request.token,
        "review_request_id": str(request.id),
        "message": message,
    }


@router.get(
    "/partner-mock/requests",
    dependencies=[Depends(_require_mock_console)],
    response_model=list[PartnerMockRequestRow],
)
async def partner_mock_requests(db: AsyncSession = Depends(get_db)) -> list[PartnerMockRequestRow]:
    """Dev-only: the demo partner's review requests, newest first -- watch
    ``pending -> submitted`` as reviews are left."""
    return [PartnerMockRequestRow(**row) for row in await dev_list_requests(db)]


@router.post("/partner-mock/callback-sink", dependencies=[Depends(_require_mock_console)])
async def partner_mock_callback_sink(
    request: Request, x_mh_signature: str | None = Header(default=None)
) -> dict:
    """Dev-only: the (mock) partner's endpoint. The mock provider POSTs the
    signed ``review.captured`` event here; we record it so the console can show
    the loop closing."""
    body = await request.body()
    try:
        event = json.loads(body.decode("utf-8", "replace"))
    except ValueError:
        event = {"_raw": body.decode("utf-8", "replace")}
    _RECEIVED_CALLBACKS.appendleft(
        {"received_at": datetime.now(UTC).isoformat(), "signature": x_mh_signature, "event": event}
    )
    logger.info("partner-mock callback-sink received: %s", event)
    return {"ok": True}


@router.get("/partner-mock/callbacks", dependencies=[Depends(_require_mock_console)])
async def partner_mock_callbacks() -> list[dict]:
    """Dev-only: the callbacks MerchantHub has delivered back to the mock partner, newest first."""
    return list(_RECEIVED_CALLBACKS)
