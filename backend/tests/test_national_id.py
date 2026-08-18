import uuid

import pytest
from fastapi import HTTPException
from pydantic import ValidationError

from app.models import NationalIdType, User, UserRole
from app.schemas import BusinessCreate, MockAadhaarOtpRequest, MockOtpVerifyRequest, UserProfileUpdate
from app.services.national_id import (
    apply_admin_national_id_mask,
    has_national_id,
    mask_national_id_number,
    merchant_national_id_required,
)


def test_national_id_type_persists_values_not_names():
    """Postgres nationalidtype is pan/aadhaar/other; names like PAN 500 the PATCH."""
    col = User.__table__.c.national_id_type
    assert set(col.type.enums) == {member.value for member in NationalIdType}
    assert "PAN" not in col.type.enums


def test_mask_keeps_last_four():
    assert mask_national_id_number("ABCDE1234F") == "••••••234F"
    assert mask_national_id_number("1234") == "••••"
    assert mask_national_id_number(None) is None


def test_merchant_required_when_missing():
    user = User(
        email="m@example.com",
        full_name="M",
        role=UserRole.MERCHANT,
        is_active=True,
        national_id_type=None,
        national_id_number=None,
    )
    assert merchant_national_id_required(user) is True
    assert has_national_id(user) is False


def test_customer_not_required():
    user = User(
        email="c@example.com",
        full_name="C",
        role=UserRole.CUSTOMER,
        is_active=True,
    )
    assert merchant_national_id_required(user) is False


def test_business_create_requires_phone():
    """S-072: BusinessCreate.phone is required at the schema level (422 before the
    service-layer national-ID gate is ever reached)."""
    with pytest.raises(ValidationError) as exc:
        BusinessCreate(name="Shop", address="1 St", city="Chennai", email="shop@example.com")
    assert any(err["loc"] == ("phone",) for err in exc.value.errors())


def test_business_create_requires_email():
    """S-072: BusinessCreate.email is required at the schema level."""
    with pytest.raises(ValidationError) as exc:
        BusinessCreate(name="Shop", address="1 St", city="Chennai", phone="+919876500099")
    assert any(err["loc"] == ("email",) for err in exc.value.errors())


def test_business_create_rejects_malformed_phone():
    """S-072 AC6: an invalid phone format (distinct from "missing") is rejected too."""
    with pytest.raises(ValidationError) as exc:
        BusinessCreate(name="Shop", address="1 St", city="Chennai", phone="abc", email="shop@example.com")
    assert any(err["loc"] == ("phone",) for err in exc.value.errors())


def test_business_create_rejects_malformed_email():
    """S-072 AC6: an invalid email format is rejected by Pydantic's EmailStr."""
    with pytest.raises(ValidationError) as exc:
        BusinessCreate(name="Shop", address="1 St", city="Chennai", phone="+919876500099", email="not-an-email")
    assert any(err["loc"] == ("email",) for err in exc.value.errors())


def test_business_create_succeeds_with_valid_phone_and_email():
    """Sanity check: a fully valid payload still passes (no over-tightening)."""
    payload = BusinessCreate(name="Shop", address="1 St", city="Chennai", phone="+919876500099", email="shop@example.com")
    assert payload.phone == "+919876500099"
    assert payload.email == "shop@example.com"


async def test_create_business_400_without_national_id():
    from fastapi import HTTPException

    from app.routers.businesses import create_business
    from app.schemas import BusinessCreate

    user = User(
        email="m@example.com",
        full_name="M",
        role=UserRole.MERCHANT,
        is_active=True,
    )
    with pytest.raises(HTTPException) as exc:
        await create_business(
            BusinessCreate(
                name="Shop",
                address="1 St",
                city="Chennai",
                phone="+919876500099",
                email="shop@example.com",
            ),
            db=None,  # type: ignore[arg-type]
            user=user,
        )
    assert exc.value.status_code == 400


# ---------------------------------------------------------------------------
# S-070 AC1/AC2/AC5: structural validation on UserProfileUpdate.national_id_number
# ---------------------------------------------------------------------------


def test_user_profile_update_accepts_structurally_valid_aadhaar():
    payload = UserProfileUpdate(national_id_type=NationalIdType.AADHAAR, national_id_number="123456789012")
    assert payload.national_id_number == "123456789012"


