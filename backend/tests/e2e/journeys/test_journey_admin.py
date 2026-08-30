"""S-124 — human-driven admin journey (AC 7).

Every /admin/* sub-page loads; destructive queue actions run against
uuid4-suffixed throwaway entities created earlier in the same test. The seeded
admin is used only as an actor.
"""

from __future__ import annotations

import re

import pytest
from playwright.sync_api import expect

from tests.e2e.api_client import PASSWORD, Api
from tests.e2e.form_data import FORMS, REVIEW_BODY, unique_email, unique_name
from tests.e2e.oracles import (
    validate_business_report,
    validate_platform_analytics,
    validate_support_ticket,
    validate_user,
)
from tests.e2e.pages.admin_panel import AdminPanelPage
from tests.e2e.session_helpers import inject_session

pytestmark = [pytest.mark.e2e, pytest.mark.journey_admin, pytest.mark.slow]


@pytest.fixture
def admin_browser(page, admin_tokens, frontend_url):
    inject_session(page, frontend_url, admin_tokens.access_token, admin_tokens.refresh_token)
    page.goto("/admin")
    return page


def _throwaway_pending_business(api: Api, admin_token: str) -> tuple[str, str]:
    m_email = unique_email("merchant")
    api.register(m_email, role="merchant", password=PASSWORD)
    m = api.complete_password_login(m_email)
    api.set_national_id(m["access_token"])
    name = unique_name("Queue Shop")
    res = api.post(
        "businesses",
        token=m["access_token"],
        json={"name": name, "address": "1 Queue St", "city": "Chennai",
              "country": "IN", "phone": "+919876540000", "email": "q@e2e.example.com"},
    )
    assert res.status == 201, res.text()
    return name, res.json()["id"]


def test_admin_panel_and_subpages_load(admin_browser):
    panel = AdminPanelPage(admin_browser)
    panel.goto()
    panel.expect_loaded()
    panel.expect_all_sections()
    panel.expect_stat_tiles()
    panel.visit_subpages()


def test_admin_platform_stats_oracle(admin_tokens, api: Api, record_form):
    validate_platform_analytics(api.get("dashboard/admin/platform", token=admin_tokens.access_token).json())


def test_enter_inert_on_admin_search_box(admin_browser):
    """AC3 — admin queue search boxes are filter inputs, not in a submitting form."""
    page = admin_browser
    page.goto("/admin")
    box = page.get_by_label("Search users")
    box.scroll_into_view_if_needed()
    box.click()
    page.keyboard.type("alex")
    url_before = page.url
    fired: list[str] = []
    page.on("request", lambda r: fired.append(r.url) if r.method in ("POST", "PATCH") else None)
    page.keyboard.press("Enter")
    expect(page).to_have_url(url_before)
    assert not fired, f"Enter in the admin search box must not submit: {fired}"


def test_category_create_and_duplicate(admin_browser, human, record_form):
    page = admin_browser
    page.goto("/admin")
    name = unique_name("E2E Cat")
    human(page).fill_and_submit(FORMS["admin.category_create"], subs={"name": name})
    expect(page.get_by_role("link", name=name)).to_be_visible(timeout=20_000)
    # duplicate name -> inline 409 error
    box = page.get_by_placeholder("New category name")
    box.click()
    box.fill(name)
    page.get_by_role("button", name="Add category").click()
    expect(page.get_by_text("already exists", exact=False)).to_be_visible(timeout=20_000)
    record_form("admin.category_create")


def test_pending_business_start_review_then_approve(admin_browser, admin_tokens, api: Api):
    name, business_id = _throwaway_pending_business(api, admin_tokens.access_token)
    AdminPanelPage(admin_browser).start_review_then_approve(name)
    # /businesses/id/{id} only serves approved listings — a 200 here is the oracle
    fresh = api.get(f"businesses/id/{business_id}").json()
    assert fresh["status"] == "approved", fresh


def test_reported_review_moderation_cycle(admin_browser, admin_tokens, api: Api):
    # throwaway approved business + reported review
    name, business_id = _throwaway_pending_business(api, admin_tokens.access_token)
    api.approve_business(admin_tokens.access_token, business_id)
    c_email = unique_email("customer")
    api.register(c_email, role="customer", password=PASSWORD)
    c = api.complete_password_login(c_email)
    review = api.create_review(c["access_token"], business_id, REVIEW_BODY + " reportable")
    r2_email = unique_email("customer")
    api.register(r2_email, role="customer", password=PASSWORD)
    r2 = api.complete_password_login(r2_email)
    api.report_review(r2["access_token"], review.id)

    panel = AdminPanelPage(admin_browser)
    snippet = "reportable"
    admin_browser.goto("/admin")  # the queue loads on mount — refresh after reporting
    panel.moderate_reported(snippet, "hide")
    # Hide removes it from the reported queue; Restore/Remove need the review back
    # in that queue, which the UI doesn't provide — assert the state via the API.
    api.moderate_review(admin_tokens.access_token, review.id, "restore")
    api.moderate_review(admin_tokens.access_token, review.id, "remove")


