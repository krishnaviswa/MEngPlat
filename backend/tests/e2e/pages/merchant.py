import re

from playwright.sync_api import Page, expect


class MerchantDashboardPage:
    def __init__(self, page: Page) -> None:
        self.page = page

    def goto(self) -> None:
        self.page.goto("/merchant/dashboard")

    def expect_empty(self) -> None:
        expect(self.page.get_by_text("No business yet")).to_be_visible()
        expect(self.page.get_by_role("link", name="Create your business")).to_be_visible()

    def expect_pending(self) -> None:
        expect(self.page.get_by_text("Awaiting approval")).to_be_visible()


class NewBusinessPage:
    def __init__(self, page: Page) -> None:
        self.page = page

    def goto(self) -> None:
        self.page.goto("/merchant/businesses/new")

    def submit(self, *, name: str, address: str, city: str) -> None:
        expect(self.page.get_by_text("New listings start as")).to_be_visible()
        self.page.get_by_label("Business name *").fill(name)
        self.page.get_by_label("Street address *").fill(address)
        self.page.get_by_label("City *").fill(city)
        self.page.get_by_role("button", name="Submit for approval").click()
        expect(self.page).to_have_url(re.compile(r"/merchant/dashboard"), timeout=20_000)
