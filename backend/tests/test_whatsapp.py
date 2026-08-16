"""S-050..052 WhatsApp ingest against the mock provider (no Meta network).

Calls webhook/dashboard handlers and `whatsapp_ingest_service` with an
in-memory db — same rationale as `test_google_reviews.py`. An ASGI + real
Postgres pass of this file hit the known function-scoped event-loop flake
(`InterfaceError: another operation is in progress`) after the first
DB-touching test.
"""

from __future__ import annotations

import json
import uuid
from datetime import UTC, datetime

import pytest
from fastapi import HTTPException
from sqlalchemy.sql.expression import Update

from app.dependencies import require_roles
from app.models import (
    Business,
    BusinessStatus,
    BusinessUpdateDraft,
    DraftStatus,
    Merchant,
    User,
    UserRole,
    WhatsAppSession,
)
from app.routers import dashboard as dashboard_router
from app.routers import webhooks as webhooks_router
from app.schemas import WhatsAppDraftApplyRequest
from app.services import whatsapp_ingest_service
from app.services.whatsapp import get_whatsapp_provider


class FakeScalars:
    def __init__(self, rows):
        self._rows = rows

    def all(self):
        return self._rows


class FakeResult:
    def __init__(self, *, scalar=None, rows=None):
        self._scalar = scalar
        self._rows = rows if rows is not None else ([] if scalar is None else [scalar])

    def scalar_one_or_none(self):
        return self._scalar

    def scalars(self):
        return FakeScalars(self._rows)


class InMemoryDB:
    """Enough of AsyncSession for WhatsApp link, inbound, drafts, and RBAC."""

    def __init__(self, business: Business | None, merchant: Merchant | None = None):
        self.business = business
        self.merchant = merchant
        self.sessions: list[WhatsAppSession] = []
        self.drafts: list[BusinessUpdateDraft] = []
        self.photos: list[object] = []

    async def get(self, model, id_):
        if model is Business and self.business and self.business.id == id_:
            return self.business
        if model is BusinessUpdateDraft:
            return next((d for d in self.drafts if d.id == id_), None)
        return None

    async def execute(self, stmt):
        if isinstance(stmt, Update):
            now = datetime.now(UTC)
            if self.business:
                for session in self.sessions:
                    if session.business_id == self.business.id and session.expires_at > now:
                        session.expires_at = now
            return FakeResult()

        compiled = str(stmt.compile(compile_kwargs={"render_postcompile": True})).lower()
        params = list(stmt.compile().params.values())

        if "merchants" in compiled:
            return FakeResult(scalar=self.merchant)

        if "businesses" in compiled:
            if self.business and self.merchant:
                self.business.merchant = self.merchant
            return FakeResult(scalar=self.business)

        if "business_update_drafts" in compiled:
            pending = [
                d
                for d in self.drafts
                if d.status == DraftStatus.PENDING
                and (self.business is None or d.business_id == self.business.id)
            ]
            return FakeResult(scalar=pending[0] if pending else None, rows=pending)

        if "whatsapp_sessions" in compiled:
            token = next((v for v in params if isinstance(v, str) and str(v).upper().startswith("MH-")), None)
            if token:
                match = next((s for s in self.sessions if s.token == token.upper()), None)
                return FakeResult(scalar=match)
            phone = next((v for v in params if isinstance(v, str) and v[:1].isdigit()), None)
            now = datetime.now(UTC)
            matches = [
                s
                for s in self.sessions
                if s.phone_e164 == phone and s.expires_at > now
            ]
            return FakeResult(scalar=matches[0] if matches else None)

        return FakeResult()

    def add(self, obj):
        if isinstance(obj, WhatsAppSession):
            self.sessions.append(obj)
        elif isinstance(obj, BusinessUpdateDraft):
            self.drafts.append(obj)
        else:
            self.photos.append(obj)

    async def flush(self):
        now = datetime.now(UTC)
        for row in (*self.sessions, *self.drafts, *self.photos):
            if getattr(row, "id", None) is None:
                row.id = uuid.uuid4()
            if getattr(row, "created_at", None) is None:
                row.created_at = now
            if hasattr(row, "updated_at") and getattr(row, "updated_at", None) is None:
                row.updated_at = now

    async def commit(self):
        return None


class FakeRequest:
    def __init__(self, body: bytes):
        self._body = body

    async def body(self) -> bytes:
        return self._body


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
        name="WA Test",
        slug=f"wa-test-{uuid.uuid4().hex[:8]}",
        address="1 Main St",
        city="Chennai",
        status=BusinessStatus.APPROVED,
        average_rating=0.0,
        review_count=0,
        description=None,
    )
    defaults.update(overrides)
    return Business(**defaults)


def _owning(business: Business) -> tuple[User, Merchant]:
    user = _make_user(UserRole.MERCHANT)
    merchant = Merchant(id=business.merchant_id, user_id=user.id)
    return user, merchant


