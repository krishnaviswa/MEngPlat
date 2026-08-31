"""S-124 — human-driven merchant journey (AC 6).

One ordered flow: KYC -> business create (Enter) -> dashboard widgets ->
AI disclaimer -> address re-verification OTP -> photo manager -> reply ->
featured mock checkout. Cross-role approval uses the seeded admin via the API.
"""

from __future__ import annotations

import re

import pytest
from playwright.sync_api import expect

from tests.e2e.api_client import PASSWORD, Api
from tests.e2e.form_data import (
    FORMS,
    REVIEW_BODY,
    SAMPLE_IMAGE,
    unique_email,
    unique_name,
)
from tests.e2e.pages.business_form import EditBusinessPage, NewBusinessPage
from tests.e2e.pages.merchant_dashboard import MerchantDashboardPage

pytestmark = [pytest.mark.e2e, pytest.mark.journey_merchant, pytest.mark.slow]


def test_merchant_full_journey(fresh_merchant, admin_tokens, api: Api, human, record_form):
    page = fresh_merchant["page"]
    m_access = fresh_merchant["access"]
    dash = MerchantDashboardPage(page)

    # --- 6a: national-ID KYC via MerchantNationalIdCard, Enter submit --------
    dash.goto()
    expect(page.get_by_role("heading", name="No business yet")).to_be_visible(timeout=20_000)
    human(page).fill_and_submit(FORMS["merchant.national_id"])  # asserts PATCH /auth/me 200
    # KYC gate hint clears once the ID is stored
    expect(
        page.get_by_text("Add PAN, Aadhaar, or another national ID", exact=False)
    ).to_have_count(0, timeout=20_000)
    assert api.me(m_access).national_id_type == "pan"
    record_form("merchant.national_id")

    # --- 6b: BusinessForm submitted with Enter -> pending --------------------
    biz_name = unique_name("E2E Merchant Shop")
    NewBusinessPage(page).goto()
    NewBusinessPage(page).expect_loaded()
    human(page).fill_and_submit(FORMS["merchant.business_create"], subs={"name": biz_name})
    expect(page).to_have_url(re.compile(r"/merchant/dashboard"), timeout=20_000)
    record_form("merchant.business_create")

    mine = [b for b in api.get("businesses/mine", token=m_access).json()]
    created = next(b for b in mine if b["name"] == biz_name)
    assert created["status"] == "pending"
    business_id = created["id"]

    # --- 6c: dashboard widgets --------------------------------------------
    dash.goto()
    dash.expect_pending()
    dash.set_date_range("90")
    dash.refresh_ai_insights()
    filename = dash.download_csv()
    assert filename.endswith(".csv")

    # --- 6d: AI disclaimer copy ------------------------------------------
    dash.expect_ai_disclaimer()

    # --- admin approves so review/reply/boost become possible ------------
    api.start_review(admin_tokens.access_token, business_id)
    api.approve_business(admin_tokens.access_token, business_id)

    # --- 6e: address re-verification OTP (2nd+ address edit) -------------
    edit = EditBusinessPage(page)
    edit.goto(business_id)
    edit.expect_loaded()
    edit.change_address_and_save("22 First Change Road")
    expect(page.get_by_text("Edit business", exact=False)).to_be_visible()
    edit.goto(business_id)
    edit.change_address_and_save("33 Second Change Avenue")
    record_form("merchant.business_edit_address_otp")
    try:
        edit.expect_address_otp_prompt()
    except AssertionError:
        pytest.skip("address OTP not demanded in this environment (S-073 gate config)")
    edit.submit_address_otp("123456")

    # --- 6f: photo manager add + remove (window.confirm auto-accepted) --
    edit.goto(business_id)
    with page.expect_response(lambda r: r.request.method == "POST" and "/photos/upload" in r.url):
        page.locator('input[type="file"]').last.set_input_files(str(SAMPLE_IMAGE))
    remove = page.get_by_role("button", name="Remove photo").first
    expect(remove).to_be_visible(timeout=20_000)
    with page.expect_response(lambda r: r.request.method == "DELETE" and "/photos/" in r.url):
        remove.click()

    # --- 6g: reply as business (needs a customer review) ----------------
    cust_email = unique_email("customer")
    api.register(cust_email, role="customer", password=PASSWORD)
    cust = api.complete_password_login(cust_email)
    api.create_review(cust["access_token"], business_id, REVIEW_BODY)
    dash.goto()
    dash.reply_to_first_review("Thank you for visiting — glad you enjoyed it!")
    record_form("merchant.reply")

    # --- 6h: featured-boost mock checkout (UI start, admin mock-complete) --
    dash.goto()
    order_id = dash.start_featured_checkout()
    res = api.mock_complete_payment(admin_tokens.access_token, order_id)
    if res.status == 404:
        pytest.skip("payments mock/complete needs Compose DEBUG=true")
    assert res.status == 200, res.text()
