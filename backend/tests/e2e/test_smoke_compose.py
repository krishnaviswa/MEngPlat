"""Compose smoke: home UI + GET /businesses schema (dual oracle). Opt-in: E2E=1."""

from __future__ import annotations

import re

import pytest
from playwright.sync_api import Page, Playwright, expect

from tests.e2e.oracles import validate_business_list
from tests.e2e.pages.business_detail import BusinessDetailPage
from tests.e2e.pages.home import HomePage

pytestmark = pytest.mark.e2e


def test_compose_home_dual_oracle(
    page: Page, playwright: Playwright, api_url: str
) -> None:
    home = HomePage(page)
    home.goto()
    home.expect_hero()

    api = playwright.request.new_context(base_url=f"{api_url}/")
    try:
        response = api.get("businesses")
        assert response.status == 200, response.text()
        businesses = validate_business_list(response.json())
    finally:
        api.dispose()

    if businesses:
        first = businesses[0]
        page.goto(f"/businesses/{first.slug}")
        detail = BusinessDetailPage(page)
        detail.expect_name(first.name)
        expect(detail.write_review_link()).to_have_attribute(
            "href", f"/businesses/{first.slug}/review"
        )
        return

    home.goto()
    home.explore_listings()
    expect(page).to_have_url(re.compile(r"/search"))
