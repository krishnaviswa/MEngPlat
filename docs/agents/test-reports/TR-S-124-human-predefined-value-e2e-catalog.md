# TR-S-124: Human-like predefined-value automation suite — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-124 |
| **Author** | Tester |
| **Date** | 2026-08-29 |
| **Branch** | `feat/s-124-human-predefined-value-e2e` |
| **Verdict** | **Hold — implementation complete, Compose execution pending** (no Docker in the build environment) |

---

## Summary

The predefined-value catalogue (`form_data.py`), the keyboard-centric `HumanForm` driver
(`human.py`), the four per-role journey modules, the selector canary, the coverage guard,
the new page objects, `Api` helpers, and Pydantic oracles are all implemented and import
cleanly. 50 e2e tests collect. The catalogue-consistency check passes. The S-010
collection gate and `e2e_trace` fixture are untouched — default `pytest` still skips every
`e2e/` test and launches no browser.

**This environment has no Docker**, so the browser-dependent suite
(`E2E=1` / `E2E_FULL=1` against Compose) has **not been run**. Every browser-dependent AC
is therefore **Implemented — pending Compose**, not Verified. One implementation bug was
found while mapping (`pages/merchant_dashboard.py` uses `re` without importing it — breaks
AC 6h at runtime). AC 5c is **Blocked** — `/profile` has no email-edit control. Several
admin sub-items are partial vs. their AC wording (7c / 7g / 7h) and several steps are
environment-conditional `pytest.skip` (6e / 6h / 7h).

A maintainer must run `docker compose up --build` then
`E2E=1 E2E_FULL=1 pytest tests/e2e -v` (or dispatch `web-e2e.yml`) and attach the trace
artifact before PM can set `Status: Accepted`.

---

## Verified locally (exact commands + observed output)

1. **Collection — all new modules import cleanly, no syntax/import errors:**
   ```
   cd backend && python -m pytest tests/e2e --collect-only -q
   → 50 tests collected in 0.52s
   ```

2. **Catalogue internal consistency (the one new test runnable without a browser):**
   ```
   cd backend && python -m pytest \
     tests/e2e/test_selectors_smoke.py::test_catalogue_is_internally_consistent -m e2e
   → 1 passed in 0.28s
   ```
   (every `FormSpec` has a `submit_label` and something to exercise; each api-oracle tuple
   is well-formed — method ∈ HTTP verbs, status is an int.)

3. **Opt-in gate intact — default e2e run skips, no browser launched:**
   ```
   cd backend && python -m pytest tests/e2e -q
   → 50 skipped in 0.62s
   ```
   (`cd backend && pytest` behaves the same — the `"e2e" in path.parts` skip in
   `pytest_collection_modifyitems` is unchanged.)

4. **Catalogue coverage surface — 17 keys, every one wired to a journey:**
   ```
   cd backend && python -c "from tests.e2e import catalog_coverage; \
     print(sorted(catalog_coverage.all_form_keys())); print(len(catalog_coverage.all_form_keys()))"
   → 17 keys (11 FORMS + 6 WIZARD_KEYS)
   ```
   Mapping (journey that calls `record_form(<key>)`):

   | key | recorded by |
   |-----|-------------|
   | `anon.search_bar` | `test_journey_anonymous::test_search_bar_enter_submit` |
   | `anon.filter_panel` | `…::test_filter_panel_enter_submit` |
   | `anon.forgot_password` | `…::test_forgot_password_enter_submit` |
   | `anon.support_ticket` | `…::test_support_ticket_form` |
   | `anon.login` | `…::test_login_wizard_totp` |
   | `anon.register` | `…::test_login_wizard_totp` |
   | `anon.register_phone_otp` | `…::test_register_phone_otp_wizard` |
   | `anon.reset_password` | `…::test_reset_password_page_states` |
   | `anon.collect_inline_auth` | `…::test_anonymous_collect_inline_auth_on_submit` |
   | `customer.review` | `test_journey_customer::test_review_submit_dual_oracle` |
   | `customer.review_title_enter` | `…::test_review_title_input_enter_submits` |
   | `customer.profile_basics` | `…::test_profile_basics_enter_submit` |
   | `merchant.national_id` | `test_journey_merchant::test_merchant_full_journey` |
   | `merchant.business_create` | `…::test_merchant_full_journey` |
   | `merchant.business_edit_address_otp` | `…::test_merchant_full_journey` (recorded before the OTP-gate skip) |
   | `merchant.reply` | `…::test_merchant_full_journey` |
   | `admin.category_create` | `test_journey_admin::test_category_create_and_duplicate` |

   Caveat: if any of those journeys `pytest.skip` (gamified flag, missing seed, DEBUG),
   its key stays unrecorded and the `E2E_FULL=1` teardown guard fails loudly — intended
   per the Architect risk table, but it means the guard only passes on a fully green run
   in the documented environment.

