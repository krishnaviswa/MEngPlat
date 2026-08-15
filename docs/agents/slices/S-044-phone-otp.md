# Slice: S-044 — Phone OTP login

| Field | Value |
|-------|-------|
| **Slice ID** | S-044 |
| **Phase** | 1 Foundation |
| **Status** | Accepted |
| **Role(s)** | customer, merchant |
| **Owner** | PM / 2026-08-15 |

---

## User story

Sign in with an Indian mobile number and SMS code without TOTP. Google unchanged. Apple deferred.

---

## Acceptance criteria

1. Request OTP always returns generic success copy; mock logs the code.
2. Verify issues JWT and skips TOTP.
3. First-time verify requires full name; admin role is 403.
4. Invalid code is 401. Invalid phone is 400.
5. Login and register show Continue with phone next to Google.

---

## Technical specification (Architect)

See ADR-011.

---

## Links

- ADR: `docs/agents/adrs/ADR-011-phone-otp-sms.md`
- Test report: `docs/agents/test-reports/TR-S-044-phone-otp.md`
