# TP-S-125: Cross-role workflow chains + layout sentinel — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-125 |
| **Author** | Tester |
| **Date** | 2026-11-08 |

---

## Scope

Test tooling only (no product code). Verifies:

- the layout sentinel (`backend/tests/e2e/layout_sentinel.py`) and its static-HTML self-test;
- the job-summary classifier (`chains/summary.py`) and its unit test;
- the additive gate change in `tests/e2e/conftest.py` (AC 7 intent: every pre-existing test still skipped by default);
- collection and static review of the 8 chains (10 test functions) in `tests/e2e/chains/`;
- the manual workflow `.github/workflows/web-workflows.yml` (triggers, inputs, target mapping, `if: always()` steps, `down -v`, artifacts);
- the README §10 / §11 / §14 edits.

Not verifiable on this machine (no Docker/Compose, no GitHub): chains executing against the real app, GitHub form / job-summary rendering, artifacts, `down -v`, the real `suite=all` and `suite=layout` dispatches required by the PM DoD. These are planned as **GH-xxx** manual items and reported as "Not run" until a maintainer dispatches them.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Sentinel self-test | pytest + Playwright Chromium on static HTML | Detects 4 defect classes at 375/768/1280; clean page = 0 findings; viewport restored |
| Summary unit test | pytest (no browser) | PASS / FAIL / KNOWN-GAP / SKIPPED classification, strict-XPASS message, layout table |
| Summary probe | throwaway pytest dir (scratchpad, not committed) | Same classifier fed by real pytest report objects, not fakes |
| Gate regression | `pytest tests/e2e` with `E2E` unset | All pre-existing e2e + chains skipped; only the 3 self-tests run |
| Collection | `E2E=1 pytest tests/e2e/chains --collect-only` | 10 chain tests, no import errors |
| Static review | YAML parse, shell snippet replay, grep of `frontend/src` + `backend/app` | Workflow shape, selectors, notification copy, sleeps |
| Integration (manual, GitHub) | `workflow_dispatch` | Chains vs real Compose stack, summary, artifacts, teardown |

---

## AC to planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Static YAML inspection + `git status` (no hook files) | M-001 |
| 2 | Static YAML inspection; form render on GitHub | M-002, GH-001 |
| 3 | Replay of the `Resolve target` shell case; real run | M-003, GH-002 |
| 4 | Static (`if: always()` + `down -v`); real run incl. a failing run | M-004, GH-002 |
| 5 | Static (3 upload steps); real run | M-005, GH-002 |
| 6 | Automated classifier test + real-pytest probe; GitHub rendering | `tests/test_workflow_summary.py` (8 tests), M-006, GH-002 |
| 7 | Automated gate check + git diff | M-007 (`pytest tests/e2e` default), `git diff` of `conftest.py` / `web-e2e.yml`; GH-003 for S-124 `suite=all` |
| 8 | Static (seed.py) + real run | M-008, GH-002 |
| 9 | Static review of `role_state` / `login_and_save`; real run | M-009, GH-002 |
| 10 | Static review of `Wf.actor`; real run | M-010, GH-002 |
| 11 | Static review (unique names / uuid markers); real run | M-011, GH-002 |
| 12 | Static grep for sleeps / `networkidle`; real run | M-012, GH-002 |
| 13-17 | Real chain runs (+ collect-only, static selector check) | `chains/test_wf_listing_approval.py`, `test_wf_new_review.py`, `test_wf_featured_boost.py`, `test_wf_suspend.py`, `test_wf_review_moderation.py`; GH-002 |
| 18-20 | Real chain runs (+ collect-only) | `test_wf_review_reply.py` (+`_gap`), `test_wf_shop_edit.py` (+`_gap`), `test_wf_whatsapp_draft.py`; GH-002 |
| 21 | Automated classifier test (strict XPASS) + real-pytest probe | `test_workflow_summary.py::test_strict_xpass_is_a_failure_with_the_removal_message` |
| 22 | Automated | `test_layout_sentinel_selftest.py::test_sentinel_detects_all_four_defects` |
| 23 | Static review of `Wf.visit` / `Wf.scan` per chain; real run | M-013, GH-002 |
| 24 | Automated (finding shape) + real run (failure message path) | `test_sentinel_detects_all_four_defects`; GH-002 |
| 25 | Automated | `test_sentinel_detects_all_four_defects` |
| 26 | Automated | `test_sentinel_clean_page_has_no_findings` |
| 27 | Automated with no stack and `E2E` unset; `suite=layout` mapping | selftest file (3 tests), M-003, GH-004 |
| 28 | Automated render test; GitHub rendering | `test_workflow_summary.py::test_render_has_table_and_layout_section`, GH-002 |
| 29 | README diff review | M-014 |

