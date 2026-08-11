# Slice: S-020 — Mandatory TOTP for password login

| Field | Value |
|-------|-------|
| **Slice ID** | S-020 |
| **Phase** | 1 Foundation |
| **Status** | Testing |
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

- [ ] All AC verified in tests
- [ ] README §6/§7/§9 updated
- [ ] PM Status set to **Accepted**

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
