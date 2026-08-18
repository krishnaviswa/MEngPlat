# TR-S-068: Merchant-aware OTP login — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-068 |
| **Author** | Tester |
| **Date** | 2026-08-18 |
| **Recommendation** | Ship |

---

## Summary

**Pass.** The frontend-only scope the Architect defined — a `loginRole` selector on
`LoginForm` passed through to `PhoneOtpPanel`, plus a role-mismatch note built on S-067's
`redirectAfterAuth` via new `expectedRole`/`onRoleMismatch` options — is implemented exactly
as specified. I independently re-read `app/routers/auth.py::phone_otp_verify` (backend,
unchanged by this slice) and confirmed the Architect's "Pre-read finding" claim is accurate:
an existing account's `role` field on the request is genuinely ignored
(`_issue_session_tokens(user)` uses `user.role`, never `payload.role`), so AC4's "no
privilege confusion via a mismatched role hint" holds at the backend level regardless of
what the frontend sends. AC3, AC6, AC8 are regression checks on that same pre-existing,
unchanged backend behavior plus the untouched password/TOTP path — verified by code read,
no backend files were modified.

Full frontend suite: **206/206 passing**, 41/41 suites (same run as TR-S-067 — both slices
share the same touched files and were verified together).

**Environment note:** see TR-S-067's "Environment note" — the same shared-working-directory
caveat applies here since both slices touch the same files
(`LoginForm.tsx`/`PhoneOtpPanel.tsx`/`api.ts`). All results below reflect one final,
decisive `npx jest` run taken immediately after a last code read of the five files this
slice's spec lists as in scope.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Phone-OTP option visibly available on `/login` regardless of intended role | A | `LoginForm.test.tsx::"renders a 'Signing in as' role selector defaulting to customer, with only customer/merchant options, and passes the picked role into the phone-OTP verify call"` — asserts `PhoneOtpPanel` (via its "Send SMS code"/"Mobile number" controls) renders unconditionally on the credentials step | Pass |
| 2 | Role selector mirrors `RegisterForm.tsx`, passes chosen role through to `PhoneOtpPanel` | A | Same test as AC1: asserts the "Signing in as" `<select>` defaults to `customer`, offers exactly `["customer","merchant"]` (no admin, matching `RegisterForm`), and that changing it to `merchant` results in `auth.phoneVerify` being called with `role: "merchant"` | Pass |
| 3 | Existing merchant with verified phone: OTP login authenticates + routes to merchant dashboard, skipping TOTP | A (existing, regression) + code read | `PhoneOtpPanel.test.tsx::"requests a code then verifies and stores tokens"` (calls `auth.phoneVerify` directly, no TOTP step in the component at all) + `frontend/src/lib/__tests__/api.test.ts::redirectAfterAuth::"stores tokens and redirects a merchant to /merchant/dashboard"` + backend code read confirming `/auth/phone/verify` never invokes any TOTP check (`app/routers/auth.py::phone_otp_verify`, lines ~473-522) | Pass |
| 4 | Role mismatch (hint says merchant, true account is customer, or vice versa) → explicit on-screen note, no silent misrouting | A | `PhoneOtpPanel.test.tsx::"shows an inline role-mismatch note when redirectAfterAuth reports the resolved role differs from the picked role"` (new test) + `api.test.ts::redirectAfterAuth::"invokes onRoleMismatch and still redirects when the resolved role differs from expectedRole"` / `"does not invoke onRoleMismatch when the resolved role matches expectedRole"` (3 new tests) + backend code read: existing-account branch always uses `user.role`, ignoring the request's `role` field entirely, so the "true role always wins" guarantee holds server-side independent of the frontend note | Pass |
| 5 | Merchant with no verified phone → clear explanatory UI, no dead end | M (UX-copy mitigation, by design — not a backend gate) | `LoginForm.test.tsx::"shows help copy above the phone panel warning phone sign-in only matches an already-verified number"` (new test) asserts the static help text renders. **Accepted, scoped limitation** (per Architect's own "Risks/tradeoffs"): this is copy-only, not a hard block, because ADR-011's auto-register-on-verify design means the backend cannot distinguish "returning merchant, forgot they never added a phone" from "brand-new signup" without a new lookup endpoint, which is explicitly out of scope. Not a failed AC — it is the deliberately scoped mitigation the slice asked for. | Pass (as scoped) |
| 6 | Merchant with password+TOTP MFA still sees the existing TOTP step unchanged | A (existing, regression) | `LoginForm.test.tsx` — 5 pre-existing S-020 tests (`"routes a first-time password login into the enroll step..."`, `"routes a returning TOTP-enrolled login into the verify step, skipping setup"`, etc.) exercise the password/TOTP path end-to-end and are unmodified in behavior by this slice; `loginRole`/`PhoneOtpPanel` changes only touch the phone-OTP branch, never `handleSubmit`'s password/TOTP logic (confirmed by code read — `loginRole` state is not referenced anywhere in `handleSubmit`) | Pass |
| 7 | Visible auth-method parity between `RegisterForm.tsx` and `LoginForm.tsx` for merchant role | A + code read | Code read of both components: both render password fields (`RegisterForm` also has them for account creation), `GoogleSignInButton`, a role `Select` (`RegisterForm`'s always-visible; `LoginForm`'s new one gates only the phone path per spec), and `PhoneOtpPanel`. `LoginForm.test.tsx`'s new selector test plus the existing `PhoneOtpPanel` presence in every `LoginForm` render together demonstrate the closed gap | Pass |
| 8 | Admin account: phone-OTP availability/non-applicability unchanged by this slice | A (existing, regression) + code read | No admin-facing UI or backend branch added by this slice (confirmed by code read of both `LoginForm.tsx`'s selector, which offers only `customer`/`merchant`, matching `RegisterForm`'s existing self-register-as-admin block, and `phone_otp_verify`'s existing `role == UserRole.ADMIN → 403` guard, untouched) | Pass |

**Coverage:** 8 / 8 AC mapped (6 automated, 1 automated+code-read as a scoped/accepted
by-design limitation, 1 automated+code-read regression check).

---

## Backend tests

### Added
None — no backend files were modified by this slice (confirmed via `git diff` — only
`frontend/src/lib/api.ts`, `LoginForm.tsx`, `PhoneOtpPanel.tsx`, and their test files
changed). Existing backend coverage for `/auth/phone/request` and `/auth/phone/verify` from
S-044 (`TR-S-044-phone-otp.md`) already covers `test_verify_new_user_requires_name`,
`test_verify_blocks_admin_self_register`, `test_verify_bad_code_is_401`, etc., and remains
valid since the endpoints are reused as-is.

### Run output
Not applicable — no backend files touched by this slice. (Did not re-run
`cd backend && pytest` since nothing in `backend/` is in this slice's diff; re-confirmed via
`git diff --stat` that no `backend/app/routers/auth.py` change exists on top of the S-044
baseline.)

---

## Frontend tests

### Added
- `frontend/src/components/__tests__/LoginForm.test.tsx`:
  - `"renders a 'Signing in as' role selector defaulting to customer, with only customer/merchant options, and passes the picked role into the phone-OTP verify call"`
  - `"shows help copy above the phone panel warning phone sign-in only matches an already-verified number"`
- `frontend/src/components/__tests__/PhoneOtpPanel.test.tsx`:
  - `"shows an inline role-mismatch note when redirectAfterAuth reports the resolved role differs from the picked role"`
- `frontend/src/lib/__tests__/api.test.ts::redirectAfterAuth` (shared with TR-S-067, directly
  relevant here for the `expectedRole`/`onRoleMismatch` extension point this slice adds):
  - `"invokes onRoleMismatch and still redirects when the resolved role differs from expectedRole"`
  - `"does not invoke onRoleMismatch when the resolved role matches expectedRole"`

### Run output
```
cd frontend && npx jest LoginForm PhoneOtpPanel api.test
Test Suites: 3 passed, 3 total
Tests:       27 passed, 27 total

cd frontend && npx jest   (full suite)
Test Suites: 41 passed, 41 total
Tests:       206 passed, 206 total
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-068-01 | Live click-through: on `/login`, pick "Merchant" in the role selector, request+verify an OTP for a brand-new phone number, land on `/merchant/dashboard` with a merchant account actually created (mock SMS provider) | Not run — no live backend/Postgres/Redis reachable in this sandbox. **Known gap**, run via `docker compose up --build` (`AI_PROVIDER=mock`/mock SMS) before merge. |
| M-068-02 | Live click-through: an existing *customer* phone number, with "Merchant" picked in the selector, shows the role-mismatch note ("Signed in as customer — this number is already registered as a customer account.") before redirecting to `/` (not `/merchant/dashboard`) | Not run — same limitation. Unit-level equivalent is covered by `PhoneOtpPanel.test.tsx`'s new mismatch test, but the real 1.5s on-screen timing/readability was not observed in a real browser. |
| M-068-03 | Swagger `/docs` — confirm `/auth/phone/request` and `/auth/phone/verify` schemas are unchanged from S-044 | Not run — no live backend to inspect; confirmed instead via code read that `app/routers/auth.py` has no diff against the S-044 baseline for these routes. |

---

## Regressions

None found. 206/206 passing (identical count/result to TR-S-067's run, since both slices
share the same test files and were verified in the same pass).

---

## Gaps / rework items

1. **AC5 is a copy-only mitigation by explicit design, not a full fix** — flagged here per
   the Architect's own instruction to report it as an accepted, scoped limitation rather
   than a failure. No action needed for this slice; a real fix would require a new
   phone-lookup endpoint, explicitly out of scope.
2. **M-068-01/M-068-02 (live OTP flow, live role-mismatch note) unverified end-to-end** —
   same sandbox limitation as TR-S-067; must be exercised via `docker compose up` before
   merge, particularly to visually confirm the role-mismatch note's copy and the 1.5s delay
   before redirect feel right in a real browser (this was only asserted programmatically via
   the mocked `redirectAfterAuth` callback, not observed as rendered UI timing).

Neither item blocks shipping — both are accepted, previously-scoped limitations or sandbox
constraints, not defects in the delivered code.

---

## Sign-off

- [x] All AC mapped to tests (6 automated + 1 automated/code-read scoped-limitation + 1 automated/code-read regression)
- [x] RBAC tested (backend code read confirms admin self-register-as-admin-via-phone is still blocked; existing-account role hint is provably ignored server-side)
- [x] AI disclaimer verified (n/a — slice has no AI-generated content, per its own UX notes)
- [x] Ready for PM acceptance