def _meta_text(from_phone: str, body: str, msg_id: str = "wamid.1") -> bytes:
    return json.dumps(
        {
            "object": "whatsapp_business_account",
            "entry": [
                {
                    "changes": [
                        {
                            "value": {
                                "messages": [
                                    {
                                        "from": from_phone,
                                        "id": msg_id,
                                        "type": "text",
                                        "text": {"body": body},
                                    }
                                ]
                            }
                        }
                    ]
                }
            ],
        }
    ).encode()


def _meta_image(from_phone: str, media_id: str = "mock-media-1", caption: str | None = None) -> bytes:
    image = {"id": media_id, "mime_type": "image/png"}
    if caption:
        image["caption"] = caption
    return json.dumps(
        {
            "object": "whatsapp_business_account",
            "entry": [
                {
                    "changes": [
                        {
                            "value": {
                                "messages": [
                                    {
                                        "from": from_phone,
                                        "id": "wamid.img",
                                        "type": "image",
                                        "image": image,
                                    }
                                ]
                            }
                        }
                    ]
                }
            ],
        }
    ).encode()


def _meta_other(from_phone: str) -> bytes:
    return json.dumps(
        {
            "object": "whatsapp_business_account",
            "entry": [
                {
                    "changes": [
                        {
                            "value": {
                                "messages": [
                                    {"from": from_phone, "id": "wamid.vid", "type": "video", "video": {"id": "x"}}
                                ]
                            }
                        }
                    ]
                }
            ],
        }
    ).encode()


async def _bind(db: InMemoryDB, phone: str) -> str:
    payload = await whatsapp_ingest_service.create_link(db, db.business)
    token = payload["token"]
    await whatsapp_ingest_service.handle_inbound(db, _meta_text(phone, token), "sha256=mock")
    return token


class TestWebhookHandshake:
    async def test_verify_echoes_challenge(self):
        res = await webhooks_router.whatsapp_verify(
            hub_mode="subscribe",
            hub_verify_token="mock-verify-token",
            hub_challenge="abc123",
        )
        assert res.body == b"abc123"

    async def test_verify_rejects_bad_token(self):
        with pytest.raises(HTTPException) as exc_info:
            await webhooks_router.whatsapp_verify(
                hub_mode="subscribe",
                hub_verify_token="nope",
                hub_challenge="abc123",
            )
        assert exc_info.value.status_code == 403


class TestWebhookSignature:
    async def test_missing_signature_is_400(self):
        with pytest.raises(HTTPException) as exc_info:
            await webhooks_router.whatsapp_inbound(
                FakeRequest(_meta_text("1555", "hi")),
                InMemoryDB(None),
                None,
            )
        assert exc_info.value.status_code == 400

    async def test_invalid_signature_is_400(self):
        with pytest.raises(HTTPException) as exc_info:
            await whatsapp_ingest_service.handle_inbound(
                InMemoryDB(None), _meta_text("1555", "hi"), "sha256=deadbeef"
            )
        assert exc_info.value.status_code == 400


class TestLinkAndRbac:
    async def test_merchant_gets_wa_me_link_with_token(self):
        business = _make_business()
        user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)
        body = await dashboard_router.create_whatsapp_link(business.id, db, user)
        assert body.available is True
        assert body.wa_url.startswith("https://wa.me/")
        assert body.token.startswith("MH-")
        assert body.token in body.wa_url
        assert len(db.sessions) == 1

    async def test_customer_cannot_create_link(self):
        checker = require_roles(UserRole.MERCHANT, UserRole.ADMIN)
        with pytest.raises(HTTPException) as exc_info:
            await checker(user=_make_user(UserRole.CUSTOMER))
        assert exc_info.value.status_code == 403

    async def test_other_merchant_cannot_create_link(self):
        business = _make_business()
        other = _make_user(UserRole.MERCHANT)
        other_merchant = Merchant(id=uuid.uuid4(), user_id=other.id)
        db = InMemoryDB(business, other_merchant)
        with pytest.raises(HTTPException) as exc_info:
            await dashboard_router.create_whatsapp_link(business.id, db, other)
        assert exc_info.value.status_code == 403


class TestInboundBindAndAck:
    async def test_token_redeems_and_text_creates_pending_draft(self):
        business = _make_business()
        _user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)
        payload = await whatsapp_ingest_service.create_link(db, business)
        token = payload["token"]
        res = await whatsapp_ingest_service.handle_inbound(
            db,
            _meta_text("15559876543", f"{token} we're open 9-9 mon-sat near the bus stand"),
            "sha256=mock",
        )
        assert res["ok"] is True
        drafts = await whatsapp_ingest_service.list_pending_drafts(db, business.id)
        assert len(drafts) == 1
        assert drafts[0].status == DraftStatus.PENDING
        fields = drafts[0].extracted_fields
        assert fields.get("description") or fields.get("address") or fields.get("business_hours")
        sess = db.sessions[0]
        assert sess.phone_e164 == "15559876543"
        assert sess.redeemed_at is not None
        assert business.description is None

    async def test_unknown_token_does_not_bind(self):
        db = InMemoryDB(None)
        res = await whatsapp_ingest_service.handle_inbound(
            db, _meta_text("15551111111", "MH-FFFFFFFF hello"), "sha256=mock"
        )
        assert res["ok"] is True
        assert db.sessions == []

    async def test_followup_from_bound_phone_without_token(self):
        business = _make_business()
        _user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)
        await _bind(db, "1555222")
        await whatsapp_ingest_service.handle_inbound(
            db, _meta_text("1555222", "open 9am near the street"), "sha256=mock"
        )
        drafts = await whatsapp_ingest_service.list_pending_drafts(db, business.id)
        assert len(drafts) >= 1


