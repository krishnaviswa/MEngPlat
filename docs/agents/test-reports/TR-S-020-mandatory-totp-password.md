# TR-S-020: Mandatory TOTP for password login — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-020 |
| **Author** | Tester |
| **Date** | 2026-08-11 |
| **Recommendation** | Ship |

---

## Summary

Pass. All 4 AC verified — backend MFA branching logic is fully covered by 9 executed,
fully-mocked pytest unit tests (5 pre-existing + 4 new) that touch **zero real
database I/O**, plus 6 executed frontend RTL tests covering the same 4 AC at the UI
level. Google-bypasses-TOTP (AC3) additionally has real-world evidence: the mobile
(Flutter) client's login → TOTP-enroll/verify → business-list flow was already
verified end-to-end today on a real Android emulator via GitHub Actions CI
(`mobile-emulator-check.yml`), per the task brief — not re-verified in this pass.

One end-to-end backend integration test file was **written but not executed live**
this pass — see the environment finding below. No bugs found in the reviewed
implementation; no code changes made.

### Environment finding (important — read before relying on "backend integration: pass")

`backend/.env`'s `DATABASE_URL` points at the live Railway Postgres instance used by
this environment (`junction.proxy.rlwy.net`) — there is no isolated/ephemeral test
database, and no Docker is available here to stand one up. Early in this pass, before
this was identified, I ran the existing full `pytest` suite as a baseline (per the
task's "run the tests you touched" instruction, applied here too broadly before the
constraint was flagged). That baseline run — and one subsequent targeted re-run of
`test_api.py`, `test_businesses_mine.py`, `test_s011_s016_batch.py` while diagnosing
flakiness — executed real `POST /auth/register`, `POST /auth/login`,
`PATCH /auth/me`, favorites toggle, and business-creation calls against the live
database with no rollback. This is confirmed, not just suspected: a fixed-email test
in `test_api.py` (`testuser@example.com`, no uuid suffix) returned `409 Conflict` on
its second execution, which is only possible if the first run's row is still present
in a persistent, shared database.

Once this was flagged mid-session, **no further mutating backend tests were
executed.** The new cross-slice integration test
(`backend/tests/test_s018_s020_login_profile.py`) was written — using uuid-suffixed
emails so it would be safe to run against an isolated DB — and verified correct by
line-by-line code review against `backend/app/routers/auth.py`, but it has **not**
been executed against the live database. Its AC coverage below is marked "verified
via code review; live execution skipped," not an executed pass. I did not attempt to
clean up any of the rows created by the earlier runs (per instruction) — reporting
their existence here (notably `testuser@example.com` and various `merchant-*@example.com`
/ `customer-*@example.com` / `favuser@example.com` / `patchme@example.com` rows from
`test_s011_s016_batch.py`/`test_businesses_mine.py`) is itself part of this finding.

This is flagged as a **real risk to track**, not just the pre-existing "thin tests"
note already in the codebase: any future agent (human or AI) running `pytest` in this
backend without first checking `DATABASE_URL` will mutate production data. Recommend,
before this suite is relied on for CI gating or run again casually:
1. Point `backend/.env` (or a `backend/.env.test`) at an isolated/ephemeral Postgres
   (Dockerized, or a disposable branch of the managed instance).
2. Audit and fix the pre-existing fixed-email tests (`test_api.py::test_register_and_login`,
   several in `test_s011_s016_batch.py`) to use uuid-suffixed emails like the rest of
   the suite already does, so reruns are idempotent regardless of which DB they hit.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|-----------------|--------|
