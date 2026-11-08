"""wf-new-review — customer posts a review -> merchant is told and sees it on the dashboard."""

from __future__ import annotations

from uuid import uuid4

import pytest
from playwright.sync_api import expect

from tests.e2e.chains.helpers import bell_expect, eventually, make_approved_business, select_business
from tests.e2e.form_data import REVIEW_BODY, unique_name

pytestmark = [pytest.mark.e2e, pytest.mark.slow, pytest.mark.workflow_chain]


def test_wf_new_review(wf, api, merchant_ready):
    chain = wf.chain_id
    biz = make_approved_business(api, wf.token("merchant"), wf.token("admin"), unique_name("WF Review"))
    marker = f"wf-{uuid4().hex[:8]}"
    body = f"{REVIEW_BODY} {marker}"

    # 1. customer posts a 4-star review through the real form
    customer = wf.actor("customer")
    wf.visit(
        customer,
        f"/businesses/{biz.slug}/review",
        ready=customer.get_by_placeholder("Share details of your experience (min 10 characters)"),
        label="review form",
    )
    customer.locator('button[aria-label="4 stars"]:not([disabled])').click()
    customer.get_by_placeholder("Title (optional)").fill("WF review")
    customer.get_by_placeholder("Share details of your experience (min 10 characters)").fill(body)
    with customer.expect_response(
        lambda r: r.request.method == "POST" and r.url.rstrip("/").endswith("/reviews"), timeout=20_000
    ) as resp:
        customer.get_by_role("button", name="Post review").click()
    assert resp.value.status == 201, resp.value.text()
    expect(customer.get_by_text("Your review is live")).to_be_visible(timeout=20_000)
    wf.scan(customer, "review posted")

    # 2. merchant is told (unread notice naming THIS business) ...
    merchant = wf.actor("merchant")
    wf.visit(
        merchant,
        "/merchant/dashboard",
        ready=merchant.get_by_text("Merchant Dashboard").first,
        label="merchant dashboard",
    )
    bell_expect(
        merchant,
        title="New review received",
        contains=f"New 4-star review on {biz.name}",
        chain=chain,
        role="merchant",
    )

    # 3. ... and the review is on that business's dashboard
    def _review_listed():
        merchant.reload()
        select_business(merchant, str(biz.id))
        expect(merchant.get_by_text(marker)).to_be_visible(timeout=4_000)

    eventually(_review_listed, chain=chain, what="merchant dashboard lists the new review")
    wf.scan(merchant, "dashboard with review")
