"""Unit tests for SEED_MODE gate (Phase 2) — no DB required."""

from scripts.seed import should_run_seed


def test_seed_mode_off_skips():
    run, reason = should_run_seed("off", has_current_version=False, approved_business_count=0)
    assert run is False
    assert "off" in reason


def test_seed_mode_force_always_runs():
    run, reason = should_run_seed("force", has_current_version=True, approved_business_count=99)
    assert run is True
    assert "force" in reason


def test_seed_mode_if_empty_skips_when_businesses_exist():
    run, reason = should_run_seed("if_empty", has_current_version=False, approved_business_count=3)
    assert run is False
    assert "if_empty" in reason


def test_seed_mode_if_empty_runs_when_catalog_empty():
    run, _ = should_run_seed("if_empty", has_current_version=False, approved_business_count=0)
    assert run is True


def test_seed_mode_if_outdated_skips_when_marker_present():
    run, reason = should_run_seed("if_outdated", has_current_version=True, approved_business_count=0)
    assert run is False
    assert "already applied" in reason


def test_seed_mode_if_outdated_runs_when_marker_missing():
    run, _ = should_run_seed("if_outdated", has_current_version=False, approved_business_count=10)
    assert run is True


def test_unknown_seed_mode_treated_as_off():
    run, reason = should_run_seed("weird", has_current_version=False, approved_business_count=0)
    assert run is False
    assert "Unknown" in reason
