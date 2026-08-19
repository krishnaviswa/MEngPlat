"""S-081: category search via GET /businesses/categories/all?q=.

Router-level unit test against a FakeDB (no live Postgres in this sandbox),
following test_businesses_cache_invalidation.py's convention. Supports the
`ilike` clause `list_categories` now builds when `q` is passed.
"""

import uuid

from sqlalchemy.sql import operators

from app.models import Category
from app.routers import businesses as businesses_module


class FakeResult:
    def __init__(self, items):
        self._items = list(items)

    def scalars(self):
        return self

    def all(self):
        return self._items


def _clause_matches(obj, clause) -> bool:
    if clause.operator is operators.ilike_op:
        pattern = clause.right.value.strip("%").lower()
        value = getattr(obj, clause.left.key, "") or ""
        return pattern in value.lower()
    return getattr(obj, clause.left.key, None) == clause.right.value


class FakeDB:
    def __init__(self, *, categories=None):
        self.categories = list(categories or [])

    async def execute(self, stmt):
        items = list(self.categories)
        wc = stmt.whereclause
        if wc is not None:
            items = [i for i in items if _clause_matches(i, wc)]
        return FakeResult(items)


def _make_category(**overrides) -> Category:
    defaults = dict(id=uuid.uuid4(), name="Bakery", slug="bakery")
    defaults.update(overrides)
    return Category(**defaults)


async def test_list_categories_without_q_returns_all():
    bakery = _make_category(name="Bakery", slug="bakery")
    cafe = _make_category(name="Cafe", slug="cafe")
    db = FakeDB(categories=[bakery, cafe])

    result = await businesses_module.list_categories(None, db)

    assert {c.name for c in result} == {"Bakery", "Cafe"}


async def test_list_categories_filters_by_case_insensitive_substring():
    bakery = _make_category(name="Bakery", slug="bakery")
    cafe = _make_category(name="Cafe", slug="cafe")
    db = FakeDB(categories=[bakery, cafe])

    result = await businesses_module.list_categories("bak", db)

    assert [c.name for c in result] == ["Bakery"]


async def test_list_categories_search_is_case_insensitive():
    bakery = _make_category(name="Bakery", slug="bakery")
    db = FakeDB(categories=[bakery])

    result = await businesses_module.list_categories("BAK", db)

    assert [c.name for c in result] == ["Bakery"]


async def test_list_categories_returns_empty_list_for_no_matches():
    bakery = _make_category(name="Bakery", slug="bakery")
    db = FakeDB(categories=[bakery])

    result = await businesses_module.list_categories("zzz", db)

    assert result == []
