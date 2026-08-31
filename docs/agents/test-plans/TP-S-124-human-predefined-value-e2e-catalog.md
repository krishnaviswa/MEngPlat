# TP-S-124: Human-like predefined-value automation suite — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-124 |
| **Author** | Tester |
| **Date** | 2026-08-29 |
| **Extends** | `TP-S-010` (does **not** replace `backend/tests/e2e/test_flow_*.py`) |
| **Branch under test** | `feat/s-124-human-predefined-value-e2e` |

---

## Scope

The systematic companion to the four hand-picked S-010 happy-path journeys:

- **`backend/tests/e2e/form_data.py`** — `FORMS`, the single auditable catalogue of
  predefined field values for every form on every route (`FieldValue` / `FormSpec`,
  `DEFAULTS` value bank, `WIZARD_KEYS`, `unique_email` / `unique_name`).
- **`backend/tests/e2e/human.py`** — `HumanForm`, the keyboard-centric driver: per-character
  typing, `Tab` between fields, **Enter** to submit where the real `<form onSubmit>`
  supports it, button-click (with an Enter-is-a-no-op negative check first) for
  textarea-terminated forms and button-only widgets. No `time.sleep` anywhere.
- **`backend/tests/e2e/journeys/test_journey_{anonymous,customer,merchant,admin}.py`** — the
  per-role surface walks, every submission asserting **both** oracles: a UI `expect()` and
  the backend's own Pydantic response schema + status.
- **`backend/tests/e2e/catalog_coverage.py`** + the session-teardown `_catalog_coverage_check`
  fixture (armed by `E2E_FULL=1`) — fails if a catalogued `FormSpec` was never exercised.
- **`backend/tests/e2e/test_selectors_smoke.py`** — copy-drift canary (there are zero
  `data-testid`s) + a pure catalogue-consistency check.
- New page objects under `backend/tests/e2e/pages/`: `search`, `password_reset`, `support`,
  `profile`, `settings`, `collect`, `business_form`, `merchant_dashboard`, `admin_panel`.
- New `Api` helpers (`api_client.py`, `DEMO_PHONE_OTP`), new Pydantic oracle wrappers +
  `SCHEMA_ORACLES` (`oracles.py`), new markers (`backend/pytest.ini`), `web-e2e.yml`
  timeout 60 + `E2E_FULL=1`.

This is **test infrastructure**, not a user-facing web capability — no README §12 parity
row (consistent with S-010). It stays opt-in (`E2E=1`, Compose) and manual-only in CI
(`web-e2e.yml`, `workflow_dispatch`). The S-010 collection gate
(`pytest_collection_modifyitems`) and `e2e_trace` fixture are untouched.

Out of scope (unchanged from the slice): live Google OAuth (manual, M-124-002), making
`web-e2e.yml` a merge gate, load/visual-regression, any backend route/schema/migration
change, mobile parity.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Browser click-through | Playwright (Python) + `pytest-playwright` | Real per-role navigation; UI `expect()` on stable accessible copy (redirects, hidden actions, form results, inline validation) |
| Human driver | `HumanForm` (`human.py`) — per-keystroke `keyboard.type`, `Tab`, `Enter` | Submits real `<form onSubmit>` forms by Enter; negative-checks Enter on non-submitting widgets; drives file / select / star / OTP fields |
| Recording | Playwright Tracing (`screenshots=True, snapshots=True, sources=True`) via the untouched `e2e_trace` autouse fixture | One `trace.zip` per test in `backend/tests/e2e/test-results/` (gitignored); GHA artifact `playwright-traces` |
| Technical oracle (client-visible calls) | `page.expect_response(predicate)` around the submit → status + `Model.model_validate(resp.json())` via `SCHEMA_ORACLES` | Response shape/status for every browser-visible submission |
| Technical oracle (SSR pages) | Playwright `APIRequestContext` (`Api` helper, no browser) hitting the same endpoint alongside the UI check | Home / Search / Business-detail render server-side — `page.on("response")` never sees `GET /businesses`; the `Api` call is the oracle |
| Negative auth / RBAC regression | `APIRequestContext` + the journeys' own replayed-token / cross-role assertions | 401 anonymous, 403 wrong role, 404 cross-tenant, 401 replayed post-logout token (README §9 is source of truth; no RBAC change) |
| Catalogue coverage | `catalog_coverage.assert_every_form_exercised()` at session teardown (`E2E_FULL=1`) | Every `FormSpec` + `WIZARD_KEYS` entry exercised by ≥1 journey |

