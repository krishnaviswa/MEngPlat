from __future__ import annotations

from playwright.sync_api import Page, expect

SECTION_HEADINGS = [
    "Categories",
    "Pending businesses",
    "Reported reviews",
    "Support",
    "WhatsApp updates",
    "Payments",
    "Users",
]

SUBPAGES = {
    "/admin/businesses": "All businesses",
    "/admin/reviews": "All reviews",
    "/admin/support": "Support tickets",
    "/admin/business-reports": "Shop reports",
    "/admin/whatsapp": "WhatsApp",
}


class AdminPanelPage:
    def __init__(self, page: Page) -> None:
        self.page = page

    def goto(self) -> None:
        self.page.goto("/admin")

    def expect_loaded(self) -> None:
        expect(self.page.get_by_role("heading", name="Admin Panel")).to_be_visible(timeout=20_000)
        expect(self.page.get_by_role("navigation", name="Admin operations")).to_be_visible()

    def expect_all_sections(self) -> None:
        for h in SECTION_HEADINGS:
            expect(self.page.get_by_role("heading", name=h)).to_be_visible()

    def expect_stat_tiles(self) -> None:
        expect(self.page.get_by_text("Total users", exact=False)).to_be_visible(timeout=20_000)
        expect(self.page.get_by_text("Pending businesses", exact=False)).to_be_visible()

    # --- queue actions, scoped to a row by its (uuid-suffixed) visible text ---

    def _row(self, text: str):
        return self.page.locator("div").filter(has_text=text)

    def start_review_then_approve(self, business_name: str) -> None:
        self.page.goto("/admin")
        row = self._row(business_name).filter(
            has=self.page.get_by_role("button", name="Approve")
        ).last
        row.scroll_into_view_if_needed()
        if row.get_by_role("button", name="Start review").count():
            with self.page.expect_response(
                lambda r: "/start-review" in r.url, timeout=20_000
            ) as ri:
                row.get_by_role("button", name="Start review").click()
            assert ri.value.status == 200, ri.value.text()
        with self.page.expect_response(lambda r: "/approve" in r.url, timeout=20_000) as ri:
            row.get_by_role("button", name="Approve").click()
        assert ri.value.status == 200, ri.value.text()

    def moderate_reported(self, snippet: str, action: str) -> None:
        label = {"hide": "Hide", "restore": "Restore", "remove": "Remove"}[action]
        row = self._row(snippet).filter(
            has=self.page.get_by_role("button", name=label)
        ).last
        row.scroll_into_view_if_needed()
        with self.page.expect_response(
            lambda r: "/moderate" in r.url and f"action={action}" in r.url, timeout=20_000
        ) as ri:
            row.get_by_role("button", name=label).click()
        assert ri.value.status == 200, ri.value.text()

    def toggle_user(self, email: str, expect_label: str) -> None:
        self.page.get_by_label("Search users").fill(email)
        row = self._row(email).filter(
            has=self.page.get_by_role("button", name=expect_label)
        ).last
        expect(row.get_by_role("button", name=expect_label)).to_be_visible(timeout=20_000)
        verb = "suspend" if expect_label == "Suspend" else "reactivate"
        with self.page.expect_response(lambda r: f"/{verb}" in r.url, timeout=20_000) as ri:
            row.get_by_role("button", name=expect_label).click()
        assert ri.value.status == 200, ri.value.text()

    def visit_subpages(self) -> None:
        for path in SUBPAGES:
            self.page.goto(path)
            expect(self.page.get_by_role("link", name="Admin panel")).to_be_visible(timeout=20_000)
