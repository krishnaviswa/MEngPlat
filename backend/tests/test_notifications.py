"""Notification list/mark-read/mark-all-read route handlers.

Calls the route handlers directly with a fake db rather than going through
ASGI + a real database (none is reachable in this environment -- see
test_google_auth.py for the same constraint).
"""

import uuid
from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy.sql.dml import Update
from sqlalchemy.sql.elements import False_, True_

from app.models import Notification, NotificationType, User, UserRole
from app.routers import notifications as notifications_module


class FakeResult:
    def __init__(self, items):
        self._items = list(items)

    def scalars(self):
        return self

    def all(self):
        return self._items


def _clause_matches(obj, clause) -> bool:
    if hasattr(clause, "clauses"):
        return all(_clause_matches(obj, c) for c in clause.clauses)
    right = clause.right
    # is_read.is_(False) compiles to a right side of the False_/True_
    # singleton rather than a bound parameter with a `.value`.
    if isinstance(right, False_):
        expected = False
    elif isinstance(right, True_):
        expected = True
    else:
        expected = right.value
    return getattr(obj, clause.left.key, None) == expected


class FakeDB:
    def __init__(self, notifications: list[Notification]):
        self.notifications = list(notifications)
        self.executed_statements: list[object] = []

    async def get(self, model, id_):
        return next((n for n in self.notifications if n.id == id_), None)

    async def execute(self, stmt):
        self.executed_statements.append(stmt)
        # update(Notification).where(...).values(is_read=True) -- mark_all_read.
        if isinstance(stmt, Update):
            wc = stmt.whereclause
            targets = [n for n in self.notifications if wc is None or _clause_matches(n, wc)]
            for n in targets:
                n.is_read = True
            return None

        items = self.notifications
        wc = stmt.whereclause
        if wc is not None:
            items = [i for i in items if _clause_matches(i, wc)]
        return FakeResult(items)


def _make_user(role: UserRole = UserRole.CUSTOMER) -> User:
    return User(id=uuid.uuid4(), email="u@example.com", full_name="U", role=role, is_active=True)


def _make_notification(user_id, *, is_read: bool = False, created_at=None) -> Notification:
    return Notification(
        id=uuid.uuid4(),
        user_id=user_id,
        type=NotificationType.SYSTEM,
        title="Title",
        message="Message",
        is_read=is_read,
        created_at=created_at or datetime.now(timezone.utc),
    )


class TestListNotifications:
    async def test_scopes_to_current_user(self):
        user = _make_user()
        other = _make_user()
        mine = _make_notification(user.id)
        theirs = _make_notification(other.id)
        db = FakeDB(notifications=[mine, theirs])

        result = await notifications_module.list_notifications(unread_only=False, db=db, user=user)

        assert [n.id for n in result] == [mine.id]

    async def test_unread_only_filters_read_notifications(self):
        user = _make_user()
        unread = _make_notification(user.id, is_read=False)
        read = _make_notification(user.id, is_read=True)
        db = FakeDB(notifications=[unread, read])

        result = await notifications_module.list_notifications(unread_only=True, db=db, user=user)

        assert [n.id for n in result] == [unread.id]

    async def test_unread_only_false_returns_all(self):
        user = _make_user()
        unread = _make_notification(user.id, is_read=False)
        read = _make_notification(user.id, is_read=True)
        db = FakeDB(notifications=[unread, read])

        result = await notifications_module.list_notifications(unread_only=False, db=db, user=user)

        assert {n.id for n in result} == {unread.id, read.id}


class TestMarkRead:
    async def test_marks_owned_notification_read(self):
        user = _make_user()
        notification = _make_notification(user.id, is_read=False)
        db = FakeDB(notifications=[notification])

        await notifications_module.mark_read(notification.id, db=db, user=user)

        assert notification.is_read is True

    async def test_does_not_mark_another_users_notification(self):
        user = _make_user()
        other = _make_user()
        notification = _make_notification(other.id, is_read=False)
        db = FakeDB(notifications=[notification])

        await notifications_module.mark_read(notification.id, db=db, user=user)

        assert notification.is_read is False

    async def test_unknown_id_is_a_no_op_not_an_error(self):
        user = _make_user()
        db = FakeDB(notifications=[])

        result = await notifications_module.mark_read(uuid.uuid4(), db=db, user=user)

        assert result.message == "Notification marked as read"


class TestMarkAllRead:
    async def test_marks_all_of_current_users_notifications(self):
        user = _make_user()
        other = _make_user()
        mine_a = _make_notification(user.id, is_read=False)
        mine_b = _make_notification(user.id, is_read=False)
        theirs = _make_notification(other.id, is_read=False)
        db = FakeDB(notifications=[mine_a, mine_b, theirs])

        await notifications_module.mark_all_read(db=db, user=user)

        assert mine_a.is_read is True
        assert mine_b.is_read is True
        assert theirs.is_read is False