Not run here: the full `E2E=1` browser suite (no Docker). No `httpx`/Postgres backend
tests are added by this slice.

---

## AC coverage matrix

Status ∈ {**Impl-pending** = Implemented, pending a Compose run · **Verified** = verified
locally · **Skipped** = documented `pytest.skip` · **Blocked** = no UI support}.

| AC | Test (module::function) | Oracle(s) | Status |
|----|-------------------------|-----------|--------|
| 1 | `test_journey_anonymous::test_home_loads_with_ssr_oracle`, `::test_business_detail_loads`, `::test_login_and_register_pages_render`, `::test_reset_password_page_states` | UI `expect()` on stable copy per route; SSR technical oracle via `Api.get` | Impl-pending |
| 1a | public `FormSpec`s filled by `HumanForm.fill_and_submit` — `test_search_bar_enter_submit`, `test_filter_panel_enter_submit`, `test_forgot_password_enter_submit`, `test_support_ticket_form` | per-field keyboard type + submit | Impl-pending |
| 1b | `HumanForm.settle` + `HumanForm._check_api` (status + `SCHEMA_ORACLES`) in the same tests | UI `expect()` **and** Pydantic schema/status | Impl-pending |
| 1c | `test_journey_anonymous::test_anonymous_review_gate_no_post`, `::test_anonymous_favorite_redirects_to_login`, `::test_anonymous_collect_inline_auth_on_submit` | `to_have_url(/login…)`; negative: no `POST /reviews`; S-121 `InlineAuthStep` swap, no nav | Impl-pending |
| 2 | `enter_submits=True` specs + `test_review_title_input_enter_submits`, `test_search_bar_enter_submit`, `test_filter_panel_enter_submit`, `test_forgot_password_enter_submit`, `test_profile_basics_enter_submit`, `test_merchant_full_journey` (national-ID + business-create Enter), `test_category_create_and_duplicate` | `HumanForm.submit` presses Enter in last text field; success oracle passes | Impl-pending |
| 3 | `HumanForm.assert_enter_noop` invoked by `customer.review`, `merchant.reply`, `anon.support_ticket`; `test_register_phone_otp_wizard` (Verify button, not Enter) | negative: no submit/nav/mutating request on Enter, then labelled button completes | Impl-pending (admin queue search boxes + collect "stars" step Enter-inert **not** separately asserted — see Gaps) |
| 4 | `test_journey_customer::test_review_requires_star_before_enter` | `HumanForm.expect_validation("select a star rating", "/reviews")` — inline error visible **and** no `POST /reviews` | Impl-pending |
| 5a | `test_journey_customer::test_review_submit_dual_oracle` | `to_have_url(/businesses/{slug}$)`; `POST /reviews` → 201 `ReviewResponse`; body present in `Api.list_reviews` | Impl-pending |
| 5b | `::test_profile_basics_enter_submit` | `"Profile updated."`; `PATCH /auth/me` → 200 `UserResponse` | Impl-pending |
| 5c | `::test_profile_email_change_reauth` | — | **Blocked** (no email-edit control; `@pytest.mark.skip`). Reauth step-up covered by AC 6a |
| 5d | `::test_profile_avatar_upload` | `POST /auth/me/avatar` → 200 (`ProfilePage.upload_avatar`) | Impl-pending (UI "avatar reflected" oracle absent — see Gaps) |
| 5e | `::test_favorite_persists` | `POST …/favorites` → 200/201; `button "favorited"` visible after reload | Impl-pending |
| 5f | `::test_report_review` | `POST /reviews/{id}/report` → 200; `"Reported — pending moderation."` visible | Impl-pending |
| 5g | `::test_logout_blocklists_token` | `/settings` logout → `to_have_url(/)`; replayed token `Api.get("auth/me")` → **401** | Impl-pending |
| 6a | `test_journey_merchant::test_merchant_full_journey` (KYC step) | `MerchantNationalIdCard` Enter → `PATCH /auth/me` → 200 `UserResponse`; number field becomes non-editable | Impl-pending |
| 6b | same (business-create step) | `BusinessForm` Enter → `POST /businesses` → 201 `BusinessResponse`; `GET /businesses/mine` → `status=="pending"` | Impl-pending |
| 6c | same (dashboard widgets) | `GET /dashboard/merchant/{id}` on date-range select; `POST …/refresh` → 200; `expect_download` filename ends `.csv` | Impl-pending |
| 6d | same (`dash.expect_ai_disclaimer`) | verbatim `"Suggestions only — not definitive judgments. Verify in person before acting."` visible | Impl-pending (copy must match live `AIInsights` — see Gaps) |
| 6e | same (`EditBusinessPage.change_address_and_save` ×2) | 2nd edit → `"Address verification code"` field → `"Verify & save"` → `PATCH …/businesses/…` → 200 | Impl-pending / **Skipped** if S-073 OTP gate off |
| 6f | same (photo manager) | `POST …/photos/upload`; `DELETE …/photos/{id}` (auto-accept `window.confirm`) | Impl-pending |
| 6g | same (`MerchantDashboardPage.reply_to_first_review`) | `"Post reply"` click → `POST /reviews/{id}/reply` → 201 `ReplyResponse`; reply body visible | Impl-pending |
| 6h | same (`MerchantDashboardPage.start_featured_checkout` → `Api.mock_complete_payment`) | `POST /payments/featured/checkout` → 200; mock-complete → 200 | Impl-pending — **BLOCKER: `NameError` bug** (`pages/merchant_dashboard.py` uses `re` unimported) + `pytest.skip` on 404 without DEBUG |
| 7a | `test_journey_admin::test_category_create_and_duplicate` | `AdminCategoryPanel` Enter → `POST /businesses/categories` → 201; duplicate → 409 + `"already exists"` inline | Impl-pending |
| 7b | `::test_pending_business_start_review_then_approve` | `"Start review"` → `"Approve"`; `GET /businesses/{id}` → `status=="approved"` | Impl-pending |
| 7c | `::test_reported_review_moderation_cycle` | `…/moderate?action=hide` → 200; Restore/Remove conditionally exercised | Impl-pending (Restore→Remove `try/except → skip`; partial vs AC — see Gaps) |
| 7d | `::test_user_suspend_reactivate` | `…/suspend` → 200 `UserResponse`, `…/reactivate` → 200; suspended `POST /auth/login` → 403 | Impl-pending |
| 7e | `::test_support_ticket_admin_update` | ticket visible on `/admin/support`; `PATCH /admin/support-tickets/{id}` → `SupportTicketResponse`, `status=="in_progress"` | Impl-pending (partial UI + API-schema oracle — button-only widget) |
| 7f | `::test_business_report_thread_and_status` | `/admin/business-reports` loads; `POST …/messages` → 201; `PATCH …/business-reports/{id}` → `BusinessReportResponse` | Impl-pending (partial UI + API-schema oracle) |
| 7g | `::test_whatsapp_drafts_queue` | `/admin/whatsapp` loads; `POST …/drafts/{id}/reject` → 200 | **Skipped** if no seeded drafts; partial (no edit-text, no approve — see Gaps) |
| 7h | `::test_admin_payment_actions` | featured checkout → mock-complete → `…/payments/{id}/approve` → 200, `…/refund` → 200/400 | Impl-pending / **Skipped** on mock-complete 404; Reject path not exercised (see Gaps) |
| 7i | `::test_admin_platform_stats_oracle` | `GET /dashboard/admin/platform` → `PlatformAnalytics` validates; `test_admin_panel_and_subpages_load` covers UI page-load | Impl-pending |
| 8 | `test_login_wizard_totp` (`LoginPage.complete_totp` enroll/verify heading transition), `test_register_phone_otp_wizard`, `test_merchant_full_journey` (KYC→OTP, business-edit→address-OTP), collect wizard in `test_anonymous_collect_inline_auth_on_submit` | `expect()` on each next-step heading/control before proceeding; `pyotp` + `DEMO_TOTP_SECRET` / `DEMO_PHONE_OTP` | Impl-pending |
| 9 | `conftest.py::_catalog_coverage_check` (session, `E2E_FULL=1`) → `catalog_coverage.assert_every_form_exercised()` over the 17 keys | teardown `AssertionError` naming any unexercised `FormSpec` | Impl-pending (17-key mapping **Verified** locally; guard fires only on a Compose run) |
| 10 | documented `pytest.skip` sites — `admin_tokens` ("seeded admin unavailable"), `seeded_business` ("no approved seeded business"), collect `variant()` ("GAMIFIED_REVIEW flipped"), address-OTP gate, `mock/complete` DEBUG | tests skip with human-readable reasons, never error | **Verified** locally (default e2e run → 50 skipped cleanly; skip reasons present in source) |
| 11 | `unique_email` / `unique_name` (`uuid4` suffix) used for every created customer / merchant / business / category / ticket / report; seeded admin used only via `admin_tokens` / `admin_browser` as an actor | no seeded demo account mutated as source of truth | **Verified** locally (code inspection — every `api.register` / `unique_name` call in the journeys carries a uuid suffix) |
| 12 | `test_selectors_smoke.py::test_public_selectors_resolve` (6 routes), `::test_catalogue_is_internally_consistent` | each catalogued selector resolves to ≥1 visible element; catalogue tuples well-formed | `test_catalogue_is_internally_consistent` **Verified** (1 passed); `test_public_selectors_resolve` Impl-pending (needs a browser) |