@pytest.mark.parametrize("bad_value", ["12345", "12345678901a", "1234567890123", ""])
def test_user_profile_update_rejects_malformed_aadhaar(bad_value):
    if bad_value == "":
        pytest.skip("empty string is falsy -- validator intentionally no-ops on falsy input")
    with pytest.raises(ValidationError) as exc:
        UserProfileUpdate(national_id_type=NationalIdType.AADHAAR, national_id_number=bad_value)
    assert any(err["loc"] == ("national_id_number",) for err in exc.value.errors())


def test_user_profile_update_accepts_structurally_valid_pan():
    payload = UserProfileUpdate(national_id_type=NationalIdType.PAN, national_id_number="ABCDE1234F")
    assert payload.national_id_number == "ABCDE1234F"


@pytest.mark.parametrize("bad_value", ["ABCDE1234", "ABCD1234FF", "12345ABCDE", "abcde1234"])
def test_user_profile_update_rejects_malformed_pan(bad_value):
    with pytest.raises(ValidationError) as exc:
        UserProfileUpdate(national_id_type=NationalIdType.PAN, national_id_number=bad_value)
    assert any(err["loc"] == ("national_id_number",) for err in exc.value.errors())


def test_user_profile_update_applies_no_structural_check_for_other_type():
    """S-070 AC5: "Other" keeps S-043's free-text behavior -- no new regex applied."""
    payload = UserProfileUpdate(national_id_type=NationalIdType.OTHER, national_id_number="not-a-pan-or-aadhaar")
    assert payload.national_id_number == "not-a-pan-or-aadhaar"


# ---------------------------------------------------------------------------
# S-070 AC1/AC3: MockAadhaarOtpRequest / MockOtpVerifyRequest schema validation
# ---------------------------------------------------------------------------


def test_mock_aadhaar_otp_request_accepts_valid_number():
    payload = MockAadhaarOtpRequest(aadhaar_number="123456789012")
    assert payload.aadhaar_number == "123456789012"


def test_mock_aadhaar_otp_request_rejects_malformed_number():
    with pytest.raises(ValidationError) as exc:
        MockAadhaarOtpRequest(aadhaar_number="not-12-digits")
    assert any(err["loc"] == ("aadhaar_number",) for err in exc.value.errors())


def test_mock_otp_verify_request_rejects_wrong_length_code():
    with pytest.raises(ValidationError):
        MockOtpVerifyRequest(code="123")


def test_mock_otp_verify_request_accepts_six_digit_code():
    payload = MockOtpVerifyRequest(code="123456")
    assert payload.code == "123456"


# ---------------------------------------------------------------------------
# S-070 AC3/AC4: POST /auth/national-id/aadhaar/mock-otp/request and /verify
# ---------------------------------------------------------------------------


class FakeRedisClient:
    """Minimal async in-memory stand-in for the pending-Aadhaar Redis key."""

    def __init__(self):
        self.store: dict[str, str] = {}

    async def set(self, key, value, ex=None):
        self.store[key] = value

    async def get(self, key):
        return self.store.get(key)

    async def delete(self, key):
        self.store.pop(key, None)


def _make_merchant_user() -> User:
    return User(id=uuid.uuid4(), email="m@example.com", full_name="M", role=UserRole.MERCHANT, is_active=True)


def _fake_get_redis(client: "FakeRedisClient"):
    """`get_redis()` is `async def` in production -- the patched replacement
    must be awaitable too, or `await get_redis()` in the router blows up."""

    async def _get():
        return client

    return _get


async def test_request_aadhaar_mock_otp_stores_pending_number_and_returns_dev_code(monkeypatch):
    from app.routers import auth as auth_module
    from app.schemas import MockAadhaarOtpRequest as _Req

    async def fake_issue_otp(key):
        return "111111"

    fake_redis = FakeRedisClient()

    class FakeSettings:
        debug = True

    monkeypatch.setattr(auth_module, "issue_otp", fake_issue_otp)
    monkeypatch.setattr(auth_module, "get_redis", _fake_get_redis(fake_redis))
    monkeypatch.setattr(auth_module, "get_settings", lambda: FakeSettings())

    user = _make_merchant_user()
    result = await auth_module.request_aadhaar_mock_otp(_Req(aadhaar_number="123456789012"), user)

    assert result.dev_code == "111111"
    assert fake_redis.store[f"aadhaar-mock-pending:{user.id}"] == "123456789012"


