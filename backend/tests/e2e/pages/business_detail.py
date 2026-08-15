from playwright.sync_api import Page, expect


class BusinessDetailPage:
    """SSR business profile (`/businesses/{slug}`)."""

    def __init__(self, page: Page) -> None:
        self.page = page

    def expect_name(self, name: str) -> None:
        expect(self.page.get_by_role("heading", level=1, name=name)).to_be_visible()

    def write_review_link(self):
        return self.page.get_by_role("link", name="Write a review")