"A trace with no `expect()` is a recording, not a test" (TP-S-010) applies unchanged.

---

## Environment

- `docker compose up --build` running — frontend `:3000`, backend `:8000`, Postgres, Redis.
- `AI_PROVIDER=mock` (no real LLM calls); mock email / payments / maps; local storage.
- **`DEBUG=true`** in the Compose backend env — required for AC 6h / 7h
  (`POST /payments/mock/complete` returns **404** when `settings.debug` is false; those
  steps `pytest.skip` with "payments mock/complete needs Compose DEBUG=true" rather than
  fail).
- **Default `NEXT_PUBLIC_GAMIFIED_REVIEW`** (classic collect UI). If flipped, the
  collect/review tests probe `CollectPage.variant()` and `pytest.skip` — they never fail
  on the wrong variant (AC 10). Note: under `E2E_FULL=1` a skipped collect test leaves
  `anon.collect_inline_auth` unexercised and the coverage guard then fails loudly at
  teardown — this is intended (surfaces the environment gap), so run the full guard only
  with the flag in its default state.
- **Seed data present** (`backend/scripts/seed.py`): the seeded admin
  `admin@merchanthub.ai` and **≥1 approved business**. `admin_tokens` / `seeded_business`
  fixtures `pytest.skip` if absent. Shared `DEMO_TOTP_SECRET`; `DEMO_PHONE_OTP = "123456"`.
- **`E2E=1`** to run the suite at all (else every `e2e/` test skips — collection gate
  intact). **`E2E_FULL=1`** to arm the session-teardown catalogue-coverage guard.
- Optional **`E2E_SLOWMO_MS`** (default `0`; `0` in CI) → Playwright `slow_mo` via the
  `browser_type_launch_args` override, for a maintainer watching a run. Optional
  `E2E_TYPE_DELAY_MS` (default `35`).
- `playwright install chromium --with-deps` (one-time). `SECRET_KEY` in the test env.
- Trace / download output → `backend/tests/e2e/test-results/` (gitignored).

---

## Per-journey expectation sketch (functional + technical oracle)

Grounded in the button text / placeholders / endpoints actually in the branch code.
Mirrors the depth of TP-S-010's per-flow sketch.

### Anonymous — `journeys/test_journey_anonymous.py`

| # | Action | Functional oracle | Technical oracle |
|---|--------|-------------------|------------------|
| A1 | `GET /` | `heading "Local businesses, reviewed with clarity"` visible | **SSR.** `Api.get("businesses")` → 200, `validate_business_list` |
| A2 | `SearchBar`: type `"cafe"` in placeholder `"Search restaurants, salons, shops..."`, **Enter** | `to_have_url(/search\?.*q=cafe)` | GET `<form action="/search">` navigation — no API assertion |
| A3 | `/search` `FilterPanel`: `name="city"`=`Chennai`, `name="sort"`=`rating`, **Enter** | `to_have_url(/search\?)` | — (SSR results; `/search` asserted against seed data only, per cache-staleness rule) |
| A4 | `GET /businesses/{seeded.slug}` | `heading level 1 == seeded_business.name` | `Api.get("businesses/{slug}")` → 200, `status == "approved"` |
| A5 | `GET /businesses/{slug}/review` while anonymous | `"Sign in to write a review."` visible; `link "Sign in"` → `href="/login"` | negative: no `POST …/reviews` request fired (gate is client-side) |
| A6 | Click `favorite` button while anonymous | `to_have_url(/login)` | — |
| A7 | `/collect/{slug}` classic variant: pick `"5 stars"`, `"Continue →"`, write body, `"Submit review"` | `radiogroup "Sign in with…"` **or** `"Mobile OTP"` swaps in; `url` unchanged (no `/login` nav) — S-121 `InlineAuthStep` | negative: no navigation; `record_form("anon.collect_inline_auth")` |
| A8 | `/login`, `/register` render | `LoginPage.expect_form()`; `heading "Create account"` | — |
| A9 | `/forgot-password` `ForgotPasswordForm`: placeholder `"Email"`, **Enter** | `heading "Check your email"` | `POST /auth/forgot-password` → 200 |
| A10 | `/reset-password` states | no token → `heading "Invalid reset link"`; junk token → `heading "Reset password"` form | — |
| A11 | `/support` `SupportTicketForm`: labels `Name` / `Phone` / `Issue` (textarea), **click "Submit"** (Enter-noop checked first) | `"Ticket submitted"` visible | `POST /support-tickets` → 201, `SupportTicketResponse` |
| A12 | `/login` wizard: credentials → `LoginPage.complete_totp()` (enroll **or** verify heading asserted, `pyotp` code) | `not to_have_url(/login)`; `localStorage.access_token` set | — (`record_form("anon.login")`, `"anon.register")`) |
| A13 | `/register` phone-OTP: `"Full name"`, radio `"Mobile OTP"`, `"Mobile number"`, `"Send SMS code"`, `"SMS code"`=`123456`, **click "Verify"** (Enter must NOT submit `PhoneOtpPanel`) | `"SMS code"` field appears after send | `POST /auth/phone/verify` fires on button click, status ∈ {200, 400} |

