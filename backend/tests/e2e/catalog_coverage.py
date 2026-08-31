"""S-124 AC9 — session-teardown guard: every catalogued form must be exercised."""

from __future__ import annotations

from tests.e2e.form_data import all_form_keys

# Mutated by journeys via the `record_form` fixture.
EXERCISED: set[str] = set()


def record(key: str) -> None:
    EXERCISED.add(key)


def assert_every_form_exercised() -> None:
    missing = all_form_keys() - EXERCISED
    if missing:
        raise AssertionError(
            "S-124 catalogue coverage gap — these FormSpec keys were never exercised "
            f"by a journey (route added but not wired in?): {sorted(missing)}"
        )
