from __future__ import annotations

import pyotp
from playwright.sync_api import Page, expect

from app.services.mfa import DEMO_TOTP_SECRET


class LoginPage:
    def __init__(self, page: Page) -> None:
        self.page = page

    def goto(self) -> None:
        self.page.goto("/login")

    def expect_form(self) -> None:
        expect(self.page.get_by_placeholder("Email")).to_be_visible()
        expect(self.page.get_by_placeholder("Password")).to_be_visible()
        expect(self.page.get_by_role("button", name="Sign in")).to_be_visible()

    def submit_credentials(self, email: str, password: str) -> None:
        self.page.get_by_placeholder("Email").fill(email)
        self.page.get_by_placeholder("Password").fill(password)
        self.page.get_by_role("button", name="Sign in").click()

    def complete_totp(self) -> None:
        enroll = self.page.get_by_role("heading", name="Set up authenticator")
        verify = self.page.get_by_role("heading", name="Authenticator code")
        expect(enroll.or_(verify)).to_be_visible(timeout=15_000)
        if enroll.is_visible():
            secret_el = self.page.locator("p.font-mono")
            expect(secret_el).to_be_visible()
            secret = secret_el.inner_text().strip()
            self.page.get_by_placeholder("6-digit code").fill(pyotp.TOTP(secret).now())
            self.page.get_by_role("button", name="Confirm and sign in").click()
            return
        self.page.get_by_placeholder("6-digit code").fill(pyotp.TOTP(DEMO_TOTP_SECRET).now())
        self.page.get_by_role("button", name="Verify and sign in").click()

    def login(self, email: str, password: str) -> None:
        self.goto()
        self.submit_credentials(email, password)
        self.complete_totp()
        self.page.wait_for_url(lambda url: "/login" not in url, timeout=20_000)
