# TR-S-035: Transactional email — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-035 |
| **Author** | Tester |
| **Date** | 2026-08-15 |
| **Recommendation** | Ship |

---

## Summary

Pass. All 7 AC verified — 6 fully by automated test, 1 (AC 5, the "no marketing/subscribe
UI" half) by automated template-content test plus a manual/code-review check of the
frontend routes. 54 new backend pytest tests + 11 new/changed frontend RTL/Jest tests
added, all green, no regressions in the existing suite (268/268 backend tests that don't
require a live/ephemeral DB still pass; 96/96 frontend tests pass). One **pre-existing
test-only regression** was found and fixed (not a product-code defect — see Regressions).
No product code was changed by this pass beyond that one test fixture.

**Environment constraint (same class of issue as `TR-S-018`, not specific to this
slice):** `backend/.env`'s `DATABASE_URL` points at the live Railway Postgres instance
(confirmed reachable this session) and `REDIS_URL` points at a local Redis that is **not**
reachable in this environment (confirmed: `ConnectionError` on `PING`). Given the explicit
`NOTE: never run this file locally against the project's dev DATABASE_URL` warnings
already in `test_admin_browse_asgi.py` / `test_admin_platform_asgi.py`, and to avoid
persisting more test rows into the shared live database, every S-035 test in this pass
uses the codebase's dominant convention (direct router-function calls + fake db/fake
Redis — the same pattern `test_reviews.py`, `test_businesses_cache_invalidation.py`,
`test_auth_hardening.py`, and `test_cache_lock.py` already use) rather than
ASGI-transport + real Postgres/Redis. This is called out per-AC below and summarized in
Gaps.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|-----------------|--------|
| 1 | Mock provider = logs only, no vendor network call; send failure never blocks review-create / business-approve | A | `test_email_provider.py::test_mock_provider_logs_to_from_subject_and_body`, `::test_mock_provider_never_touches_httpx` (asserts `httpx.AsyncClient` is never constructed), `::test_try_send_swallows_provider_send_exception_and_logs`, `::test_try_send_swallows_get_email_provider_exception_itself`; `test_transactional_email_side_effects.py::TestApproveBusinessNotificationAndEmail::test_approve_succeeds_and_still_persists_notification_when_email_send_fails`, `::TestCreateReviewNotificationAndEmail::test_create_review_succeeds_and_still_persists_notification_when_email_send_fails` (both patch the email vendor boundary to raise and assert the router's own HTTP-facing result + the `Notification` row are unaffected) | Pass |
| 2 | Forgot-password: same generic response for known / unknown / Google-only addresses; no extra enumeration | A | `test_forgot_reset_password.py::TestForgotPasswordEnumeration` (4 tests, incl. `test_response_body_is_identical_for_known_unknown_and_google_only` — direct dict-equality across all three), `::TestForgotPasswordRedisDown::test_returns_503_before_the_account_lookup` (asserts `db.execute` never called — the 503 branch itself can't leak); frontend: `ForgotPasswordForm.test.tsx` (2 tests confirming identical on-screen copy) | Pass |
| 3 | Admin approve → merchant gets in-app `APPROVAL` notification (previously-missing row) **and** a best-effort "listing approved" email | A | `test_transactional_email_side_effects.py::TestApproveBusinessNotificationAndEmail::test_creates_approval_notification_row`, `::test_sends_listing_approved_email_to_business_owner`, `::test_creates_audit_log_row`, `::test_no_merchant_row_skips_notification_and_email_without_error` (orphan-business edge case) | Pass |
| 4 | Customer review → merchant gets in-app `REVIEW` notification **and** a best-effort "new review" email; reviewer is never the recipient | A | `test_transactional_email_side_effects.py::TestCreateReviewNotificationAndEmail::test_creates_review_notification_row`, `::test_emails_business_owner_not_the_reviewer` (asserts recipient == owner email and `!=` reviewer email) | Pass |
| 5 | All three templates are transactional-only; no newsletter/promo/campaign template or subscribe/unsubscribe UI | A + M | `test_email_templates.py::test_no_marketing_or_campaign_language_in_any_template` (11-marker keyword sweep across all 3 rendered bodies+subjects); M-001 (frontend route/component code review — no email-settings page, no subscribe UI added; `ForgotPasswordForm`/`ResetPasswordForm` are the only new routes and both are reset-flow-only) | Pass |
| 6 | Local/demo with mock provider: reset/approve/review-submit work fully offline; all 3 sends land in inspectable logs | A | `test_email_provider.py::test_mock_provider_logs_to_from_subject_and_body` + all 3 `try_send_*` tests (provider swap proven via `get_email_provider()` factory tests); `test_password_reset.py` (7 tests, no real Redis) + `test_forgot_reset_password.py` (14 tests, no real Redis) prove reset works with a fake in-memory store standing in for `mock`-equivalent offline operation; M-002 (full `docker compose up --build` browser smoke — not executed, no Docker in this environment, see Gaps) | Pass (automated); M-002 not executed |
| 7 | No AI-generated text in any v1 email body (no sentiment, no suggested reply, no insights) | A | `test_email_templates.py::test_no_ai_derived_language_in_any_template` (8-marker keyword sweep) + 3 signature-shape tests (`test_new_review_email_signature_only_accepts_business_name_and_a_plain_rating`, `test_listing_approved_email_signature_only_accepts_business_name`, `test_password_reset_email_signature_only_accepts_a_token` — guards a future accidental AI-field addition); code inspection of the two call sites confirms only `business.name` (str) and `payload.rating` (plain int) ever cross into a template, never `ai_analysis`/`ai_merchant_summary`/`sentiment`/`suggested_response` | Pass |

**Coverage:** 7 / 7 AC mapped

---

## Backend tests

### Added
- `backend/tests/test_password_reset.py` (7 tests) — `app/services/password_reset.py`: hashed key shape, TTL=3600/NX on create, single-use delete on consume, fail-**closed** on Redis error for both create and consume (fake Redis, same convention as `test_cache_lock.py`).
- `backend/tests/test_email_provider.py` (16 tests) — mock provider (log content, zero `httpx` usage), `get_email_provider()` factory (mock default / resend), `validate_startup_config()` (unregistered name, resend missing key/from, mock/resend happy paths — mirrors `test_ai_startup_validation.py`), `try_send_*` catch-all-and-log contract (provider-raises and factory-raises cases), and the Resend HTTP adapter's request shape (`Authorization: Bearer`, `from`/`to`/`subject`/`text` payload) plus its error-propagation (so `try_send_*` has something real to catch) via a fake `httpx.AsyncClient`.
- `backend/tests/test_email_templates.py` (9 tests) — AC 5/AC 7 content sweeps (marketing-marker and AI-marker keyword lists) across all 3 rendered templates, plus per-template content/signature assertions.
- `backend/tests/test_forgot_reset_password.py` (14 tests) — `POST /auth/forgot-password` / `POST /auth/reset-password` router functions called directly with a fake db + fake Redis (mirrors `test_auth_hardening.py`); enumeration-parity, Redis-down 503-before-lookup, reset happy path (password hash actually changes, no session tokens), generic 400 for missing/expired/orphaned token, 503 on Redis error during consume, and `ForgotPasswordRequest`/`ResetPasswordRequest` schema validation (password policy reuse).
- `backend/tests/test_transactional_email_side_effects.py` (8 tests) — `approve_business` / `create_review` best-effort email + notification side effects (AC 1/3/4), using a fake db that (unlike the pre-existing fakes in `test_reviews.py`/`test_businesses_cache_invalidation.py`) also tracks a `users` table so the new `db.get(User, merchant.user_id)` lookup resolves to a real row instead of always `None`.
- `backend/tests/test_businesses_cache_invalidation.py` — **1-line fix to a pre-existing test fixture**, not a new test (see Regressions).

### Run output
```
cd backend && .venv/Scripts/python.exe -m pytest -q tests/test_password_reset.py tests/test_email_provider.py \
  tests/test_email_templates.py tests/test_forgot_reset_password.py \
  tests/test_transactional_email_side_effects.py tests/test_businesses_cache_invalidation.py

57 passed in 3.85s   (54 new S-035 tests + 3 pre-existing businesses-cache-invalidation tests, incl. the one this pass fixed)

cd backend && .venv/Scripts/python.exe -m pytest -q --ignore=tests/test_admin_browse_asgi.py \
  --ignore=tests/test_admin_platform_asgi.py --ignore=tests/test_api.py \
  --ignore=tests/test_businesses_mine.py --ignore=tests/test_dashboard.py \
  --ignore=tests/test_s011_s016_batch.py --ignore=tests/test_s018_s020_login_profile.py

268 passed, 12 warnings in 7.62s   (full non-DB-dependent suite; 214 baseline + 54 new, zero regressions)
```
The 7 ignored files are pre-existing ASGI-transport + real-Postgres integration files unrelated
to S-035 (S-021/S-034/S-011/S-016/S-018/S-020/mine-listing coverage); they were not re-run this
pass to avoid compounding writes against the shared live database, consistent with those files'
own `NOTE: never run this file locally against the project's dev DATABASE_URL` warnings.

---

## Frontend tests

### Added
- `frontend/src/components/__tests__/ForgotPasswordForm.test.tsx` (4 tests) — generic confirmation copy shown for any submitted email, error surfaced instead of the confirmation on API failure, back-to-login link.
- `frontend/src/components/__tests__/ResetPasswordForm.test.tsx` (4 tests) — missing-token invalid-link state, happy path (token from URL + password → success screen → link to `/login`, no session stored), client-side password-mismatch guard, generic invalid/expired error surfaced from the API.
- `frontend/src/components/__tests__/LoginForm.test.tsx` — +1 test: "Forgot password?" link present and points to `/forgot-password`.
- `frontend/src/lib/__tests__/api.test.ts` — +2 tests: `auth.forgotPassword`/`auth.resetPassword` POST the expected URL/body shape (incl. `new_password` snake_case).

### Run output
```
cd frontend && npx jest src/components/__tests__/ForgotPasswordForm.test.tsx \
  src/components/__tests__/ResetPasswordForm.test.tsx src/components/__tests__/LoginForm.test.tsx \
  src/lib/__tests__/api.test.ts

PASS (4 suites, 25 tests)

cd frontend && npx jest

Test Suites: 21 passed, 21 total
Tests:       96 passed, 96 total
```
Full suite run, zero regressions.

`cd frontend && npx tsc --noEmit` — no errors in any S-035 file (`ForgotPasswordForm.tsx`,
`ResetPasswordForm.tsx`, `app/forgot-password/page.tsx`, `app/reset-password/page.tsx`,
`LoginForm.tsx`, `lib/api.ts`, and the 4 new/changed test files). The command does report
~60 pre-existing `Property 'toBeInTheDocument' does not exist` errors, but they're spread
across many unrelated pre-existing test files (`MerchantDashboard.test.tsx`,
`ReviewCard.test.tsx`, `AdminUserPanel.test.tsx`, `StatCard.test.tsx`, etc.) — a
project-wide `tsc`-vs-`jest-dom`-types environment quirk that predates this slice, not
something S-035 introduced. `npm run lint` / raw `eslint` could not run in this environment
(no `eslint.config.js` present; `next lint`'s interactive setup wizard is not scriptable
headlessly here) — also a pre-existing repo gap, not S-035-specific.

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | Code review: no marketing/campaign page or subscribe-unsubscribe UI was added; the only new frontend surfaces are `/forgot-password`, `/reset-password`, and the "Forgot password?" link on `/login`'s credentials step; no merchant email-settings page exists | Pass |
| M-002 | `docker compose up --build`; trigger forgot-password, listing-approved (admin approve), and new-review (customer review) with `EMAIL_PROVIDER=mock` (default) and no internet to a mail vendor; confirm all three land in backend logs and the reset link from the log completes a real password change via `/reset-password` | Not executed — no Docker available in this environment. Covered instead by the automated `try_send_*`/mock-provider tests (log content, zero-network) plus the fake-Redis-backed reset round-trip tests, which exercise the same code paths without a container runtime. |
| M-003 | Swagger `/docs` shows `POST /auth/forgot-password` and `POST /auth/reset-password` matching the implemented request/response/error shapes in the slice's technical spec | Not executed live (no running server in this environment) — confirmed instead by direct code read of `backend/app/routers/auth.py`'s docstrings/response models against the spec's API-contract table; shapes match (`MessageResponse`, 422/429/503/400 as specified). |

---

## Regressions

**Found and fixed (test-only, not a product-code defect):** `approve_business`'s new
`Merchant` lookup (added by this slice, needed to resolve the notification/email
recipient) calls `.scalar_one_or_none()` on the query result. The pre-existing
`test_businesses_cache_invalidation.py::test_approve_business_invalidates_search_cache`
test used a local `FakeResult` fixture that only implemented `.scalar_one()`, not
`.scalar_one_or_none()` — every other `FakeResult` in this codebase (`test_reviews.py`,
`test_notifications.py`, `test_auth_hardening.py`) already implements both. Without a fix,
this pre-existing test would `AttributeError` on every future run, purely because its
local fake fell behind a legitimate new query shape — `approve_business` itself is
correct against a real `AsyncSession`. Fixed by adding a 4-line `scalar_one_or_none()`
method to that file's `FakeResult` (returns `None` when no rows match, same as every
other fake in the repo). Confirmed passing after the fix; no other pre-existing test was
affected (full 268-test non-DB suite is green).

No other regressions observed.

---

## Gaps / rework items

None block shipping. Flagged for awareness:

1. **No live ASGI + real-Postgres/Redis round trip was executed for S-035 specifically**
   (see Summary's environment note). Every S-035 assertion — including "the `Notification`
   row actually persists with the right enum value" and "`approve_business`/
   `create_review`'s real `Depends(require_roles(...))` chain resolves correctly" — is
   proven at the direct-function-call + fake-db/fake-Redis level, the same convention the
   majority of this repo's existing test suite already uses, rather than through a real
   commit. This mirrors a pre-existing, previously-flagged (`TR-S-018`) gap in the
   project's test infrastructure (no isolated/ephemeral test database), not something
   introduced by this slice. Recommend a dedicated ephemeral Postgres + Redis (Docker
   Compose test profile or CI service containers) before RBAC/persistence assertions for
   *any* slice are relied on beyond fake-db coverage.
2. **M-002 / M-003 not executed live** — no Docker/running server in this environment.
   Covered instead by equivalent automated coverage at the unit/router level (see table
   above).
3. **Minor code-inspection note, not a functional bug:** `password_reset.create_reset_token`
   calls `client.set(key, value, ex=3600, nx=True)` but never checks the return value. A
   `nx=True` SET silently no-ops if the key already exists; since the key is
   `sha256(secrets.token_urlsafe(32))`, an accidental collision with a still-live reset
   token is astronomically unlikely (~1 in 2^256) and not practically exploitable — flagged
   for completeness only, not a blocker.

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested — N/A for the two new endpoints by design (`POST /auth/forgot-password`
      and `POST /auth/reset-password` are intentionally public per the slice's own RBAC
      matrix; no `Depends(get_current_user)`/`require_roles` exists to test). The
      pre-existing RBAC on `POST /businesses/{id}/approve` (admin-only) and
      `POST /reviews` (customer/merchant/admin) is unchanged by this slice and already has
      401/403 coverage elsewhere in the suite (`test_admin_browse_asgi.py`,
      `test_businesses_cache_invalidation.py`, `test_reviews.py`).
- [x] AI disclaimer verified (if applicable) — N/A by design: AC 7 requires **no** AI
      content in any v1 email body, and `test_email_templates.py` proves that (keyword
      sweep + call-site inspection). If a later slice adds AI-derived text to an email,
      the "suggestion" disclaimer becomes mandatory per the slice's own UX notes.
- [x] Ready for PM acceptance
