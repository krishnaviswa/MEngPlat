from playwright.sync_api import Page, expect


class HomePage:
    """SSR home (`/`). Hero copy must match `frontend/src/app/page.tsx`."""

    HERO_HEADING = "Local businesses, reviewed with clarity"

    def __init__(self, page: Page) -> None:
        self.page = page

    def goto(self) -> None:
        self.page.goto("/")

    def expect_hero(self) -> None:
        expect(self.page.get_by_role("heading", name=self.HERO_HEADING)).to_be_visible()

    def explore_listings(self) -> None:
        self.page.get_by_role("link", name="Explore listings").click()