### Customer — `journeys/test_journey_customer.py` (fixture `fresh_customer`: API-register `unique_email("customer")` → browser login → tokens lifted from `localStorage`)

| # | Action | Functional oracle | Technical oracle |
|---|--------|-------------------|------------------|
| C1 (5a) | `/businesses/{slug}/review`: `"5 stars"`, `"Title (optional)"`, body textarea `"Share details… (min 10 characters)"`, **click "Post review"** (Enter-noop first) | `to_have_url(/businesses/{slug}$)` | `POST /reviews` → 201, `ReviewResponse`; side-effect: body present in `Api.list_reviews(business.id)` |
| C2 (2) | Same form, title input last, **Enter** submits | `to_have_url(/businesses/{slug}$)` | `POST /reviews` → 201, `ReviewResponse` |
| C3 (4) | Fill body, focus `"Title (optional)"`, **Enter** with no star | `HumanForm.expect_validation("select a star rating")` — inline error visible | negative: no `POST …/reviews` fired |
| C4 (5b) | `/profile`: `#full_name`, `#phone`, placeholders `Address line 1` / `City` / `State` / `Postal code`, **Enter** | `"Profile updated."` visible | `PATCH /auth/me` → 200, `UserResponse` |
| C5 (5c) | *(skipped — see Known limitations)* | — | — |
| C6 (5d) | `/profile` → hidden `input[type=file]` `set_input_files(sample.png)` | (upload control exercised) | `POST /auth/me/avatar` → 200 (status asserted in `ProfilePage.upload_avatar`) |
| C7 (5e) | `/businesses/{slug}` → `favorite` button; reload | after reload, `button "favorited"` visible | `POST …/favorites` → 200/201 |
| C8 (5f) | Another API customer authors a review → this customer clicks `"Report"` → placeholder `"Why are you reporting this review? (min 10 characters)"` → `"Submit report"` | `"Reported — pending moderation."` visible | `POST /reviews/{id}/report` → 200 |
| C9 (5g) | `/settings` → `"Log out"` | `to_have_url(/)` after logout | replay pre-logout access token → `Api.get("auth/me")` → **401** (blocklist) |

### Merchant — `journeys/test_journey_merchant.py::test_merchant_full_journey` (one ordered flow; fixture `fresh_merchant`; cross-role approval via `admin_tokens` API)

