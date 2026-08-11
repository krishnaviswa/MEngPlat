# Slice: S-020 — Mandatory TOTP for password login

| Field | Value |
|-------|-------|
| **Slice ID** | S-020 |
| **Phase** | 1 Foundation |
| **Status** | Accepted |
| **Role(s)** | customer \| merchant \| admin |
| **Owner** | Builder / 2026-08-11 |

---

## User story

**As a** user signing in with email and password  
**I want** to use an authenticator app as a second factor  
**So that** my account is protected beyond the password alone  
*(Gmail/Google sign-in remains the alternate path without TOTP.)*

---

## Acceptance criteria

1. **Given** a password account without TOTP, **when** I log in with correct password, **then** I must enroll an authenticator (QR) before receiving session tokens.
2. **Given** a password account with TOTP, **when** I log in, **then** I must enter a valid TOTP code before receiving session tokens.
3. **Given** Google sign-in, **when** the ID token verifies, **then** I receive session tokens without TOTP.
4. **Given** a wrong TOTP code, **when** I submit verify/confirm, **then** I get 401 and no session tokens.

---

## Out of scope

- SMS OTP
- Recovery codes
- Enforcing TOTP on Google-only accounts

---

## Dependencies

- S-001 auth
- ADR-001

---

## Definition of done (PM)

- [x] All AC verified in tests
- [x] README §6/§7/§9 updated
- [x] PM Status set to **Accepted**

---

## Technical specification (Architect)

### API contract

| Method | Path | Auth | Request | Response |
|--------|------|------|---------|----------|
| POST | `/auth/login` | Public | email, password | `LoginResult` (MFA flags + mfa_token) |
| POST | `/auth/mfa/totp/setup` | mfa enroll | mfa_token | otpauth_uri, secret, qr_svg |
| POST | `/auth/mfa/totp/confirm` | mfa enroll | mfa_token, code | `TokenResponse` |
| POST | `/auth/mfa/totp/verify` | mfa verify | mfa_token, code | `TokenResponse` |
| POST | `/auth/google` | Public | credential | `TokenResponse` (no TOTP) |

### Data model impact

- [x] Extend `users`: `totp_secret`, `totp_enabled` (+ profile fields in shared migration)

### Frontend

- **Route:** `/login`
- **Rendering:** CSR
- **Components:** `LoginForm` multi-step

### Architect checklist

- [x] API contract defined
- [x] RBAC matrix complete
- [x] Data model impact documented
- [x] Cache invalidation considered
- [x] Uses AI/storage abstractions where applicable
- [x] ERD/API/FLOWS updates noted

---

## Links

- ADR: `docs/agents/adrs/ADR-001-mandatory-totp-password.md`

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-11 | PM+Architect+Builder | Implemented |
| 2026-08-11 | Tester | TR-S-020 filed — 4/4 AC pass (28 executed mocked backend unit tests + 6 executed frontend RTL tests; AC3/Google-bypass additionally has real Android-emulator CI evidence via `mobile-emulator-check.yml`). Recommendation: Ship. |
| 2026-08-11 | PM | Accepted. All 4 AC verified per TR-S-020, including independent mobile E2E CI evidence for the Google-bypasses-TOTP path. README §6 (auth sequence diagram already shows the enroll-vs-verify branch), §7 (`/auth/mfa/totp/setup`, `/confirm`, `/verify`, `/auth/google` already documented in the Authentication table + example payloads), and §9 (Token design `type: "mfa"` row, "Password MFA" row, "TOTP MFA" control row all already present) already accurately reflect this slice — no changes needed. Flagging the production-DB test-isolation gap as a real infra risk: this session's only reachable Postgres was live production Railway (no Docker, no isolated test DB), so the new `test_s018_s020_login_profile.py` integration file was written but deliberately not executed live, and an earlier baseline `pytest` run before the constraint was identified persisted real rows to production. Per Tester's recommendation ("Ship, with the DB-infra gap tracked as a follow-up, not a slice blocker") this does not block acceptance here; it's already reflected in README §11/§14 ("no test-database isolation yet" / "Build out the test suite with fixtures and an isolated test database") and has task-tracking elsewhere in this session — no new tracking created by this acceptance. |
