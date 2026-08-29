"""Playwright e2e opt-in fixtures (Compose). Skipped unless E2E=1."""

from __future__ import annotations

import os
from pathlib import Path

import pytest

from tests.e2e import catalog_coverage
from tests.e2e.api_client import PASSWORD, Api
from tests.e2e.form_data import SAMPLE_IMAGE, SAMPLE_PNG_BYTES, unique_email
from tests.e2e.human import HumanForm
from tests.e2e.pages.login import LoginPage

E2E_ENABLED = os.environ.get("E2E") == "1"
E2E_FULL = os.environ.get("E2E_FULL") == "1"
FRONTEND_URL = os.environ.get("FRONTEND_URL", "http://localhost:3000").rstrip("/")
API_URL = os.environ.get("API_URL", "http://localhost:8000/api/v1").rstrip("/")
TRACE_DIR = Path(__file__).resolve().parent / "test-results"


def pytest_collection_modifyitems(config: pytest.Config, items: list[pytest.Item]) -> None:
    markexpr = config.getoption("markexpr") or ""
    if E2E_ENABLED or "e2e" in markexpr:
        return
    skip = pytest.mark.skip(reason="e2e opt-in: set E2E=1 with Compose up (frontend :3000, API :8000)")
    for item in items:
        path = Path(str(item.path if hasattr(item, "path") else item.fspath))
        if "e2e" in path.parts:
            item.add_marker(skip)


@pytest.fixture(scope="session")
def frontend_url() -> str:
    return FRONTEND_URL


@pytest.fixture(scope="session")
def api_url() -> str:
    return API_URL


@pytest.fixture(scope="session")
def browser_context_args(browser_context_args: dict) -> dict:
    return {**browser_context_args, "base_url": FRONTEND_URL}


@pytest.fixture(scope="session")
def api(playwright, api_url: str):
    client = Api(playwright, api_url)
    yield client
    client.dispose()


@pytest.fixture(autouse=True)
def e2e_trace(request: pytest.FixtureRequest):
    if not E2E_ENABLED:
        yield
        return
    if "page" not in getattr(request, "fixturenames", ()):
        yield
        return
    context = request.getfixturevalue("context")
    TRACE_DIR.mkdir(parents=True, exist_ok=True)
    context.tracing.start(screenshots=True, snapshots=True, sources=True)
    yield
    dest = TRACE_DIR / f"{request.node.name}.zip"
    context.tracing.stop(path=str(dest))


# --- S-124 additive fixtures (do NOT touch the collection gate or e2e_trace) ---


@pytest.fixture(scope="session")
def browser_type_launch_args(browser_type_launch_args: dict) -> dict:
    slowmo = int(os.environ.get("E2E_SLOWMO_MS", "0"))
    if slowmo:
        return {**browser_type_launch_args, "slow_mo": slowmo}
    return browser_type_launch_args


@pytest.fixture(scope="session", autouse=True)
def _e2e_assets() -> None:
    if not E2E_ENABLED:
        return
    SAMPLE_IMAGE.parent.mkdir(parents=True, exist_ok=True)
    if not SAMPLE_IMAGE.exists():
        SAMPLE_IMAGE.write_bytes(SAMPLE_PNG_BYTES)


@pytest.fixture
def human():
    def _make(page, scope=None) -> HumanForm:
        page.on("dialog", lambda d: d.accept())
        return HumanForm(page, scope)

    return _make


@pytest.fixture
def record_form():
    return catalog_coverage.record


def _register_and_login(api: Api, page, role: str) -> dict:
    """Register via API, then log in through the browser (first login enrolls TOTP
    with a fresh secret), and lift the real session tokens straight out of
    localStorage — a second API login can't reproduce the UI's random TOTP secret.
    """
    email = unique_email(role)
    user = api.register(email, role=role, password=PASSWORD)
    LoginPage(page).login(email, PASSWORD)
    HumanForm(page).wait_for_token()
    access = page.evaluate("() => window.localStorage.getItem('access_token')")
    refresh = page.evaluate("() => window.localStorage.getItem('refresh_token')")
    assert access, "no access_token in localStorage after login"
    return {"page": page, "email": email, "user": user,
            "access": access, "refresh": refresh}


@pytest.fixture
def fresh_customer(api: Api, page) -> dict:
    return _register_and_login(api, page, "customer")


@pytest.fixture
def fresh_merchant(api: Api, page) -> dict:
    return _register_and_login(api, page, "merchant")


@pytest.fixture(scope="session")
def admin_tokens(api: Api):
    tok = api.seed_admin_tokens()
    if tok is None:
        pytest.skip("seeded admin unavailable (seed not run / MFA changed)")
    return tok


@pytest.fixture(scope="session")
def seeded_business(api: Api):
    businesses = [b for b in api.list_businesses() if b.status == "approved"]
    if not businesses:
        pytest.skip("no approved seeded business available")
    return businesses[0]


@pytest.fixture(scope="session", autouse=True)
def _catalog_coverage_check():
    yield
    # The coverage set is process-local: under xdist each worker sees only its
    # slice, so the guard only makes sense single-process (web-e2e.yml runs it so).
    if E2E_ENABLED and E2E_FULL and not os.environ.get("PYTEST_XDIST_WORKER"):
        catalog_coverage.assert_every_form_exercised()
