from playwright.sync_api import Page, expect


class AdminPage:
    def __init__(self, page: Page) -> None:
        self.page = page

    def goto(self) -> None:
        self.page.goto("/admin")

    def expect_loaded(self) -> None:
        expect(self.page.get_by_role("heading", name="Admin Panel")).to_be_visible()
        expect(self.page.get_by_role("navigation", name="Admin operations")).to_be_visible()
        expect(self.page.get_by_text("Total users")).to_be_visible()
        expect(self.page.get_by_role("heading", name="Pending businesses")).to_be_visible()

    def approve_named(self, name: str) -> None:
        # exact=True so "Approve" doesn't also match "Approve boost"; .last picks
        # the innermost wrapper div containing this business's row.
        row = (
            self.page.locator("div")
            .filter(has_text=name)
            .filter(has=self.page.get_by_role("button", name="Approve", exact=True))
            .last
        )
        btn = row.get_by_role("button", name="Approve", exact=True)
        expect(btn).to_be_visible(timeout=15_000)
        btn.click()
        expect(btn).to_have_count(0, timeout=15_000)

    def hide_first_reported(self) -> None:
        self.page.get_by_role("button", name="Hide").first.click()
