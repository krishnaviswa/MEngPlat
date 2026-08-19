# TP-S-092: Authenticator vs Mobile OTP — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-092 |
| **Author** | Tester |
| **Date** | 2026-08-19 |

---

## Scope

Login/register method chooser (Authenticator vs Mobile OTP) for customer, merchant, and admin; existing-admin OTP; no new admin self-register.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend API | pytest | Existing admin OTP tokens; admin self-register 403 |
| Frontend | RTL | Chooser exclusivity; roles; register parity |
| Integration | Manual | Mock SMS + seeded phones after re-seed |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `LoginForm.test.tsx` chooser + admin in role select |
| 2 | Automated | `LoginForm.test.tsx` hides SMS on Authenticator (existing TOTP tests) |
| 3 | Automated | `LoginForm.test.tsx` hides email when Mobile OTP selected |
| 4 | Automated | `LoginForm.test.tsx` merchant role on verify; `PhoneOtpPanel` existing |
| 5 | Automated | `test_phone_otp.py::test_verify_existing_admin_issues_admin_tokens`; `api.test.ts` admin `/admin` |
| 6 | Automated | `test_phone_otp.py::test_verify_blocks_admin_self_register` |
| 7 | Automated | `RegisterForm.test.tsx` |
| 8 | Manual | M-001 re-seed + README phones |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| New phone + role=admin | — | 403 |
| Existing admin phone | admin | JWT role admin |
| Register UI | — | no admin option |

---

## Manual checklist

- [ ] M-001: After seed with new `SEED_VERSION`, mock SMS login as admin `9000000000` (country +91) lands on `/admin`

---

## Environment

- `AI_PROVIDER=mock`, `SMS_PROVIDER=mock`
