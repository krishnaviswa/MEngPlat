"""Anonymous browse + signed-out review gate (TP-S-010)."""

from __future__ import annotations

import re

import pytest
from playwright.sync_api import Page, expect

from app.schemas import BusinessResponse, ReviewResponse
from tests.e2e.api_client import Api
from tests.e2e.pages.business_detail import BusinessDetailPage
from tests.e2e.pages.home import HomePage
from tests.e2e.pages.login import LoginPage

pytestmark = pytest.mark.e2e


def test_anonymous_browse_and_redirect(page: Page, api: Api) -> None:
    posted: list[str] = []
    page.on("response", lambda res: posted.append(f"{res.request.method} {res.url}"))

    home = HomePage(page)
    home.goto()
    home.expect_hero()

    businesses = api.list_businesses()
    cities = api.list_cities()
    if cities:
        city = cities[0]
        page.get_by_role("link", name=re.compile(rf"View all in {re.escape(city)}")).click()
        expect(page).to_have_url(re.compile(rf"/search\?city={re.escape(city)}", re.I))
        search = api.get(f"search/businesses?city={city}")
        assert search.status == 200, search.text()
        for item in search.json():
            assert city.lower() in BusinessResponse.model_validate(item).city.lower()
    else:
        home.explore_listings()
        expect(page).to_have_url(re.compile(r"/search"))

    if not businesses:
        pytest.skip("No approved listings — seed Compose to cover business detail")

    first = businesses[0]
    page.goto(f"/businesses/{first.slug}")
    detail = BusinessDetailPage(page)
    detail.expect_name(first.name)
    expect(detail.write_review_link()).to_have_attribute("href", f"/businesses/{first.slug}/review")
    slug_res = api.get(f"businesses/{first.slug}")
    assert slug_res.status == 200
    slug_biz = BusinessResponse.model_validate(slug_res.json())
    assert slug_biz.status == "approved"
    reviews = api.get(f"reviews/business/{first.id}")
    assert reviews.status == 200
    for item in reviews.json():
        ReviewResponse.model_validate(item)

    posted.clear()
    detail.write_review_link().click()
    expect(page.get_by_text("Sign in to write a review.")).to_be_visible()
    sign_in_link = page.get_by_role("main").get_by_role("link", name="Sign in")
    expect(sign_in_link).to_have_attribute("href", "/login")
    assert not any("POST" in u and "/reviews" in u for u in posted)

    sign_in_link.click()
    LoginPage(page).expect_form()
