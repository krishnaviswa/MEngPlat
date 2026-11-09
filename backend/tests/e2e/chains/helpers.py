"""S-125 — shared helpers for cross-role workflow chains.

`Wf` owns one browser context per role actor, scans every page it visits with the layout
sentinel (recording findings, never failing fast), and writes a Playwright trace per context.
No fixed sleeps: waits are `expect(...)` or bounded retry loops (`eventually`, `bell_expect`).
"""

from __future__ import annotations

import base64
import json
import re
import time
from pathlib import Path
from urllib.parse import urlparse

import pyotp  # noqa: F401  (kept for parity with LoginPage imports)
from playwright.sync_api import BrowserContext, Locator, Page, expect
from playwright.sync_api import TimeoutError as PlaywrightTimeoutError

from tests.e2e.layout_sentinel import check_layout
from tests.e2e.pages.login import LoginPage
from tests.e2e.session_helpers import inject_session

TRACE_DIR = Path(__file__).resolve().parents[1] / "test-results"

# Seeded demo accounts — backend/scripts/seed.py (TOTP is the demo secret, see services/mfa.py)
ROLE_CREDS = {
    "admin": ("admin@merchanthub.ai", "admin12345ok"),
    "merchant": ("merchant@example.com", "merchant1234"),
    "customer": ("customer@example.com", "customer1234"),
}

_RETRYABLE = (AssertionError, PlaywrightTimeoutError)


# --- role sessions -----------------------------------------------------------------


def login_and_save(browser, context_args: dict, role: str, state_dir: Path) -> Path:
    """The ONE real UI login for a seeded role (credentials -> TOTP), saved as storage_state."""
    email, password = ROLE_CREDS[role]
    path = state_dir / f"{role}.json"
    last: Exception | None = None
    for attempt in range(2):
        context = browser.new_context(**{**context_args, "viewport": {"width": 1280, "height": 800}})
        try:
            page = context.new_page()
            LoginPage(page).login(email, password)
            token = page.evaluate("() => localStorage.getItem('access_token')")
            assert token, f"{role}: login finished but no access_token in localStorage"
            context.storage_state(path=str(path))
            data = json.loads(path.read_text(encoding="utf-8"))
            ls = [kv for o in data.get("origins", []) for kv in o.get("localStorage", [])]
            assert any(kv["name"] == "access_token" for kv in ls), (
                f"{role}: storage_state has no access_token — the frontend origin must match FRONTEND_URL"
            )
            return path
        except _RETRYABLE as exc:  # one retry covers a transient /auth rate limit (login 10/min, verify 5/min)
            last = exc
            if attempt == 0:
                time.sleep(15)  # rate-limit back-off only; not an assertion wait
        finally:
            context.close()
    raise AssertionError(f"{role}: real UI login failed twice (auth limits: login 10/min, totp verify 5/min): {last}")


def _jwt_exp(token: str) -> int:
    payload = token.split(".")[1]
    payload += "=" * (-len(payload) % 4)
    return int(json.loads(base64.urlsafe_b64decode(payload))["exp"])


def _read_tokens(state_path: Path) -> tuple[str, str]:
    data = json.loads(state_path.read_text(encoding="utf-8"))
    ls = {kv["name"]: kv["value"] for o in data.get("origins", []) for kv in o.get("localStorage", [])}
    return ls["access_token"], ls.get("refresh_token", "")


def role_tokens(api, state_path: Path) -> tuple[str, str]:
    """Live (access, refresh) for a role; refreshes + rewrites the state file when < 5 min remain."""
    access, refresh = _read_tokens(state_path)
    if _jwt_exp(access) - time.time() >= 300 or not refresh:
        return access, refresh
    res = api.post(f"auth/refresh?refresh_token={refresh}")
    assert res.status == 200, f"token refresh failed: {res.status} {res.text()}"
    body = res.json()
    data = json.loads(state_path.read_text(encoding="utf-8"))
    for origin in data.get("origins", []):
        for kv in origin.get("localStorage", []):
            if kv["name"] == "access_token":
                kv["value"] = body["access_token"]
            elif kv["name"] == "refresh_token":
                kv["value"] = body["refresh_token"]
    state_path.write_text(json.dumps(data), encoding="utf-8")
    return body["access_token"], body["refresh_token"]


def ensure_merchant_kyc(api, token: str, password: str) -> None:
    """POST /businesses needs a national ID; the seeded merchant may not have one."""
    me = api.me(token)
    if me.national_id_type:
        return
    rt = api.reauth_token(token, password=password)
    res = api.patch(
        f"auth/me?reauth_token={rt}",
        token=token,
        json={"national_id_type": "pan", "national_id_number": "ABCDE1234F"},
    )
    assert res.status == 200, res.text()


def make_approved_business(api, merchant_token: str, admin_token: str, name: str, city: str = "Chennai"):
    from app.schemas import BusinessResponse

    res = api.post(
        "businesses",
        token=merchant_token,
        json={
            "name": name,
            "address": "14 Marina Loop",
            "city": city,
            "country": "IN",
            "phone": "+919876500098",
            "email": "e2e-business@example.com",
        },
    )
    assert res.status == 201, res.text()
    biz = BusinessResponse.model_validate(res.json())
    return api.approve_business(admin_token, biz.id) if biz.status != "approved" else biz


# --- bounded retries ---------------------------------------------------------------


