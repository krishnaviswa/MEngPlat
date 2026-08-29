from __future__ import annotations

from playwright.sync_api import Page, expect


class CollectPage:
    """Non-gamified collect flow: stars step -> "Continue" -> text step -> button.

    The gamified variant (NEXT_PUBLIC_GAMIFIED_REVIEW) tap-throughs stars->chips->text;
    `variant()` lets a test skip when the flag is flipped from the default.
    """

    def __init__(self, page: Page) -> None:
        self.page = page

    def goto(self, business_ref: str) -> None:
        self.page.goto(f"/collect/{business_ref}")

    def expect_loaded(self) -> None:
        expect(
            self.page.get_by_text("Your review takes", exact=False)
        ).to_be_visible(timeout=20_000)

    def variant(self) -> str:
        if self.page.get_by_role("button", name="Continue →").count():
            return "classic"
        if self.page.get_by_text("How was your experience?", exact=False).count():
            return "classic"
        return "gamified"

    def pick_rating(self, stars: int) -> None:
        self.page.get_by_role("button", name=f"{stars} stars").first.click()

    def continue_to_text(self) -> None:
        self.page.get_by_role("button", name="Continue →").click()
        expect(self.page.get_by_placeholder("Share what made your visit memorable…")).to_be_visible()

    def write_and_submit(self, body: str) -> None:
        self.page.get_by_placeholder("Share what made your visit memorable…").fill(body)

    def expect_done(self) -> None:
        expect(
            self.page.get_by_text("Your review is live", exact=False)
            .or_(self.page.get_by_text("we received your review", exact=False))
        ).to_be_visible(timeout=20_000)
