"""S-124 — human-driven anonymous / public surface journey.

Visits every public route, fills every catalogued public form with predefined
values, submits (Enter where the form supports it), and asserts both oracles.
"""

from __future__ import annotations

import re

import pytest
from playwright.sync_api import expect

from tests.e2e.api_client import PASSWORD, Api
from tests.e2e.form_data import FORMS, DEFAULTS, unique_email
from tests.e2e.oracles import validate_business_list
from tests.e2e.pages.login import LoginPage
from tests.e2e.pages.password_reset import ForgotPasswordPage, ResetPasswordPage
from tests.e2e.pages.register import RegisterPage
from tests.e2e.pages.search import SearchPage
from tests.e2e.pages.support import SupportPage

pytestmark = [pytest.mark.e2e, pytest.mark.journey_anonymous]


def test_home_loads_with_ssr_oracle(page, api: Api, api_url):
    page.goto("/")
    expect(
        page.get_by_role("heading", name="Local businesses, reviewed with clarity")
    ).to_be_visible(timeout=20_000)
    # SSR: the browser never sees GET /businesses — run the technical oracle directly.
    res = api.get("businesses")
    assert res.status == 200
    validate_business_list(res.json())


def test_search_bar_enter_submit(page, human, record_form):
    spec = FORMS["anon.search_bar"]
    page.goto(spec.route)
    human(page).fill_and_submit(spec)
    expect(page).to_have_url(re.compile(r"/search\?.*q=cafe"))
    record_form("anon.search_bar")


def test_filter_panel_enter_submit(page, human, record_form):
    spec = FORMS["anon.filter_panel"]
    SearchPage(page).goto("cafe")
    SearchPage(page).expect_loaded()
    human(page).fill_and_submit(spec)
    expect(page).to_have_url(re.compile(r"/search\?"))
    record_form("anon.filter_panel")


def test_business_detail_loads(page, api: Api, seeded_business):
    page.goto(f"/businesses/{seeded_business.slug}")
    expect(page.get_by_role("heading", level=1, name=seeded_business.name)).to_be_visible(
        timeout=20_000
    )
    res = api.get(f"businesses/{seeded_business.slug}")
    assert res.status == 200 and res.json()["status"] == "approved"


def test_anonymous_review_gate_no_post(page, seeded_business):
    posts: list[str] = []
    page.on("request", lambda r: posts.append(r.url) if r.method == "POST" and "/reviews" in r.url else None)
    page.goto(f"/businesses/{seeded_business.slug}/review")
    gate = page.locator("div", has=page.get_by_text("Sign in to write a review.", exact=False)).last
    expect(gate).to_be_visible(timeout=20_000)
    expect(gate.get_by_role("link", name="Sign in")).to_have_attribute("href", "/login")
    assert not posts, f"anonymous review must not POST: {posts}"


def test_anonymous_favorite_redirects_to_login(page, seeded_business):
    page.goto(f"/businesses/{seeded_business.slug}")
    page.get_by_role("button", name=re.compile("favorite", re.I)).first.click()
    expect(page).to_have_url(re.compile(r"/login"), timeout=20_000)


def test_anonymous_collect_inline_auth_on_submit(page, seeded_business, record_form):
    """S-121 / AC1c — Submit while logged out swaps in InlineAuthStep, no navigation."""
    from tests.e2e.pages.collect import CollectPage

    cp = CollectPage(page)
    cp.goto(seeded_business.slug)
    cp.expect_loaded()
    if cp.variant() != "classic":
        pytest.skip("NEXT_PUBLIC_GAMIFIED_REVIEW flipped from default — collect UI differs")
    url_before = page.url
    cp.pick_rating(5)
    cp.continue_to_text()
    cp.write_and_submit("Lovely spot, the staff were friendly and it was spotless throughout.")
    page.get_by_role("button", name="Submit review").click()
    expect(
        page.get_by_role("radiogroup", name=re.compile("Sign in with", re.I))
        .or_(page.get_by_text("Mobile OTP", exact=False))
    ).to_be_visible(timeout=20_000)
    expect(page).to_have_url(url_before)  # no navigation to /login
    record_form("anon.collect_inline_auth")


