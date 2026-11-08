# TR-S-125: Cross-role workflow chains + layout sentinel — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-125 |
| **Author** | Tester |
| **Date** | 2026-11-08 |
| **Recommendation** | Ship with conditions (Pass-with-conditions): merge-ready as tooling, but the slice is NOT acceptance-complete until the GitHub dispatches in "Conditions" are run and recorded |

---

## Summary

**Verdict: Pass-with-conditions.**

Everything that can be proven on a machine with no Docker and no GitHub passes:

- Layout sentinel self-test: 3 / 3 pass (detects all four defect classes at 375 / 768 / 1280, clean page = 0 findings, viewport restored). No stack, no `E2E=1`.
- Summary classifier unit test: 8 / 8 pass. I also fed the same classifier **real pytest report objects** in a throwaway directory (scratchpad, not in the repo): PASS / FAIL / KNOWN-GAP / SKIPPED and the strict-XPASS "known gap now passes - remove xfail and update README §14" message all came out correctly.
- Default `pytest tests/e2e` (E2E unset): `3 passed, 62 skipped`. Every pre-existing S-010 / S-124 test and every chain is SKIPPED; the only tests that run are the 3 self-tests. The `conftest.py` diff is exactly the one early-continue line; `pytest.ini` is exactly +2 markers; `web-e2e.yml` is unmodified; no `app/`, `frontend/`, `mobile/` or hook files in the diff.
- `E2E=1 pytest tests/e2e/chains --collect-only`: 10 tests collected (8 chains, 2 `_gap` tests), no import errors.
- `web-workflows.yml`: triggers are `workflow_dispatch` only; 10 `suite` options exactly as specified; `pytest_args` string input; `pytest_args` passed via `env:`; `if: always()` on summary, Compose logs, three uploads and `docker compose down -v`; `layout` does not start Compose.

**What is NOT proven** (stated plainly): no chain has ever executed against the app. The functional claims of ACs 8-20, the layout sentinel on real pages, the GitHub job summary rendering, artifacts, `down -v`, and the PM DoD requirement of one real `suite=all` and one `suite=layout` dispatch are all **Not run — needs GitHub dispatch**. The 10 chain tests are only collected and statically reviewed.

No blocking defects found. 4 low-severity defects and several unverified-selector risks are listed below.

### Conditions before PM sets `Status: Accepted`

1. Dispatch `web-workflows.yml` with `suite=all` on the feature branch; record run URL, per-chain table, layout findings (as product follow-ups, per PM DoD) in this TR.
2. Dispatch with `suite=layout`; record run URL (expect: no Compose steps, 3 self-tests pass).
3. Confirm S-124 `web-e2e.yml` `suite=all` is still green (AC 7).
4. Fix D1 (README broken command) before merge (one-line doc fix).
5. PM to confirm the AC 7 wording reconciliation (see D5).

---

## AC coverage matrix

Result key: **Pass** = proven by a test I ran or by direct inspection of the artifact the AC describes. **Not run** = needs a real Compose stack and/or a real GitHub dispatch. "Partial" lists which part passed and which part is Not run.

