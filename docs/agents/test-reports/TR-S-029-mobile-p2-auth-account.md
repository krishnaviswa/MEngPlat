# TR-S-029: Mobile P2 auth/account — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-029 |
| **Author** | Tester |
| **Date** | 2026-08-13 |
| **Recommendation** | Pending combined P1+P2 `flutter analyze && flutter test` |

---

## Summary

Implementation and AC-mapped widget tests are in tree. This pass did **not** execute analyze/test (deferred to a single combined run after P1 and P2). Coverage mapping is complete; results below are **not run**.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Customer register → login, no tokens | A | `register_google_auth_test.dart` customer register | Not run |
| 2 | Merchant register | A | `register_google_auth_test.dart` merchant role | Not run |
| 3 | Admin not offered | A | `register_google_auth_test.dart` admin not offered | Not run |
| 4 | Duplicate email stays on register | A | `register_google_auth_test.dart` duplicate email | Not run |
| 5 | Client validation | A | `register_google_auth_test.dart` invalid email / short password | Not run |
| 6 | After register, MFA is existing LoginScreen | A | `register_google_auth_test.dart` no session / no MFA field | Not run |
| 7 | Create account → `/register` | A | `register_google_auth_test.dart` Create account | Not run |
| 8 | Sign in → `/login` | A | `register_google_auth_test.dart` Sign in returns | Not run |
| 9 | Google on login skips TOTP | A | `register_google_auth_test.dart` Google on login | Not run |
| 10 | Google on register (customer) | A | `register_google_auth_test.dart` Google on register | Not run |
| 11 | Google hidden if unconfigured | A | `register_google_auth_test.dart` unconfigured | Not run |
| 12 | Google cancel silent | A | `register_google_auth_test.dart` cancel | Not run |
| 13 | Profile edit form, all roles | A | `profile_screen_test.dart` edit form | Not run |
| 14 | Save success | A | `profile_screen_test.dart` save success | Not run |
| 15 | Save error keeps input | A | `profile_screen_test.dart` save error | Not run |
| 16 | Guest profile → login | A | `register_google_auth_test.dart` guest profile | Not run |
| 17 | Email/role read-only | A | `profile_screen_test.dart` read-only keys | Not run |
| 18 | Gmail skips authenticator copy | A | `register_google_auth_test.dart` skip-MFA copy | Not run |
| 19 | Logout still works (M-49) | A | `app_shell_test.dart` logout → login | Not run |
| 20 | Register/login have no bottom nav | A | `register_google_auth_test.dart` no `primaryNav` | Not run |

**Coverage:** 20 / 20 AC mapped

---

## Backend tests

### Added
- None (existing APIs)

### Run output
```
n/a — no backend changes
```

---

## Frontend tests

### Added
- n/a (web unchanged)

### Mobile tests added
- `mobile/test/register_google_auth_test.dart`
- `mobile/test/profile_screen_test.dart`
- `mobile/test/app_shell_test.dart` (profile assertions updated for edit form)

### Run output
```
Deferred — combined flutter analyze && flutter test after P1 + P2
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | Real Google on device | Not run |
| M-002 | Post-register TOTP enroll | Not run |

---

## Regressions

- S-027 Account logout / shell tests still present; not re-executed this pass.

---

## Gaps / rework items

1. Execute combined `flutter analyze && flutter test` before PM Accepted.

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC covered in mapped widget tests
- [x] AI disclaimer N/A
- [ ] Ready for PM acceptance (blocked on combined verify)
