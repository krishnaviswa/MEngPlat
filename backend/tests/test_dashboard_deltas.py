"""S-037 previous-window fields that do not need a live database."""

import uuid
from datetime import timedelta
from unittest.mock import AsyncMock, MagicMock

import pytest

from app.services.merchant_dashboard import _range_cutoff, _range_kpis


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
    row = MagicMock(
        count_in_range=4, r1=0, r2=0, r3=0, r4=2, r5=2, replied=1,
    )
    db = MagicMock()
    db.execute = AsyncMock(return_value=MagicMock(one=MagicMock(return_value=row)))
    kpis = await _range_kpis(db, uuid.uuid4(), "all")
    assert kpis["review_count_previous"] is None
    assert kpis["reply_rate_previous"] is None
    assert kpis["reply_rate"] == 0.25
    db.execute.assert_awaited_once()
