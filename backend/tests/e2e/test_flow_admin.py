"""Admin panel approve + hide reported review (TP-S-010)."""

from __future__ import annotations

from uuid import uuid4

import pytest
from playwright.sync_api import Page, expect

from tests.e2e.api_client import Api
from tests.e2e.pages.admin import AdminPage
from tests.e2e.pages.login import LoginPage

pytestmark = pytest.mark.e2e


def test_admin_full_journey(page: Page, api: Api) -> None:
    if not api.seed_admin_tokens():
        pytest.skip("Seeded admin@merchanthub.ai not available")

    merch_email = f"e2e-admin-m-{uuid4().hex[:10]}@example.com"
    api.register(merch_email, role="merchant", full_name="E2E Admin Merchant")
    merch = api.tokens(merch_email)
    pending_name = f"E2E Pending {uuid4().hex[:6]}"
    biz = api.create_business(merch.access_token, pending_name)

    cust_email = f"e2e-admin-c-{uuid4().hex[:10]}@example.com"
    api.register(cust_email, role="customer")
    cust = api.tokens(cust_email)
    listings = api.list_businesses()
    reported = False
    if listings:
        review = api.create_review(cust.access_token, listings[0].id, "Reportable e2e review body here.")
        report = api.post(
            f"reviews/{review.id}/report",
            token=cust.access_token,
            json={"reason": "This e2e report is spammy."},
        )
        assert report.status == 200, report.text()
        reported = True

    LoginPage(page).login("admin@merchanthub.ai", "admin12345ok")
    admin = AdminPage(page)
    admin.goto()
    admin.expect_loaded()
    platform = api.get(
        "dashboard/admin/platform",
        token=page.evaluate("() => localStorage.getItem('access_token')"),
    )
    assert platform.status == 200

    admin.approve_named(pending_name)
    if reported:
        hide_buttons = page.get_by_role("button", name="Hide")
        before = hide_buttons.count()
        admin.hide_first_reported()
        expect(hide_buttons).to_have_count(max(before - 1, 0), timeout=15_000)

    forbidden = api.get("businesses?status_filter=pending", token=cust.access_token)
    assert forbidden.status == 403