### Counts (36 rows)

| Status | Count | Rows |
|--------|-------|------|
| Implemented — pending Compose | 31 | 1, 1a, 1b, 1c, 2, 3, 4, 5a, 5b, 5d, 5e, 5f, 5g, 6a, 6b, 6c, 6d, 6e, 6f, 6g, 6h, 7a, 7b, 7c, 7d, 7e, 7f, 7h, 7i, 8, 9 |
| Verified locally | 3 | 10, 11, 12 |
| Skipped (documented) | 1 | 7g |
| Blocked (no UI support) | 1 | 5c |

(6h and 7h additionally carry a hard blocker / environment-skip flag; 9 and 12 are
partially verified locally as noted.)

---

## Backend tests added

- `backend/tests/e2e/journeys/test_journey_anonymous.py` — 13 tests
- `backend/tests/e2e/journeys/test_journey_customer.py` — 9 tests (1 `@pytest.mark.skip`)
- `backend/tests/e2e/journeys/test_journey_merchant.py` — 1 ordered journey (`slow`)
- `backend/tests/e2e/journeys/test_journey_admin.py` — 11 tests (`slow`)
- `backend/tests/e2e/test_selectors_smoke.py` — `test_public_selectors_resolve` (6 params) + `test_catalogue_is_internally_consistent`
- Supporting (not tests): `form_data.py`, `human.py`, `catalog_coverage.py`, `oracles.py`
  (new wrappers + `SCHEMA_ORACLES`), `api_client.py` (helpers + `DEMO_PHONE_OTP`),
  `conftest.py` (additive fixtures), 9 new `pages/*.py`, `pytest.ini` markers,
  `.github/workflows/web-e2e.yml` (timeout 60, `E2E_FULL=1`).

