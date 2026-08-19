# ADR-017: Admin may use Mobile OTP only for an existing User.phone

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-19 |
| **Slice** | S-092 |

---

## Context

S-044/S-068 already issue JWTs from `POST /auth/phone/verify` and skip TOTP. The login UI stacked password+TOTP and SMS. Admins had no first-class OTP path; self-register as admin is blocked. Product now wants **one chooser** (Authenticator vs Mobile OTP) for customer, merchant, **and** admin.

---

## Decision

1. UI: mutually exclusive **Authenticator** | **Mobile OTP** on `/login` and `/register`.
2. Backend: keep 403 on **new** `role=admin`. Existing admin matched by `users.phone` already receives admin JWTs — no new endpoint.
3. Seed distinct demo `User.phone` values so OTP can be tried without profile edits.
4. `roleLandingPath("admin")` is `/admin`.

---

## Consequences

### Positive
- Same screen for all roles; no duplicate merchant/admin login pages.
- Admin OTP does not create a new admin.

### Negative / tradeoffs
- SMS is weaker than TOTP; both remain available.

### Follow-ups
- Flutter login chooser (parity row).

---

## Alternatives considered

1. OTP as second factor after password — rejected; product asked for a primary-method choice.
2. Separate `/admin/login` — rejected; extra surface, same API.
