"""S-073: address autocomplete + re-verification on edit.

Router-level unit tests against a FakeDB (no live Postgres/Redis in this
sandbox), following test_businesses_cache_invalidation.py's convention.
Covers `update_business`'s new OTP-gating branch (`_ADDRESS_FIELDS`,
`address_edit_count`) and the new `POST /businesses/{id}/address-verify/request`
endpoint. `phone_otp.consume_otp`/`issue_otp` and `sms.get_sms_provider` are
monkeypatched on the `businesses` router module, mirroring how the existing
file mocks `cache_delete_pattern`.
"""

import uuid

import pytest
from fastapi import HTTPException

from app.models import Business, BusinessStatus, Merchant, User, UserRole
from app.routers import businesses as businesses_module
from app.schemas import BusinessUpdate


class FakeResult:
    def __init__(self, items):
        self._items = list(items)

    def scalar_one(self):
        return self._items[0]

    def scalar_one_or_none(self):
        return self._items[0] if self._items else None


def _clause_matches(obj, clause) -> bool:
    if hasattr(clause, "clauses"):
        return all(_clause_matches(obj, c) for c in clause.clauses)
    return getattr(obj, clause.left.key, None) == clause.right.value


class FakeDB:
    """Supports both Business and Merchant selects, distinguished by the
    statement's mapped entity (SQLAlchemy `column_descriptions[0]["entity"]`)."""

    def __init__(self, *, businesses=None, merchants=None):
        self.businesses = list(businesses or [])
        self.merchants = list(merchants or [])
        self.added: list[object] = []

    async def get(self, model, id_):
        if model is Business:
            return next((b for b in self.businesses if b.id == id_), None)
        if model is Merchant:
            return next((m for m in self.merchants if m.id == id_), None)
        return None

    async def execute(self, stmt):
        entity = stmt.column_descriptions[0]["entity"]
        pool = self.businesses if entity is Business else self.merchants
        items = list(pool)
        wc = stmt.whereclause
        if wc is not None:
            items = [i for i in items if _clause_matches(i, wc)]
        return FakeResult(items)

    def add(self, obj):
        self.added.append(obj)

    async def flush(self):
        pass


def _make_business(**overrides) -> Business:
    defaults = dict(
        id=uuid.uuid4(),
        merchant_id=uuid.uuid4(),
        name="Test Business",
        slug="test-business",
        address="1 Main St",
        city="Metropolis",
        country="US",
        phone=None,
        average_rating=0.0,
        review_count=0,
        address_edit_count=0,
        status=BusinessStatus.APPROVED,
    )
    defaults.update(overrides)
    return Business(**defaults)


def _make_merchant_user(merchant_id) -> tuple[User, Merchant]:
    user_id = uuid.uuid4()
    user = User(id=user_id, email="merch@example.com", full_name="Merch", role=UserRole.MERCHANT, is_active=True)
    merchant = Merchant(id=merchant_id, user_id=user_id, phone=None)
    return user, merchant


def _make_admin() -> User:
    return User(id=uuid.uuid4(), email="admin@example.com", full_name="Admin", role=UserRole.ADMIN, is_active=True)


async def _noop_cache_delete(pattern):
    pass


# ---------------------------------------------------------------------------
# AC4/AC5: first address edit (create implicitly covered by create_business;
# this exercises the "first edit on an existing business" no-OTP path).
# ---------------------------------------------------------------------------


async def test_first_address_edit_requires_no_otp_and_increments_count(monkeypatch):
    monkeypatch.setattr(businesses_module, "cache_delete_pattern", _noop_cache_delete)
    business = _make_business(address_edit_count=0)
    merchant_id = business.merchant_id
    user, merchant = _make_merchant_user(merchant_id)
    db = FakeDB(businesses=[business], merchants=[merchant])

    result = await businesses_module.update_business(
        business.id, BusinessUpdate(address="2 New St"), db, user
    )

    assert result.address == "2 New St"
    assert business.address_edit_count == 1


# ---------------------------------------------------------------------------
# AC6/AC7: second edit requires OTP -- missing code, wrong code, correct code.
# ---------------------------------------------------------------------------


async def test_second_address_edit_without_otp_code_400s_and_does_not_change_address(monkeypatch):
    monkeypatch.setattr(businesses_module, "cache_delete_pattern", _noop_cache_delete)
    business = _make_business(address_edit_count=1, address="Original Address")
    user, merchant = _make_merchant_user(business.merchant_id)
    db = FakeDB(businesses=[business], merchants=[merchant])

    with pytest.raises(HTTPException) as exc:
        await businesses_module.update_business(business.id, BusinessUpdate(address="Hacked Address"), db, user)

    assert exc.value.status_code == 400
    assert "verification code required" in exc.value.detail.lower()
    assert business.address == "Original Address"
    assert business.address_edit_count == 1


async def test_second_address_edit_with_wrong_otp_code_401s_and_does_not_change_address(monkeypatch):
    monkeypatch.setattr(businesses_module, "cache_delete_pattern", _noop_cache_delete)

    async def fake_consume_otp(key, code):
        return False

    monkeypatch.setattr(businesses_module, "consume_otp", fake_consume_otp)

    business = _make_business(address_edit_count=1, address="Original Address")
    user, merchant = _make_merchant_user(business.merchant_id)
    db = FakeDB(businesses=[business], merchants=[merchant])

    with pytest.raises(HTTPException) as exc:
        await businesses_module.update_business(
            business.id, BusinessUpdate(address="Hacked Address", address_otp_code="000000"), db, user
        )

    assert exc.value.status_code == 401
    assert business.address == "Original Address"
    assert business.address_edit_count == 1


