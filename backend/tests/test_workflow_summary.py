"""S-125 — unit tests for the workflow job-summary classifier (no browser, no stack)."""

from __future__ import annotations

from types import SimpleNamespace

from tests.e2e.chains.summary import FAIL, KNOWN_GAP, PASS, SKIPPED, XPASS_MESSAGE, WorkflowSummary


def rep(when="call", *, passed=False, failed=False, skipped=False, wasxfail=None, longrepr=None, flips=0):
    r = SimpleNamespace(when=when, passed=passed, failed=failed, skipped=skipped, longrepr=longrepr)
    if wasxfail is not None:
        r.wasxfail = wasxfail
    if flips:
        r.wf_layout_flip = flips
    return r


def test_pass():
    s = WorkflowSummary()
    s.add_report("wf-a", "test_wf_a", rep(passed=True))
    assert s.chain_status("wf-a") == (PASS, "")


def test_functional_failure_uses_first_error_line():
    s = WorkflowSummary()
    s.add_report("wf-a", "test_wf_a", rep(failed=True, longrepr="trace\nE   AssertionError: boom\nmore"))
    status, reason = s.chain_status("wf-a")
    assert status == FAIL and "boom" in reason


def test_layout_flip_reason():
    s = WorkflowSummary()
    s.add_report("wf-a", "test_wf_a", rep(failed=True, longrepr="x", flips=3))
    assert s.chain_status("wf-a") == (FAIL, "functional steps passed; 3 layout finding(s)")


def test_known_gap_when_main_passes_and_gap_xfails():
    s = WorkflowSummary()
    s.add_report("wf-r", "test_wf_r", rep(passed=True))
    s.add_report("wf-r", "test_wf_r_gap", rep(skipped=True, wasxfail="customer is not notified"))
    assert s.chain_status("wf-r") == (KNOWN_GAP, "customer is not notified")


def test_strict_xpass_is_a_failure_with_the_removal_message():
    s = WorkflowSummary()
    s.add_report("wf-r", "test_wf_r", rep(passed=True))
    s.add_report("wf-r", "test_wf_r_gap", rep(failed=True, longrepr="[XPASS(strict)] customer is not notified"))
    assert s.chain_status("wf-r") == (FAIL, XPASS_MESSAGE)


def test_skipped_main_makes_the_chain_skipped():
    s = WorkflowSummary()
    s.add_report("wf-w", "test_wf_w", rep(skipped=True, longrepr=("f.py", 1, "Skipped: no drafts")))
    assert s.chain_status("wf-w") == (SKIPPED, "no drafts")


def test_setup_error_is_a_failure():
    s = WorkflowSummary()
    s.add_report("wf-a", "test_wf_a", rep(when="setup", failed=True, longrepr="E   RuntimeError: login failed"))
    status, reason = s.chain_status("wf-a")
    assert status == FAIL and reason.startswith("error:")


def test_render_has_table_and_layout_section():
    s = WorkflowSummary()
    s.add_report("wf-a", "test_wf_a", rep(passed=True))
    out = s.render()
    assert "| `wf-a` | **PASS** |" in out and "No layout findings." in out
    s.add_findings("wf-a", [{"rule": "overlap", "url": "/x", "width": 375, "detail": "A overlaps B", "label": "p"}])
    assert "A overlaps B" in s.render() and "375px" in s.render()