def eventually(step, *, timeout_ms: int = 30_000, chain: str = "", what: str = "") -> None:
    """Call `step()` until it stops raising AssertionError/TimeoutError or the deadline passes."""
    deadline = time.monotonic() + timeout_ms / 1000
    last: Exception | None = None
    while True:
        try:
            step()
            return
        except _RETRYABLE as exc:
            last = exc
            if time.monotonic() > deadline:
                raise AssertionError(f"[{chain}] {what}: still failing after {timeout_ms} ms: {last}") from exc


def bell_expect(
    page: Page,
    *,
    contains: str,
    title: str | None = None,
    unread: bool = True,
    timeout_ms: int = 45_000,
    chain: str = "",
    role: str = "",
) -> None:
    """Wait until the bell shows an (unread) notice whose text contains `contains`.

    The bell polls only the unread COUNT; the list is fetched when the dropdown opens, so each
    attempt reloads, opens the dropdown and looks. One row per (user, scenario) is overwritten
    by later events (customer notices are keyed per review / shop, S-126), so callers pass a per-run
    unique name in `contains` — never assert counts.
    """
    deadline = time.monotonic() + timeout_ms / 1000
    last: Exception | None = None
    while True:
        try:
            page.reload()
            bell = page.get_by_role("button", name="Notifications")
            expect(bell).to_be_visible(timeout=20_000)
            bell.click()
            item = page.locator("ul li button").filter(has_text=contains)
            if title:
                item = item.filter(has_text=title)
            expect(item.first).to_be_visible(timeout=4_000)
            if unread:
                expect(item.first).not_to_have_class(re.compile(r"opacity-70"), timeout=2_000)
            return
        except _RETRYABLE as exc:
            last = exc
            if time.monotonic() > deadline:
                try:
                    seen = page.locator("ul li button").all_inner_texts()
                except Exception:  # noqa: BLE001
                    seen = []
                raise AssertionError(
                    f"[{chain}] expected an unread {title or 'any'!r} notice containing {contains!r} "
                    f"on the {role or 'actor'} bell; saw: {seen}; last error: {last}"
                ) from exc


def select_business(page: Page, business_id: str) -> None:
    """Merchants with several shops get a 'Your businesses' <select>; pick ours."""
    sel = page.get_by_label("Your businesses")
    if sel.count():
        sel.select_option(value=str(business_id))


# --- the per-test actor/scan helper ---------------------------------------------------


class Wf:
    def __init__(self, *, chain_id, test_name, browser, context_args, api, role_state, frontend_url):
        self.chain_id = chain_id
        self.test_name = test_name
        self._browser = browser
        self._context_args = context_args
        self._api = api
        self._role_state = role_state
        self.frontend_url = frontend_url
        self.findings: list[dict] = []
        self.visited: set[str] = set()
        self.scanned: set[str] = set()
        self._contexts: list[tuple[str, BrowserContext]] = []

    # -- contexts ---------------------------------------------------------------------
    def _new_page(self, label: str, **ctx_kwargs) -> Page:
        context = self._browser.new_context(
            **{**self._context_args, "viewport": {"width": 1280, "height": 800}, **ctx_kwargs}
        )
        context.tracing.start(screenshots=True, snapshots=True, sources=True)
        self._contexts.append((f"{label}-{len(self._contexts) + 1}", context))
        page = context.new_page()
        page.on(
            "framenavigated",
            lambda frame: self.visited.add(urlparse(frame.url).path)
            if frame == page.main_frame and frame.url.startswith("http")
            else None,
        )
        return page

    def token(self, role: str) -> str:
        return role_tokens(self._api, self._role_state(role))[0]

    def actor(self, role: str) -> Page:
        state = self._role_state(role)
        role_tokens(self._api, state)  # refresh the saved pair first if it is about to expire
        return self._new_page(role, storage_state=str(state))

    def anon(self) -> Page:
        return self._new_page("anon")

    def session_actor(self, access: str, refresh: str | None) -> Page:
        page = self._new_page("session")
        inject_session(page, self.frontend_url, access, refresh)
        return page

    def skip_scan(self, path: str) -> None:
        """Mark a page as intentionally unscanned (gap tests only touch it to assert absence)."""
        self.scanned.add(path)

    # -- visiting + scanning ------------------------------------------------------------
    def visit(self, page: Page, path: str, *, ready: Locator, label: str = "") -> None:
        page.goto(path)
        expect(ready).to_be_visible(timeout=20_000)
        try:  # best effort only — never relied upon, never unbounded
            page.wait_for_load_state("networkidle", timeout=5_000)
        except PlaywrightTimeoutError:
            pass
        self.scan(page, label or path)

    def scan(self, page: Page, label: str) -> None:
        page.keyboard.press("Escape")  # never scan with an overlay (bell menu, modal) open
        found = check_layout(page, label=label)
        for f in found:
            f["chain"] = self.chain_id
        self.findings.extend(found)
        self.scanned.add(urlparse(page.url).path)

    # -- teardown ---------------------------------------------------------------------------
    def close(self) -> None:
        TRACE_DIR.mkdir(parents=True, exist_ok=True)
        for label, context in self._contexts:
            try:
                context.tracing.stop(path=str(TRACE_DIR / f"{self.test_name}-{label}.zip"))
            except Exception:  # noqa: BLE001
                pass
            try:
                context.close()
            except Exception:  # noqa: BLE001
                pass
