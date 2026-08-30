from __future__ import annotations

import re

from playwright.sync_api import Page, expect


class NewBusinessPage:
    def __init__(self, page: Page) -> None:
        self.page = page

    def goto(self) -> None:
        self.page.goto("/merchant/businesses/new")

    def expect_loaded(self) -> None:
        expect(self.page.get_by_role("heading", name="Register your business")).to_be_visible(
            timeout=20_000
        )
        expect(self.page.get_by_text("New listings start as", exact=False)).to_be_visible()


class EditBusinessPage:
    def __init__(self, page: Page) -> None:
        self.page = page

    def goto(self, business_id: str) -> None:
        self.page.goto(f"/merchant/businesses/{business_id}/edit")

    def expect_loaded(self) -> None:
        expect(self.page.get_by_role("heading", name="Edit business")).to_be_visible(timeout=20_000)

    def change_address_and_save(self, new_address: str) -> None:
        field = self.page.get_by_label("Street address ★", exact=False)
        field.click()
        field.fill(new_address)
        self.page.get_by_role("button", name="Save changes").click()

    def expect_address_otp_prompt(self) -> None:
        expect(self.page.get_by_label("Address verification code")).to_be_visible(timeout=20_000)

    def submit_address_otp(self, code: str) -> None:
        self.page.get_by_label("Address verification code").fill(code)
        with self.page.expect_response(
            lambda r: r.request.method == "PATCH" and re.search(r"/businesses/", r.url),
            timeout=20_000,
        ) as ri:
            self.page.get_by_role("button", name="Verify & save").click()
        assert ri.value.status == 200, ri.value.text()
