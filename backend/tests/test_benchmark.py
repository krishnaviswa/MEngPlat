from app.services.benchmark import _median_or_none


def test_median_none_below_three():
    assert _median_or_none([4.0, 5.0]) is None


def test_median_of_three():
    assert _median_or_none([3.0, 4.0, 5.0]) == 4.0
