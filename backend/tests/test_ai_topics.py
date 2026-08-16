"""GET /ai/businesses/{id}/topics -- S-049 AI topic clustering.

Calls the route handler (and the shared require_roles/get_current_user
dependency factories) directly with fake db/provider objects, rather than
going through ASGI + a real database -- same rationale as test_reviews.py
and test_admin_browse.py's TestAdminBrowseRBAC: no isolated local Postgres is
reachable in this environment. An initial attempt at ASGI+real-DB coverage
here (mirroring test_dashboard.py) hit that file's own documented caveat
firsthand -- "never run this file locally against the project's dev
DATABASE_URL" -- reproducing InterfaceError: cannot perform operation:
another operation is in progress (and, worse, cross-request parameter
corruption on a plain PATCH /auth/me) on the very first two-registration
test, consistently, even run in complete isolation. That confirms the known
connection-pool-contention flake against the remote Railway proxy DB isn't
limited to the "unrelated 48 tests in the mega-suite" case -- it also hits
small, targeted, DB-heavy ASGI suites locally. Not chased/fixed here per the
Builder's note; this file works around it entirely by not touching the real
database.

ScriptedDB.execute() returns pre-scripted results in the exact order
get_topic_clusters issues db.execute() calls (Merchant-ownership lookup only
for a MERCHANT caller, then the eligibility COUNT, then -- only on an
eligible + cache-miss path -- the reviews+analysis fetch): the same
scripted-sequence idea test_ai_gateway.py's FakeProvider already uses for
provider calls, applied here to db.execute instead. Generically faking
func.count(...)/join(...) selects (as a real AsyncSession would need) isn't
worth it for one router; RBAC/ownership/eligibility/degrade/unavailable
logic is what's under test, not SQLAlchemy's query-compilation correctness
(that part is the same shape of query test_dashboard.py already exercises
in CI's ephemeral Postgres for the sibling dashboard endpoints).
"""

import uuid

import pytest
from fastapi import HTTPException

from app.dependencies import get_current_user, require_roles
from app.models import Business, BusinessStatus, Merchant, Review, User, UserRole
from app.routers import ai as ai_router_module
from app.services.ai.base import AIProvider
from app.services.ai.gateway import AIGateway
from app.services.ai.providers.mock import MockAIProvider


class FakeResult:
    """Stands in for a SQLAlchemy Result -- callers use scalar_one,
    scalar_one_or_none, or all() depending on which query issued it."""

    def __init__(self, *, scalar=None, rows=None):
        self._scalar = scalar
        self._rows = rows if rows is not None else []

    def scalar_one(self):
        return self._scalar

    def scalar_one_or_none(self):
        return self._scalar

    def all(self):
        return self._rows


class ScriptedDB:
    def __init__(self, business: Business | None, script: list[FakeResult]):
        self.business = business
        self.script = list(script)
        self.calls = 0

    async def get(self, model, id_):
        return self.business

    async def execute(self, stmt):
        self.calls += 1
        return self.script.pop(0)


class _AlwaysFailsProvider(AIProvider):
    """Errors outright on every call -- simulates AC7's "the AI provider
    call errors outright" without a gateway/fallback layer in the way."""

    provider_name = "always-fails"

    async def analyze_review_text(self, text, context=None):
        raise NotImplementedError

    async def analyze_image(self, image_url, context=None):
        raise NotImplementedError

    async def generate_merchant_summary(self, reviews, context=None):
        raise NotImplementedError

    async def generate_topic_clusters(self, reviews, context=None):
        raise RuntimeError("simulated provider outage")


def _make_business(**overrides) -> Business:
    defaults = dict(
        id=uuid.uuid4(),
        merchant_id=uuid.uuid4(),
        name="Topics Test Biz",
        slug="topics-test-biz",
        address="1 Main St",
        city="Metropolis",
        status=BusinessStatus.APPROVED,
    )
    defaults.update(overrides)
    return Business(**defaults)


def _make_user(role: UserRole = UserRole.CUSTOMER) -> User:
    return User(id=uuid.uuid4(), email=f"{uuid.uuid4().hex[:8]}@example.com", full_name="U", role=role, is_active=True)


def _make_owning_merchant(business: Business) -> tuple[User, Merchant]:
    user = _make_user(role=UserRole.MERCHANT)
    merchant = Merchant(id=business.merchant_id, user_id=user.id)
    return user, merchant


def _make_review(body: str, rating: int = 4) -> Review:
    return Review(id=uuid.uuid4(), business_id=uuid.uuid4(), author_id=uuid.uuid4(), rating=rating, body=body)


