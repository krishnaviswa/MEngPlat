"""wf-listing-approval — merchant creates a business -> admin approves -> merchant is told -> customer finds it."""

from __future__ import annotations

import re
from urllib.parse import quote

import pytest
from playwright.sync_api import expect

from tests.e2e.chains.helpers import bell_expect, eventually
from tests.e2e.form_data import unique_name
from tests.e2e.pages.admin_panel import AdminPanelPage
from tests.e2e.pages.merchant import NewBusinessPage

pytestmark = [pytest.mark.e2e, pytest.mark.slow, pytest.mark.workflow_chain]


def test_wf_listing_approval(wf, api, merchant_ready):
    chain = wf.chain_id
    name = unique_name("WF Listing")

    # 1. merchant registers the business through the real form
    merchant = wf.actor("merchant")
    wf.visit(
        merchant,
        "/merchant/businesses/new",
        ready=merchant.get_by_role("heading", name="Register your business"),
        label="new business form",
    )
    NewBusinessPage(merchant).submit(name=name, address="14 Marina Loop", city="Chennai")
    wf.scan(merchant, "dashboard after create")

    mine = api.get("businesses/mine", token=wf.token("merchant"))
    assert mine.status == 200, mine.text()
    entry = next((b for b in mine.json() if b["name"] == name), None)
    assert entry is not None, f"[{chain}] created business not in /businesses/mine"
    assert entry["status"] == "pending", entry["status"]
    slug = entry["slug"]

    # 2. admin approves it in the panel
    admin = wf.actor("admin")
    AdminPanelPage(admin).start_review_then_approve(name)
    wf.scan(admin, "/admin queue")

    # 3. merchant is told (unread bell notice naming THIS business)
    bell_expect(
        merchant,
        title="Listing approved",
        contains=f"{name} has been approved and is now live",
        chain=chain,
        role="merchant",
    )

    # 4. customer can open the public profile (SSR, no cache) and find it in search
    customer = wf.actor("customer")
    wf.visit(
        customer,
        f"/businesses/{slug}",
        ready=customer.get_by_role("heading", level=1, name=name),
        label="public profile",
    )

    def _in_search():
        customer.goto(f"/search?q={quote(name)}")
        expect(customer.get_by_role("link", name=re.compile(re.escape(name))).first).to_be_visible(timeout=4_000)

    eventually(_in_search, chain=chain, what="approved business appears in customer search")
    wf.scan(customer, "search results")
