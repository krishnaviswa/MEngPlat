"""wf-review-moderation — customer reports a review -> admin hides it -> it disappears from the public page."""

from __future__ import annotations

from uuid import uuid4

import pytest
from playwright.sync_api import expect

from tests.e2e.api_client import PASSWORD
from tests.e2e.chains.helpers import eventually, make_approved_business
from tests.e2e.form_data import REPORT_REASON, REVIEW_BODY, unique_email, unique_name
from tests.e2e.pages.admin_panel import AdminPanelPage

pytestmark = [pytest.mark.e2e, pytest.mark.slow, pytest.mark.workflow_chain]


def test_wf_review_moderation(wf, api, merchant_ready):
    chain = wf.chain_id
    biz = make_approved_business(api, wf.token("merchant"), wf.token("admin"), unique_name("WF Moderation"))
    marker = f"wf-mod-{uuid4().hex[:8]}"

    # setup: a fresh customer authored a review (the seeded customer will report it)
    author_email = unique_email("customer")
    api.register(author_email, role="customer", password=PASSWORD)
    author = api.tokens(author_email, PASSWORD)
    api.create_review(author.access_token, biz.id, f"{REVIEW_BODY} {marker}")

    # 1. the review is public
    anon = wf.anon()
    wf.visit(anon, f"/businesses/{biz.slug}", ready=anon.get_by_role("heading", level=1, name=biz.name), label="public profile")
    expect(anon.get_by_text(marker).first).to_be_visible(timeout=20_000)

    # 2. another customer reports it through the UI
    customer = wf.actor("customer")
    wf.visit(
        customer,
        f"/businesses/{biz.slug}",
        ready=customer.get_by_role("heading", level=1, name=biz.name),
        label="public profile (customer)",
    )
    customer.get_by_role("button", name="Report", exact=True).first.click()
    customer.get_by_placeholder("Why are you reporting this review? (min 10 characters)").fill(REPORT_REASON)
    with customer.expect_response(
        lambda r: r.request.method == "POST" and r.url.rstrip("/").endswith("/report"), timeout=20_000
    ) as resp:
        customer.get_by_role("button", name="Submit report").click()
    assert resp.value.status == 200, resp.value.text()
    expect(customer.get_by_text("Reported — pending moderation.")).to_be_visible(timeout=20_000)

    # 3. admin hides it from the reported queue
    admin = wf.actor("admin")
    panel = AdminPanelPage(admin)
    admin.goto("/admin")
    panel.expect_loaded()
    panel.moderate_reported(marker, "hide")
    wf.scan(admin, "/admin reported queue")

    # 4. the public page no longer shows it
    def _gone():
        anon.reload()
        expect(anon.get_by_role("heading", level=1, name=biz.name)).to_be_visible(timeout=4_000)
        expect(anon.get_by_text(marker)).to_have_count(0, timeout=4_000)

    eventually(_gone, chain=chain, what="hidden review disappears from the public page")
