"""refresh_merchant_ai_summary's prompt-size bounds, and the debounce wrapper
around it (refresh_merchant_ai_summary_bg).

Uses fake db/provider objects rather than a real database: this environment
has no working async Postgres connection (greenlet's DLL doesn't load under
this Python install), and these two behaviors -- truncation math, and
lock-then-run-then-log wiring -- don't actually need a real session to verify.
"""

from dataclasses import dataclass, field

import pytest

import app.services.ai as ai_module
from app.config import get_settings
from app.services import business_service
from app.services.ai.base import AICallMeta, MerchantSummaryResult


@dataclass
class FakeReview:
    rating: int
    body: str


@dataclass
class FakeRow:
    review: FakeReview
    analysis: None = None


@dataclass
class FakeExecuteResult:
    rows: list[FakeRow]

    def all(self):
        return [(r.review, r.analysis) for r in self.rows]


@dataclass
class FakeBusiness:
    ai_merchant_summary: str | None = None
    ai_positives: list | None = None
    ai_complaints: list | None = None
    ai_monthly_trends: list | None = None
    ai_degraded: bool = False


class FakeDB:
    def __init__(self, rows: list[FakeRow], business: FakeBusiness):
        self._rows = rows
        self._business = business
        self.limit_applied: int | None = None

    async def execute(self, stmt):
        # The real query chains .limit(settings.ai_max_reviews_per_summary);
        # emulate that here since these are fakes, not a real queryable table.
        limit = getattr(stmt, "_fake_limit", None)
        rows = self._rows[:limit] if limit is not None else self._rows
        return FakeExecuteResult(rows)

    async def get(self, model, business_id):
        return self._business

    async def commit(self):
        pass


class FakeSelectStub:
    """Stands in for the SQLAlchemy select(...) chain long enough to capture
    the .limit(N) call -- nothing here executes real SQL."""

    def __init__(self):
        self._fake_limit = None

    def options(self, *a, **kw):
        return self

    def join(self, *a, **kw):
        return self

    def where(self, *a, **kw):
        return self

    def order_by(self, *a, **kw):
        return self

    def limit(self, n):
        self._fake_limit = n
        return self


class FakeProvider:
    provider_name = "fake"

    def __init__(self, degraded: bool = False):
        self.received_reviews: list[dict] | None = None
        self._degraded = degraded

    async def generate_merchant_summary(self, reviews, context=None):
        self.received_reviews = reviews
        return MerchantSummaryResult(
            summary="s",
            positives=[],
            complaints=[],
            monthly_trends=[],
            suggested_responses=[],
            meta=AICallMeta(provider="fake", degraded=self._degraded),
        )


@pytest.fixture(autouse=True)
def _clear_settings_cache():
    yield
    get_settings.cache_clear()


@pytest.fixture(autouse=True)
def _patch_select(monkeypatch):
    """refresh_merchant_ai_summary builds its query via module-level select()
    -- swap in the stub so .limit(N) is observable without a real engine."""
    monkeypatch.setattr(business_service, "select", lambda *a, **kw: FakeSelectStub())


class TestTruncation:
    async def test_review_count_is_capped(self, monkeypatch):
        monkeypatch.setenv("AI_MAX_REVIEWS_PER_SUMMARY", "2")
        get_settings.cache_clear()

        rows = [FakeRow(FakeReview(rating=5, body=f"review {i}")) for i in range(10)]
        db = FakeDB(rows, FakeBusiness())
        provider = FakeProvider()
        monkeypatch.setattr(ai_module, "get_ai_provider", lambda: provider)

        await business_service.refresh_merchant_ai_summary(db, "biz-1")

        assert provider.received_reviews is not None
        assert len(provider.received_reviews) == 2

    async def test_review_body_is_truncated_to_max_chars(self, monkeypatch):
        monkeypatch.setenv("AI_MAX_REVIEW_CHARS", "20")
        get_settings.cache_clear()

        long_body = "x" * 5000
        rows = [FakeRow(FakeReview(rating=5, body=long_body))]
        db = FakeDB(rows, FakeBusiness())
        provider = FakeProvider()
        monkeypatch.setattr(ai_module, "get_ai_provider", lambda: provider)

        await business_service.refresh_merchant_ai_summary(db, "biz-1")

        assert len(provider.received_reviews[0]["body"]) == 20

    async def test_no_reviews_skips_the_llm_call_entirely(self, monkeypatch):
        db = FakeDB([], FakeBusiness())
        provider = FakeProvider()
        monkeypatch.setattr(ai_module, "get_ai_provider", lambda: provider)

        await business_service.refresh_merchant_ai_summary(db, "biz-1")

        assert provider.received_reviews is None


