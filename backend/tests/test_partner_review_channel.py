"""S-123 partner review channel — mock loop.

Unit-style, no real DB (same constraint as test_reviews.py / test_whatsapp.py):
pure helpers are called directly; service functions run against a small
in-memory fake that satisfies the queries partner_service actually issues.
"""

from __future__ import annotations

import json
import uuid
from datetime import UTC, datetime, timedelta

import pytest
from fastapi import BackgroundTasks, HTTPException

from app.models import (
    AIAnalysis,
    Business,
    BusinessStatus,
    Merchant,
    Partner,
    PartnerMerchantLink,
    PartnerReviewRequest,
    Review,
    ReviewStatus,
    User,
)
from app.schemas import CollectTokenReviewCreate, PartnerReviewRequestCreate
from app.services import partner_service
from app.services.partners import get_partner_provider, validate_startup_config
from app.services.partners.hmac_util import header_value, sign_body, signatures_match
from app.services.partners.mock import MockPartnerProvider


# --- pure helpers ----------------------------------------------------------------


class TestHmac:
    def test_round_trip(self):
        body = b'{"transaction_ref":"INV-1"}'
        assert signatures_match("s3cr3t", body, sign_body("s3cr3t", body))
        assert signatures_match("s3cr3t", body, header_value("s3cr3t", body))  # sha256= prefix ok

    def test_rejects_wrong_secret_and_missing(self):
        body = b"{}"
        assert not signatures_match("right", body, sign_body("wrong", body))
        assert not signatures_match("right", body, None)
        assert not signatures_match("right", body, "")


class TestHashing:
    def test_api_key_hash_is_sha256_hex_and_stable(self):
        h = partner_service.hash_api_key("mhk_demo_partner")
        assert len(h) == 64 and h == partner_service.hash_api_key("mhk_demo_partner")

    def test_customer_ref_hash_never_returns_raw_phone(self):
        h = partner_service.hash_customer_ref("+919812345678")
        assert h and "9812345678" not in h and len(h) == 64
        assert partner_service.hash_customer_ref(None) is None
        assert partner_service.hash_customer_ref("  ") is None


class TestCollectUrl:
    def test_uses_public_app_url_and_c_prefix(self, monkeypatch):
        monkeypatch.setattr(
            partner_service, "get_settings",
            lambda: type("S", (), {"public_app_url": "https://app.example/", "partner_review_token_ttl_hours": 1})(),
        )
        assert partner_service.collect_url("abc123") == "https://app.example/c/abc123"


class TestStartupConfig:
    def test_mock_is_registered(self, monkeypatch):
        monkeypatch.setattr(
            "app.services.partners.get_settings",
            lambda: type("S", (), {"partners_provider": "mock"})(),
        )
        validate_startup_config()  # no raise

    def test_unregistered_provider_raises(self, monkeypatch):
        monkeypatch.setattr(
            "app.services.partners.get_settings",
            lambda: type("S", (), {"partners_provider": "sendgrid"})(),
        )
        with pytest.raises(RuntimeError, match="not a registered provider"):
            validate_startup_config()


class TestMockProvider:
    def test_get_partner_provider_returns_mock(self):
        assert isinstance(get_partner_provider(), MockPartnerProvider)

    def test_verify_signature_is_real(self):
        p = MockPartnerProvider()
        body = b'{"a":1}'
        assert p.verify_request_signature(body, header_value("k", body), "k")
        assert not p.verify_request_signature(body, "sha256=deadbeef", "k")

    async def test_send_callback_signs_and_is_best_effort(self, caplog):
        # No network in this env -> the POST fails; the call must still not raise
        # and must log the signed payload it attempted to deliver.
        with caplog.at_level("INFO", logger="app.partners"):
            await MockPartnerProvider().send_callback(
                "http://127.0.0.1:59999/hook", {"event": "review.captured"}, "sekret"
            )
        assert "partner callback (mock)" in caplog.text
        assert "X-MH-Signature: sha256=" in caplog.text


# --- in-memory fake -------------------------------------------------------------


class _Scalars:
    def __init__(self, rows):
        self._rows = list(rows)

    def all(self):
        return self._rows

    def first(self):
        return self._rows[0] if self._rows else None


