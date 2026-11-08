"""wf-whatsapp-draft — admin approves a WhatsApp draft -> merchant is told.

seed.py creates no WhatsApp drafts and ingest needs a live webhook, so on a fresh Compose stack
this chain is SKIPPED (expected). It executes only where drafts already exist (staging / local DB).
"""

from __future__ import annotations

import pytest
from playwright.sync_api import expect

from tests.e2e.chains.helpers import bell_expect

pytestmark = [pytest.mark.e2e, pytest.mark.slow, pytest.mark.workflow_chain]


def test_wf_whatsapp_draft(wf, api, merchant_ready):
    chain = wf.chain_id
    admin_token = wf.token("admin")
    queue = api.whatsapp_drafts(admin_token)
    drafts = queue.get("items", queue) if isinstance(queue, dict) else queue
    if not drafts:
        pytest.skip("no seeded WhatsApp drafts: seed.py creates none and ingest needs a live WhatsApp webhook")

    mine = api.get("businesses/mine", token=wf.token("merchant"))
    assert mine.status == 200, mine.text()
    my_ids = {b["id"] for b in mine.json()}
    draft = next((d for d in drafts if str(d.get("business_id")) in my_ids), None)
    if draft is None:
        pytest.skip("no pending draft targets the seeded merchant, so the bell cannot be observed")
    name = draft.get("business_name") or ""

    admin = wf.actor("admin")
    wf.visit(
        admin,
        "/admin/whatsapp",
        ready=admin.get_by_role("link", name="Admin panel"),
        label="/admin/whatsapp",
    )
    row = (
        admin.locator("div")
        .filter(has_text=name)
        .filter(has=admin.get_by_role("button", name="Approve", exact=True))
        .last
    )
    approve = row.get_by_role("button", name="Approve", exact=True)
    expect(approve).to_be_visible(timeout=20_000)
    with admin.expect_response(
        lambda r: r.request.method == "POST" and "/approve" in r.url, timeout=20_000
    ) as resp:
        approve.click()
    assert resp.value.status == 200, resp.value.text()

    merchant = wf.actor("merchant")
    merchant.goto("/merchant/dashboard")
    bell_expect(merchant, title="WhatsApp update applied", contains=name, chain=chain, role="merchant")
