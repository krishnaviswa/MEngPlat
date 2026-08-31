"""Merchant create listing, pending dashboard, reply after admin approve (TP-S-010)."""

from __future__ import annotations

from uuid import uuid4

import pytest
from playwright.sync_api import Page, expect

from app.schemas import BusinessResponse
from tests.e2e.api_client import PASSWORD, Api
from tests.e2e.pages.merchant import MerchantDashboardPage, NewBusinessPage
from tests.e2e.pages.register import RegisterPage

pytestmark = pytest.mark.e2e


def test_merchant_full_journey(page: Page, api: Api) -> None:
    admin = api.seed_admin_tokens()
    if not admin:
        pytest.skip("Seeded admin@merchanthub.ai not available")

    email = f"e2e-merch-{uuid4().hex[:10]}@example.com"
    name = f"E2E Shop {uuid4().hex[:6]}"

    RegisterPage(page).goto()
    RegisterPage(page).sign_up(full_name="E2E Merchant", email=email, role="merchant")
    page.goto("/merchant/dashboard")
    MerchantDashboardPage(page).expect_empty()
    expect(page.get_by_label("National ID type")).to_be_visible()
    page.get_by_label("National ID type").select_option("pan")
    page.get_by_label("National ID number").fill("ABCDE1234F")
    page.get_by_label("Confirm with password").fill(PASSWORD)  # S-114 reauth step-up
    page.get_by_role("button", name="Save national ID").click()
    expect(page.get_by_text("Add PAN, Aadhaar, or another national ID")).not_to_be_visible()
    mine = api.get("businesses/mine", token=page.evaluate("() => localStorage.getItem('access_token')"))
    assert mine.status == 200
    assert mine.json() == []

    NewBusinessPage(page).goto()
    NewBusinessPage(page).submit(name=name, address="12 Test Road", city="Chennai")
    MerchantDashboardPage(page).expect_pending()

    token = page.evaluate("() => localStorage.getItem('access_token')")
    mine2 = api.get("businesses/mine", token=token)
    assert mine2.status == 200
    created = BusinessResponse.model_validate(mine2.json()[0])
    assert created.status == "pending"
    assert created.name == name

    api.approve_business(admin.access_token, created.id)

    cust_email = f"e2e-rev-{uuid4().hex[:10]}@example.com"
    api.register(cust_email, role="customer")
    cust = api.tokens(cust_email)
    api.create_review(cust.access_token, created.id, "Great service from this e2e shop visit.")

    page.goto("/merchant/dashboard")
    page.get_by_role("button", name="Reply as business").click()
    page.get_by_placeholder("Write a response to this review").fill("Thanks for visiting us today.")
    page.get_by_role("button", name="Post reply").click()
    expect(page.get_by_text("Response from the business")).to_be_visible()
    expect(page.get_by_text("Thanks for visiting us today.")).to_be_visible()

    approve = api.post(f"businesses/{created.id}/approve", token=token)
    assert approve.status == 403

    other = api.register(f"e2e-merch2-{uuid4().hex[:10]}@example.com", role="merchant")
    other_tok = api.tokens(other.email)
    listings = api.list_businesses()
    other_biz = next((b for b in listings if str(b.id) != str(created.id)), None)
    if other_biz:
        stolen = api.patch(f"businesses/{other_biz.id}", token=other_tok.access_token, json={"name": "stolen"})
        assert stolen.status in {403, 404}
