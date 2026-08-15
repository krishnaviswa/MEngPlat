"""S-038 directory medians + dashboard ownership helper (no live DB)."""

import uuid

import pytest
from fastapi import HTTPException

from app.models import Business, BusinessStatus, Merchant, User, UserRole
from app.routers.dashboard import _load_owned_business, merchant_benchmark
from app.services.benchmark import DISCLAIMER, _median_or_none


class FakeResult:
    def __init__(self, items):
        self._items = list(items)

    def scalar_one_or_none(self):
        return self._items[0] if self._items else None


class FakeDB:
    def __init__(self, *, businesses=None, merchants=None):
        self.businesses = list(businesses or [])
        self.merchants = list(merchants or [])

    async def get(self, model, id_, options=None):
        table = self.businesses if model is Business else []
        return next((o for o in table if o.id == id_), None)

    async def execute(self, stmt):
        items = list(self.merchants)
        wc = stmt.whereclause
        if wc is not None and hasattr(wc, "right"):
            items = [m for m in items if m.user_id == wc.right.value]
        return FakeResult(items)


def _business(**overrides) -> Business:
    defaults = dict(
        id=uuid.uuid4(),
        merchant_id=uuid.uuid4(),
        name="Peer Cafe",
        slug="peer-cafe",
        address="1 Main",
        city="Chennai",
        status=BusinessStatus.APPROVED,
        average_rating=4.2,
    )
    defaults.update(overrides)
    return Business(**defaults)


def test_median_none_below_three():
    assert _median_or_none([4.0, 5.0]) is None


def test_median_none_empty():
    assert _median_or_none([]) is None


def test_median_of_three():
    assert _median_or_none([3.0, 4.0, 5.0]) == 4.0


def test_median_of_four_is_midpoint():
    assert _median_or_none([1.0, 2.0, 3.0, 4.0]) == 2.5


def test_disclaimer_is_directory_medians_not_ai_judgment():
    assert DISCLAIMER == "Directory medians from MerchantHub listings — not an AI judgment."
    assert "AI judgment" in DISCLAIMER
    assert "Directory medians" in DISCLAIMER


@pytest.mark.asyncio
async def test_load_owned_business_403_for_other_merchant():
    business = _business()
    other = User(id=uuid.uuid4(), email="o@example.com", full_name="O", role=UserRole.MERCHANT, is_active=True)
    other_merchant = Merchant(id=uuid.uuid4(), user_id=other.id)
    db = FakeDB(businesses=[business], merchants=[other_merchant])

    with pytest.raises(HTTPException) as exc:
        await _load_owned_business(db, business.id, other)
    assert exc.value.status_code == 403


@pytest.mark.asyncio
async def test_load_owned_business_404_missing():
    owner = User(id=uuid.uuid4(), email="m@example.com", full_name="M", role=UserRole.MERCHANT, is_active=True)
    db = FakeDB(businesses=[], merchants=[Merchant(id=uuid.uuid4(), user_id=owner.id)])

    with pytest.raises(HTTPException) as exc:
        await _load_owned_business(db, uuid.uuid4(), owner)
    assert exc.value.status_code == 404


@pytest.mark.asyncio
async def test_merchant_benchmark_returns_payload_and_disclaimer(monkeypatch):
    business = _business()
    owner = User(id=uuid.uuid4(), email="m@example.com", full_name="M", role=UserRole.MERCHANT, is_active=True)
    db = FakeDB(
        businesses=[business],
        merchants=[Merchant(id=business.merchant_id, user_id=owner.id)],
    )

    async def fake_get(_db, biz):
        return {
            "business_id": biz.id,
            "own_rating": biz.average_rating,
            "category_median": 4.1,
            "city_median": None,
            "category_sample_size": 4,
            "city_sample_size": 1,
            "disclaimer": DISCLAIMER,
        }

    monkeypatch.setattr("app.routers.dashboard.benchmark_service.get_benchmark", fake_get)
    result = await merchant_benchmark(business.id, db, owner)
    assert result.own_rating == business.average_rating
    assert result.category_median == 4.1
    assert result.city_median is None
    assert result.disclaimer == DISCLAIMER
