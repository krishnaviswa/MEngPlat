"""S-124 — human-driven customer journey (AC 4, 5)."""

from __future__ import annotations

import re

import pytest
from playwright.sync_api import expect

from tests.e2e.api_client import PASSWORD, Api
from tests.e2e.form_data import FORMS, REVIEW_BODY, SAMPLE_IMAGE, unique_email
from tests.e2e.human import HumanForm
from tests.e2e.pages.profile import ProfilePage
from tests.e2e.pages.settings import SettingsPage

pytestmark = [pytest.mark.e2e, pytest.mark.journey_customer]


def test_review_submit_dual_oracle(fresh_customer, seeded_business, human, record_form, api: Api):
    page = fresh_customer["page"]
    spec = FORMS["customer.review"]
    page.goto(f"/businesses/{seeded_business.slug}/review")
    expect(
        page.get_by_placeholder("Share details of your experience (min 10 characters)")
    ).to_be_visible(timeout=20_000)
    human(page).fill_and_submit(spec)
    expect(page.get_by_text("Your review is live", exact=False)).to_be_visible(timeout=20_000)
    # side-effect oracle: the review is now on the listing
    bodies = [r.body for r in api.list_reviews(seeded_business.id)]
    assert any(REVIEW_BODY in b for b in bodies)
    record_form("customer.review")


def test_review_title_input_enter_submits(fresh_customer, seeded_business, human, record_form):
    page = fresh_customer["page"]
    spec = FORMS["customer.review_title_enter"]
    page.goto(f"/businesses/{seeded_business.slug}/review")
    expect(page.get_by_placeholder("Title (optional)")).to_be_visible(timeout=20_000)
    human(page).fill_and_submit(spec)  # submit() presses Enter in the title input
    expect(page.get_by_text("Your review is live", exact=False)).to_be_visible(timeout=20_000)
    record_form("customer.review_title_enter")


def test_review_requires_star_before_enter(fresh_customer, seeded_business):
    page = fresh_customer["page"]
    page.goto(f"/businesses/{seeded_business.slug}/review")
    body = page.get_by_placeholder("Share details of your experience (min 10 characters)")
    body.fill(REVIEW_BODY)
    title = page.get_by_placeholder("Title (optional)")
    title.click()
    HumanForm(page).expect_validation(r"select a star rating", r"/reviews")


def test_profile_basics_enter_submit(fresh_customer, human, record_form):
    page = fresh_customer["page"]
    ProfilePage(page).goto()
    ProfilePage(page).expect_loaded()
    human(page).fill_and_submit(FORMS["customer.profile_basics"])
    ProfilePage(page).expect_saved()
    record_form("customer.profile_basics")


@pytest.mark.skip(
    reason="/profile has no email-change control ('Email changes aren't supported yet'). "
    "The reauth step-up is regression-covered by the merchant national-ID flow (6a)."
)
def test_profile_email_change_reauth(fresh_customer):
    ...


def test_profile_avatar_upload(fresh_customer):
    page = fresh_customer["page"]
    ProfilePage(page).goto()
    ProfilePage(page).expect_loaded()
    ProfilePage(page).upload_avatar(str(SAMPLE_IMAGE))


def test_favorite_persists(fresh_customer, seeded_business):
    page = fresh_customer["page"]
    page.goto(f"/businesses/{seeded_business.slug}")
    btn = page.get_by_role("button", name=re.compile("favorite", re.I)).first
    with page.expect_response(
        lambda r: r.request.method == "POST" and "/favorites" in r.url, timeout=20_000
    ) as ri:
        btn.click()
    assert ri.value.status in (200, 201), ri.value.text()
    page.reload()
    expect(
        page.get_by_role("button", name=re.compile("favorited", re.I)).first
    ).to_be_visible(timeout=20_000)


def test_report_review(fresh_customer, seeded_business, api: Api):
    # another customer authors a review this one can report
    author_email = unique_email("customer")
    api.register(author_email, role="customer", password=PASSWORD)
    author = api.complete_password_login(author_email)
    review = api.create_review(author["access_token"], seeded_business.id, REVIEW_BODY + " (report me)")

    page = fresh_customer["page"]
    page.goto(f"/businesses/{seeded_business.slug}")
    card = page.locator("div").filter(has_text=review.body).filter(
        has=page.get_by_role("button", name="Report")
    ).last
    card.get_by_role("button", name="Report").click()
    box = page.get_by_placeholder("Why are you reporting this review? (min 10 characters)")
    box.fill("This looks like duplicated spam with a promo link.")
    with page.expect_response(
        lambda r: r.request.method == "POST" and "/report" in r.url, timeout=20_000
    ) as ri:
        page.get_by_role("button", name="Submit report").click()
    assert ri.value.status == 200, ri.value.text()
    expect(page.get_by_text("Reported — pending moderation.", exact=False)).to_be_visible()


def test_logout_blocklists_token(fresh_customer, api: Api):
    page = fresh_customer["page"]
    token = fresh_customer["access"]
    SettingsPage(page).goto()
    SettingsPage(page).expect_loaded()
    SettingsPage(page).logout()
    res = api.get("auth/me", token=token)
    assert res.status == 401, f"replayed token should be blocklisted, got {res.status}"