@pytest.fixture(autouse=True)
def _no_real_cache(monkeypatch):
    """No real Redis is reachable in this environment -- cache_get/cache_set
    already fail open, but pinning them explicitly here makes every test's
    cache behavior deterministic (always a miss) rather than dependent on
    whatever happens to be listening on localhost:6379 in a given run."""

    async def fake_cache_get(key):
        return None

    async def fake_cache_set(key, value, ttl=300):
        pass

    monkeypatch.setattr(ai_router_module, "cache_get", fake_cache_get)
    monkeypatch.setattr(ai_router_module, "cache_set", fake_cache_set)


class TestRBAC:
    """AC5: customer/unauthenticated rejected; merchant restricted to own
    business. The role gate is the shared Depends(require_roles(...))
    factory -- calling the route handler directly never exercises it
    (FastAPI resolves Depends(...) outside the function body), so it's
    exercised the same way test_admin_browse.py's TestAdminBrowseRBAC does:
    invoking the dependency factory itself.
    """

    async def test_401_unauthenticated(self):
        with pytest.raises(HTTPException) as exc_info:
            await get_current_user(credentials=None, db=None)
        assert exc_info.value.status_code == 401

    async def test_403_customer_role(self):
        checker = require_roles(UserRole.MERCHANT, UserRole.ADMIN)
        customer = _make_user(role=UserRole.CUSTOMER)

        with pytest.raises(HTTPException) as exc_info:
            await checker(user=customer)
        assert exc_info.value.status_code == 403

    async def test_403_non_owning_merchant(self):
        business = _make_business()
        other_user = _make_user(role=UserRole.MERCHANT)
        other_merchant = Merchant(id=uuid.uuid4(), user_id=other_user.id)  # id != business.merchant_id
        db = ScriptedDB(business, script=[FakeResult(scalar=other_merchant)])

        with pytest.raises(HTTPException) as exc_info:
            await ai_router_module.get_topic_clusters(business.id, db, other_user)
        assert exc_info.value.status_code == 403


class TestNotFound:
    async def test_404_for_missing_business(self):
        db = ScriptedDB(business=None, script=[])
        merchant_user = _make_user(role=UserRole.MERCHANT)

        with pytest.raises(HTTPException) as exc_info:
            await ai_router_module.get_topic_clusters(uuid.uuid4(), db, merchant_user)
        assert exc_info.value.status_code == 404


class TestEligibilityGate:
    """AC4: too few/too-short reviews -> insufficient_data, no AI call."""

    async def test_insufficient_data_when_below_threshold(self):
        business = _make_business()
        owner_user, owner_merchant = _make_owning_merchant(business)
        db = ScriptedDB(
            business,
            script=[
                FakeResult(scalar=owner_merchant),  # ownership lookup
                FakeResult(scalar=2),  # eligibility count, below the 5-review threshold
            ],
        )

        result = await ai_router_module.get_topic_clusters(business.id, db, owner_user)

        assert result.insufficient_data is True
        assert result.topics == []
        assert result.degraded is False
        assert result.unavailable is False
        assert db.calls == 2, "must stop after the eligibility COUNT -- no reviews+analysis fetch"

    async def test_provider_never_called_when_below_threshold(self, monkeypatch):
        """The eligibility COUNT must run and short-circuit BEFORE any AI
        provider call -- a business below threshold never pays for (or waits
        on) an LLM call, per the Architect's spec."""
        business = _make_business()
        owner_user, owner_merchant = _make_owning_merchant(business)
        db = ScriptedDB(
            business,
            script=[FakeResult(scalar=owner_merchant), FakeResult(scalar=0)],
        )

        calls: list[str] = []

        def spy_get_ai_provider():
            calls.append("called")
            return MockAIProvider()

        monkeypatch.setattr(ai_router_module, "get_ai_provider", spy_get_ai_provider)

        result = await ai_router_module.get_topic_clusters(business.id, db, owner_user)

        assert result.insufficient_data is True
        assert calls == [], "get_ai_provider must not be called for a below-threshold business"


