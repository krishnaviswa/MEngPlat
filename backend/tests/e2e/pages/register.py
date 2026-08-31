import re

from playwright.sync_api import Page, expect

from tests.e2e.api_client import PASSWORD
from tests.e2e.pages.login import LoginPage


class RegisterPage:
    def __init__(self, page: Page) -> None:
        self.page = page

    def goto(self) -> None:
        self.page.goto("/register")

    def sign_up(self, *, full_name: str, email: str, role: str = "customer") -> None:
        expect(self.page.get_by_role("heading", name="Create account")).to_be_visible()
        self.page.get_by_placeholder("Full name").fill(full_name)
        self.page.get_by_placeholder("Email").fill(email)
        self.page.get_by_placeholder("Password (min 12 chars, include a letter and a digit)").fill(
            PASSWORD
        )
        self.page.get_by_role("combobox", name="Account type").select_option(role)
        # /auth/register is 5/min per IP; a full e2e run can bunch registrations,
        # so re-submit through the rate-limit window instead of failing outright.
        for attempt in range(4):
            self.page.get_by_role("button", name="Sign up").click()
            try:
                expect(self.page).to_have_url(re.compile(r"/login"), timeout=15_000)
                break
            except AssertionError:
                if attempt == 3:
                    raise
                self.page.wait_for_timeout(15_000)  # rate-limit window
        LoginPage(self.page).login(email, PASSWORD)
