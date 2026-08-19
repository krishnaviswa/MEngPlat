"""Customer register → review → profile → logout / blocklist (TP-S-010)."""

from __future__ import annotations

import re
from uuid import uuid4

import pytest
from jose import jwt
from playwright.sync_api import Page, expect

from app.schemas import ReviewResponse, TokenResponse, UserResponse
from tests.e2e.api_client import PASSWORD, Api
from tests.e2e.pages.register import RegisterPage

pytestmark = pytest.mark.e2e


def test_customer_full_journey(page: Page, api: Api) -> None:
    listings = api.list_businesses()
    if not listings:
        pytest.skip("No approved listings — seed Compose")
    business = listings[0]
    email = f"e2e-cust-{uuid4().hex[:10]}@example.com"
    body = f"Playwright customer review {uuid4().hex[:8]} was great."

    RegisterPage(page).goto()
    RegisterPage(page).sign_up(full_name="E2E Customer", email=email, role="customer")
    expect(page).to_have_url(re.compile(r"https?://[^/]+/?$"))

    access = page.evaluate("() => localStorage.getItem('access_token')")
    assert access
    TokenResponse.model_validate(
        {
            "access_token": access,
            "refresh_token": page.evaluate("() => localStorage.getItem('refresh_token')") or "x",
        }
    )
    claims = jwt.get_unverified_claims(access)
    assert claims.get("type") == "access"
    assert claims.get("role") == "customer"

    me = api.get("auth/me", token=access)
    assert me.status == 200
    user = UserResponse.model_validate(me.json())
    assert user.role == "customer"
    assert str(claims.get("sub")) == str(user.id)

    page.goto(f"/businesses/{business.slug}/review")
    expect(page.get_by_placeholder("Share details of your experience (min 10 characters)")).to_be_visible()
    page.get_by_role("button", name="5 stars").click()
    page.get_by_placeholder("Share details of your experience (min 10 characters)").fill(body)
    page.get_by_role("button", name="Post review").click()
    expect(page.get_by_text("Thank you! Your review is live.")).to_be_visible()
    page.get_by_role("link", name=re.compile(r"Back to")).click()
    expect(page).to_have_url(re.compile(rf"/businesses/{re.escape(business.slug)}"), timeout=20_000)
    review_card = page.locator("article").filter(has_text=body)
    expect(review_card).to_be_visible()
    expect(review_card.get_by_text("Quick take:")).to_be_visible()

    listed = api.get(f"reviews/business/{business.id}")
    assert listed.status == 200
    match = next(ReviewResponse.model_validate(r) for r in listed.json() if r.get("body") == body)
    assert match.ai_analysis is not None
    assert match.ai_analysis.sentiment in {"positive", "neutral", "negative"}
    assert str(match.author_id) == str(user.id)

    page.goto("/profile")
    expect(page.get_by_label("Full name")).to_have_value("E2E Customer")

    page.goto("/settings")
    page.get_by_role("button", name="Log out").click()
    expect(page.get_by_role("link", name="Login")).to_be_visible()
    blocked = api.get("auth/me", token=access)
    assert blocked.status == 401
