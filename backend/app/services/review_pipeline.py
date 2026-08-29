"""Shared review side-effects: AI text analysis (S-123 extraction).

Both the organic ``POST /reviews`` handler and the partner login-free
``POST /collect/{token}`` handler run the exact same suggestion-grade AI
analysis on submit. This is that one block, so the two paths cannot drift.

Keyword moderation stays a one-liner at each call site
(``content_moderation.contains_disallowed_language``) -- it needs no shared
state and inlining it keeps the status decision visible in the handler.
"""

from __future__ import annotations

from uuid import UUID

from app.models import AIAnalysis, Sentiment
from app.services.ai import AIProvider, coerce_sentiment, get_ai_provider


async def build_review_ai_analysis(
    review_id: UUID,
    body: str,
    *,
    business_id: UUID,
    provider: AIProvider | None = None,
) -> AIAnalysis:
    """Run text analysis for a just-created review and return an unsaved ``AIAnalysis``.

    Callers ``db.add(...)`` the result. ``provider`` is injectable so the
    organic handler can keep passing its own module-level ``get_ai_provider``
    (monkeypatched in tests); it defaults to the real factory otherwise.
    """
    provider = provider or get_ai_provider()
    result = await provider.analyze_review_text(body, {"business_id": str(business_id)})
    return AIAnalysis(
        review_id=review_id,
        analysis_type="text",
        # coerce_sentiment runs here even though every provider already applies
        # it -- a provider bug that skips it would otherwise raise ValueError on
        # Sentiment(...) and roll the review back. Same defence as before the
        # extraction.
        sentiment=Sentiment(coerce_sentiment(result.sentiment)),
        summary=result.summary,
        positives=result.positives,
        complaints=result.complaints,
        suggested_response=result.suggested_response,
        # meta.provider is who actually answered -- the configured provider
        # after a gateway fallback, not necessarily who was asked.
        provider=result.meta.provider,
        raw_response=result.raw_response,
        degraded=result.meta.degraded,
    )