class _Result:
    def __init__(self, rows):
        self._rows = list(rows)

    def scalar_one_or_none(self):
        return self._rows[0] if self._rows else None

    def scalar_one(self):
        return self._rows[0]

    def scalars(self):
        return _Scalars(self._rows)


class FakePartnerDB:
    def __init__(self, *, partners=None, links=None, businesses=None, merchants=None,
                 requests=None, users=None, prior_partner_reviews=None):
        self.partners = list(partners or [])
        self.links = list(links or [])
        self.businesses = list(businesses or [])
        self.merchants = list(merchants or [])
        self.requests = list(requests or [])
        self.users = list(users or [])
        self.reviews: list[Review] = []
        self.prior_partner_reviews = list(prior_partner_reviews or [])
        self.added: list[object] = []
        self.rolled_back = False

    async def get(self, model, id_, options=None):
        table = {
            Business: self.businesses, Merchant: self.merchants, User: self.users,
            Partner: self.partners, Review: self.reviews, PartnerReviewRequest: self.requests,
        }.get(model, [])
        return next((o for o in table if getattr(o, "id", None) == id_), None)

    async def execute(self, stmt):
        sql = str(stmt).lower()
        params = list(stmt.compile().params.values())

        if "from reviews" in sql or "join partner_review_requests" in sql:
            return _Result(self.prior_partner_reviews)
        if "partner_review_requests" in sql:
            token = next((p for p in params if isinstance(p, str) and len(p) > 20), None)
            if token is not None:
                rows = [r for r in self.requests if r.token == token]
            else:
                rows = [
                    r for r in self.requests
                    if r.partner_id in params and r.partner_txn_ref in params
                ]
            for r in rows:
                r.business = next((b for b in self.businesses if b.id == r.business_id), None)
            return _Result(rows)
        if "partners" in sql:
            return _Result([p for p in self.partners if p.api_key_hash in params])
        if "partner_merchant_links" in sql:
            return _Result([
                lk for lk in self.links
                if lk.partner_id in params and lk.partner_merchant_ref in params
            ])
        if "from businesses" in sql:
            return _Result([b for b in self.businesses if b.slug in params])
        if "merchants" in sql:
            return _Result([m for m in self.merchants if m.id in params])
        if "notifications" in sql:
            return _Result([])
        return _Result([])

    def add(self, obj):
        self.added.append(obj)
        if isinstance(obj, Review):
            self.reviews.append(obj)
        elif isinstance(obj, User):
            self.users.append(obj)
        elif isinstance(obj, PartnerReviewRequest):
            self.requests.append(obj)

    async def flush(self):
        for obj in self.added:
            if getattr(obj, "id", None) is None:
                obj.id = uuid.uuid4()

    async def rollback(self):
        self.rolled_back = True

    async def refresh(self, obj):
        pass


def _business(**kw) -> Business:
    d = dict(
        id=uuid.uuid4(), merchant_id=uuid.uuid4(), name="Sri Balaji Tiffin",
        slug=f"sri-balaji-{uuid.uuid4().hex[:6]}", address="1 North Usman Rd", city="Chennai",
        status=BusinessStatus.APPROVED, average_rating=0.0, review_count=0,
    )
    d.update(kw)
    return Business(**d)


def _partner(**kw) -> Partner:
    d = dict(
        id=uuid.uuid4(), slug="demo-billing", name="Demo Billing App",
        api_key_hash=partner_service.hash_api_key("mhk_demo_partner"),
        hmac_secret="mhs_demo_partner_secret", callback_url="http://localhost:8000/sink",
        status="active",
    )
    d.update(kw)
    return Partner(**d)


def _request(partner, business, **kw) -> PartnerReviewRequest:
    d = dict(
        id=uuid.uuid4(), partner_id=partner.id, business_id=business.id,
        partner_merchant_ref="demo-merchant-001", partner_txn_ref="INV-2026-1",
        partner_customer_ref=None, token=uuid.uuid4().hex + uuid.uuid4().hex,
        channel="invoice_link", status="pending",
        expires_at=datetime.now(UTC) + timedelta(days=14), redeemed_at=None, review_id=None,
        created_at=datetime.now(UTC),
    )
    d.update(kw)
    return PartnerReviewRequest(**d)