class TestDegradedPropagation:
    async def test_business_ai_degraded_reflects_the_call_result(self, monkeypatch):
        rows = [FakeRow(FakeReview(rating=5, body="fine"))]
        business = FakeBusiness()
        db = FakeDB(rows, business)
        monkeypatch.setattr(ai_module, "get_ai_provider", lambda: FakeProvider(degraded=True))

        await business_service.refresh_merchant_ai_summary(db, "biz-1")

        assert business.ai_degraded is True


class TestBackgroundDebounce:
    async def test_skips_entirely_when_lock_not_acquired(self, monkeypatch):
        """The core of the fix: a burst of callers must not all run the
        refresh just because they all got scheduled."""
        called = False
        lock_fn_invoked = False

        async def fake_refresh(db, business_id):
            nonlocal called
            called = True

        async def lock_not_acquired(key, ttl):
            nonlocal lock_fn_invoked
            lock_fn_invoked = True
            return False

        monkeypatch.setattr(business_service, "refresh_merchant_ai_summary", fake_refresh)
        monkeypatch.setattr("app.services.cache.try_acquire_lock", lock_not_acquired)

        await business_service.refresh_merchant_ai_summary_bg("biz-1")

        # Confirms the fake actually ran -- without this, a monkeypatch that
        # silently failed to apply would still pass here, because the real
        # try_acquire_lock also returns False in this environment (no Redis
        # reachable) and fails closed for the same reason on a real error.
        assert lock_fn_invoked is True
        assert called is False

    async def test_runs_and_commits_when_lock_acquired(self, monkeypatch):
        calls = []

        async def fake_refresh(db, business_id):
            calls.append(business_id)

        async def lock_acquired(key, ttl):
            return True

        class FakeSession:
            async def __aenter__(self):
                return self

            async def __aexit__(self, *exc):
                return False

            async def commit(self):
                calls.append("committed")

        monkeypatch.setattr(business_service, "refresh_merchant_ai_summary", fake_refresh)
        monkeypatch.setattr("app.services.cache.try_acquire_lock", lock_acquired)
        monkeypatch.setattr("app.database.AsyncSessionLocal", lambda: FakeSession())

        await business_service.refresh_merchant_ai_summary_bg("biz-1")
        assert calls == ["biz-1", "committed"]

    async def test_an_exception_is_logged_not_raised(self, monkeypatch, caplog):
        """FastAPI silently swallows BackgroundTasks exceptions -- without
        explicit logging, a broken refresh just stops happening with no
        signal at all."""

        async def failing_refresh(db, business_id):
            raise RuntimeError("boom")

        async def lock_acquired(key, ttl):
            return True

        class FakeSession:
            async def __aenter__(self):
                return self

            async def __aexit__(self, *exc):
                return False

        monkeypatch.setattr(business_service, "refresh_merchant_ai_summary", failing_refresh)
        monkeypatch.setattr("app.services.cache.try_acquire_lock", lock_acquired)
        monkeypatch.setattr("app.database.AsyncSessionLocal", lambda: FakeSession())

        await business_service.refresh_merchant_ai_summary_bg("biz-1")  # must not raise
        assert "merchant_ai_summary_background_refresh_failed" in caplog.text
