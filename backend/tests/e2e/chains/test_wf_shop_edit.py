"""wf-shop-edit — merchant edits the description -> it is public immediately (no re-approval) and a
reviewer of the shop is told (S-126)."""

from __future__ import annotations

from uuid import uuid4

import pytest
from playwright.sync_api import expect

from tests.e2e.api_client import PASSWORD
from tests.e2e.chains.helpers import bell_expect, eventually, make_approved_business
from tests.e2e.form_data import REVIEW_BODY, unique_email, unique_name

pytestmark = [pytest.mark.e2e, pytest.mark.slow, pytest.mark.workflow_chain]


def test_wf_shop_edit(wf, api, merchant_ready):
    chain = wf.chain_id
    biz = make_approved_business(api, wf.token("merchant"), wf.token("admin"), unique_name("WF Edit"))
    desc = f"Edited by WF {uuid4().hex[:8]}"

    # setup: a fresh customer has an active review of this shop (S-126: reviewers are told about edits)
    reviewer_email = unique_email("customer")
    api.register(reviewer_email, role="customer", password=PASSWORD)
    reviewer_tokens = api.tokens(reviewer_email, PASSWORD)
    api.create_review(reviewer_tokens.access_token, biz.id, f"{REVIEW_BODY} wf-edit-{uuid4().hex[:6]}")

    # 1. merchant edits the DESCRIPTION (an address edit can demand the address-OTP gate; this never does)
    merchant = wf.actor("merchant")
    wf.visit(
        merchant,
        f"/merchant/businesses/{biz.id}/edit",
        ready=merchant.get_by_role("heading", name="Edit business").first,
        label="edit business",
    )
    merchant.get_by_label("Description", exact=True).fill(desc)
    with merchant.expect_response(
        lambda r: r.request.method == "PATCH" and "/businesses/" in r.url, timeout=20_000
    ) as resp:
        merchant.get_by_role("button", name="Save changes").click()
    assert resp.value.status == 200, resp.value.text()

    # 2. the new description is public straight away
    anon = wf.anon()
    wf.visit(anon, f"/businesses/{biz.slug}", ready=anon.get_by_role("heading", level=1, name=biz.name), label="public profile")

    def _desc_visible():
        anon.reload()
        expect(anon.get_by_text(desc, exact=False).first).to_be_visible(timeout=4_000)

    eventually(_desc_visible, chain=chain, what="edited description visible publicly")

    # 3. the reviewer is told the shop changed (S-126)
    reviewer = wf.session_actor(reviewer_tokens.access_token, reviewer_tokens.refresh_token)
    reviewer.goto("/")
    wf.skip_scan("/")  # only touched to open the bell
    bell_expect(reviewer, contains=biz.name, title="Shop details updated", chain=chain, role="reviewer")