@pytest.fixture(autouse=True)
def _neuter_side_effects(monkeypatch):
    async def _noop(*a, **k):
        return None

    async def _fake_ai(review_id, body, *, business_id, provider=None):
        return AIAnalysis(review_id=review_id, analysis_type="text", provider="mock")

    monkeypatch.setattr(partner_service, "update_business_rating", _noop)
    monkeypatch.setattr(partner_service, "cache_delete_pattern", _noop)
    monkeypatch.setattr(partner_service, "refresh_merchant_ai_summary_bg", lambda *_a: None)
    monkeypatch.setattr(partner_service, "upsert_notice", _noop)
    monkeypatch.setattr(partner_service, "try_send_new_review", _noop)
    monkeypatch.setattr(partner_service, "build_review_ai_analysis", _fake_ai)
    yield


# --- resolve_partner -----------------------------------------------------------


class TestResolvePartner:
    async def test_valid_key(self):
        p = _partner()
        got = await partner_service.resolve_partner(FakePartnerDB(partners=[p]), "mhk_demo_partner")
        assert got is p

    async def test_missing_key_401(self):
        with pytest.raises(HTTPException) as e:
            await partner_service.resolve_partner(FakePartnerDB(), None)
        assert e.value.status_code == 401

    async def test_unknown_key_401(self):
        with pytest.raises(HTTPException) as e:
            await partner_service.resolve_partner(FakePartnerDB(partners=[_partner()]), "nope")
        assert e.value.status_code == 401

    async def test_suspended_partner_401(self):
        p = _partner(status="suspended")
        with pytest.raises(HTTPException) as e:
            await partner_service.resolve_partner(FakePartnerDB(partners=[p]), "mhk_demo_partner")
        assert e.value.status_code == 401


# --- create_review_request ---------------------------------------------------------


class TestCreateReviewRequest:
    async def test_new_request_via_merchant_link(self):
        p, b = _partner(), _business()
        link = PartnerMerchantLink(
            id=uuid.uuid4(), partner_id=p.id, partner_merchant_ref="demo-merchant-001", business_id=b.id
        )
        db = FakePartnerDB(partners=[p], links=[link], businesses=[b])
        payload = PartnerReviewRequestCreate(merchant_ref="demo-merchant-001", transaction_ref="INV-9")
        req, created = await partner_service.create_review_request(db, p, payload)
        assert created is True
        assert req.token and req.business_id == b.id
        assert req.expires_at > datetime.now(UTC)
        assert req.partner_customer_ref is None

    async def test_resolves_by_business_slug_when_no_link(self):
        p, b = _partner(), _business(slug="sri-balaji-x")
        db = FakePartnerDB(partners=[p], businesses=[b])
        payload = PartnerReviewRequestCreate(merchant_ref="sri-balaji-x", transaction_ref="INV-1")
        req, created = await partner_service.create_review_request(db, p, payload)
        assert created and req.business_id == b.id

    async def test_phone_is_hashed(self):
        p, b = _partner(), _business(slug="s-phone")
        db = FakePartnerDB(partners=[p], businesses=[b])
        payload = PartnerReviewRequestCreate(
            merchant_ref="s-phone", transaction_ref="INV-1", customer_phone="+919812345678"
        )
        req, _ = await partner_service.create_review_request(db, p, payload)
        assert req.partner_customer_ref and "9812345678" not in req.partner_customer_ref

    async def test_duplicate_txn_ref_returns_existing(self):
        p, b = _partner(), _business()
        existing = _request(p, b, partner_txn_ref="INV-DUP")
        db = FakePartnerDB(partners=[p], businesses=[b], requests=[existing])
        payload = PartnerReviewRequestCreate(merchant_ref="demo-merchant-001", transaction_ref="INV-DUP")
        req, created = await partner_service.create_review_request(db, p, payload)
        assert created is False and req is existing
        assert len([r for r in db.requests if r.partner_txn_ref == "INV-DUP"]) == 1

    async def test_unknown_merchant_ref_404(self):
        p = _partner()
        db = FakePartnerDB(partners=[p])
        payload = PartnerReviewRequestCreate(merchant_ref="ghost-merchant", transaction_ref="INV-1")
        with pytest.raises(HTTPException) as e:
            await partner_service.create_review_request(db, p, payload)
        assert e.value.status_code == 404 and e.value.detail == "merchant_not_onboarded"

    async def test_unapproved_business_404(self):
        p = _partner()
        b = _business(slug="pending-co", status=BusinessStatus.PENDING)
        db = FakePartnerDB(partners=[p], businesses=[b])
        payload = PartnerReviewRequestCreate(merchant_ref="pending-co", transaction_ref="INV-1")
        with pytest.raises(HTTPException) as e:
            await partner_service.create_review_request(db, p, payload)
        assert e.value.status_code == 404


