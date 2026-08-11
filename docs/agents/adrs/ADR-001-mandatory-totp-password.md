# ADR-001: Mandatory TOTP for password login; Google exempt

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-11 |
| **Slice** | S-020 |

---

## Context

Password accounts need a second factor. Google/Gmail sign-in already proves possession of a Google identity. SMS OTP has no provider in this repo.

## Decision

- Email/password login **never** issues session tokens until TOTP enrollment (first time) or verification succeeds.
- Google OAuth (`POST /auth/google`) issues session tokens without TOTP.
- TOTP secrets are Fernet-encrypted with a key derived from `SECRET_KEY`; never exposed on `UserResponse`.
- Short-lived JWT `type=mfa` + `purpose=enroll|verify` bridges password check and authenticator confirmation.

## Consequences

### Positive
- Password accounts gain authenticator MFA without SMS cost.
- Clear split: Gmail path vs password+authenticator path.

### Negative / tradeoffs
- Existing password users must enroll on next login (or use seeded demo secret).
- Demo curl/login recipes need an MFA step.
- Recovery codes deferred (documented gap).

### Follow-ups
- Recovery codes / MFA reset admin flow.
- Optional TOTP for Google-linked accounts that also set a password.

## Alternatives considered

1. Optional MFA toggle — rejected; password path must be mandatory.
2. SMS OTP — deferred; no provider.
3. Enforce TOTP on Google too — rejected; Gmail is the alternate trusted path.