No `httpx.AsyncClient` / RTL tests — this slice is browser-e2e infrastructure only.

## Frontend tests added

None. No product frontend change was required (no `aria-label` fix fired) — so no
README §12 parity row, consistent with S-010.

---

## Gaps found while mapping

1. **BLOCKER — `pages/merchant_dashboard.py` `NameError`.** `start_featured_checkout`
   (and the file generally) references `re.compile(...)` but the module only does
   `from playwright.sync_api import Page, expect` — no `import re`. Collection passes
   (the call is inside a method body) but `test_merchant_full_journey` step 6h will raise
   `NameError: name 're' is not defined` at runtime. Fix: add `import re`. Assign to
   Builder before the Compose run.
2. **AC 6d disclaimer copy is unverified against live UI.** `MerchantDashboardPage.AI_DISCLAIMER`
   = `"Suggestions only — not definitive judgments. Verify in person before acting."` If
   this doesn't match the rendered `AIInsights` string verbatim, AC 6d fails. This is the
   non-negotiable #1 regression check — Builder must confirm against
   `frontend/src/components/AIInsights.tsx` (or the selector canary must be extended to a
   logged-in route to lock it).
3. **AC 7c partial.** Hide is asserted; Restore → Remove are `try/except → pytest.skip`.
   The AC wants all three transitions asserted on the same review.
4. **AC 7g partial.** Only `reject` on the first seeded draft. The AC also wants
   "edit the draft text" and "Approve one draft" — not exercised. Also fully skipped when
   the seed has no drafts (the default seed state is unverified here).
