"""S-037 previous-window fields that do not need a live database."""

import uuid
from datetime import timedelta
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.services.merchant_dashboard import _count_reviews, _range_cutoff, _reply_rate_previous


def test_range_cutoff_all_is_none():
    assert _range_cutoff("all") is None


def test_range_cutoff_30_and_90_are_that_many_days_ago():
    cutoff_30 = _range_cutoff("30")
    cutoff_90 = _range_cutoff("90")
    assert cutoff_30 is not None and cutoff_90 is not None
    delta = cutoff_30 - cutoff_90
    assert timedelta(days=59) <= delta <= timedelta(days=61)


@pytest.mark.asyncio
async def test_previous_count_and_reply_rate_are_null_for_all_time():
    db = MagicMock()
    db.execute = AsyncMock()
    biz = uuid.uuid4()
    assert await _count_reviews(db, biz, "all", previous=True) is None
    assert await _reply_rate_previous(db, biz, "all") is None
    db.execute.assert_not_called()