After tests land, README §11 **Feature to test index** must carry the S-125 row (present: "Cross-role workflow chains + layout sentinel (S-125)"). Default verification: run only those files.

---

## RBAC test cases

S-125 adds no endpoint and no RBAC rule; roles are test actors only. RBAC is exercised indirectly by the chains and is existing coverage elsewhere (`tests/e2e/test_rbac_matrix.py`, backend pytest).

| Case | Role | Expected | Where |
|------|------|----------|-------|
| Suspended user cannot sign in | customer (suspended) | login refused, no `access_token`, "suspend" error | `test_wf_suspend` (GH-002) |
| Each actor uses only its own saved session | admin / merchant / customer | one context per role, never two roles in one context | `Wf.actor` review (M-010) |
| Chains never suspend a seeded account | admin | only a fresh per-run user is suspended, reactivated in `finally` | `test_wf_suspend` review |
| Unauthenticated / wrong-role API 401/403 | n/a | out of scope (no API change) | existing suites |

---

## Edge cases

- Default `pytest` (E2E unset): chains and all S-010 / S-124 tests SKIPPED; self-test (marker `layout_selftest`) still runs.
- Chromium missing: self-test skips unless `LAYOUT_SELFTEST_REQUIRE_BROWSER=1` (workflow sets it).
- `DEBUG` not true: `wf-featured-boost` SKIPPED with reason (not FAIL).
- No seeded WhatsApp drafts (always on fresh Compose): `wf-whatsapp-draft` SKIPPED.
- Known-gap `xfail(strict)` later passes: chain becomes FAIL with "known gap now passes ..." (AC 21).
- Layout finding on an otherwise passing chain: chain flips to FAIL with "functional steps passed; N layout finding(s)".
- Seeded merchant owns many shops: dashboard steps must select the run's business by id.
- Rate limits (login 10/min, TOTP verify 5/min, register 5/min) during the three opening UI logins.
- Bell semantics: one row per (user, scenario), overwritten: oracles must contain the per-run unique business name.

---

## Manual checklist

Local / static (done by Tester without a stack):

- [ ] M-001: `web-workflows.yml` triggers = `workflow_dispatch` only; no hook files changed
- [ ] M-002: `suite` options exactly `all`, 8 chain ids, `layout`; `pytest_args` string input
- [ ] M-003: `Resolve target` mapping for `all`, `layout`, `wf-*`
- [ ] M-004: `down -v` has `if: always()` and runs after artifact steps
- [ ] M-005: `playwright-traces`, pytest log, Compose logs uploaded with `if: always()`
- [ ] M-006: classifier fed by real pytest reports (PASS / FAIL / KNOWN-GAP / SKIPPED / strict XPASS)
- [ ] M-007: `pytest tests/e2e` default run + `git diff` of `conftest.py` and `web-e2e.yml`
- [ ] M-008 to M-012: static review of seed accounts, `role_state`, `Wf.actor`, unique naming, no fixed sleeps
- [ ] M-013: every page visited in each chain goes through `Wf.visit` or `Wf.scan`
- [ ] M-014: README §10 / §11 / §14 edits

GitHub (needs a maintainer dispatch; reported as Not run until done):

- [ ] GH-001: Run workflow form shows branch selector, `suite` dropdown (10 options), `pytest_args`
- [ ] GH-002: `suite=all` run on the feature branch: record URL, per-chain table, layout findings, artifacts present, Compose torn down, all three artifacts downloadable
- [ ] GH-003: S-124 `web-e2e.yml` `suite=all` still green (AC 7, PM DoD)
- [ ] GH-004: `suite=layout` run: no Compose started, self-test passes, summary step prints pytest tail
- [ ] GH-005: one deliberately failing run (e.g. `pytest_args=-k nonexistent` is not enough; use a branch with a broken selector or `-x` on a failing chain) to confirm summary + artifacts + `down -v` still happen on failure
- [ ] GH-006: read the trace zip with `playwright show-trace` for one chain

---

## Environment

- `AI_PROVIDER=mock`, `EMAIL/PAYMENTS/...=mock`, `DEBUG=true` (Compose file)
- Local verification: Windows, Python 3.12.10, pytest 8.3.4, pytest-playwright 0.7.1, Chromium installed, no Docker
- Commands run from `C:\Self Projects\MEngPlat\backend` with `PYTHONPATH=. python -m pytest ... -p no:cacheprovider`
- GitHub: `docker compose up --build`, `web-workflows.yml` dispatch