| AC# | Description | Type | Test reference / evidence | Result |
|-----|-------------|------|---------------------------|--------|
| 1 | Only trigger is `workflow_dispatch`; no push/PR/schedule, no deploy step, no hooks | M | YAML parsed: `on` keys = `['workflow_dispatch']`; no deploy step; `git status` shows no `.githooks`/hook file changes (M-001) | **Pass** (static) |
| 2 | Form: branch selector, `suite` choice (exact 10 options), optional free-text pytest args | M | YAML parsed: options = `all`, 8 chain ids, `layout`; `pytest_args` type string, default `""` (M-002). Form rendering on GitHub: GH-001 | **Partial** — definition Pass (static); form render **Not run — needs GitHub dispatch** |
| 3 | Only selected suite runs; `all` = every chain + layout; extra args appended | M | Replayed the `Resolve target` shell `case`: `all` -> `tests/e2e/chains tests/e2e/test_layout_sentinel_selftest.py` stack=1 e2e=1; `layout` -> selftest only stack=0 e2e=empty; `wf-new-review` / `wf-review-reply` -> their files stack=1 (M-003). Run step appends unquoted `$PYTEST_ARGS`. Actual execution: GH-002/GH-004 | **Partial** — mapping Pass (replayed); execution **Not run — needs GitHub dispatch** |
| 4 | Fresh Compose per run; `down -v` on success, failure and cancellation | M | Static: `docker compose up --build -d` on a fresh runner; final step `if: always() && stack == '1'` runs `docker compose down -v` (M-004). Real behaviour incl. a failing run: GH-002, GH-005 | **Not run — needs GitHub dispatch** (static review OK) |
| 5 | Artifacts `playwright-traces`, pytest log, Compose logs on every run | M | Static: three `actions/upload-artifact@v4` steps, `if: always()`, names `playwright-traces`, `workflows-pytest-log`, `compose-logs`; trace path `backend/tests/e2e/test-results/` matches `TRACE_DIR` in `chains/helpers.py` (M-005) | **Not run — needs GitHub dispatch** (static review OK) |
| 6 | Job summary table per chain (id, PASS/FAIL/KNOWN-GAP/SKIPPED, reason), produced even on failure | A + M | `tests/test_workflow_summary.py` (8 tests, all Pass) + real-pytest probe (M-006); `pytest_sessionfinish` writes the file, summary step is `if: always()`. Rendering in `$GITHUB_STEP_SUMMARY`: GH-002 | **Partial** — classifier/markdown Pass; GitHub job-summary rendering **Not run — needs GitHub dispatch** |
| 7 | `web-e2e.yml` unchanged; S-010/S-124 still collect and pass on `suite=all`; default `pytest` skips all e2e, no browser; gate hook and `e2e_trace` untouched | A + M | `git status`: `web-e2e.yml` not modified. `git diff` of `conftest.py` = one added early-continue (`layout_selftest` marker) inside the existing loop; `e2e_trace` untouched. Default `pytest tests/e2e` = `3 passed, 62 skipped`, all pre-existing e2e + chains SKIPPED (M-007). S-124 `suite=all` green: GH-003 | **Partial** — intent Pass (see D5: literal "hook untouched" cannot hold alongside AC 27; 3 self-tests launch Chromium in default runs, skip if Chromium missing); S-124 `suite=all` re-run **Not run — needs GitHub dispatch** |
| 8 | Fixed seeded admin/merchant/customer with known TOTP; no manual setup | M | Static: `seed.py` creates `admin@merchanthub.ai` / `merchant@example.com` / `customer@example.com` with the passwords in `ROLE_CREDS` and calls `enable_demo_totp`; workflow adds "Check the seed ran" (`Seed complete` string exists, `seed.py:359`). Real stack: GH-002 | **Not run — needs GitHub dispatch** (static review OK) |
| 9 | Each role signed in once per run via real login page; `storage_state` saved and reused | M | Static: session-scoped `role_state` factory with dict cache -> `login_and_save` -> `LoginPage.login` -> `context.storage_state(path=tmp dir)`; asserts `access_token` in saved state; state dir is a pytest tmp dir outside repo/artifacts | **Not run — needs GitHub dispatch** (static review OK) |
| 10 | Single pytest test, one browser context per role, each from saved storage_state | M | Static: `Wf.actor(role)` = new context with `storage_state`; `anon()` / `session_actor()` separate contexts; chains never share a context | **Not run — needs GitHub dispatch** (static review OK) |
| 11 | Per-run unique suffix on every created entity; no cross-chain state | M | Static: `unique_name(...)`, `unique_email(...)`, `uuid4` markers in every chain; `wf-suspend` suspends only a fresh user and reactivates in `finally` | **Not run — needs GitHub dispatch** (static review OK) |
| 12 | Cross-role assertions wait and retry to a bounded timeout; no fixed sleeps / bare `networkidle` | M | `grep` of `chains/`, `layout_sentinel.py`, selftest: only `time.sleep(15)` in `login_and_save` (documented login rate-limit back-off, not an assertion wait) and one bounded `wait_for_load_state("networkidle", timeout=5_000)` wrapped in try/except. No `wait_for_timeout`. `bell_expect` / `eventually` use monotonic deadlines. Runtime behaviour: GH-002 | **Not run — needs GitHub dispatch** (static review OK) |
| 13 | `wf-listing-approval`: merchant creates via UI; admin approves; merchant bell unread "Listing approved"; customer sees it | A | `chains/test_wf_listing_approval.py::test_wf_listing_approval` (collected only). Copy verified in `routers/businesses.py:428-429`. Asserts profile page AND search (both) | **Not run — needs GitHub dispatch** |
| 14 | `wf-new-review`: customer N-star review; merchant bell unread "New N-star review"; dashboard lists it | A | `chains/test_wf_new_review.py::test_wf_new_review` (collected only). Copy verified in `routers/reviews.py:211-212` | **Not run — needs GitHub dispatch** |
| 15 | `wf-featured-boost`: payment received, then boost live; SKIPPED if not `DEBUG` | A | `chains/test_wf_featured_boost.py::test_wf_featured_boost` (collected only). Titles verified in `payments/featured.py:100,137`; DEBUG gate is `pytest.skip` on 404 "Not found" | **Not run — needs GitHub dispatch** |
| 16 | `wf-suspend`: suspended customer cannot log in | A | `chains/test_wf_suspend.py::test_wf_suspend` (collected only). Backend detail "Account suspended" (`routers/auth.py:189`) is forwarded by `apiFetch` (`api.ts:322-323`) and shown by `LoginForm` (`setError(err.message)`) | **Not run — needs GitHub dispatch** |
| 17 | `wf-review-moderation`: report then hide; public page no longer shows review | A | `chains/test_wf_review_moderation.py::test_wf_review_moderation` (collected only) | **Not run — needs GitHub dispatch** |
| 18 | `wf-review-reply`: reply visible publicly (must pass); customer-notified assertion = KNOWN-GAP | A | `chains/test_wf_review_reply.py::test_wf_review_reply` and `::test_wf_review_reply_gap` (`xfail(strict=True, raises=AssertionError, reason="customer is not notified of replies (README §14)")`). Collected only; gap -> KNOWN-GAP mapping proven by probe | **Not run — needs GitHub dispatch** (KNOWN-GAP expected by design, not a failure) |
| 19 | `wf-shop-edit`: edit visible publicly (must pass); notify assertion = KNOWN-GAP | A | `chains/test_wf_shop_edit.py::test_wf_shop_edit` and `::test_wf_shop_edit_gap` (`reason="business edits notify nobody (README §14)"`). Collected only | **Not run — needs GitHub dispatch** (KNOWN-GAP expected by design) |
| 20 | `wf-whatsapp-draft`: approve draft -> merchant bell "applied"; SKIPPED with reason if no drafts | A | `chains/test_wf_whatsapp_draft.py::test_wf_whatsapp_draft` (collected only). Title verified in `whatsapp_ingest_service.py:155`. Expected result on a fresh stack: SKIPPED (seed.py creates no drafts) | **Not run — needs GitHub dispatch** (SKIPPED expected by design) |
| 21 | Known-gap later passing is surfaced (strict xfail / XPASS note) | A | `tests/test_workflow_summary.py::test_strict_xpass_is_a_failure_with_the_removal_message` + real-pytest probe: strict XPASS -> chain FAIL with "known gap now passes - remove xfail and update README §14" | **Pass** (classification). Gap tests themselves not executed against the app |
| 22 | Helper reports horizontal scroll, overlap, clipped text, off-screen interactive | A | `tests/e2e/test_layout_sentinel_selftest.py::test_sentinel_detects_all_four_defects` | **Pass** |
| 23 | Helper wired into chains: every visited page at 375/768/1280, viewport restored | A + M | Restore: `::test_sentinel_restores_viewport` (Pass). Wiring: `Wf.visit` / `Wf.scan` call `check_layout` (default `WIDTHS`); each chain's pages reviewed (M-013) — all functional pages scanned; unscanned hops only produce warnings (see D3) | **Partial** — helper + restore Pass; scanning real chain pages **Not run — needs GitHub dispatch** |
| 24 | Finding includes URL, width, rule, both overlapping elements; fails test with detail | A | Self-test asserts every finding has `url`, `width`, `rule`, `a.path` and that the overlap finding names both "Overlap A" and "Overlap B". Failure-message hook (`pytest_runtest_makereport` flip in `chains/conftest.py`) has no automated test without a stack | **Partial** — finding shape Pass; "fails the test with that detail" **Not run — needs GitHub dispatch** (see D6) |
| 25 | Self-test detects all 4 classes on the broken fixture at each width | A | `test_sentinel_detects_all_four_defects` (asserts all four rules at 375, 768 and 1280) | **Pass** |
| 26 | Clean fixture -> zero findings at all 3 widths | A | `test_sentinel_clean_page_has_no_findings` | **Pass** |
| 27 | Self-test needs no stack/backend/data; selectable via `suite=layout` | A + M | Ran with `E2E` unset and nothing on :3000/:8000: 3 passed in 2.75 s. `suite=layout` mapping replayed (stack=0, e2e empty). GitHub execution: GH-004 | **Partial** — local Pass; `suite=layout` on GitHub **Not run — needs GitHub dispatch** |
| 28 | Job summary lists every layout finding (page, width, elements/rule) or "No layout findings" | A | `test_workflow_summary.py::test_render_has_table_and_layout_section`; probe output showed `No layout findings.` | **Partial** — markdown Pass; GitHub rendering **Not run — needs GitHub dispatch** |
| 29 | README §11 index row + subsection reconciled, §14 row, no new `.md` outside `docs/agents/` | M | `git diff` of README (M-014): §11 index row added, "Cross-role workflow chains" subsection rewritten ("Design (built, S-125)", per-chain status, nightly/schedule/GitHub-issue wording gone — `grep -i nightly` finds none for this feature), "How to run" + GitHub-manual text mention `web-workflows.yml`, §10 CI paragraph names it as the "fourth" workflow, §14 rows updated. No new `.md` outside `docs/agents/`. **Defect D1** in the new run-command block | **Pass with defect D1** |

