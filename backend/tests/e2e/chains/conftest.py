"""S-125 — fixtures and hooks for cross-role workflow chains (opt-in: E2E=1 via the parent conftest)."""

from __future__ import annotations

import re
from pathlib import Path

import pytest

from tests.e2e.chains import summary as wf_summary
from tests.e2e.chains.helpers import ROLE_CREDS, Wf, ensure_merchant_kyc, login_and_save, role_tokens

_CHAIN_FILE = re.compile(r"test_(wf_[a-z_]+)\.py$")


def _chain_id(item) -> str | None:
    m = _CHAIN_FILE.search(Path(str(item.path)).name)
    return m.group(1).replace("_", "-") if m else None


# --- hooks ---------------------------------------------------------------------------------


@pytest.hookimpl(hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """A chain that passed functionally still FAILS if the sentinel recorded layout findings."""
    outcome = yield
    rep = outcome.get_result()
    if rep.when != "call" or not rep.passed:
        return
    wf = getattr(item, "funcargs", {}).get("wf")
    if wf is None or not wf.findings:
        return
    lines = [f"functional steps passed; {len(wf.findings)} layout finding(s)"]
    for f in wf.findings:
        lines.append(
            f"[{f['chain']}] layout: {f['url']} @{f['width']}px {f['rule']}: {f['detail']}"
            + (f" ({f['label']})" if f.get("label") else "")
        )
    rep.outcome = "failed"
    rep.longrepr = "\n".join(lines)
    rep.wf_layout_flip = len(wf.findings)


def pytest_runtest_logreport(report):
    chain = _chain_id_from_nodeid(report.nodeid)
    if chain is None:
        return
    name = report.nodeid.split("::")[-1]
    wf_summary.REGISTRY.add_report(chain, name, report)


def _chain_id_from_nodeid(nodeid: str) -> str | None:
    m = _CHAIN_FILE.search(nodeid.split("::")[0].replace("\\", "/").split("/")[-1])
    return m.group(1).replace("_", "-") if m else None


def pytest_sessionfinish(session, exitstatus):
    wf_summary.REGISTRY.write()


# --- fixtures --------------------------------------------------------------------------------


@pytest.fixture(scope="session")
def role_state(browser, browser_context_args, tmp_path_factory):
    """Lazy per-role storage_state path: each seeded role does ONE real UI login per run."""
    cache: dict[str, Path] = {}
    state_dir = tmp_path_factory.mktemp("wf-state")  # outside the repo and the uploaded artifacts

    def get(role: str) -> Path:
        if role not in cache:
            cache[role] = login_and_save(browser, browser_context_args, role, state_dir)
        return cache[role]

    return get


@pytest.fixture(scope="session")
def merchant_ready(api, role_state):
    state = role_state("merchant")
    token, _ = role_tokens(api, state)
    ensure_merchant_kyc(api, token, ROLE_CREDS["merchant"][1])
    return True


@pytest.fixture
def wf(request, browser, browser_context_args, api, role_state, frontend_url):
    chain_id = _chain_id(request.node) or "wf-unknown"
    helper = Wf(
        chain_id=chain_id,
        test_name=re.sub(r"[^A-Za-z0-9_.-]", "_", request.node.name),
        browser=browser,
        context_args=browser_context_args,
        api=api,
        role_state=role_state,
        frontend_url=frontend_url,
    )
    yield helper
    helper.close()
    wf_summary.REGISTRY.add_findings(chain_id, helper.findings)
    for path in sorted(helper.visited - helper.scanned):
        wf_summary.REGISTRY.add_warning(f"`{chain_id}`: page visited but not scanned: `{path}`")