5. **AC 7h partial.** Approve + Refund on one payment. The AC wants the Reject path on a
   *separate* throwaway payment.
6. **AC 3 partial.** `assert_enter_noop` covers the 3 textarea-terminated catalogue specs
   and `PhoneOtpPanel`. "Every admin queue search box" and the "collect flow stars step"
   Enter-is-inert checks (explicit in the AC) are not separately asserted.
7. **AC 5d.** Only the upload API 200 is asserted, not "the new avatar is reflected in
   the UI".
8. **`test_admin_payment_actions` fixture ordering smell.** `admin_browser` (logs in as
   admin) then `fresh_merchant` (logs in as merchant) share the same `page`; the trailing
   `admin_browser.goto("/admin")` runs with merchant `localStorage`. No assertion depends
   on it, so no failure — but the "admin journey" for 7h is effectively all-API with a
   weak UI oracle.
9. **Catalogue possibly under-specifies `merchant.business_create` / `anon.filter_panel`.**
   `merchant.business_create` sets no country/state/category; `anon.filter_panel` does
   `select_option("")` for `category` / `min_rating` and `select_option("rating")` for
   `sort`. If the live form requires those fields or uses different option values, the
   Enter submit / select fails. Only a Compose run confirms.
10. **Coverage guard vs. `pytest-xdist`.** `catalog_coverage.EXERCISED` is a per-process
    module global; `-n auto` + `E2E_FULL=1` would fail the teardown on every worker.
    `web-e2e.yml` runs single-process so CI is fine — but document it (done in TP-S-124).

None of items 2–10 block the *structure* of the suite; they are refinements or
environment confirmations for the Compose run.

---

## Regressions

- None introduced. S-010's `test_flow_*.py`, `test_rbac_matrix.py`,
  `test_token_security.py`, `test_smoke_compose.py` still collect (50 total) and the
  collection gate / `e2e_trace` are byte-for-byte unchanged.
- Default `cd backend && pytest tests/e2e` → 50 skipped, no browser — opt-in preserved.

---

## Blockers before Accepted

1. **Run the Compose suite.** On a Docker host: `docker compose up --build` then
   `cd backend && E2E=1 E2E_FULL=1 pytest tests/e2e -v` (or dispatch **Web e2e
   (Playwright)**). Attach the `playwright-traces` artifact. Manual **M-124-001**.
2. **Fix the `import re` bug** in `pages/merchant_dashboard.py` (Gap 1) — Builder — before
   that run, else AC 6h errors.
3. **Confirm AC 6d disclaimer copy** matches the live `AIInsights` string (Gap 2).
4. **PM to decide AC 5c disposition** — accept as Manual/Blocked or descope. `/profile`
   has no email-edit control; reauth step-up is covered by AC 6a.
5. **Confirm AC 6e / 7h are not *permanently* skipped in CI** — ensure the Compose env
   used by `web-e2e.yml` has `DEBUG=true` and the S-073 address-OTP gate on, so 6e / 6h /
   7h actually execute rather than always skipping.
6. Optionally close AC 3 / 7c / 7g / 7h coverage partials (Gaps 3–6) or have PM accept the
   documented deviations.

---

## Sign-off checklist

- [x] Every AC (and lettered sub-item) mapped — 36 rows, no AC unmapped
- [x] `TP-S-124` written; `TR-S-124` (this doc) written; `TP-S-010` already carries the
      "Systematic layer — S-124" section (not duplicated)
- [x] README §11 feature → test index rows for S-124 present (added by Builder — the new
      "Full role journeys — predefined-value human-driven catalogue (S-124)" row plus
      `journeys/…` appended to the logout / step-up / profile / reviews / dashboard /
      featured-boost / support / shop-reports / AI rows); §14 + §16 entries present
- [x] RBAC negative paths covered (401 anonymous gates AC 1c, 403 suspended-login AC 7d,
      401 replayed post-logout token AC 5g) — no RBAC change, regression net only
- [x] AI disclaimer regression-covered (AC 6d) — **copy still to be confirmed against live
      UI** (Gap 2)
- [ ] **Compose run green + trace artifact attached** — NOT DONE (no Docker here)
- [ ] PM acceptance — **withhold** until blockers 1–5 above are cleared

**Recommendation: Hold / Rework.** Not Ship. Implementation is complete and structurally
sound; acceptance is gated on a maintainer executing the Compose suite (M-124-001), the
one-line `import re` fix, and the PM's AC 5c call.
