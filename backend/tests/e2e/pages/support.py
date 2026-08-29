from __future__ import annotations

from playwright.sync_api import Page, expect


class SupportPage:
    def __init__(self, page: Page) -> None:
        self.page = page

    def goto(self) -> None:
        self.page.goto("/support")

    def expect_loaded(self) -> None:
        expect(self.page.get_by_label("Name")).to_be_visible()
        expect(self.page.get_by_label("Issue")).to_be_visible()
        expect(self.page.get_by_role("button", name="Submit")).to_be_visible()

    def expect_submitted(self) -> None:
        expect(self.page.get_by_text("Ticket submitted", exact=False)).to_be_visible()
