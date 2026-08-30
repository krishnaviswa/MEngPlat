"""S-124 — keyboard-centric human driver.

`HumanForm` types predefined values into a form the way a person would (per
keystroke, Tab between fields) and submits by pressing Enter where the real
`<form onSubmit>` supports it — falling back to the labelled button only for
textarea-terminated forms and button-only widgets, and in those cases pressing
Enter first as a negative check.

No `time.sleep` anywhere: every wait is `expect()`, `expect_response`,
`expect_download`, `wait_for_function`, or `wait_for_url`.
"""

from __future__ import annotations

import os
import re
from typing import Callable

from playwright.sync_api import Locator, Page, expect

from tests.e2e.form_data import FieldValue, FormSpec
from tests.e2e.oracles import SCHEMA_ORACLES

TYPE_DELAY = int(os.environ.get("E2E_TYPE_DELAY_MS", "35"))
SLOWMO_MS = int(os.environ.get("E2E_SLOWMO_MS", "0"))

_API_METHODS = ("POST", "PATCH", "PUT", "DELETE")


class HumanForm:
    def __init__(self, page: Page, scope: Locator | None = None) -> None:
        self.page = page
        self.scope = scope if scope is not None else page.locator("body")

    # --- locator resolution ------------------------------------------------

    def locate(self, f: FieldValue) -> Locator:
        if f.kind == "star":
            # readonly RatingWidgets share the "N stars" aria-label but are disabled.
            return self.page.locator(
                f'button[aria-label="{f.name}"]:not([disabled])'
            ).first
        if f.by in ("label", "aria"):
            # get_by_label also resolves aria-label; works for password inputs,
            # which get_by_role("textbox") does not match.
            return self.page.get_by_label(f.name, exact=False)
        if f.by == "placeholder":
            return self.page.get_by_placeholder(f.name, exact=False)
        if f.by == "text":
            return self.page.get_by_text(f.name, exact=False)
        if f.by == "id":
            return self.page.locator(f"#{f.name}")
        if f.by == "name":
            return self.page.locator(f'[name="{f.name}"]')
        if f.by == "role":
            return self.page.get_by_role(f.role, name=f.name)
        raise ValueError(f"unknown FieldValue.by={f.by!r}")

    # --- primitives ------------------------------------------------------

    def fill(self, f: FieldValue, subs: dict[str, str] | None = None) -> None:
        value = f.value
        if isinstance(value, str) and subs:
            value = value.format(**subs)
        loc = self.locate(f)
        if f.kind in ("text", "textarea", "otp"):
            loc.click()  # Playwright auto-scrolls on click/fill
            loc.fill("")  # clear any prefill / default value
            self.page.keyboard.type(str(value), delay=TYPE_DELAY)
        elif f.kind == "select":
            loc.select_option(str(value))
        elif f.kind == "checkbox":
            loc.set_checked(bool(value))
        elif f.kind == "file":
            loc.set_input_files(str(value))
        elif f.kind == "star":
            loc.click()
        else:
            raise ValueError(f"unknown FieldValue.kind={f.kind!r}")

    def tab(self) -> None:
        self.page.keyboard.press("Tab")

    def press_enter_here(self) -> None:
        self.page.keyboard.press("Enter")

    # --- submission -----------------------------------------------------

    def _last_text_field(self, spec: FormSpec) -> FieldValue | None:
        for f in reversed(spec.fields):
            if f.kind in ("text", "otp"):
                return f
        return None

    def _api_predicate(self, spec: FormSpec) -> Callable[[object], bool] | None:
        api = spec.success.get("api")
        if not api:
            return None
        method, path_rx, _status, _schema = api
        pat = re.compile(path_rx)

        def _pred(resp) -> bool:  # playwright Response
            return resp.request.method == method and bool(pat.search(resp.url))

        return _pred

    def submit(self, spec: FormSpec, subs: dict[str, str] | None = None) -> None:
        pred = self._api_predicate(spec)
        if spec.enter_submits:
            last = self._last_text_field(spec)
            if last is not None:
                self.locate(last).click()
            if pred is not None:
                with self.page.expect_response(pred, timeout=20_000) as ri:
                    self.press_enter_here()
                self._check_api(spec, ri.value)
            else:
                self.press_enter_here()
            return

        # enter_submits is False (AC3): Enter must be inert; the labelled button
        # does the work. Count matching requests across BOTH actions — Enter must
        # contribute none, so the button's click is the only one seen.
        url_before = self.page.url
        seen: list[str] = []
        api = spec.success.get("api")
        want_method = api[0] if api else None
        want_pat = re.compile(api[1]) if api else None

        def _watch(req) -> None:
            if want_pat is not None:
                if req.method == want_method and want_pat.search(req.url):
                    seen.append(req.url)
            elif req.method in _API_METHODS and "/api/" in req.url:
                seen.append(req.url)

        self.page.on("request", _watch)
        try:
            self.press_enter_here()
            expect(self.page).to_have_url(url_before)  # auto-retries: no premature nav
            assert not seen, f"Enter should be inert on {spec.form_key!r} but fired: {seen}"
            button = self.page.get_by_role("button", name=spec.submit_label)
            if pred is not None:
                with self.page.expect_response(pred, timeout=20_000) as ri:
                    button.click()
                self._check_api(spec, ri.value)
            else:
                button.click()
        finally:
            self.page.remove_listener("request", _watch)

    def _check_api(self, spec: FormSpec, resp) -> None:
        method, _path, want_status, schema = spec.success["api"]
        assert resp.status == want_status, (
            f"{method} {resp.url} -> {resp.status} (wanted {want_status}): {resp.text()[:400]}"
        )
        if schema and schema in SCHEMA_ORACLES:
            SCHEMA_ORACLES[schema](resp.json())

    def settle(self, spec: FormSpec) -> None:
        url_rx = spec.success.get("url")
        if url_rx:
            expect(self.page).to_have_url(re.compile(url_rx), timeout=20_000)
        text = spec.success.get("text")
        if text:
            expect(self.page.get_by_text(text, exact=False).first).to_be_visible(timeout=20_000)

    def fill_and_submit(self, spec: FormSpec, subs: dict[str, str] | None = None) -> None:
        for f in spec.fields:
            self.fill(f, subs)
            if f.kind in ("text",):
                self.tab()
        self.submit(spec, subs)
        self.settle(spec)

    # --- validation / auth helpers ------------------------------------

    def expect_validation(self, message_rx: str, api_path_rx: str) -> None:
        """AC4: assert an inline error shows and no matching mutating request fired."""
        pat = re.compile(api_path_rx)
        fired: list[str] = []

        def _watch(req) -> None:
            if req.method in _API_METHODS and pat.search(req.url):
                fired.append(req.url)

        self.page.on("request", _watch)
        try:
            self.press_enter_here()
            expect(self.page.get_by_text(re.compile(message_rx, re.I)).first).to_be_visible(
                timeout=10_000
            )
        finally:
            self.page.remove_listener("request", _watch)
        assert not fired, f"no request expected, but saw: {fired}"

    def wait_for_token(self) -> None:
        self.page.wait_for_function(
            "() => !!window.localStorage.getItem('access_token')", timeout=20_000
        )
