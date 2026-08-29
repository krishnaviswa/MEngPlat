from __future__ import annotations

from playwright.sync_api import Page, expect


class ProfilePage:
    def __init__(self, page: Page) -> None:
        self.page = page

    def goto(self) -> None:
        self.page.goto("/profile")

    def expect_loaded(self) -> None:
        expect(self.page.get_by_role("heading", name="Profile")).to_be_visible(timeout=20_000)
        expect(self.page.locator("#full_name")).to_be_visible()

    def expect_saved(self) -> None:
        expect(self.page.get_by_text("Profile updated.", exact=False)).to_be_visible(timeout=20_000)

    def upload_avatar(self, path: str) -> None:
        # The visible control is a button; the real <input type=file> is hidden.
        with self.page.expect_response(
            lambda r: r.request.method == "POST" and "/auth/me/avatar" in r.url, timeout=20_000
        ) as ri:
            self.page.locator('input[type="file"]').set_input_files(path)
        assert ri.value.status == 200, ri.value.text()

    def email_field_is_readonly(self) -> bool:
        # S-124 note: /profile has no email edit control — "Email changes aren't
        # supported yet." The reauth step-up is covered by the merchant journey.
        return self.page.get_by_text("Email changes aren't supported yet", exact=False).count() > 0
