"""wf-featured-boost — merchant starts checkout -> payment captured -> admin approves -> merchant told twice."""

from __future__ import annotations

import pytest
from playwright.sync_api import expect

from tests.e2e.chains.helpers import bell_expect, make_approved_business, select_business
from tests.e2e.form_data import unique_name
from tests.e2e.pages.merchant_dashboard import MerchantDashboardPage

pytestmark = [pytest.mark.e2e, pytest.mark.slow, pytest.mark.workflow_chain]


def test_wf_featured_boost(wf, api, merchant_ready):
    chain = wf.chain_id
    admin_token = wf.token("admin")

    # 0. DEBUG gate — a SKIP (never a fail) when the mock-complete route is disabled
    probe = api.mock_complete_payment(admin_token, "wf-probe-no-such-order")
    if probe.status == 404 and probe.json().get("detail") == "Not found":
        pytest.skip("DEBUG is not true on this stack: payments/mock/complete is disabled (Compose sets DEBUG=true)")

    biz = make_approved_business(api, wf.token("merchant"), admin_token, unique_name("WF Boost"))

    # 1. merchant starts the featured checkout in the UI
    merchant = wf.actor("merchant")
    wf.visit(
        merchant,
        "/merchant/dashboard",
        ready=merchant.get_by_text("Merchant Dashboard").first,
        label="merchant dashboard",
    )
    select_business(merchant, str(biz.id))
    order_id = MerchantDashboardPage(merchant).start_featured_checkout()
    wf.scan(merchant, "dashboard after checkout")

    # 2. the payment is captured (mock provider)
    done = api.mock_complete_payment(admin_token, order_id)
    assert done.status == 200, done.text()
    bell_expect(
        merchant,
        title="Featured payment received",
        contains=biz.name,
        chain=chain,
        role="merchant",
    )

    # 3. admin approves the placement in the Payments panel
    admin = wf.actor("admin")
    wf.visit(
        admin,
        "/admin",
        ready=admin.get_by_role("heading", name="Payments", exact=True).first,
        label="/admin payments",
    )
    row = (
        admin.locator("div")
        .filter(has_text=biz.name)
        .filter(has=admin.get_by_role("button", name="Approve boost"))
        .last
    )
    approve = row.get_by_role("button", name="Approve boost")
    expect(approve).to_be_visible(timeout=30_000)
    with admin.expect_response(
        lambda r: r.request.method == "POST" and "/approve" in r.url and "payments" in r.url, timeout=20_000
    ) as resp:
        approve.click()
    assert resp.value.status == 200, resp.value.text()

    # 4. merchant is told the boost is live
    bell_expect(
        merchant,
        title="Featured boost is live",
        contains=biz.name,
        chain=chain,
        role="merchant",
    )