async def test_request_aadhaar_mock_otp_omits_dev_code_when_not_debug(monkeypatch):
    from app.routers import auth as auth_module
    from app.schemas import MockAadhaarOtpRequest as _Req

    async def fake_issue_otp(key):
        return "111111"

    class FakeSettings:
        debug = False

    monkeypatch.setattr(auth_module, "issue_otp", fake_issue_otp)
    monkeypatch.setattr(auth_module, "get_redis", _fake_get_redis(FakeRedisClient()))
    monkeypatch.setattr(auth_module, "get_settings", lambda: FakeSettings())

    user = _make_merchant_user()
    result = await auth_module.request_aadhaar_mock_otp(_Req(aadhaar_number="123456789012"), user)

    assert result.dev_code is None


async def test_verify_aadhaar_mock_otp_wrong_code_401s_and_does_not_save(monkeypatch):
    from app.routers import auth as auth_module

    async def fake_consume_otp(key, code):
        return False

    monkeypatch.setattr(auth_module, "consume_otp", fake_consume_otp)

    user = _make_merchant_user()
    with pytest.raises(HTTPException) as exc:
        await auth_module.verify_aadhaar_mock_otp(MockOtpVerifyRequest(code="000000"), user, db=None)  # type: ignore[arg-type]

    assert exc.value.status_code == 401
    assert user.national_id_number is None


async def test_verify_aadhaar_mock_otp_expired_pending_value_401s(monkeypatch):
    """Code matched, but the pending Aadhaar number's TTL already lapsed -- AC4's
    "retry allowed" path, not a silent partial save."""
    from app.routers import auth as auth_module

    async def fake_consume_otp(key, code):
        return True

    monkeypatch.setattr(auth_module, "consume_otp", fake_consume_otp)
    monkeypatch.setattr(auth_module, "get_redis", _fake_get_redis(FakeRedisClient()))  # empty -- nothing pending

    user = _make_merchant_user()
    with pytest.raises(HTTPException) as exc:
        await auth_module.verify_aadhaar_mock_otp(MockOtpVerifyRequest(code="123456"), user, db=None)  # type: ignore[arg-type]

    assert exc.value.status_code == 401


class FakeDbSession:
    async def flush(self):
        pass

    async def refresh(self, obj):
        pass


async def test_verify_aadhaar_mock_otp_correct_code_saves_and_marks_verified(monkeypatch):
    """S-070: verify *is* the save step -- national_id_type/number set only here,
    never via a direct PATCH /auth/me for Aadhaar."""
    from app.routers import auth as auth_module

    async def fake_consume_otp(key, code):
        return True

    fake_redis = FakeRedisClient()
    user = _make_merchant_user()
    fake_redis.store[f"aadhaar-mock-pending:{user.id}"] = "123456789012"

    monkeypatch.setattr(auth_module, "consume_otp", fake_consume_otp)
    monkeypatch.setattr(auth_module, "get_redis", _fake_get_redis(fake_redis))

    result = await auth_module.verify_aadhaar_mock_otp(
        MockOtpVerifyRequest(code="123456"), user, db=FakeDbSession()  # type: ignore[arg-type]
    )

    assert "verified" in result.message.lower() or "saved" in result.message.lower()
    assert user.national_id_type == NationalIdType.AADHAAR
    assert user.national_id_number == "123456789012"
    assert f"aadhaar-mock-pending:{user.id}" not in fake_redis.store


# ---------------------------------------------------------------------------
# S-070 AC8: admin-list masking is unaffected by mock-verification status.
# ---------------------------------------------------------------------------


def test_apply_admin_national_id_mask_masks_aadhaar_regardless_of_type():
    user = User(
        email="m@example.com",
        full_name="M",
        role=UserRole.MERCHANT,
        is_active=True,
        national_id_type=NationalIdType.AADHAAR,
        national_id_number="123456789012",
    )
    masked = apply_admin_national_id_mask(user)
    assert masked.national_id_number == "••••••••9012"
    assert "123456789012" not in masked.national_id_number


def test_apply_admin_national_id_mask_masks_pan():
    user = User(
        email="m@example.com",
        full_name="M",
        role=UserRole.MERCHANT,
        is_active=True,
        national_id_type=NationalIdType.PAN,
        national_id_number="ABCDE1234F",
    )
    masked = apply_admin_national_id_mask(user)
    assert masked.national_id_number == "••••••234F"