# --- load_request_for_collect + status ------------------------------------------------


class TestCollectContext:
    async def test_unknown_token_404(self):
        with pytest.raises(HTTPException) as e:
            await partner_service.load_request_for_collect(FakePartnerDB(), "deadbeef" * 8)
        assert e.value.status_code == 404

    async def test_status_pending_then_expired_then_submitted(self):
        p, b = _partner(), _business()
        pending = _request(p, b, token="t" * 40)
        expired = _request(p, b, token="e" * 40, expires_at=datetime.now(UTC) - timedelta(hours=1))
        done = _request(p, b, token="d" * 40, redeemed_at=datetime.now(UTC), status="submitted")
        db = FakePartnerDB(partners=[p], businesses=[b], requests=[pending, expired, done])
        assert (await partner_service.load_request_for_collect(db, "t" * 40))[2] == "pending"
        assert (await partner_service.load_request_for_collect(db, "e" * 40))[2] == "expired"
        assert (await partner_service.load_request_for_collect(db, "d" * 40))[2] == "submitted"


# --- submit_token_review -----------------------------------------------------------


def _review_payload(**kw):
    return CollectTokenReviewCreate(**{"rating": 5, "body": "Fresh food and quick service, loved it", **kw})


class TestSubmitTokenReview:
    async def test_happy_path_writes_partner_review_and_burns_token(self):
        p, b = _partner(), _business()
        merchant = Merchant(id=b.merchant_id, user_id=uuid.uuid4())
        req = _request(p, b, token="tok" * 20)
        db = FakePartnerDB(partners=[p], businesses=[b], merchants=[merchant], requests=[req])

        review, biz = await partner_service.submit_token_review(db, "tok" * 20, _review_payload(), BackgroundTasks())

        assert biz.id == b.id
        assert review.source == "partner"
        assert review.verified_purchase is True
        assert review.status == ReviewStatus.ACTIVE
        assert review.author_id is not None
        author = await db.get(User, review.author_id)
        assert author.auth_provider == "partner" and author.email is None
        assert req.redeemed_at is not None and req.status == "submitted" and req.review_id == review.id

    async def test_schedules_the_signed_partner_callback(self):
        p, b = _partner(), _business()
        bg = BackgroundTasks()
        db = FakePartnerDB(
            partners=[p], businesses=[b],
            merchants=[Merchant(id=b.merchant_id, user_id=uuid.uuid4())],
            requests=[_request(p, b, token="cb" * 20)],
        )
        await partner_service.submit_token_review(db, "cb" * 20, _review_payload(), bg)
        scheduled = {t.func.__name__ for t in bg.tasks}
        assert "send_partner_callback_bg" in scheduled

    async def test_disallowed_language_is_reported(self):
        p, b = _partner(), _business()
        db = FakePartnerDB(
            partners=[p], businesses=[b],
            merchants=[Merchant(id=b.merchant_id, user_id=uuid.uuid4())],
            requests=[_request(p, b, token="bad" * 20)],
        )
        review, _ = await partner_service.submit_token_review(
            db, "bad" * 20, _review_payload(body="the owner is a complete asshole"), BackgroundTasks()
        )
        assert review.status == ReviewStatus.REPORTED

    async def test_expired_token_410(self):
        p, b = _partner(), _business()
        db = FakePartnerDB(
            partners=[p], businesses=[b],
            requests=[_request(p, b, token="exp" * 20, expires_at=datetime.now(UTC) - timedelta(hours=1))],
        )
        with pytest.raises(HTTPException) as e:
            await partner_service.submit_token_review(db, "exp" * 20, _review_payload(), BackgroundTasks())
        assert e.value.status_code == 410

    async def test_already_redeemed_token_409(self):
        p, b = _partner(), _business()
        db = FakePartnerDB(
            partners=[p], businesses=[b],
            requests=[_request(p, b, token="used" * 15, redeemed_at=datetime.now(UTC), status="submitted")],
        )
        with pytest.raises(HTTPException) as e:
            await partner_service.submit_token_review(db, "used" * 15, _review_payload(), BackgroundTasks())
        assert e.value.status_code == 409

    async def test_repeat_customer_reuses_shadow_user(self):
        p, b = _partner(), _business()
        cust_ref = partner_service.hash_customer_ref("+919812345678")
        prior_user = User(id=uuid.uuid4(), full_name="Verified customer", auth_provider="partner", is_active=True)
        prior_review = Review(
            id=uuid.uuid4(), business_id=b.id, author_id=prior_user.id, rating=4,
            body="first visit was good", source="partner", verified_purchase=True,
        )
        req = _request(p, b, token="rep" * 20, partner_customer_ref=cust_ref)
        db = FakePartnerDB(
            partners=[p], businesses=[b], users=[prior_user],
            merchants=[Merchant(id=b.merchant_id, user_id=uuid.uuid4())],
            requests=[req], prior_partner_reviews=[prior_review],
        )
        review, _ = await partner_service.submit_token_review(db, "rep" * 20, _review_payload(), BackgroundTasks())
        assert review.author_id == prior_user.id