| 1 | No-TOTP password account must enroll (QR) before receiving tokens | A | Backend (mocked, executed): `backend/tests/test_mfa.py::test_login_requires_enrollment_when_totp_disabled`, `::test_totp_setup_returns_uri_secret_qr_and_keeps_totp_disabled`, `::test_totp_confirm_enables_totp_and_issues_tokens_on_correct_code`, `::test_mfa_token_cannot_authenticate_as_an_access_token`. Frontend (executed): `frontend/src/components/__tests__/LoginForm.test.tsx::"routes a first-time password login into the enroll step and fetches the QR/secret"`, `"issues session tokens and navigates away once enrollment is confirmed with a correct code"`. Backend integration (written, code-review only): `test_s018_s020_login_profile.py::test_password_login_totp_and_profile_enrichment_flow` | Pass |
| 2 | TOTP-enrolled account must verify a valid code before receiving tokens | A | Backend (mocked, executed): `test_mfa.py::test_login_requires_verify_when_totp_enabled`, `::test_totp_verify_issues_tokens`. Frontend (executed): `LoginForm.test.tsx::"routes a returning TOTP-enrolled login into the verify step, skipping setup"`, `"issues session tokens and navigates away once a correct verify code is submitted"`. Backend integration (written, code-review only): same file | Pass |
| 3 | Google sign-in issues tokens without TOTP | A + CI evidence | Backend (mocked, executed): `backend/tests/test_google_auth.py::TestNewAndReturningUsers::test_new_user_is_created_on_first_google_signin` (tokens asserted issued; `google_auth()` structurally never reads/writes any TOTP field), `::TestLoginGuardsGoogleOnlyAccounts::test_password_login_on_google_only_account_returns_400`. Backend integration (written, code-review only): `test_s018_s020_login_profile.py::test_google_login_bypasses_totp`. **Mobile:** `mobile-emulator-check.yml` CI run, 2026-08-11, real Android emulator — login → TOTP enroll/verify → business-list passed end-to-end (per task brief; not re-run this pass) | Pass |
| 4 | Wrong TOTP code on verify/confirm → 401, no tokens | A | Backend (mocked, executed): `test_mfa.py::test_totp_verify_rejects_bad_code` (pre-existing), `::test_totp_confirm_rejects_bad_code_and_leaves_totp_disabled` (new — closes a gap; no confirm-path wrong-code test existed before this pass). Frontend (executed): `LoginForm.test.tsx::"shows an error and stores no tokens when the verify code is wrong"`, `"...when the enrollment confirm code is wrong"`. Backend integration (written, code-review only): both wrong-code assertions in `test_s018_s020_login_profile.py` | Pass |

**Coverage:** 4 / 4 AC mapped

---

## Backend tests

### Added
- `backend/tests/test_mfa.py` — extended with 5 new tests (all mocked/fake DB, no real
  DB connection opened):
  - `test_totp_setup_returns_uri_secret_qr_and_keeps_totp_disabled`
  - `test_totp_confirm_enables_totp_and_issues_tokens_on_correct_code`
  - `test_totp_confirm_rejects_bad_code_and_leaves_totp_disabled`
  - `test_mfa_token_cannot_authenticate_as_an_access_token`
  - (plus the `_FlushOnlyDb` helper class used by the first three)
- `backend/tests/test_s018_s020_login_profile.py` — new file, 3 tests, **written this
  pass but not executed live** (see environment finding above):
  - `test_password_login_totp_and_profile_enrichment_flow`
  - `test_google_login_bypasses_totp`
  - `test_auth_me_and_logout_require_authentication`

