from __future__ import annotations

from playwright.sync_api import Page, expect


class ForgotPasswordPage:
    def __init__(self, page: Page) -> None:
        self.page = page

    def goto(self) -> None:
        self.page.goto("/forgot-password")

    def expect_loaded(self) -> None:
        expect(self.page.get_by_role("heading", name="Forgot password")).to_be_visible()
        expect(self.page.get_by_placeholder("Email")).to_be_visible()

    def expect_confirmation(self) -> None:
        expect(self.page.get_by_role("heading", name="Check your email")).to_be_visible()


class ResetPasswordPage:
    def __init__(self, page: Page) -> None:
        self.page = page

    def goto(self, token: str) -> None:
        self.page.goto(f"/reset-password?token={token}")

    def expect_loaded(self) -> None:
        expect(self.page.get_by_role("heading", name="Reset password")).to_be_visible()

    def expect_invalid_link(self) -> None:
        expect(self.page.get_by_role("heading", name="Invalid reset link")).to_be_visible()