**Coverage:** 29 / 29 AC mapped. Tally: **Pass 6** (1, 21, 22, 25, 26, 29), **Partial 8** (2, 3, 6, 7, 23, 24, 27, 28; the local part passes, the GitHub part is Not run), **Not run — needs GitHub dispatch 15** (4, 5, 8-20), **Fail 0**.

---

## Backend tests

### Added (by Builder; verified by Tester)
- `backend/tests/e2e/test_layout_sentinel_selftest.py::test_sentinel_detects_all_four_defects`
- `backend/tests/e2e/test_layout_sentinel_selftest.py::test_sentinel_clean_page_has_no_findings`
- `backend/tests/e2e/test_layout_sentinel_selftest.py::test_sentinel_restores_viewport`
- `backend/tests/test_workflow_summary.py` (8 tests: `test_pass`, `test_functional_failure_uses_first_error_line`, `test_layout_flip_reason`, `test_known_gap_when_main_passes_and_gap_xfails`, `test_strict_xpass_is_a_failure_with_the_removal_message`, `test_skipped_main_makes_the_chain_skipped`, `test_setup_error_is_a_failure`, `test_render_has_table_and_layout_section`)
- `backend/tests/e2e/chains/test_wf_*.py` — 10 chain test functions (collected, not executed): `test_wf_listing_approval`, `test_wf_new_review`, `test_wf_featured_boost`, `test_wf_suspend`, `test_wf_review_moderation`, `test_wf_review_reply`, `test_wf_review_reply_gap`, `test_wf_shop_edit`, `test_wf_shop_edit_gap`, `test_wf_whatsapp_draft`