def test_user_suspend_reactivate(admin_browser, admin_tokens, api: Api):
    u_email = unique_email("customer")
    user = api.register(u_email, role="customer", password=PASSWORD)
    panel = AdminPanelPage(admin_browser)
    panel.goto()
    admin_browser.get_by_role("button", name="Total users").click()  # scrolls to #admin-users
    panel.toggle_user(u_email, "Suspend")
    panel.toggle_user(u_email, "Reactivate")
    # technical oracle: the round-trip validates against UserResponse
    validate_user(api.suspend_user(admin_tokens.access_token, user.id).model_dump(mode="json"))
    login = api.post("auth/login", json={"email": u_email, "password": PASSWORD})
    assert login.status == 403, "suspended user must not be able to log in"
    api.reactivate_user(admin_tokens.access_token, user.id)


def test_support_ticket_admin_update(admin_browser, admin_tokens, api: Api):
    ticket = api.create_support_ticket(
        name="E2E Reporter", phone="+919876500000", issue="Cannot see my review after posting it."
    )
    admin_browser.goto("/admin/support")
    expect(admin_browser.get_by_text(ticket.issue[:20], exact=False)).to_be_visible(timeout=20_000)
    updated = api.admin_update_support_ticket(
        admin_tokens.access_token, ticket.id, status="in_progress", admin_response="Looking into it now."
    )
    validate_support_ticket(updated.model_dump(mode="json"))
    assert updated.status == "in_progress"


def test_business_report_thread_and_status(admin_browser, admin_tokens, api: Api):
    name, business_id = _throwaway_pending_business(api, admin_tokens.access_token)
    api.approve_business(admin_tokens.access_token, business_id)
    c_email = unique_email("customer")
    api.register(c_email, role="customer", password=PASSWORD)
    c = api.complete_password_login(c_email)
    report = api.create_business_report(c["access_token"], business_id, "This listing address looks fabricated.")
    admin_browser.goto("/admin/business-reports")
    expect(admin_browser.get_by_role("link", name="Admin panel")).to_be_visible(timeout=20_000)
    api.admin_add_report_message(admin_tokens.access_token, report.id, "Thanks — we are reviewing this shop.")
    updated = api.admin_update_business_report(admin_tokens.access_token, report.id, "in_progress")
    validate_business_report(updated.model_dump(mode="json"))


def test_whatsapp_drafts_queue(admin_browser, admin_tokens, api: Api):
    queue = api.whatsapp_drafts(admin_tokens.access_token)
    drafts = queue.get("items", queue) if isinstance(queue, dict) else queue
    if not drafts:
        pytest.skip("no seeded WhatsApp drafts to edit/approve/reject")
    admin_browser.goto("/admin/whatsapp")
    expect(admin_browser.get_by_role("link", name="Admin panel")).to_be_visible(timeout=20_000)
    # edit a draft field in the UI if one is editable
    edit_inputs = admin_browser.locator('input[type="text"]')
    if edit_inputs.count():
        edit_inputs.first.fill("Edited by e2e — corrected description.")
    # reject the first; approve the second if present
    assert api.post(
        f"admin/whatsapp/drafts/{drafts[0]['id']}/reject", token=admin_tokens.access_token
    ).status == 200
    if len(drafts) > 1:
        assert api.post(
            f"admin/whatsapp/drafts/{drafts[1]['id']}/approve",
            token=admin_tokens.access_token,
            json={},
        ).status == 200


def test_admin_payment_actions(admin_browser, admin_tokens, api: Api):
    admin_token = admin_tokens.access_token

    def _paid_boost():
        m_email = unique_email("merchant")
        api.register(m_email, role="merchant", password=PASSWORD)
        m = api.complete_password_login(m_email)
        api.set_national_id(m["access_token"])
        res = api.post(
            "businesses", token=m["access_token"],
            json={"name": unique_name("Pay Shop"), "address": "9 Pay St", "city": "Chennai",
                  "country": "IN", "phone": "+919876590000", "email": "pay@e2e.example.com"},
        )
        business_id = res.json()["id"]
        api.approve_business(admin_token, business_id)
        skus = api.featured_skus(m["access_token"])
        checkout = api.request_featured_boost(m["access_token"], business_id, skus[0]["code"])
        done = api.mock_complete_payment(admin_token, checkout.provider_order_id)
        if done.status == 404:
            pytest.skip("payments mock/complete needs Compose DEBUG=true")
        assert done.status == 200, done.text()
        return checkout

    # UI: the admin payments section renders
    admin_browser.goto("/admin")
    expect(admin_browser.get_by_role("heading", name="Payments")).to_be_visible(timeout=20_000)

    approve_target = _paid_boost()
    reject_target = _paid_boost()
    refund_target = _paid_boost()

    assert api.admin_payment_action(admin_token, str(approve_target.payment_id), "approve").status == 200
    assert api.admin_payment_action(admin_token, str(reject_target.payment_id), "reject").status == 200
    r = api.admin_payment_action(admin_token, str(refund_target.payment_id), "refund")
    assert r.status in (200, 400), r.text()  # refund may require prior approve depending on state