### Run output
```
cd backend && .venv/Scripts/python.exe -m pytest -v tests/test_mfa.py tests/test_auth_logout.py tests/test_dependencies_blocklist.py tests/test_google_auth.py

tests/test_mfa.py::test_encrypt_decrypt_roundtrip PASSED
tests/test_mfa.py::test_verify_totp_code_accepts_current PASSED
tests/test_mfa.py::test_qr_svg_contains_svg_root PASSED
tests/test_mfa.py::test_create_mfa_token_purpose PASSED
tests/test_mfa.py::test_login_requires_enrollment_when_totp_disabled PASSED
tests/test_mfa.py::test_login_requires_verify_when_totp_enabled PASSED
tests/test_mfa.py::test_totp_verify_issues_tokens PASSED
tests/test_mfa.py::test_totp_verify_rejects_bad_code PASSED
tests/test_mfa.py::test_totp_setup_rejects_already_enabled PASSED
tests/test_mfa.py::test_totp_setup_returns_uri_secret_qr_and_keeps_totp_disabled PASSED
tests/test_mfa.py::test_totp_confirm_enables_totp_and_issues_tokens_on_correct_code PASSED
tests/test_mfa.py::test_totp_confirm_rejects_bad_code_and_leaves_totp_disabled PASSED
tests/test_mfa.py::test_mfa_token_cannot_authenticate_as_an_access_token PASSED
tests/test_auth_logout.py :: 5 passed
tests/test_dependencies_blocklist.py :: 2 passed
tests/test_google_auth.py :: 8 passed

28 passed, 9 warnings in ~6-7s
```
All 28 of these tests call router/service/dependency functions directly with
mocks/fakes (`SimpleNamespace`, `FakeDB`, `_FlushOnlyDb`, `_ExplodingDB` — see each
file's docstring) — none open a real database connection, so all were safe to execute
against the current environment and were in fact run live, repeatably, with
consistent results.

`test_s018_s020_login_profile.py` was **not** included in this run (would require the
live production DB) — see environment finding.

---

## Frontend tests

### Added
- `frontend/src/components/__tests__/LoginForm.test.tsx` — new file, 6 tests

### Run output
```
cd frontend && npx jest src/components/__tests__/LoginForm.test.tsx

PASS src/components/__tests__/LoginForm.test.tsx
  LoginForm
    √ routes a first-time password login into the enroll step and fetches the QR/secret
    √ issues session tokens and navigates away once enrollment is confirmed with a correct code
    √ routes a returning TOTP-enrolled login into the verify step, skipping setup
    √ issues session tokens and navigates away once a correct verify code is submitted
    √ shows an error and stores no tokens when the verify code is wrong
    √ shows an error and stores no tokens when the enrollment confirm code is wrong

Test Suites: 1 passed, 1 total
Tests:       6 passed, 6 total
```
Full suite (`cd frontend && npx jest`) also run: **10 suites / 38 tests, all passed**
— no regressions.

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | Register, log in, scan QR with a real authenticator app, confirm session issued | Not executed — no Docker/browser in this environment |
| M-002 | Log out/in again, verify step with a real authenticator code | Not executed — same reason |
| M-003 | Google sign-in shows no TOTP step | Not executed live in a browser here; equivalent proven at the API-contract level (`test_google_auth.py`) and end-to-end on mobile via CI |
| Mobile E2E | login → TOTP enroll/verify → business-list, real Android emulator | **Pass** — `mobile-emulator-check.yml`, GitHub Actions CI, 2026-08-11 (per task brief; not independently re-verified in this session) |

---

## Regressions

None observed in the tests actually executed this pass.

---

## Gaps / rework items

1. **Test infra / safety risk (highest priority, not a slice-implementation bug):**
   `backend/.env`'s `DATABASE_URL` is the live production Railway Postgres instance;
   there is no isolated test DB in this environment. This blocked live execution of
   the new `test_s018_s020_login_profile.py` integration file and caused real rows to
   be persisted by an earlier baseline run before the constraint was identified (see
   Summary). Recommend: (a) an ephemeral/Dockerized Postgres for test runs, (b) fixing
   the pre-existing fixed-email tests noted above so reruns are idempotent regardless.
2. `test_s018_s020_login_profile.py`'s "Pass" status in the AC matrix above is
   **code-review-verified, not execution-verified**. Recommend running it once an
   isolated test DB exists, before treating this slice's backend integration coverage
   as fully proven end-to-end (as opposed to proven at the unit level, which it is).
3. Minor gaps noted in `TP-S-020`'s Edge cases section, none blocking: no dedicated
   test for `/mfa/totp/confirm` called before `/setup` (guard exists, verified by code
   review only), no dedicated test for `mfa_token` replay-after-consumption (blocklist
   exists, verified by code review only), no explicit TOTP clock-skew boundary test
   (pre-existing gap, not introduced this pass).

None of the above indicate a defect in S-020's implementation — the router/service
code was read in full and every AC's logic checks out. The gaps are entirely about
*live execution evidence* for the DB-touching integration path, blocked by the
environment constraint.

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested (mfa-token-as-access-token rejection, blocklisted-token rejection,
      Google-only/password-login guard, suspended-account guard — all executed, mocked)
- [x] AI disclaimer verified (if applicable) — N/A, no AI-generated content in this slice
- [x] Ready for PM acceptance