| Step | Action | Functional oracle | Technical oracle |
|------|--------|-------------------|------------------|
| 6a | `/merchant/dashboard` with no business → `MerchantNationalIdCard`: aria `National ID type`=`pan`, `National ID number`=`ABCDE1234F`, `Confirm with password`, **Enter** | `heading "No business yet"` pre; `National ID number` becomes non-editable | `PATCH /auth/me` → 200, `UserResponse` (reauth step-up path) |
| 6b | `/merchant/businesses/new` `BusinessForm`: labels `Business name` / `Street address` / `City` / `Phone` / `Email`, **Enter** ("Submit for approval") | `heading "Register your business"` + `"New listings start as…"` pre; `to_have_url(/merchant/dashboard)` | `POST /businesses` → 201, `BusinessResponse`; `GET /businesses/mine` shows `status == "pending"` (authoritative, uncached) |
| 6c | Dashboard: `get_by_label("Date range").select_option("90")`; `"Refresh AI insights"`; `"Export CSV"` | date-range change re-queries; insights re-render | `GET /dashboard/merchant/{id}` fires on select; `POST …/refresh` → 200; `expect_download` → `suggested_filename` ends `.csv` |
| 6d | Dashboard `AIInsights` panel | verbatim copy `"Suggestions only — not definitive judgments. Verify in person before acting."` visible | — (non-negotiable #1 regression check) |
| — | admin approves | — | `Api.start_review` → `Api.approve_business` → 200 each |
| 6e | `/merchant/businesses/{id}/edit`: change `Street address` twice, `"Save changes"` | 1st save returns to editor; 2nd triggers `"Address verification code"` field | 2nd save: `"Verify & save"` → `PATCH …/businesses/…` → 200; **`pytest.skip`** if OTP not demanded (S-073 gate config) |
| 6f | Photo manager: `input[type=file]` add; `"Remove photo"` (auto-accept `window.confirm`) | remove button visible after add | `POST …/photos/upload`; `DELETE …/photos/{id}` |
| 6g | Dashboard `"Reply as business"` → placeholder `"Write a response to this review"` → **click "Post reply"** | reply body visible under the review | `POST /reviews/{id}/reply` → 201, `ReplyResponse` (via `MerchantDashboardPage`) |
| 6h | `FeaturedBoostPanel` `"Boost this listing"` → mock-complete | checkout response `provider_order_id` captured | `POST /payments/featured/checkout` → 200, then `Api.mock_complete_payment` → 200; **`pytest.skip`** on 404 (needs DEBUG) |

### Admin — `journeys/test_journey_admin.py` (seeded admin via `admin_browser` fixture = `LoginPage.login(admin)`; throwaway entities created per test)

| Test | Action | Functional oracle | Technical oracle |
|------|--------|-------------------|------------------|
| `test_admin_panel_and_subpages_load` | `/admin` + `/admin/{businesses,reviews,support,business-reports,whatsapp}` | `heading "Admin Panel"`, `navigation "Admin operations"`, all 7 section headings, stat tiles; each subpage shows `link "Admin panel"` | — |
| `test_admin_platform_stats_oracle` (7i) | — | — | `GET /dashboard/admin/platform` → `PlatformAnalytics` validates |
| `test_category_create_and_duplicate` (7a) | `AdminCategoryPanel` placeholder `"New category name"`, **Enter**; then duplicate | new category `link` visible; `"already exists"` inline on duplicate | `POST /businesses/categories` → 201; duplicate → 409 surfaced |
| `test_pending_business_start_review_then_approve` (7b) | throwaway pending business → `"Start review"` → `"Approve"` | queue row action | `…/start-review` → 200, `…/approve` → 200; `GET /businesses/{id}` → `status == "approved"` |
| `test_reported_review_moderation_cycle` (7c) | throwaway reported review → `"Hide"` → (`"Restore"` → `"Remove"`) | row `"Hide"` action fires | `…/moderate?action=hide` → 200; restore/remove `pytest.skip` if the row leaves the reported queue |
| `test_user_suspend_reactivate` (7d) | throwaway user → `"Suspend"` → `"Reactivate"` via `Search users` | row buttons | `…/suspend` → 200 `UserResponse`, `…/reactivate` → 200; suspended user `POST /auth/login` → 403 |
| `test_support_ticket_admin_update` (7e) | throwaway ticket visible on `/admin/support`; status + admin response via API | ticket issue snippet visible | `PATCH /admin/support-tickets/{id}` → `SupportTicketResponse`, `status == "in_progress"` |
| `test_business_report_thread_and_status` (7f) | throwaway report on `/admin/business-reports`; thread message + status via API | page loads (`link "Admin panel"`) | `POST …/messages` → 201, `PATCH …/business-reports/{id}` → `BusinessReportResponse` |
| `test_whatsapp_drafts_queue` (7g) | `/admin/whatsapp`; reject first seeded draft | page loads | `POST /admin/whatsapp/drafts/{id}/reject` → 200; **`pytest.skip`** if no seeded drafts |
| `test_admin_payment_actions` (7h) | throwaway approved business → featured checkout → mock-complete → `approve` + `refund` | `/admin` loads | `…/payments/{id}/approve` → 200, `…/refund` → 200/400; **`pytest.skip`** on mock-complete 404 |

---

## Enter-submit decision table

Copied from the slice's Architect section; drives `FormSpec.enter_submits` and the
`HumanForm.submit` branch.

| Form / widget | `enter_submits` | Why |
|---|---|---|
| `SearchBar` | **true** | real `<form action="/search" method="get">` + `<button type="submit">` |
| `FilterPanel` | **true** | same GET `<form>` + submit button |
| `LoginForm` (every step) | **true** | `<form onSubmit>` per step, submit button |
| `RegisterForm` | **true** | `<form onSubmit>` + submit |
| `ForgotPasswordForm` | **true** | `<form onSubmit>` + submit |
| `ResetPasswordForm` | **true** | `<form onSubmit>` + submit |
| `SupportTicketForm` (name / phone / businessId text inputs) | **true** | `<form onSubmit>`; Enter from a text input submits |
| `BusinessForm` | **true** | `<form onSubmit>` + "Submit for approval" (AC 6b requires Enter) |
| `ProfilePage` | **true** | `<form onSubmit>` + submit |
| `ReviewForm` (title text input) | **true** | `<form onSubmit>`; Enter from the **title** input (last non-textarea) submits |
| `MerchantNationalIdCard` | **true** | real `<form onSubmit>` with text inputs |
| `AdminCategoryPanel` | **true** | `<form onSubmit>` + submit |
| `GooglePlacePicker` | **true** | search `<form onSubmit>` (query text input) |
| `InlineAuthStep` (S-121) | **true** | `<form onSubmit>` + submit |
| `PhoneOtpPanel` | **false** | OTP boxes are `type="button"`-driven / segmented; Enter is a no-op → negative check then "Verify" |
| every admin queue **search box** | **false** | filter inputs, not in a submitting `<form>`; Enter must not navigate |
| card widgets (`FeaturedBoostPanel`, `CollectQrCard`, `WhatsAppUpdateCard`) | **false** | button-only, no text `<form>` |
| collect flow **"stars" step** | **false** | rating is a button group; advance via "Next"/"Continue" |
| every **textarea-terminated** form (`ReviewForm` body, collect text step, `ReviewCard` report / reply, `ReportShopButton`, `SupportTicketForm` issue textarea) | **false** | Enter in a `<textarea>` = newline; must click the labelled button |

Catalogue realisation: `enter_submits=True` — `anon.search_bar`, `anon.filter_panel`,
`anon.forgot_password`, `customer.review_title_enter`, `customer.profile_basics`,
`merchant.national_id`, `merchant.business_create`, `admin.category_create`.
`enter_submits=False` (Enter-noop negative check then button) — `anon.support_ticket`,
`customer.review`, `merchant.reply`. Login / register / phone-OTP / reset / collect /
address-OTP are `WIZARD_KEYS` driven step-by-step by the journey, not by a single
`fill_and_submit`.

---

## Known limitations / documented deviations

- **AC 5c (customer email change via `/profile`) is not implementable.** `ProfilePage`
  exposes no email-edit control — the UI reads "Email changes aren't supported yet."
  `test_journey_customer.py::test_profile_email_change_reauth` is `@pytest.mark.skip`
  with that reason. The **reauth (step-up) component** is instead regression-covered by
  **AC 6a**: `MerchantNationalIdCard` performs `auth.reauth` → `PATCH /auth/me` inside
  `test_merchant_full_journey`. **PM decision needed:** accept AC 5c as Manual/Blocked or
  descope it from the slice.
- **AC 6e / 7h / 6h are environment-conditional `pytest.skip`:**
  - 6e — address re-verification OTP only fires when the S-073 address-OTP gate is
    configured on in Compose; otherwise `skip("address OTP not demanded…")`.
  - 6h / 7h — `POST /payments/mock/complete` is DEBUG-only; `skip("payments mock/complete
    needs Compose DEBUG=true")` on 404.
- **AC 7g (WhatsApp drafts)** — `skip("no seeded WhatsApp drafts to approve/reject")`
  when the seed produced none. The implemented step rejects one draft; "edit draft text"
  and "approve one / reject another" are not both exercised (partial vs. the AC's full
  wording).
- **AC 7c** — Hide is always asserted; Restore → Remove are wrapped in a
  `try/except → pytest.skip` because the row can leave the reported queue after Hide in
  some states.
- **AC 7h** — Approve + Refund are exercised on one throwaway payment; the Reject path on
  a separate payment (AC wording: "separate throwaway payments") is not.
- **AC 7e / 7f** do a partial UI assertion (queue page loads, throwaway entity visible)
  plus the API-schema oracle — the admin support / report queues are button-only widgets,
  so the status change + admin response / thread message go through `Api` helpers, not
  keyboard-driven form fills.
- **AC 5d** asserts the upload API response (200) but not the "new avatar reflected in the
  UI" functional oracle.
- **AC 3** — `HumanForm.assert_enter_noop` runs for the three `enter_submits=False`
  catalogue specs and `PhoneOtpPanel` (via `test_register_phone_otp_wizard`). The AC's
  "every admin queue search box" and "collect flow stars step" Enter-is-inert checks are
  **not** separately asserted.
- **Coverage guard is single-process.** `web-e2e.yml` runs `pytest tests/e2e -v` with no
  `-n auto`, so `catalog_coverage.EXERCISED` is complete at teardown. Running locally with
  `pytest-xdist` **and** `E2E_FULL=1` will fail the guard (each worker only sees its own
  exercised set) — run the full guard single-process.

---

## Edge cases

- `/auth/register` (5/min) and `/auth/login` (10/min) rate limits under xdist / repeated
  fixture setup — `Api.register` / `complete_password_login` retry on 429 with a fixed
  backoff (`time.sleep` inside the API client only, never in the browser driver).
- 30 s notification poll defeats `wait_for_load_state("networkidle")` — every wait is
  `expect()`, `page.expect_response`, `page.expect_download`, or `wait_for_function`.
- `search:*` Redis cache staleness — fresh entities asserted via `/businesses/mine` or
  `/businesses/{slug}` (uncached); `/search` and `FilterPanel` results asserted against
  seed data only.
- `window.confirm` on photo delete / downloads — global `page.on("dialog", accept)` set
  by the `human` fixture; `page.expect_download` context; artifacts only under
  `test-results/`.
- TOTP clock skew — `pyotp.TOTP(secret).now()` generated immediately before each call,
  well inside the 30 s window (existing `api_client.py` / `pages/login.py` pattern).
- Client-side `localStorage` write race after login redirect — `HumanForm.wait_for_token()`
  (`wait_for_function`) and `LoginPage`'s URL-poll-then-read pattern.
- `NEXT_PUBLIC_GAMIFIED_REVIEW` flipped from default — `CollectPage.variant()` probe →
  `pytest.skip`; see the coverage-guard note above.
- Seeded admin used only as an actor; seeded approved business is read-only (throwaway
  customers' reviews against it are acceptable, cleaned by DB re-seed, never asserted as
  permanent state). Every created entity carries a `uuid4` suffix.

---

## Manual checklist

- [ ] **M-124-001** — On a machine with Docker: `docker compose up --build`, then
  `cd backend && E2E=1 E2E_FULL=1 pytest tests/e2e -v` (or dispatch the
  **Web e2e (Playwright)** workflow). Suite green including the session-teardown
  catalogue-coverage guard; attach / download the `playwright-traces` artifact and spot
  check one journey in `playwright show-trace`. **Blocks PM acceptance** — the build
  environment has no Docker, so this has not been run.
- [ ] **M-124-002** — Live Google OAuth sign-in with a real Google test account
  (client-side ID-token flow can't be scripted headlessly). Unchanged from
  TP-S-010 M-001 / ADR-009.

---

## AC → planned tests (summary; full AC-coverage matrix lives in TR-S-124)

| AC | Planned test(s) |
|----|-----------------|
| 1 / 1a / 1b / 1c | `test_journey_anonymous.py` (home SSR oracle, search bar, filter panel, business detail, review gate no-post, favorite redirect, collect inline-auth) |
| 2 | every `enter_submits=True` `FormSpec` + `test_review_title_input_enter_submits`, `test_search_bar_enter_submit`, `test_filter_panel_enter_submit`, `test_forgot_password_enter_submit`, `test_profile_basics_enter_submit`, merchant national-ID / business-create, `test_category_create_and_duplicate` |
| 3 | `HumanForm.assert_enter_noop` on `customer.review` / `merchant.reply` / `anon.support_ticket` + `test_register_phone_otp_wizard` ("Verify button, not Enter") |
| 4 | `test_review_requires_star_before_enter` (`HumanForm.expect_validation`) |
| 5a–5g | `test_journey_customer.py` (5c skipped — no UI) |
| 6a–6h | `test_merchant_full_journey` ordered steps |
| 7a–7i | `test_journey_admin.py` functions |
| 8 | `LoginPage.complete_totp` transitions + `test_login_wizard_totp` + `test_register_phone_otp_wizard` + collect + address-OTP steps |
| 9 | `_catalog_coverage_check` fixture + `catalog_coverage.assert_every_form_exercised` (17 keys) |
| 10 | the documented `pytest.skip` sites (seed / admin tokens / gamified flag / DEBUG) |
| 11 | `unique_email` / `unique_name` throughout; seeded admin used only as actor |
| 12 | `test_selectors_smoke.py` (`test_public_selectors_resolve`, `test_catalogue_is_internally_consistent`) |
