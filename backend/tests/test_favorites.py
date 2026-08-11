"""Favorite create/delete route handlers (list_favorites is left to
test_s011_s016_batch.py's ASGI test since it needs a real join + selectinload
that this fake db doesn't model).

Calls the route handlers directly with a fake db rather than going through
ASGI + a real database (none is reachable in this environment -- see
test_google_auth.py for the same constraint).
"""

import uuid

import pytest
from fastapi import HTTPException

from app.models import Business, BusinessStatus, Favorite, User, UserRole
from app.routers import favorites as favorites_module
from app.schemas import FavoriteCreate


class FakeResult:
    def __init__(self, items):
        self._items = list(items)

    def scalar_one_or_none(self):
        return self._items[0] if self._items else None


def _clause_matches(obj, clause) -> bool:
    if hasattr(clause, "clauses"):
        return all(_clause_matches(obj, c) for c in clause.clauses)
    return getattr(obj, clause.left.key, None) == clause.right.value


class FakeDB:
    def __init__(self, *, businesses=None, favorites=None):
        self.businesses = list(businesses or [])
        self.favorites = list(favorites or [])
        self.added: list[object] = []
        self.deleted: list[object] = []

    async def get(self, model, id_):
        table = self.businesses if model is Business else self.favorites
        return next((o for o in table if o.id == id_), None)

    async def execute(self, stmt):
        items = [f for f in self.favorites]
        wc = stmt.whereclause
        if wc is not None:
            items = [i for i in items if _clause_matches(i, wc)]
        return FakeResult(items)

    def add(self, obj):
        self.added.append(obj)
        if isinstance(obj, Favorite):
            self.favorites.append(obj)

    async def delete(self, obj):
        self.deleted.append(obj)
        if obj in self.favorites:
            self.favorites.remove(obj)


def _make_user() -> User:
    return User(id=uuid.uuid4(), email="u@example.com", full_name="U", role=UserRole.CUSTOMER, is_active=True)


def _make_business(status: BusinessStatus = BusinessStatus.APPROVED) -> Business:
    return Business(
        id=uuid.uuid4(),
        merchant_id=uuid.uuid4(),
        name="Test Biz",
        slug="test-biz",
        address="1 Main St",
        city="Metropolis",
        status=status,
    )


class TestCreateFavorite:
    async def test_favoriting_approved_business_creates_favorite(self):
        user = _make_user()
        business = _make_business(BusinessStatus.APPROVED)
        db = FakeDB(businesses=[business])

        result = await favorites_module.create_favorite(FavoriteCreate(business_id=business.id), db=db, user=user)

        assert result.favorited is True
        assert result.business_id == business.id
        assert len(db.added) == 1
        assert db.added[0].user_id == user.id
        assert db.added[0].business_id == business.id

    async def test_favoriting_twice_is_idempotent(self):
        user = _make_user()
        business = _make_business(BusinessStatus.APPROVED)
        existing = Favorite(id=uuid.uuid4(), user_id=user.id, business_id=business.id)
        db = FakeDB(businesses=[business], favorites=[existing])

        result = await favorites_module.create_favorite(FavoriteCreate(business_id=business.id), db=db, user=user)

        assert result.favorited is True
        assert db.added == []

    async def test_favoriting_missing_business_returns_404(self):
        user = _make_user()
        db = FakeDB(businesses=[])

        with pytest.raises(HTTPException) as exc_info:
            await favorites_module.create_favorite(FavoriteCreate(business_id=uuid.uuid4()), db=db, user=user)

        assert exc_info.value.status_code == 404
        assert db.added == []

    async def test_favoriting_unapproved_business_returns_404(self):
        user = _make_user()
        business = _make_business(BusinessStatus.PENDING)
        db = FakeDB(businesses=[business])

        with pytest.raises(HTTPException) as exc_info:
            await favorites_module.create_favorite(FavoriteCreate(business_id=business.id), db=db, user=user)

        assert exc_info.value.status_code == 404
        assert db.added == []


class TestDeleteFavorite:
    async def test_deletes_existing_favorite(self):
        user = _make_user()
        business_id = uuid.uuid4()
        existing = Favorite(id=uuid.uuid4(), user_id=user.id, business_id=business_id)
        db = FakeDB(favorites=[existing])

        await favorites_module.delete_favorite(business_id, db=db, user=user)

        assert db.deleted == [existing]
        assert existing not in db.favorites

    async def test_deleting_nonexistent_favorite_is_a_no_op(self):
        user = _make_user()
        db = FakeDB(favorites=[])

        await favorites_module.delete_favorite(uuid.uuid4(), db=db, user=user)

        assert db.deleted == []

    async def test_does_not_delete_another_users_favorite(self):
        user = _make_user()
        other = _make_user()
        business_id = uuid.uuid4()
        theirs = Favorite(id=uuid.uuid4(), user_id=other.id, business_id=business_id)
        db = FakeDB(favorites=[theirs])

        await favorites_module.delete_favorite(business_id, db=db, user=user)

        assert db.deleted == []
        assert theirs in db.favorites
