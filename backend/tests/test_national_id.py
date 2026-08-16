from app.models import NationalIdType, User, UserRole
from app.services.national_id import has_national_id, mask_national_id_number, merchant_national_id_required


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


async def test_create_business_400_without_national_id():
    import pytest
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
            BusinessCreate(name="Shop", address="1 St", city="Chennai"),
            db=None,  # type: ignore[arg-type]
            user=user,
        )
    assert exc.value.status_code == 400
