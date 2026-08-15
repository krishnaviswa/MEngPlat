# ADR-011: Phone OTP via SMS port (mock | Msg91)

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-15 |
| **Slice** | S-044 |

---

## Context

Google ID-token login exists. Facebook was rejected on cost/review. Phone OTP is the India-native third method. Apple is deferred. Email remains unique when present; phone-only accounts need nullable email.

---

## Decision

1. `SMS_PROVIDER=mock|msg91` port, same pattern as email/payments.
2. Redis hashed OTP, 5 minutes, fail-closed.
3. `POST /auth/phone/request` generic 200; `POST /auth/phone/verify` issues JWT and skips TOTP.
4. `users.email` nullable; unique index on `phone` where not null.
5. First verify requires `full_name`. Admin self-register forbidden.

---

## Consequences

### Positive
- Local demo without SMS spend (mock logs the code).

### Negative / tradeoffs
- Phone-only users have no password-reset email.
- Msg91 template/DLT is ops.

### Follow-ups
- Apple Sign In when iOS ships.
