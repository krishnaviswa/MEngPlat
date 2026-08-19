# TR-S-092: Authenticator vs Mobile OTP — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-092 |
| **Author** | Tester |
| **Date** | 2026-08-19 |
| **Recommendation** | Ship |

---

## Summary

Chooser UI, admin existing-phone OTP tokens, and register parity tests passed. Admin self-register remains 403. Re-seed (`SEED_VERSION=2026-08-19-demo-otp-phones-v1`) is required locally so demo `User.phone` values exist.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Role + Authenticator/Mobile OTP chooser | A | `LoginForm.test.tsx` chooser + admin option | Pass |
| 2 | Authenticator hides SMS; TOTP unchanged | A | `LoginForm.test.tsx` exclusive fields + existing TOTP tests | Pass |
| 3 | Mobile OTP hides email/password | A | `LoginForm.test.tsx` exclusive fields | Pass |
| 4 | Merchant/customer OTP session | A | `LoginForm.test.tsx` merchant verify payload; `PhoneOtpPanel.test.tsx` | Pass |
| 5 | Existing admin OTP → `/admin` | A | `test_phone_otp.py::test_verify_existing_admin_issues_admin_tokens`; `api.test.ts` admin redirect | Pass |
| 6 | New number + admin → 403 | A | `test_phone_otp.py::test_verify_blocks_admin_self_register` | Pass |
| 7 | Register same chooser; no admin | A | `RegisterForm.test.tsx` | Pass |
| 8 | Seeded demo phones | M | M-001 (Compose re-seed) | Pending env |

**Coverage:** 8 / 8 AC mapped (AC8 manual until Compose seed run)

---

## Backend tests

### Added
- `backend/tests/test_phone_otp.py::test_verify_existing_admin_issues_admin_tokens`

### Run output
```
python -m pytest tests/test_phone_otp.py -q
9 passed
```

---

## Frontend tests

### Added / updated
- `LoginForm.test.tsx`, `RegisterForm.test.tsx`, `AuthMethodToggle.test.tsx`, `AlreadySignedIn.test.tsx`, `api.test.ts`

### Run output
```
npm test -- LoginForm|RegisterForm|AuthMethodToggle|AlreadySignedIn|api.test
37 passed
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | Re-seed then mock SMS as admin `9000000000` | Not run in this pass (Compose) |

---

## Gaps / rework items

1. AC8 — run Compose seed after bumping `SEED_VERSION` so Railway/local DBs that already have an older marker pick up phones (`if_outdated`).

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested (admin 403 vs existing admin JWT)
- [x] AI disclaimer N/A
- [ ] Ready for PM acceptance after M-001 or explicit PM waiver of Compose smoke