### Run output
```
cd backend && PYTHONPATH=. python -m pytest <files> -p no:cacheprovider

tests/e2e/test_layout_sentinel_selftest.py -v        -> 3 passed in 2.75s   (E2E unset, no stack)
tests/test_workflow_summary.py -v                    -> 8 passed in 0.16s
tests/e2e -q            (E2E unset)                  -> 3 passed, 62 skipped in 4.30s
                                                        (every S-010/S-124 test and all 10 chains SKIPPED
                                                         with the "e2e opt-in" reason; the one S-124 skip with its
                                                         own reason, /profile email-change, is unchanged)
E2E=1 tests/e2e/chains --collect-only -q             -> 10 tests collected, no import errors
Throwaway probe (scratchpad, not committed): real pytest reports through chains/summary.py
                                                     -> FAIL / KNOWN-GAP / SKIPPED / strict-XPASS->FAIL rendered correctly
```
Full `pytest` / `npm test` not run (not requested; no shared helper changed beyond the one additive conftest line).

Working tree after my runs: `git status --short` shows only the Builder's intended files plus the two TP/TR docs. My runs generated no `workflow-summary.md`, no `tests/e2e/assets/`, no new trace zips (`test-results/` already existed and is gitignored; `__pycache__` ignored).

---

## Frontend tests

