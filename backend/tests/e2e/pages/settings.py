from __future__ import annotations

import re

from playwright.sync_api import Page, expect


class SettingsPage:
    def __init__(self, page: Page) -> None:
        self.page = page

    def goto(self) -> None:
        self.page.goto("/settings")

    def expect_loaded(self) -> None:
        expect(self.page.get_by_role("heading", name="Settings")).to_be_visible(timeout=20_000)
        expect(self.page.get_by_role("button", name="Log out")).to_be_visible()

    def logout(self) -> None:
        with self.page.expect_response(
            lambda r: r.request.method == "POST" and "/auth/logout" in r.url, timeout=20_000
        ):
            self.page.get_by_role("button", name="Log out").click()
        expect(self.page).to_have_url(re.compile(r"/$"), timeout=20_000)