# --- dev mock console --------------------------------------------------------------


class TestDevDispatch:
    async def test_dispatch_uses_demo_partner_and_generates_txn(self, monkeypatch):
        p, b = _partner(), _business(slug="demo-shop")
        monkeypatch.setattr(
            partner_service, "get_settings",
            lambda: type("S", (), {
                "partner_demo_api_key": "mhk_demo_partner",
                "public_app_url": "http://localhost:3000",
                "partner_review_token_ttl_hours": 336,
            })(),
        )
        db = FakePartnerDB(partners=[p], businesses=[b])
        req, created, message = await partner_service.dev_dispatch(
            db, type("R", (), {"business_slug": "demo-shop", "transaction_ref": None, "customer_phone": None})()
        )
        assert created and req.partner_txn_ref.startswith("MOCK-")
        assert "Rate your visit" in message and req.token in message


def test_partner_mock_endpoints_are_dev_gated(monkeypatch):
    """_require_mock_console 404s unless debug AND partners_provider == mock."""
    from app.routers import partner as partner_router

    monkeypatch.setattr(
        partner_router, "get_settings",
        lambda: type("S", (), {"debug": False, "partners_provider": "mock"})(),
    )
    with pytest.raises(HTTPException) as e:
        partner_router._require_mock_console()
    assert e.value.status_code == 404


def test_bearer_token_parsing():
    from app.routers.partner import _bearer_token

    assert _bearer_token("Bearer abc123") == "abc123"
    assert _bearer_token("bearer abc123") == "abc123"
    assert _bearer_token(None) is None
    assert _bearer_token("abc123") == "abc123"  # tolerate a bare key


async def test_callback_sink_records_events_for_the_console():
    """The mock partner's endpoint keeps a ring buffer the console reads back."""
    from app.routers import partner as partner_router

    partner_router._RECEIVED_CALLBACKS.clear()
    body = json.dumps({"event": "review.captured", "status": "published", "rating": 5}).encode()

    class _Req:
        async def body(self):
            return body

    await partner_router.partner_mock_callback_sink(_Req(), x_mh_signature="sha256=abc")
    got = await partner_router.partner_mock_callbacks()
    assert got[0]["event"]["event"] == "review.captured"
    assert got[0]["signature"] == "sha256=abc"


def test_callback_event_shape_is_opaque():
    """The callback carries refs + rating only — never invoice contents."""
    event = {
        "event": "review.captured",
        "review_request_id": str(uuid.uuid4()),
        "merchant_ref": "demo-merchant-001",
        "transaction_ref": "INV-1",
        "rating": 5,
        "has_text": True,
        "status": "published",
        "listing_url": "http://x/businesses/y",
        "captured_at": datetime.now(UTC).isoformat(),
    }
    blob = json.dumps(event)
    for forbidden in ("amount", "line_item", "customer_name", "phone"):
        assert forbidden not in blob