### Added
- None (test tooling slice; no frontend change).

### Run output
```
Not run — no frontend files changed.
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | `web-workflows.yml` `on:` = `workflow_dispatch` only; no hook files changed | Pass |
| M-002 | `suite` options exact (`all`, 8 chains, `layout`); `pytest_args` string | Pass |
| M-003 | `Resolve target` case replayed for `all`, `layout`, `wf-new-review`, `wf-review-reply` | Pass |
| M-004 | `down -v` `if: always() && stack == '1'`, last step, after artifact uploads | Pass (static) |
| M-005 | Three uploads `if: always()`, `if-no-files-found: warn`, 14-day retention | Pass (static) |
| M-006 | Classifier fed real pytest reports | Pass |
| M-007 | Default `pytest tests/e2e` skips everything pre-existing; `conftest.py` diff = one line; `pytest.ini` = +2 markers; `web-e2e.yml` unmodified | Pass |
| M-008..M-012 | Static review: seeded creds, role_state, Wf.actor, unique names, no sleeps | Pass (static); runtime Not run |
| M-013 | Every page visited in each chain is passed through `Wf.visit`/`Wf.scan` (exceptions: D3) | Pass (static) |
| M-014 | README §10 / §11 / §14 edits | Pass with D1 |
| GH-001 | Run workflow form on GitHub | **Not run — needs GitHub dispatch** |
| GH-002 | Real `suite=all` run: URL, chain table, layout findings, artifacts, teardown | **Not run — needs GitHub dispatch** |
| GH-003 | S-124 `web-e2e.yml` `suite=all` still green | **Not run — needs GitHub dispatch** |
| GH-004 | Real `suite=layout` run (no Compose) | **Not run — needs GitHub dispatch** |
| GH-005 | A failing run still produces summary, artifacts and `down -v` | **Not run — needs GitHub dispatch** |
| GH-006 | `playwright show-trace` on a chain zip | **Not run — needs GitHub dispatch** |

---

## Spec conformance review of the chains (step lists in Architect section 6)

All 8 chains follow the spec's step order and oracles. Deviations are benign:

- `wf-suspend` readies `/admin` on `heading "Admin Panel"` instead of `AdminPanelPage.expect_loaded()` — same heading, fewer checks.
- `wf-new-review` / `wf-review-moderation` use `unique_name`/uuid markers as specified; bell oracles all contain the per-run business name (no row-count assertions).
- `wf-listing-approval` asserts **both** the profile page and search (spec's decided option); no pre-emptive downgrade.
- `_gap` tests use `wf.session_actor(...)` and `goto("/")` without scanning (spec: gap tests do not scan).
- Fixed sleeps: none besides the documented `time.sleep(15)` rate-limit back-off in `login_and_save`.

---

## Regressions

- None found. Pre-existing e2e tests: all still collected and still SKIPPED by default. No product code touched.

---

## Defects / gaps (for Builder; none blocks merge except D1 which is a one-line fix)

| # | Sev | AC | Description |
|---|-----|----|-------------|
| D1 | Low (doc) | 29 | `README.md` §11 "Chains and layout (S-125)" code block line ~2321 contains a **literal backslash-n** (`API_URL=http://localhost:8000/api/v1 \n  pytest ...`) instead of a line break, so the copy-paste command is broken. Fix: real line continuation. |
| D2 | Low | 6 | `chains/summary.py::_first_line` uses `line.lstrip("E ")` (a character-set strip, not a prefix strip). A failure message that begins with the letter "E" (e.g. "Expected ...") loses its first character(s) in the summary reason. Use `line[2:]` after `startswith("E ")`. |
| D3 | Low | 23 | The two `_gap` tests (and the merchant page in `wf-whatsapp-draft`) visit pages that are never scanned, so every `suite=all` run will list "page visited but not scanned: `/`" warnings in the job summary. Spec-sanctioned, but it is permanent noise; consider excluding `/` for gap tests. |
| D4 | Info | 15 | `wf-featured-boost` fetches the admin token (`wf.token("admin")`) before the DEBUG skip, so a skip still costs one real admin UI login. Harmless. |
| D5 | Info | 7 / 27 | AC 7 ("gate hook untouched") conflicts literally with AC 27 (self-test without `E2E=1`). Builder followed the Architect's reconciliation (one additive early-continue). Side effect: default `pytest` now launches Chromium for 3 tests (skips cleanly if Chromium is absent). PM must confirm the wording. |
| D6 | Info | 24 | No automated test for the `pytest_runtest_makereport` flip (layout findings failing a functionally-passing chain) or the `Wf` class; these only run in a real chain execution. |

