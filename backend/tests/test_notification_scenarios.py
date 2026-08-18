"""S-065: one in-app notice per workflow scenario (balanced 1:1 with the README table).

Uses an in-memory session stand-in — same constraint as test_notifications.py.
Does not touch businesses, photos, or addresses.
"""

from __future__ import annotations

import uuid

import pytest

from app.models import Notification, NotificationType
from app.services.notifications import (
    SCENARIO_LISTING_APPROVED,
    SCENARIO_NEW_REVIEW,
    SCENARIO_PAYMENT_BOOST_APPROVED,
    SCENARIO_PAYMENT_CAPTURED,
    SCENARIO_WHATSAPP_APPLIED,
    SCENARIO_WHATSAPP_REJECTED,
    SCENARIOS,
    upsert_notice,
)


class FakeResult:
    def __init__(self, item):
        self._item = item

    def scalar_one_or_none(self):
        return self._item


class FakeDB:
    def __init__(self):
        self.notifications: list[Notification] = []
        self.added: list[object] = []

    async def execute(self, stmt):
        items = list(self.notifications)
        wc = stmt.whereclause
        if wc is not None:
            items = [n for n in items if _matches(n, wc)]
        return FakeResult(items[0] if items else None)

    def add(self, obj):
        self.added.append(obj)
        if isinstance(obj, Notification):
            self.notifications.append(obj)


def _matches(obj: Notification, clause) -> bool:
    if hasattr(clause, "clauses"):
        return all(_matches(obj, c) for c in clause.clauses)
    expected = clause.right.value
    return getattr(obj, clause.left.key, None) == expected


def _user_id():
    return uuid.uuid4()


SCENARIO_CASES = (
    (
        SCENARIO_LISTING_APPROVED,
        NotificationType.APPROVAL,
        "Listing approved",
        "Cafe A is live",
        "Cafe A is still live",
    ),
    (
        SCENARIO_NEW_REVIEW,
        NotificationType.REVIEW,
        "New review received",
        "New 5-star review on Cafe A",
        "New 3-star review on Cafe A",
    ),
    (
        SCENARIO_WHATSAPP_APPLIED,
        NotificationType.APPROVAL,
        "WhatsApp update applied",
        "WhatsApp suggestion for Cafe A is live",
        "Later WhatsApp suggestion for Cafe A is live",
    ),
    (
        SCENARIO_WHATSAPP_REJECTED,
        NotificationType.SYSTEM,
        "WhatsApp suggestion not applied",
        "Suggestion for Cafe A was not applied",
        "A later suggestion for Cafe A was not applied",
    ),
    (
        SCENARIO_PAYMENT_CAPTURED,
        NotificationType.SYSTEM,
        "Featured payment received",
        "Payment for Cafe A is recorded",
        "A newer payment for Cafe A is recorded",
    ),
    (
        SCENARIO_PAYMENT_BOOST_APPROVED,
        NotificationType.SYSTEM,
        "Featured boost is live",
        "Boost for Cafe A is on",
        "Boost for Cafe A is on again",
    ),
)


@pytest.mark.parametrize(
    "scenario,ntype,title,first_msg,second_msg",
    SCENARIO_CASES,
    ids=list(SCENARIOS),
)
async def test_one_notice_per_scenario_updates_in_place(scenario, ntype, title, first_msg, second_msg):
    """One row per scenario: a second event refreshes copy, does not insert another."""
    db = FakeDB()
    user_id = _user_id()
    first = await upsert_notice(
        db, user_id=user_id, scenario=scenario, ntype=ntype, title=title, message=first_msg
    )
    second = await upsert_notice(
        db, user_id=user_id, scenario=scenario, ntype=ntype, title=title, message=second_msg
    )
    rows = [n for n in db.notifications if n.scenario == scenario]
    assert len(rows) == 1
    assert first is second
    assert rows[0].message == second_msg
    assert rows[0].is_read is False


async def test_different_scenarios_coexist_for_the_same_user():
    db = FakeDB()
    user_id = _user_id()
    for scenario, ntype, title, first_msg, _second in SCENARIO_CASES:
        await upsert_notice(
            db, user_id=user_id, scenario=scenario, ntype=ntype, title=title, message=first_msg
        )
    assert {n.scenario for n in db.notifications} == set(SCENARIOS)
    assert len(db.notifications) == len(SCENARIOS)


async def test_same_scenario_does_not_cross_users():
    db = FakeDB()
    a, b = _user_id(), _user_id()
    await upsert_notice(
        db,
        user_id=a,
        scenario=SCENARIO_NEW_REVIEW,
        ntype=NotificationType.REVIEW,
        title="New review received",
        message="A",
    )
    await upsert_notice(
        db,
        user_id=b,
        scenario=SCENARIO_NEW_REVIEW,
        ntype=NotificationType.REVIEW,
        title="New review received",
        message="B",
    )
    assert len(db.notifications) == 2
