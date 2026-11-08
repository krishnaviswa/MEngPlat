"""S-126: customer notices (review reply, moderation, shop details edited).

In-memory session stand-in (same approach as test_notification_scenarios.py): the rules in
`app/services/customer_notices.py` take plain attribute objects, so no database is needed.
"""

from __future__ import annotations

import uuid
from types import SimpleNamespace

import pytest

from app.models import BusinessStatus, Notification, NotificationType, ReviewStatus
from app.services import customer_notices as cn
from app.services.notifications import (
    CUSTOMER_SCENARIOS,
    SCENARIO_REVIEW_MODERATION,
    SCENARIO_REVIEW_REPLY,
    SCENARIO_SHOP_DETAILS_UPDATED,
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

    async def execute(self, stmt):
        items = list(self.notifications)
        wc = stmt.whereclause
        if wc is not None:
            items = [n for n in items if _matches(n, wc)]
        return FakeResult(items[0] if items else None)

    def add(self, obj):
        if isinstance(obj, Notification):
            self.notifications.append(obj)

    def rows(self, user_id, scenario=None):
        return [n for n in self.notifications if n.user_id == user_id and (scenario is None or n.scenario == scenario)]


def _matches(obj, clause) -> bool:
    if hasattr(clause, "clauses"):
        return all(_matches(obj, c) for c in clause.clauses)
    return getattr(obj, clause.left.key, None) == clause.right.value


def make_business(**over):
    base = dict(
        id=uuid.uuid4(),
        name="Cafe A",
        status=BusinessStatus.APPROVED,
        description="Good coffee",
        phone="+919876500001",
        business_hours={"mon": "9-5"},
        address="14 Marina Loop",
        city="Chennai",
        state="TN",
        postal_code="600001",
        country="IN",
        website=None,
        email="a@example.com",
    )
    base.update(over)
    return SimpleNamespace(**base)


def make_review(business=None, **over):
    base = dict(
        id=uuid.uuid4(),
        author_id=uuid.uuid4(),
        business_id=(business.id if business else uuid.uuid4()),
        status=ReviewStatus.ACTIVE,
        source="organic",
    )
    base.update(over)
    return SimpleNamespace(**base)


MERCHANT = uuid.uuid4()
ADMIN = uuid.uuid4()


# --- upsert keying (AC 14, 16, 17) ---------------------------------------------------------------


async def test_upsert_without_key_is_legacy_behaviour():
    db, uid = FakeDB(), uuid.uuid4()
    for msg in ("one", "two"):
        await upsert_notice(db, user_id=uid, scenario="new_review", ntype=NotificationType.REVIEW, title="t", message=msg)
    assert len(db.notifications) == 1
    assert db.notifications[0].message == "two"
    assert db.notifications[0].dedupe_key == ""


async def test_upsert_keyed_rows_do_not_overwrite_each_other():
    db, uid = FakeDB(), uuid.uuid4()
    for key in ("shop-a", "shop-b"):
        await upsert_notice(
            db, user_id=uid, scenario="x", ntype=NotificationType.SYSTEM, title="t", message=key, dedupe_key=key
        )
    assert {n.dedupe_key for n in db.notifications} == {"shop-a", "shop-b"}


async def test_upsert_same_key_refreshes_and_marks_unread():
    db, uid = FakeDB(), uuid.uuid4()
    await upsert_notice(db, user_id=uid, scenario="x", ntype=NotificationType.SYSTEM, title="t", message="a", dedupe_key="k")
    db.notifications[0].is_read = True
    await upsert_notice(db, user_id=uid, scenario="x", ntype=NotificationType.SYSTEM, title="t", message="b", dedupe_key="k")
    assert len(db.notifications) == 1
    assert db.notifications[0].message == "b" and db.notifications[0].is_read is False


def test_notification_unique_constraint_columns():
    constraint = next(c for c in Notification.__table__.constraints if c.name == "uq_user_notification_scenario_key")
    assert [c.name for c in constraint.columns] == ["user_id", "scenario", "dedupe_key"]


def test_customer_scenarios_are_separate_from_merchant_scenarios():
    assert set(CUSTOMER_SCENARIOS).isdisjoint(SCENARIOS)
    assert len(SCENARIOS) == 6


# --- normalisers ----------------------------------------------------------------------------------


def test_normalise_text():
    assert cn.normalise_text("  Good   coffee\n") == "Good coffee"
    assert cn.normalise_text(None) == "" == cn.normalise_text("")
    assert cn.normalise_text("Good") != cn.normalise_text("good")  # case-sensitive


def test_normalise_phone():
    assert cn.normalise_phone("+91 98765-43210") == "+919876543210"
    assert cn.normalise_phone(None) == ""
    assert cn.normalise_phone("98765 43210") == "9876543210"


def test_normalise_hours():
    assert cn.normalise_hours(None) == {} == cn.normalise_hours({})
    assert cn.normalise_hours({"Mon": " 9-5 ", "tue": ""}) == cn.normalise_hours({"mon": "9-5"})
    assert cn.normalise_hours({"mon": "9-5"}) != cn.normalise_hours({"mon": "10-5"})


# --- reply (AC 1, 2, 3, 13) -----------------------------------------------------------------------


async def test_reply_first_notifies_author_only():
    db, biz = FakeDB(), make_business()
    review = make_review(biz)
    assert await cn.notify_review_reply(db, review=review, business=biz, actor_id=MERCHANT, previous_body=None, new_body="Thanks!")
    assert [n.user_id for n in db.notifications] == [review.author_id]
    n = db.notifications[0]
    assert (n.scenario, n.type, n.title, n.dedupe_key) == (
        SCENARIO_REVIEW_REPLY, NotificationType.REPLY, "Reply to your review", str(review.id)
    )
    assert n.message == "Cafe A replied to your review."


async def test_reply_edit_different_text_refreshes_same_row():
    db, biz = FakeDB(), make_business()
    review = make_review(biz)
    await cn.notify_review_reply(db, review=review, business=biz, actor_id=MERCHANT, previous_body=None, new_body="one")
    db.notifications[0].is_read = True
    assert await cn.notify_review_reply(db, review=review, business=biz, actor_id=MERCHANT, previous_body="one", new_body="two")
    assert len(db.notifications) == 1 and db.notifications[0].is_read is False


@pytest.mark.parametrize("new", ["one", "  one  ", "o ne".replace("o ne", "one")])
async def test_reply_edit_same_text_is_noop(new):
    db, biz = FakeDB(), make_business()
    review = make_review(biz)
    assert not await cn.notify_review_reply(db, review=review, business=biz, actor_id=MERCHANT, previous_body="one", new_body=new)
    assert db.notifications == []


@pytest.mark.parametrize("status", [ReviewStatus.HIDDEN, ReviewStatus.REMOVED, ReviewStatus.REPORTED])
async def test_reply_on_non_active_review_sends_nothing(status):
    db, biz = FakeDB(), make_business()
    review = make_review(biz, status=status)
    assert not await cn.notify_review_reply(db, review=review, business=biz, actor_id=MERCHANT, previous_body=None, new_body="x")
    assert db.notifications == []


async def test_reply_actor_is_author_sends_nothing():
    db, biz = FakeDB(), make_business()
    review = make_review(biz)
    assert not await cn.notify_review_reply(db, review=review, business=biz, actor_id=review.author_id, previous_body=None, new_body="x")


async def test_reply_partner_review_sends_nothing():
    db, biz = FakeDB(), make_business()
    review = make_review(biz, source="partner")
    assert not await cn.notify_review_reply(db, review=review, business=biz, actor_id=MERCHANT, previous_body=None, new_body="x")


# --- moderation (AC 4, 5, 6, 13, 15) --------------------------------------------------------------


@pytest.mark.parametrize(
    ("action", "after", "title"),
    [
        ("hide", ReviewStatus.HIDDEN, "Your review was hidden"),
        ("remove", ReviewStatus.REMOVED, "Your review was removed"),
    ],
)
async def test_moderate_hide_and_remove_notify_author(action, after, title):
    db, biz = FakeDB(), make_business()
    review = make_review(biz, status=after)  # status already updated by the router
    assert await cn.notify_review_moderation(
        db, review=review, business=biz, admin_id=ADMIN, previous_status=ReviewStatus.ACTIVE, action=action
    )
    n = db.notifications[0]
    assert (n.scenario, n.type, n.title) == (SCENARIO_REVIEW_MODERATION, NotificationType.MODERATION, title)
    assert "Cafe A" in n.message and n.extra_data["action"] == action


async def test_moderate_restore_replaces_hide_notice():
    db, biz = FakeDB(), make_business()
    review = make_review(biz, status=ReviewStatus.HIDDEN)
    await cn.notify_review_moderation(db, review=review, business=biz, admin_id=ADMIN, previous_status=ReviewStatus.ACTIVE, action="hide")
    review.status = ReviewStatus.ACTIVE
    assert await cn.notify_review_moderation(
        db, review=review, business=biz, admin_id=ADMIN, previous_status=ReviewStatus.HIDDEN, action="restore"
    )
    assert len(db.notifications) == 1
    assert db.notifications[0].title == "Your review is visible again"


@pytest.mark.parametrize("previous", [ReviewStatus.ACTIVE, ReviewStatus.REPORTED])
async def test_moderate_restore_of_active_or_reported_sends_nothing(previous):
    db, biz = FakeDB(), make_business()
    review = make_review(biz, status=ReviewStatus.ACTIVE)
    assert not await cn.notify_review_moderation(
        db, review=review, business=biz, admin_id=ADMIN, previous_status=previous, action="restore"
    )
    assert db.notifications == []


async def test_moderate_repeat_action_sends_nothing():
    db, biz = FakeDB(), make_business()
    review = make_review(biz, status=ReviewStatus.HIDDEN)
    assert not await cn.notify_review_moderation(
        db, review=review, business=biz, admin_id=ADMIN, previous_status=ReviewStatus.HIDDEN, action="hide"
    )


async def test_moderate_own_review_by_admin_sends_nothing():
    db, biz = FakeDB(), make_business()
    review = make_review(biz, status=ReviewStatus.HIDDEN)
    assert not await cn.notify_review_moderation(
        db, review=review, business=biz, admin_id=review.author_id, previous_status=ReviewStatus.ACTIVE, action="hide"
    )


async def test_moderate_without_business_or_partner_sends_nothing():
    db, biz = FakeDB(), make_business()
    review = make_review(biz, status=ReviewStatus.HIDDEN)
    assert not await cn.notify_review_moderation(db, review=review, business=None, admin_id=ADMIN, previous_status=ReviewStatus.ACTIVE, action="hide")
    partner = make_review(biz, status=ReviewStatus.HIDDEN, source="partner")
    assert not await cn.notify_review_moderation(db, review=partner, business=biz, admin_id=ADMIN, previous_status=ReviewStatus.ACTIVE, action="hide")


async def test_reply_and_moderation_for_same_review_coexist():
    db, biz = FakeDB(), make_business()
    review = make_review(biz, status=ReviewStatus.ACTIVE)
    await cn.notify_review_reply(db, review=review, business=biz, actor_id=MERCHANT, previous_body=None, new_body="x")
    review.status = ReviewStatus.HIDDEN
    await cn.notify_review_moderation(db, review=review, business=biz, admin_id=ADMIN, previous_status=ReviewStatus.ACTIVE, action="hide")
    assert {n.scenario for n in db.rows(review.author_id)} == {SCENARIO_REVIEW_REPLY, SCENARIO_REVIEW_MODERATION}


# --- shop edit (AC 8-11, 13, 14) ------------------------------------------------------------------


@pytest.fixture
def reviewers(monkeypatch):
    ids = [uuid.uuid4() for _ in range(3)]

    async def fake(db, business_id, exclude_user_id, limit):
        return [i for i in ids if i != exclude_user_id][:limit]

    monkeypatch.setattr(cn, "_active_reviewer_ids", fake)
    return ids


@pytest.mark.parametrize(
    ("field", "value", "group"),
    [
        ("description", "Brand new description", "description"),
        ("phone", "+919000000000", "phone"),
        ("business_hours", {"mon": "10-6"}, "hours"),
        ("city", "Madurai", "address"),
    ],
)
async def test_shop_edit_notifies_active_reviewers_only(reviewers, field, value, group):
    db, biz = FakeDB(), make_business()
    before = cn.snapshot_shop_details(biz)
    setattr(biz, field, value)
    sent = await cn.notify_shop_details_changed(db, business=biz, before=before, actor_id=MERCHANT)
    assert sent == len(reviewers) == len(db.notifications)
    n = db.notifications[0]
    assert (n.scenario, n.type, n.title, n.dedupe_key) == (
        SCENARIO_SHOP_DETAILS_UPDATED, NotificationType.SYSTEM, "Shop details updated", str(biz.id)
    )
    assert n.extra_data["changed"] == [group]


@pytest.mark.parametrize(
    ("field", "value"),
    [("name", "Renamed"), ("website", "https://x.example"), ("email", "z@example.com")],
)
async def test_shop_edit_ignored_fields_notify_nobody(reviewers, field, value):
    db, biz = FakeDB(), make_business()
    before = cn.snapshot_shop_details(biz)
    setattr(biz, field, value)
    assert await cn.notify_shop_details_changed(db, business=biz, before=before, actor_id=MERCHANT) == 0
    assert db.notifications == []


async def test_shop_edit_noop_and_cosmetic_whitespace_notifies_nobody(reviewers):
    db, biz = FakeDB(), make_business()
    before = cn.snapshot_shop_details(biz)
    biz.description = "  Good   coffee "
    biz.phone = "+91 98765 00001"
    biz.city = " chennai "
    assert await cn.notify_shop_details_changed(db, business=biz, before=before, actor_id=MERCHANT) == 0


async def test_shop_edit_repeated_keeps_one_row_per_shop(reviewers):
    db, biz = FakeDB(), make_business()
    for text in ("v2", "v3"):
        before = cn.snapshot_shop_details(biz)
        biz.description = text
        await cn.notify_shop_details_changed(db, business=biz, before=before, actor_id=MERCHANT)
    assert len(db.notifications) == len(reviewers)


async def test_shop_edit_two_shops_keep_two_rows(reviewers):
    db = FakeDB()
    for _ in range(2):
        biz = make_business()
        before = cn.snapshot_shop_details(biz)
        biz.description = "changed"
        await cn.notify_shop_details_changed(db, business=biz, before=before, actor_id=MERCHANT)
    assert len(db.rows(reviewers[0], SCENARIO_SHOP_DETAILS_UPDATED)) == 2


@pytest.mark.parametrize("status", [BusinessStatus.PENDING, BusinessStatus.REJECTED])
async def test_shop_edit_pending_business_notifies_nobody(reviewers, status):
    db, biz = FakeDB(), make_business(status=status)
    before = cn.snapshot_shop_details(biz)
    biz.description = "changed"
    assert await cn.notify_shop_details_changed(db, business=biz, before=before, actor_id=MERCHANT) == 0


async def test_shop_edit_excludes_actor(reviewers):
    db, biz = FakeDB(), make_business()
    before = cn.snapshot_shop_details(biz)
    biz.description = "changed"
    await cn.notify_shop_details_changed(db, business=biz, before=before, actor_id=reviewers[0])
    assert reviewers[0] not in {n.user_id for n in db.notifications}


async def test_shop_edit_fanout_is_capped_at_200(monkeypatch):
    many = [uuid.uuid4() for _ in range(cn.MAX_SHOP_EDIT_FANOUT + 50)]

    async def fake(db, business_id, exclude_user_id, limit):
        return many[:limit]

    monkeypatch.setattr(cn, "_active_reviewer_ids", fake)
    db, biz = FakeDB(), make_business()
    before = cn.snapshot_shop_details(biz)
    biz.description = "changed"
    sent = await cn.notify_shop_details_changed(db, business=biz, before=before, actor_id=MERCHANT)
    assert sent == cn.MAX_SHOP_EDIT_FANOUT == len(db.notifications)


# --- privacy (AC 12) ------------------------------------------------------------------------------


async def test_notice_payload_has_no_foreign_pii(reviewers):
    db, biz = FakeDB(), make_business()
    review = make_review(biz)
    await cn.notify_review_reply(db, review=review, business=biz, actor_id=MERCHANT, previous_body=None, new_body="secret reply text")
    before = cn.snapshot_shop_details(biz)
    biz.phone = "+919111111111"
    await cn.notify_shop_details_changed(db, business=biz, before=before, actor_id=MERCHANT)
    for n in db.notifications:
        blob = f"{n.title} {n.message} {n.extra_data}"
        assert "secret reply text" not in blob and "+919111111111" not in blob and "a@example.com" not in blob
        assert set(n.extra_data) <= {"scenario", "review_id", "business_id", "action", "changed"}