---

## Risks / selectors not verified

Nothing below has been executed in a browser against the app. "Verified" means I found the text/role in `frontend/src` or `backend/app` by grep; it does not prove the locator resolves uniquely or in the right state.

**Verified to exist in source (static only):**
- Notification bell: `button[aria-label="Notifications"]`, list in `ul li button`, read rows carry `opacity-70` (`NotificationBell.tsx:86,112,120`); unread count polled every 30 s, list fetched on open (matches `bell_expect` reload-and-open loop).
- Notification titles/messages: "Listing approved" + "{name} has been approved and is now live", "New review received" + "New {n}-star review on {name}", "Featured payment received", "Featured boost is live", "WhatsApp update applied".
- Headings/labels/buttons: "Register your business" / "Edit business" (h2 in `BusinessForm`), "Merchant Dashboard", "Your businesses" (only rendered when the merchant owns more than one shop; the dashboard shows "Loading dashboard..." until shops are loaded, so `select_business` should not race), "Admin Panel", "Payments" (h2), "Approve boost", "Boost this listing", "Reply as business", "Write a response to this review", "Post reply", "Post review", "Title (optional)", review placeholder, "Your review is live", "Submit report", "Why are you reporting", "Reported — pending moderation", "Save changes", `aria-label="{n} stars"` (`ui/RatingWidget.tsx:62`).
- Suspended login error: backend "Account suspended" -> `apiFetch` throws `ApiError(detail)` -> `LoginForm` renders `err.message`; matches the `/suspend/i` oracle.

