"""Wraps the configured AI provider with retry, a deadline, and fallback
degradation, so a bad key or a flaky vendor never surfaces to a caller as an
exception that rolls back whatever database work is in flight.

Concretely, this is what stops a live provider from destroying a customer's
review: without it, any AI failure (bad key, 429, timeout) propagates out of
the request handler, and get_db's `except Exception: rollback()` takes the
just-flushed review down with it.
"""

from __future__ import annotations

import asyncio
import logging
import random
import time
from collections.abc import Awaitable, Callable
from typing import TypeVar

import httpx

from app.services.ai.base import (
    AIProvider,
    ImageAnalysisResult,
    MerchantSummaryResult,
    ReviewAnalysisResult,
    TopicClusterResult,
)

logger = logging.getLogger(__name__)

_RETRYABLE_STATUS = frozenset({429, 500, 502, 503, 504})

_ResultT = TypeVar(
    "_ResultT", ReviewAnalysisResult, ImageAnalysisResult, MerchantSummaryResult, TopicClusterResult
)


def _is_retryable(exc: Exception) -> bool:
    if isinstance(exc, httpx.HTTPStatusError):
        # 400/401/403/404 are config errors -- the key is wrong, the model
        # name is wrong, the account has no access. Retrying sends the exact
        # same broken request again; go straight to the fallback instead.
        return exc.response.status_code in _RETRYABLE_STATUS
    return isinstance(exc, (httpx.TimeoutException, httpx.ConnectError, httpx.ReadError, TimeoutError))


class AIGateway(AIProvider):
    """provider_name reports the CONFIGURED provider -- what the app is set up
    to use, matching how callers used to read it off the bare provider object.
    An individual call's result.meta.provider is the one that actually
    answered, which differs from this when that specific call degraded.
    """

    def __init__(
        self,
        primary: AIProvider,
        fallback: AIProvider,
        *,
        max_retries: int = 2,
        total_deadline_seconds: float = 25.0,
        degrade_on_failure: bool = True,
    ) -> None:
        self._primary = primary
        self._fallback = fallback
        self._max_retries = max_retries
        self._total_deadline_seconds = total_deadline_seconds
        self._degrade_on_failure = degrade_on_failure

    @property
    def provider_name(self) -> str:
        return self._primary.provider_name

    @property
    def supports_vision(self) -> bool:
        return self._primary.supports_vision

    async def _call_with_retry(self, make_call: Callable[[], Awaitable[_ResultT]]) -> _ResultT:
        deadline = time.monotonic() + self._total_deadline_seconds
        attempts = 0
        last_exc: Exception | None = None

        while attempts < 1 + self._max_retries:
            attempts += 1
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                break
            try:
                result = await asyncio.wait_for(make_call(), timeout=remaining)
            except Exception as exc:  # classified below -- never silently swallowed
                last_exc = exc
                if not _is_retryable(exc) or attempts >= 1 + self._max_retries:
                    break
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    break
                backoff = min(0.5 * (2 ** (attempts - 1)), remaining)
                jitter = backoff * random.uniform(-0.25, 0.25)
                await asyncio.sleep(max(0.0, min(backoff + jitter, remaining)))
                continue
            else:
                result.meta.attempts = attempts
                return result

        assert last_exc is not None
        raise last_exc

    async def _run(
        self,
        operation: str,
        primary_call: Callable[[], Awaitable[_ResultT]],
        fallback_call: Callable[[], Awaitable[_ResultT]],
    ) -> _ResultT:
        try:
            return await self._call_with_retry(primary_call)
        except Exception as exc:
            logger.warning(
                "ai_call_failed",
                extra={
                    "operation": operation,
                    "provider": self._primary.provider_name,
                    "error_type": type(exc).__name__,
                },
            )
            if not self._degrade_on_failure:
                raise
            result = await fallback_call()
            # This is what a caller checks to tell real analysis from a
            # fabricated stand-in -- the fallback (mock, by default) returns
            # plausible-looking output that is not actually derived from the
            # model that's supposed to be configured.
            result.meta.degraded = True
            result.meta.status = "degraded"
            return result

    async def analyze_review_text(
        self, text: str, context: dict | None = None
    ) -> ReviewAnalysisResult:
        return await self._run(
            "review_text",
            lambda: self._primary.analyze_review_text(text, context),
            lambda: self._fallback.analyze_review_text(text, context),
        )

    async def analyze_image(self, image_url: str, context: dict | None = None) -> ImageAnalysisResult:
        return await self._run(
            "image",
            lambda: self._primary.analyze_image(image_url, context),
            lambda: self._fallback.analyze_image(image_url, context),
        )

    async def generate_merchant_summary(
        self, reviews: list[dict], context: dict | None = None
    ) -> MerchantSummaryResult:
        return await self._run(
            "merchant_summary",
            lambda: self._primary.generate_merchant_summary(reviews, context),
            lambda: self._fallback.generate_merchant_summary(reviews, context),
        )

    async def generate_topic_clusters(
        self, reviews: list[dict], context: dict | None = None
    ) -> TopicClusterResult:
        return await self._run(
            "topic_clustering",
            lambda: self._primary.generate_topic_clusters(reviews, context),
            lambda: self._fallback.generate_topic_clusters(reviews, context),
        )
