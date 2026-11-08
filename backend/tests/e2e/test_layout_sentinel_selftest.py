"""S-125 — the layout sentinel must DETECT a broken page and PASS a clean one.

Runs on static HTML: no Compose stack, no E2E=1 (see `layout_selftest` marker and the
additive early-continue in `conftest.pytest_collection_modifyitems`).
Skips when Chromium is not installed, unless LAYOUT_SELFTEST_REQUIRE_BROWSER=1 (the workflow).
"""

from __future__ import annotations

import os
from pathlib import Path

import pytest
from playwright.sync_api import sync_playwright

from tests.e2e.layout_sentinel import WIDTHS, check_layout

pytestmark = pytest.mark.layout_selftest

FIXTURES = Path(__file__).resolve().parent / "fixtures"
ALL_RULES = {"horizontal-scroll", "overlap", "clipped-text", "offscreen-interactive"}


@pytest.fixture(scope="module")
def sentinel_page():
    # Own sync_playwright (not pytest-playwright's session-scoped `playwright`): that one keeps an
    # asyncio loop running for the rest of the pytest session and would break every async-fixture
    # test collected after this module in a default `pytest` run. This one is stopped at module end.
    with sync_playwright() as pw:
        try:
            browser = pw.chromium.launch()
        except Exception as exc:  # noqa: BLE001 - any launch failure means "no browser here"
            if os.environ.get("LAYOUT_SELFTEST_REQUIRE_BROWSER") == "1":
                raise
            pytest.skip(f"chromium not installed: run `playwright install chromium` ({exc.__class__.__name__})")
        context = browser.new_context(viewport={"width": 1000, "height": 700})
        page = context.new_page()
        yield page
        context.close()
        browser.close()


def test_sentinel_detects_all_four_defects(sentinel_page):
    sentinel_page.goto((FIXTURES / "layout_broken.html").as_uri())
    findings = check_layout(sentinel_page, label="broken-fixture")
    for width in WIDTHS:
        at_width = [f for f in findings if f["width"] == width]
        rules = {f["rule"] for f in at_width}
        assert ALL_RULES <= rules, f"@{width}px missing {ALL_RULES - rules}; got {sorted(rules)}"
        overlap = [f for f in at_width if f["rule"] == "overlap"]
        names = {overlap[0]["a"]["name"], overlap[0]["b"]["name"]}
        assert names == {"Overlap A", "Overlap B"}, names
    for f in findings:
        assert f["rule"] in ALL_RULES and f["url"].endswith("layout_broken.html")
        assert f["width"] in WIDTHS and f["a"]["path"]


def test_sentinel_clean_page_has_no_findings(sentinel_page):
    sentinel_page.goto((FIXTURES / "layout_clean.html").as_uri())
    assert check_layout(sentinel_page, label="clean-fixture") == []


def test_sentinel_restores_viewport(sentinel_page):
    sentinel_page.goto((FIXTURES / "layout_clean.html").as_uri())
    sentinel_page.set_viewport_size({"width": 913, "height": 611})
    check_layout(sentinel_page)
    assert sentinel_page.viewport_size == {"width": 913, "height": 611}