**NOT verified (needs a live run):**
1. `get_by_label("Description", exact=True)` on the edit form: the label wraps `<span>Description</span><Textarea>`; Playwright should resolve it, but strictness/uniqueness unproven.
2. `get_by_role("heading", name="Edit business").first` — two "Edit business" strings exist on the edit page (page title + form h2); `.first` hides ambiguity.
3. Admin panel "Total users" **button** role (only the text was found in `admin/page.tsx`), "Search users" label, and the `Suspend` row button — reused from the existing S-124 pattern, not re-run here.
4. `get_by_role("button", name="Report", exact=True).first` on the public business page, and the report form flow, for a seeded customer.
5. `/admin/whatsapp`: `link "Admin panel"` and button `Approve` (exact) — only relevant on a stack with drafts; the chain is expected to SKIP on fresh Compose.
6. `wf-featured-boost` / `wf-review-reply`: after `select_option`, the dashboard re-fetches stats/reviews for the chosen shop. The seeded merchant owns many shops, so `reply_to_first_review` / `start_featured_checkout` may act on stale content from the previously shown shop before the re-fetch completes (possible flake; wrong review replied to would fail the public-page assertion). Unverified.
7. Seeded customer posting a review without extra profile steps, and the merchant KYC bootstrap (`ensure_merchant_kyc`, reauth then PATCH `auth/me`) on a fresh seed.
8. Rate limits: three opening UI logins (login 10/min, TOTP verify 5/min, one IP) and four `register` calls per run — analysed in the spec's budget, not exercised.
9. Layout sentinel on real pages: thresholds (overlap 16 px² / 5 %, ellipsis exemption, fixed/sticky exemption, `checkVisibility`) were only exercised on two hand-made fixtures. First real run will probably produce FAIL rows that are layout-only (spec Risk 1) and may include false positives from the navbar, tables or cards; these must be triaged and listed as product follow-ups, not silenced.
10. Strict-XPASS false trigger risk in the two gap tests: `bell_expect(contains=biz.name)` with any title would XPASS if the review author already received any notice naming the business. From `grep` of `upsert_notice` callers, only merchants are notified today, so none expected.
11. Traces contain bearer tokens of a throwaway stack (accepted by spec).
12. `web-workflows.yml` itself has never run: `docker compose` steps are copied from `web-e2e.yml`; "Check the seed ran" depends on the `Seed complete.` line appearing in backend logs on a fresh volume (string exists in `seed.py:359`).

---

## Gaps / rework items

1. D1 — fix README command line break (blocks a clean docs review, trivial).
2. AC 4, 5, 6 (render), 8-20, 23, 24, 28 and PM DoD item "real `suite=all` + `suite=layout` dispatch recorded" — **Not run — needs GitHub dispatch**. Slice cannot be set `Accepted` until these are recorded in this TR (Conditions above).
3. D2, D3, D6 — optional polish; can follow after the first real run.

---

## Sign-off

- [ ] All AC mapped to tests — **mapped (29/29), but 15 are Not run and 8 Partial; real dispatch evidence outstanding**
- [x] README §11 feature → test index updated if tests were added or moved (row "Cross-role workflow chains + layout sentinel (S-125)"; plus §11 status rows, subsection, §10, §14)
- [x] RBAC tested — no RBAC change; suspend-login negative is a chain (Not run); existing RBAC suites unchanged
- [x] AI disclaimer verified (if applicable) — N/A, no AI surface added
- [ ] Ready for PM acceptance — **No**: pending GH-002 / GH-004 / GH-003 and D1. Recommendation: Pass-with-conditions (merge the tooling on a feature branch + PR, then dispatch, then PM accepts)