class TestHappyPath:
    """AC1: eligible business renders named topics with count + sentiment,
    ordered by count descending. Reviews are worded to trigger
    MockAIProvider's keyword buckets with distinct, verifiable counts."""

    def _seed(self, *, role: UserRole = UserRole.MERCHANT):
        business = _make_business()
        reviews = [
            _make_review(body) for body in [
                "This place is way too expensive for what you get here overall.",
                "Prices are expensive, not much value for the money spent here.",
                "Such expensive pricing here, the value is questionable at this spot.",
                "Way overpriced and expensive, low value for money spent today.",
                "Staff was very friendly and helpful during my whole visit today.",
            ]
        ]
        rows = [(r, None) for r in reviews]
        script = [FakeResult(scalar=len(reviews)), FakeResult(rows=rows)]
        if role == UserRole.MERCHANT:
            user, merchant = _make_owning_merchant(business)
            script = [FakeResult(scalar=merchant)] + script
        else:
            user = _make_user(role=UserRole.ADMIN)
        db = ScriptedDB(business, script=script)
        return business, user, db

    async def test_topics_render_with_expected_shape_and_counts(self, monkeypatch):
        monkeypatch.setattr(ai_router_module, "get_ai_provider", lambda: MockAIProvider())
        business, user, db = self._seed()

        result = await ai_router_module.get_topic_clusters(business.id, db, user)

        assert result.insufficient_data is False
        assert result.unavailable is False
        assert result.degraded is False
        assert len(result.topics) >= 1
        for topic in result.topics:
            assert topic.sentiment in {"positive", "negative", "mixed"}
            assert topic.count > 0

        by_label = {t.label: t for t in result.topics}
        assert by_label["Value for money"].count == 4
        assert by_label["Staff friendliness"].count == 1

    async def test_topics_are_ordered_by_count_descending(self, monkeypatch):
        """AC1: 'ordered by count descending'. "Value for money" (count=4)
        must precede "Staff friendliness" (count=1) in the response list."""
        monkeypatch.setattr(ai_router_module, "get_ai_provider", lambda: MockAIProvider())
        business, user, db = self._seed()

        result = await ai_router_module.get_topic_clusters(business.id, db, user)

        counts = [t.count for t in result.topics]
        assert counts == sorted(counts, reverse=True), (
            f"topics are not ordered by count descending: {counts!r} -- neither "
            "get_topic_clusters nor MockAIProvider.generate_topic_clusters sorts "
            "by count; MockAIProvider emits topics in a fixed bucket-definition "
            "order regardless of match count"
        )


class TestAdminParity:
    async def test_admin_sees_same_topics_as_owning_merchant(self, monkeypatch):
        monkeypatch.setattr(ai_router_module, "get_ai_provider", lambda: MockAIProvider())
        happy = TestHappyPath()
        business, merchant_user, merchant_db = happy._seed(role=UserRole.MERCHANT)
        _, admin_user, admin_db = happy._seed(role=UserRole.ADMIN)
        admin_db.business = business  # same business as the merchant call

        merchant_result = await ai_router_module.get_topic_clusters(business.id, merchant_db, merchant_user)
        admin_result = await ai_router_module.get_topic_clusters(business.id, admin_db, admin_user)

        assert admin_db.calls == 2, "admin skips the Merchant-ownership lookup entirely"
        assert [t.model_dump() for t in merchant_result.topics] == [t.model_dump() for t in admin_result.topics]


class TestDegradedAndUnavailable:
    def _seed_eligible(self):
        business = _make_business()
        owner_user, owner_merchant = _make_owning_merchant(business)
        reviews = [
            _make_review(body) for body in [
                "Friendly staff and fast helpful service every time I visit here.",
                "Clean store and friendly staff, always a great helpful experience.",
                "Fast and friendly, staff are consistently helpful and courteous.",
                "Helpful, friendly, and fast -- a genuinely great place to shop.",
                "Staff friendliness stood out, fast and helpful the whole visit.",
            ]
        ]
        rows = [(r, None) for r in reviews]
        db = ScriptedDB(
            business,
            script=[FakeResult(scalar=owner_merchant), FakeResult(scalar=len(reviews)), FakeResult(rows=rows)],
        )
        return business, owner_user, db

    async def test_falls_back_to_mock_and_reports_degraded(self, monkeypatch):
        """AC3: primary provider fails, AIGateway falls back to mock,
        degraded=True, topics still render."""
        business, owner_user, db = self._seed_eligible()
        gateway = AIGateway(_AlwaysFailsProvider(), MockAIProvider(), max_retries=0)
        monkeypatch.setattr(ai_router_module, "get_ai_provider", lambda: gateway)

        result = await ai_router_module.get_topic_clusters(business.id, db, owner_user)

        assert result.degraded is True
        assert result.unavailable is False
        assert result.insufficient_data is False
        assert len(result.topics) >= 1

    async def test_provider_error_returns_unavailable_not_5xx(self, monkeypatch):
        """AC7: the AI provider call errors outright -- must degrade to
        unavailable=True (never propagate as a 5xx) and never populate the
        cache with a bad result."""
        business, owner_user, db = self._seed_eligible()
        monkeypatch.setattr(ai_router_module, "get_ai_provider", lambda: _AlwaysFailsProvider())

        cache_set_calls: list[tuple] = []

        async def spy_cache_set(key, value, ttl=300):
            cache_set_calls.append((key, value, ttl))

        monkeypatch.setattr(ai_router_module, "cache_set", spy_cache_set)

        result = await ai_router_module.get_topic_clusters(business.id, db, owner_user)

        assert result.unavailable is True
        assert result.topics == []
        assert result.degraded is False
        assert cache_set_calls == [], "an unavailable result must never be cached"
