from __future__ import annotations

import re

from playwright.sync_api import Page, expect


class SearchPage:
    def __init__(self, page: Page) -> None:
        self.page = page

    def goto(self, query: str = "") -> None:
        self.page.goto(f"/search?q={query}" if query else "/search")

    def expect_loaded(self) -> None:
        expect(self.page.get_by_role("heading", name="Filters")).to_be_visible()

    def expect_results_for_city(self, city: str) -> None:
        expect(self.page).to_have_url(re.compile(rf"/search\?.*city={city}", re.I))