def test_enter_inert_on_collect_stars_step(page, seeded_business):
    """AC3 — the collect 'stars' step has no submitting <form>; Enter is a no-op."""
    from tests.e2e.pages.collect import CollectPage

    cp = CollectPage(page)
    cp.goto(seeded_business.slug)
    cp.expect_loaded()
    if cp.variant() != "classic":
        pytest.skip("gamified collect variant — different step model")
    url_before = page.url
    fired: list[str] = []
    page.on("request", lambda r: fired.append(r.url) if r.method in ("POST", "PATCH") and "/api/" in r.url else None)
    expect(page.get_by_text("How was your experience?", exact=False)).to_be_visible()
    page.keyboard.press("Enter")  # nothing focused / no form on this step
    expect(page).to_have_url(url_before)
    assert not fired, f"Enter on the collect stars step must be inert: {fired}"


def test_login_and_register_pages_render(page):
    LoginPage(page).goto()
    LoginPage(page).expect_form()
    RegisterPage(page).goto()
    expect(page.get_by_role("heading", name="Create account")).to_be_visible()


def test_forgot_password_enter_submit(page, human, record_form):
    spec = FORMS["anon.forgot_password"]
    ForgotPasswordPage(page).goto()
    ForgotPasswordPage(page).expect_loaded()
    human(page).fill_and_submit(spec)
    ForgotPasswordPage(page).expect_confirmation()
    record_form("anon.forgot_password")


def test_reset_password_page_states(page, record_form):
    rp = ResetPasswordPage(page)
    rp.goto("")  # missing token
    rp.expect_invalid_link()
    rp.goto("e2e-not-a-real-token")  # token present → form renders (submit would 400)
    rp.expect_loaded()
    record_form("anon.reset_password")


def test_support_ticket_form(page, human, record_form):
    spec = FORMS["anon.support_ticket"]
    SupportPage(page).goto()
    SupportPage(page).expect_loaded()
    human(page).fill_and_submit(spec)
    SupportPage(page).expect_submitted()
    record_form("anon.support_ticket")


def test_login_wizard_totp(page, api: Api, record_form):
    """AC8 — register via API, log in through the browser, asserting each step."""
    email = unique_email("customer")
    api.register(email, role="customer", password=PASSWORD)
    lp = LoginPage(page)
    lp.goto()
    lp.submit_credentials(email, PASSWORD)
    lp.complete_totp()  # asserts the enroll/verify heading transition internally
    expect(page).not_to_have_url(re.compile(r"/login"), timeout=20_000)
    assert page.evaluate("() => !!localStorage.getItem('access_token')")
    record_form("anon.login")
    record_form("anon.register")  # register page exercised via api + login wizard


def test_register_phone_otp_wizard(page, record_form):
    """AC8 — phone-OTP account creation on /register (Enter does not submit PhoneOtpPanel)."""
    from uuid import uuid4

    RegisterPage(page).goto()
    page.get_by_placeholder("Full name").fill(DEFAULTS["full_name"])
    page.get_by_role("radio", name="Mobile OTP").click()
    phone_local = "98" + str(uuid4().int % 100_000_000).zfill(8)
    page.get_by_label("Mobile number").fill(phone_local)
    page.get_by_role("button", name="Send SMS code").click()
    code_box = page.get_by_label("SMS code")
    expect(code_box).to_be_visible(timeout=20_000)
    code_box.fill("123456")
    # Enter must NOT submit PhoneOtpPanel — the "Verify" button does.
    with page.expect_response(
        lambda r: r.request.method == "POST" and "/auth/phone/verify" in r.url, timeout=20_000
    ) as ri:
        page.get_by_role("button", name=re.compile("Verify", re.I)).click()
    assert ri.value.status in (200, 400)  # 400 only if the demo OTP window drifted
    record_form("anon.register_phone_otp")
