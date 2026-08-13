# TP-S-029: Mobile P2 auth/account — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-029 |
| **Author** | Tester |
| **Date** | 2026-08-13 |

---

## Scope

Flutter register (`/register`), Google ID-token sign-in on login/register, profile edit (`/account/profile`). Reuses existing `POST /auth/register`, `POST /auth/google`, `PATCH /auth/me`. No backend changes. Combined `flutter analyze && flutter test` is deferred to a later P1+P2 pass.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Mobile widget | `flutter test` | Register roles, validation, Google skip-MFA, profile save/error, guest redirect |
| Mobile unit | n/a | Google client is a Riverpod port; faked in widget tests |
| Backend | n/a | No new endpoints |
| Integration | Deferred | Combined analyze+test after P1 and P2 land |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `register_google_auth_test.dart` customer register → login note |
| 2 | Automated | `register_google_auth_test.dart` merchant role submit |
| 3 | Automated | `register_google_auth_test.dart` admin not offered |
| 4 | Automated | `register_google_auth_test.dart` duplicate email error |
| 5 | Automated | `register_google_auth_test.dart` invalid email / short password |
| 6 | Automated | `register_google_auth_test.dart` no MFA fields / no session after register |
| 7 | Automated | `register_google_auth_test.dart` Create account → register |
| 8 | Automated | `register_google_auth_test.dart` Sign in → login |
| 9 | Automated | `register_google_auth_test.dart` Google on login, no TOTP, Explore |
| 10 | Automated | `register_google_auth_test.dart` Google on register |
| 11 | Automated | `register_google_auth_test.dart` Google hidden when unconfigured |
| 12 | Automated | `register_google_auth_test.dart` Google cancel |
| 13 | Automated | `profile_screen_test.dart` edit form; merchant/admin |
| 14 | Automated | `profile_screen_test.dart` save success |
| 15 | Automated | `profile_screen_test.dart` save error keeps input |
| 16 | Automated | `register_google_auth_test.dart` guest `/account/profile` → login |
| 17 | Automated | `profile_screen_test.dart` email/role read-only keys |
| 18 | Automated | `register_google_auth_test.dart` Gmail skips authenticator copy |
| 19 | Automated | `app_shell_test.dart` logout → login (S-027 regression) |
| 20 | Automated | `register_google_auth_test.dart` register has no `primaryNav` |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Register as customer / merchant | anonymous | Allowed |
| Register as admin | anonymous | Not in UI |
| Google new account | anonymous | customer session |
| Profile GET/PATCH | customer, merchant, admin | Allowed |
| Profile | guest | Redirect `/login` |
| Change email/role in form | any | Not editable |

---

## Edge cases

- Google button omitted when `--dart-define=GOOGLE_CLIENT_ID` is empty.
- Google cancel returns `null` credential — no error, still signed out.
- Register does not write tokens.

---

## Manual checklist (if applicable)

- [ ] M-001: Real Google sign-in on a device with Web + Android OAuth clients configured.
- [ ] M-002: After password register, first login shows TOTP enroll QR (S-020).

Not run in this pass (no emulator; combined verify later).

---

## Environment

- Widget tests only; `GOOGLE_CLIENT_ID` unset in tests (fake client injected when needed)
