"""wf-review-reply — merchant replies -> the reply is visible publicly (PASS).

Known gap (README §14): the review author is NOT notified of the reply. The gap assertion is an
xfail(strict) — when the notification feature lands it XPASSes, which FAILS the run until the
xfail and README §14 are updated.
"""

from __future__ import annotations

from uuid import uuid4

import pytest
from playwright.sync_api import expect

from tests.e2e.api_client import PASSWORD
from tests.e2e.chains.helpers import bell_expect, eventually, make_approved_business, select_business
from tests.e2e.form_data import REVIEW_BODY, unique_email, unique_name
from tests.e2e.pages.merchant_dashboard import MerchantDashboardPage

pytestmark = [pytest.mark.e2e, pytest.mark.slow, pytest.mark.workflow_chain]


def _author_with_review(api, wf, merchant_ready, label: str):
    biz = make_approved_business(api, wf.token("merchant"), wf.token("admin"), unique_name(label))
    email = unique_email("customer")
    api.register(email, role="customer", password=PASSWORD)
    tokens = api.tokens(email, PASSWORD)
    marker = f"wf-reply-{uuid4().hex[:8]}"
    review = api.create_review(tokens.access_token, biz.id, f"{REVIEW_BODY} {marker}")
    return biz, tokens, review, marker


def test_wf_review_reply(wf, api, merchant_ready):
    chain = wf.chain_id
    biz, _tokens, _review, _marker = _author_with_review(api, wf, merchant_ready, "WF Reply")
    reply = f"Thanks from WF {uuid4().hex[:8]}"

    # 1. merchant replies on their dashboard
    merchant = wf.actor("merchant")
    wf.visit(
        merchant,
        "/merchant/dashboard",
        ready=merchant.get_by_text("Merchant Dashboard").first,
        label="merchant dashboard",
    )
    select_business(merchant, str(biz.id))
    MerchantDashboardPage(merchant).reply_to_first_review(reply)
    wf.scan(merchant, "dashboard after reply")

    # 2. anyone opening the business sees the reply
    anon = wf.anon()
    wf.visit(anon, f"/businesses/{biz.slug}", ready=anon.get_by_role("heading", level=1, name=biz.name), label="public profile")

    def _reply_visible():
        anon.reload()
        expect(anon.get_by_text(reply, exact=False).first).to_be_visible(timeout=4_000)

    eventually(_reply_visible, chain=chain, what="merchant reply visible on the public page")


@pytest.mark.xfail(
    strict=True,
    raises=AssertionError,
    reason="customer is not notified of replies (README §14)",
)
def test_wf_review_reply_gap(wf, api, merchant_ready):
    chain = wf.chain_id
    biz, tokens, review, _marker = _author_with_review(api, wf, merchant_ready, "WF Reply Gap")
    api.reply_to_review(wf.token("merchant"), review.id, f"Gap reply {uuid4().hex[:8]}")

    author = wf.session_actor(tokens.access_token, tokens.refresh_token)
    author.goto("/")
    wf.skip_scan("/")  # only touched to open the bell and assert absence
    # Today this raises AssertionError (no notice) -> XFAIL. Once the feature lands it returns
    # normally -> strict XPASS -> FAIL: "known gap now passes - remove xfail and update README §14".
    bell_expect(author, contains=biz.name, timeout_ms=8_000, chain=chain, role="review author")
