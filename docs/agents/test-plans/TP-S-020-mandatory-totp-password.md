# TP-S-020: Mandatory TOTP for password login — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-020 |
| **Author** | Tester |
| **Date** | 2026-08-11 |

> Tested together with S-018 and S-019 — see TP-S-018 for the shared environment note.
> Mobile (Flutter) is **out of scope for this pass**: it was already built and verified
> end-to-end today on a real Android emulator via GitHub Actions CI
> (`mobile-emulator-check.yml`) — login → TOTP enroll/verify → business-list passed. See
> the S-020 test report for that CI evidence citation; this plan covers backend + web
> frontend only.

---

## Scope

`POST /auth/login` MFA branching, `POST /auth/mfa/totp/{setup,confirm,verify}`,
`POST /auth/google` (TOTP bypass), and the multi-step `LoginForm` (credentials →
enroll → verify).

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend (unit, mocked DB) | pytest | Router-level MFA branching, TOTP setup/confirm/verify, mfa-token type enforcement — all run against fakes, **zero real DB I/O**, safe to execute live |
| Backend (integration, real DB) | pytest (`httpx.AsyncClient` + `ASGITransport`) | Full register → login → enroll/verify → logout flow — **written this pass but not executed live** (see environment note) |
| Frontend | Jest + RTL | `LoginForm` step transitions, token issuance, wrong-code error handling |
| Mobile | Flutter integration test on Android emulator (CI) | Already executed and passed today — reused as evidence, not re-run |
| Manual | Browser | QR scan with a real authenticator app |

**Environment note:** `backend/.env`'s `DATABASE_URL` points at the live Railway
Postgres instance for this environment; there is no isolated/ephemeral test DB and no
Docker available here to create one. A baseline full-suite `pytest` run performed
*before* this constraint was flagged already persisted rows to that database (a fixed
test email in a pre-existing test file collided with itself on a rerun — `409` on
`testuser@example.com`, confirming the DB is real, shared, and durable across runs).
No further mutating backend tests were executed after the constraint was identified.
The new integration file (`backend/tests/test_s018_s020_login_profile.py`) is written,
uses uuid-suffixed emails so it *would* be safe to rerun against an isolated DB, and is
verified correct by code review against `backend/app/routers/auth.py` — but it has not
been run against the live database and its "passed" status in the report below is
therefore "verified via code review; live execution skipped," not an executed result.

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1. No-TOTP password account must enroll (QR) before receiving tokens | Automated (mocked, executed) | `backend/tests/test_mfa.py::test_login_requires_enrollment_when_totp_disabled`, `::test_totp_setup_returns_uri_secret_qr_and_keeps_totp_disabled`, `::test_totp_confirm_enables_totp_and_issues_tokens_on_correct_code`, `::test_mfa_token_cannot_authenticate_as_an_access_token`. Frontend: `frontend/src/components/__tests__/LoginForm.test.tsx::"routes a first-time password login into the enroll step..."`, `"issues session tokens and navigates away once enrollment is confirmed..."`. Backend integration (written, not live): `test_s018_s020_login_profile.py::test_password_login_totp_and_profile_enrichment_flow` |
| 2. TOTP-enrolled account must verify a valid code before receiving tokens | Automated (mocked, executed) | `test_mfa.py::test_login_requires_verify_when_totp_enabled`, `::test_totp_verify_issues_tokens`. Frontend: `LoginForm.test.tsx::"routes a returning TOTP-enrolled login into the verify step..."`, `"issues session tokens and navigates away once a correct verify code is submitted"`. Backend integration (written, not live): same file, second half of the flow |
| 3. Google sign-in issues tokens without TOTP | Automated (mocked, executed) | `backend/tests/test_google_auth.py::TestNewAndReturningUsers::test_new_user_is_created_on_first_google_signin` (tokens issued; `google_auth()` never touches TOTP fields at all), `::TestLoginGuardsGoogleOnlyAccounts::test_password_login_on_google_only_account_returns_400`. Backend integration (written, not live): `test_s018_s020_login_profile.py::test_google_login_bypasses_totp`. Mobile: CI evidence (`mobile-emulator-check.yml`, 2026-08-11 run, passed) |
| 4. Wrong TOTP code on verify/confirm → 401, no tokens | Automated (mocked, executed) | `test_mfa.py::test_totp_verify_rejects_bad_code`, `::test_totp_confirm_rejects_bad_code_and_leaves_totp_disabled`. Frontend: `LoginForm.test.tsx::"shows an error and stores no tokens when the verify code is wrong"`, `"...when the enrollment confirm code is wrong"`. Backend integration (written, not live): both wrong-code assertions in `test_s018_s020_login_profile.py` |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Unauthenticated `GET /auth/me` | none | 401 (existing `test_dependencies_blocklist.py` pattern; written integration `test_auth_me_and_logout_require_authentication`) |
| `mfa_token` (enroll or verify purpose) used as a Bearer access token | any | 401, rejected before the DB is ever queried — `test_mfa.py::test_mfa_token_cannot_authenticate_as_an_access_token` |
| Blocklisted/revoked token reused | any | 401 — existing `test_dependencies_blocklist.py::test_get_current_user_rejects_blocklisted_token_without_hitting_db` |
| Suspended account, Google login | google | 403 — existing `test_google_auth.py::TestErrorPaths::test_suspended_account_returns_403` |
| Password login on a Google-only (no password) account | any | 400 — existing `test_google_auth.py::TestLoginGuardsGoogleOnlyAccounts` |

No customer/merchant/admin role distinction applies to login/MFA itself (every role
follows the same password+TOTP or Google path) — the cases above are this slice's
auth-baseline equivalent of an RBAC matrix.

---

## Edge cases

- `/mfa/totp/setup` called twice (already enrolled) → 400, `test_mfa.py::test_totp_setup_rejects_already_enabled`.
- `/mfa/totp/confirm` called before `/setup` (no `totp_secret` yet) → 400 (existing router guard, verified by code review; not separately unit-tested — flagged as a minor gap, low risk since the frontend always calls `/setup` first and the guard exists).
- Replay of a consumed `mfa_token` — `_consume_mfa_token` blocklists the `jti` after a successful confirm/verify (existing router code, exercised implicitly by the integration flow; not separately unit-tested — flagged as a gap).
- Clock skew — `verify_totp_code` uses `valid_window=1` (±30s), covered by `test_mfa.py::test_verify_totp_code_accepts_current` implicitly (exact-window case only; skew boundary not explicitly tested — pre-existing gap, not introduced by this plan).

---

## Manual checklist (if applicable)

- [ ] M-001: `docker compose up --build`; register a new password account, log in,
      scan the QR with a real authenticator app (e.g. Google Authenticator), enter the
      6-digit code, confirm session tokens are issued and the app lands on `/`.
- [ ] M-002: Log out and log back in with the same account — confirm the verify step
      (no QR this time) appears and a valid code from the same authenticator app signs
      in successfully.
- [ ] M-003: Attempt Google sign-in — confirm no TOTP step appears at any point.

---

## Environment

- `AI_PROVIDER=mock`
- `docker compose up --build` (for the manual checklist)
- Backend live-DB execution intentionally skipped this pass for anything beyond the
  fully-mocked unit suite — see environment note above.