class TestPhotos:
    async def test_bound_image_creates_general_photo(self, monkeypatch):
        saved: list[dict] = []

        async def _save(db, **kwargs):
            saved.append(kwargs)
            return object()

        monkeypatch.setattr("app.services.whatsapp_ingest_service.save_business_photo", _save)
        business = _make_business()
        _user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)
        await _bind(db, "1555333")
        await whatsapp_ingest_service.handle_inbound(db, _meta_image("1555333"), "sha256=mock")
        assert len(saved) == 1
        assert saved[0]["photo_type"] == "general"
        assert saved[0]["business_id"] == business.id

    async def test_unbound_image_is_ignored(self, monkeypatch):
        saved: list[dict] = []

        async def _save(db, **kwargs):
            saved.append(kwargs)
            return object()

        monkeypatch.setattr("app.services.whatsapp_ingest_service.save_business_photo", _save)
        business = _make_business()
        db = InMemoryDB(business)
        await whatsapp_ingest_service.handle_inbound(db, _meta_image("1555444"), "sha256=mock")
        assert saved == []

    async def test_failed_media_does_not_create_photo(self, monkeypatch):
        saved: list[dict] = []

        async def _save(db, **kwargs):
            saved.append(kwargs)
            return object()

        monkeypatch.setattr("app.services.whatsapp_ingest_service.save_business_photo", _save)
        business = _make_business()
        _user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)
        await _bind(db, "1555555")
        await whatsapp_ingest_service.handle_inbound(
            db, _meta_image("1555555", media_id="mock-media-fail"), "sha256=mock"
        )
        assert saved == []

    async def test_video_is_not_stored(self, monkeypatch):
        saved: list[dict] = []

        async def _save(db, **kwargs):
            saved.append(kwargs)
            return object()

        monkeypatch.setattr("app.services.whatsapp_ingest_service.save_business_photo", _save)
        business = _make_business()
        _user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)
        await _bind(db, "1555666")
        await whatsapp_ingest_service.handle_inbound(db, _meta_other("1555666"), "sha256=mock")
        assert saved == []


class TestDrafts:
    async def _pending(self) -> tuple[User, InMemoryDB, BusinessUpdateDraft]:
        business = _make_business()
        user, merchant = _owning(business)
        db = InMemoryDB(business, merchant)
        payload = await whatsapp_ingest_service.create_link(db, business)
        await whatsapp_ingest_service.handle_inbound(
            db,
            _meta_text("1555777", f"{payload['token']} open 9-9 near the bus stand friendly cafe"),
            "sha256=mock",
        )
        drafts = await whatsapp_ingest_service.list_pending_drafts(db, business.id)
        assert drafts
        return user, db, drafts[0]

    async def test_apply_writes_live_fields(self, monkeypatch):
        async def _noop(*_a, **_k):
            return None

        monkeypatch.setattr("app.services.whatsapp_ingest_service.cache_delete_pattern", _noop)
        user, db, draft = await self._pending()
        before_desc = db.business.description
        body = await dashboard_router.apply_whatsapp_draft(
            db.business.id, draft.id, WhatsAppDraftApplyRequest(), db, user
        )
        assert body.status == DraftStatus.APPLIED
        fields = draft.extracted_fields
        if fields.get("description"):
            assert db.business.description == fields["description"]
            assert db.business.description != before_desc or before_desc == fields["description"]
        if fields.get("address"):
            assert db.business.address == fields["address"]

    async def test_discard_does_not_change_listing(self):
        user, db, draft = await self._pending()
        before_addr = db.business.address
        body = await dashboard_router.discard_whatsapp_draft(db.business.id, draft.id, db, user)
        assert body.status == DraftStatus.DISCARDED
        assert db.business.address == before_addr
        remaining = await whatsapp_ingest_service.list_pending_drafts(db, db.business.id)
        assert remaining == []

    async def test_customer_cannot_list_or_apply_drafts(self):
        checker = require_roles(UserRole.MERCHANT, UserRole.ADMIN)
        with pytest.raises(HTTPException) as exc_info:
            await checker(user=_make_user(UserRole.CUSTOMER))
        assert exc_info.value.status_code == 403

    async def test_admin_can_list_drafts(self):
        _user, db, _draft = await self._pending()
        admin = _make_user(UserRole.ADMIN)
        rows = await dashboard_router.list_whatsapp_drafts(db.business.id, db, admin)
        assert rows
        assert rows[0].status == DraftStatus.PENDING


class TestMockProvider:
    def test_click_to_chat_uses_demo_number(self):
        provider = get_whatsapp_provider()
        assert provider.is_available()
        url = provider.click_to_chat_url("MH-ABCD1234")
        assert "wa.me/" in url
        assert "MH-ABCD1234" in url