async def test_second_address_edit_with_correct_otp_code_saves_and_increments_count(monkeypatch):
    monkeypatch.setattr(businesses_module, "cache_delete_pattern", _noop_cache_delete)

    consumed_keys = []

    async def fake_consume_otp(key, code):
        consumed_keys.append((key, code))
        return True

    monkeypatch.setattr(businesses_module, "consume_otp", fake_consume_otp)

    business = _make_business(address_edit_count=1, address="Original Address")
    user, merchant = _make_merchant_user(business.merchant_id)
    db = FakeDB(businesses=[business], merchants=[merchant])

    result = await businesses_module.update_business(
        business.id, BusinessUpdate(address="Confirmed New Address", address_otp_code="123456"), db, user
    )

    assert result.address == "Confirmed New Address"
    assert business.address_edit_count == 2
    assert consumed_keys == [(f"bizaddr:{business.id}", "123456")]


async def test_non_address_field_update_never_triggers_otp_gate(monkeypatch):
    """A PATCH that touches no address-bearing field is unaffected, even on a
    business with a prior address edit -- the gate is address-change-specific."""
    monkeypatch.setattr(businesses_module, "cache_delete_pattern", _noop_cache_delete)
    business = _make_business(address_edit_count=1, name="Old Name")
    user, merchant = _make_merchant_user(business.merchant_id)
    db = FakeDB(businesses=[business], merchants=[merchant])

    result = await businesses_module.update_business(business.id, BusinessUpdate(name="New Name"), db, user)

    assert result.name == "New Name"
    assert business.address_edit_count == 1  # unchanged -- no address field touched


async def test_admin_edit_bypasses_otp_gate_even_on_second_edit(monkeypatch):
    """ADR-014 Risks: admin-initiated address edits are not OTP-gated (no single
    merchant phone to send an admin-initiated OTP to). The edit counter still
    advances on an admin edit, though, so a later merchant edit isn't wrongly
    treated as the free first edit just because an admin touched the address in
    between (fixed after TR-S-073 flagged the original nested-under-MERCHANT
    increment as a gap)."""
    monkeypatch.setattr(businesses_module, "cache_delete_pattern", _noop_cache_delete)
    business = _make_business(address_edit_count=1, address="Original Address")
    admin = _make_admin()
    db = FakeDB(businesses=[business])

    result = await businesses_module.update_business(business.id, BusinessUpdate(address="Admin Edit"), db, admin)

    assert result.address == "Admin Edit"
    assert business.address_edit_count == 2


async def test_update_business_rejects_non_owner_merchant(monkeypatch):
    monkeypatch.setattr(businesses_module, "cache_delete_pattern", _noop_cache_delete)
    business = _make_business()
    # A different merchant (not the owner) attempts the PATCH.
    other_user, other_merchant = _make_merchant_user(uuid.uuid4())
    db = FakeDB(businesses=[business], merchants=[other_merchant])

    with pytest.raises(HTTPException) as exc:
        await businesses_module.update_business(business.id, BusinessUpdate(name="Nope"), db, other_user)

    assert exc.value.status_code == 403


# ---------------------------------------------------------------------------
# POST /businesses/{id}/address-verify/request
# ---------------------------------------------------------------------------


async def test_request_address_verify_409_when_no_prior_edit(monkeypatch):
    business = _make_business(address_edit_count=0)
    user, merchant = _make_merchant_user(business.merchant_id)
    db = FakeDB(businesses=[business], merchants=[merchant])

    with pytest.raises(HTTPException) as exc:
        await businesses_module.request_address_verify(business.id, db, user)

    assert exc.value.status_code == 409


async def test_request_address_verify_400_when_no_phone_available(monkeypatch):
    business = _make_business(address_edit_count=1, phone=None)
    user, merchant = _make_merchant_user(business.merchant_id)
    merchant.phone = None
    user.phone = None
    db = FakeDB(businesses=[business], merchants=[merchant])

    with pytest.raises(HTTPException) as exc:
        await businesses_module.request_address_verify(business.id, db, user)

    assert exc.value.status_code == 400
    assert "phone number" in exc.value.detail.lower()


async def test_request_address_verify_sends_otp_via_sms_provider(monkeypatch):
    business = _make_business(address_edit_count=1, phone="+919876500011")
    user, merchant = _make_merchant_user(business.merchant_id)
    db = FakeDB(businesses=[business], merchants=[merchant])

    issued_keys = []

    async def fake_issue_otp(key):
        issued_keys.append(key)
        return "654321"

    sent = []

    class FakeSmsProvider:
        async def send_otp(self, phone, code):
            sent.append((phone, code))

    monkeypatch.setattr(businesses_module, "issue_otp", fake_issue_otp)
    monkeypatch.setattr(businesses_module, "get_sms_provider", lambda: FakeSmsProvider())

    result = await businesses_module.request_address_verify(business.id, db, user)

    assert issued_keys == [f"bizaddr:{business.id}"]
    assert sent == [("+919876500011", "654321")]
    assert "sent" in result.message.lower() or "code" in result.message.lower()


async def test_request_address_verify_rejects_non_owner(monkeypatch):
    business = _make_business(address_edit_count=1, phone="+919876500011")
    other_user, other_merchant = _make_merchant_user(uuid.uuid4())
    db = FakeDB(businesses=[business], merchants=[other_merchant])

    with pytest.raises(HTTPException) as exc:
        await businesses_module.request_address_verify(business.id, db, other_user)

    assert exc.value.status_code == 403
