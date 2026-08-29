from __future__ import annotations

import re

from playwright.sync_api import Page, expect

AI_DISCLAIMER = "Suggestions only — not definitive judgments. Verify in person before acting."


class MerchantDashboardPage:
    def __init__(self, page: Page) -> None:
        self.page = page

    def goto(self) -> None:
        self.page.goto("/merchant/dashboard")

    def expect_empty(self) -> None:
        expect(self.page.get_by_role("heading", name="No business yet")).to_be_visible(timeout=20_000)

    def expect_pending(self) -> None:
        expect(self.page.get_by_text("Awaiting approval", exact=False)).to_be_visible(timeout=20_000)

    def set_date_range(self, value: str) -> None:
        with self.page.expect_response(
            lambda r: r.request.method == "GET" and "/dashboard/merchant/" in r.url, timeout=20_000
        ):
            self.page.get_by_label("Date range").select_option(value)

    def refresh_ai_insights(self) -> None:
        with self.page.expect_response(
            lambda r: r.request.method == "POST" and "/refresh" in r.url, timeout=20_000
        ) as ri:
            self.page.get_by_role("button", name="Refresh AI insights").click()
        assert ri.value.status == 200, ri.value.text()

    def expect_ai_disclaimer(self) -> None:
        expect(self.page.get_by_text(AI_DISCLAIMER, exact=False)).to_be_visible(timeout=20_000)

    def download_csv(self) -> str:
        with self.page.expect_download(timeout=20_000) as di:
            self.page.get_by_role("button", name="Export CSV").click()
        return di.value.suggested_filename

    def start_featured_checkout(self) -> str:
        """Click the first boost SKU; return provider_order_id from the checkout response."""
        btn = self.page.get_by_role("button", name=re.compile("Boost this listing", re.I)).first
        expect(btn).to_be_visible(timeout=20_000)
        with self.page.expect_response(
            lambda r: r.request.method == "POST" and "/payments/featured/checkout" in r.url,
            timeout=20_000,
        ) as ri:
            btn.click()
        assert ri.value.status == 200, ri.value.text()
        return ri.value.json()["provider_order_id"]

    def reply_to_first_review(self, body: str) -> None:
        self.page.get_by_role("button", name="Reply as business").first.click()
        box = self.page.get_by_placeholder("Write a response to this review")
        expect(box).to_be_visible()
        box.fill(body)
        with self.page.expect_response(
            lambda r: r.request.method == "POST" and "/reply" in r.url, timeout=20_000
        ) as ri:
            self.page.get_by_role("button", name="Post reply").click()
        assert ri.value.status == 201, ri.value.text()
        expect(self.page.get_by_text(body, exact=False)).to_be_visible()
