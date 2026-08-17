# TR-S-054: Mobile forgot/reset password (M-65) — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-054 |
| **Author** | Tester |
| **Date** | 2026-08-17 |
| **Recommendation** | Ship |

---

## Summary

Pass. All 7 ACs mapped: 6/7 automated and passing (`forgot_password_screen_test.dart`,
8 widget tests), 1/7 (AC 7, the OpenAPI-regen requirement) verified by code review +
`flutter analyze` rather than a widget test, since every widget test in this file fakes
`AuthController` above the repository layer and therefore never exercises the real
generated Dio client. `flutter analyze` → "No issues found!" and the full suite
(`flutter test`, all mobile test files) → "All tests passed!" (**149 tests**), both
re-run and confirmed directly by this Tester pass (not taken on trust from the Builder's
self-report).

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|-----------------|--------|
| 1 | `forgotPasswordLink` visible on login screen | A | `forgot_password_screen_test.dart::AC1: forgotPasswordLink is visible on the login screen` | Pass |
| 2 | Forgot-password screen has only email field + submit | A | `forgot_password_screen_test.dart::AC2: tapping the link opens a screen with only an email field and submit button` | Pass |
| 3 | Generic confirmation, same for known/unknown email | A | `forgot_password_screen_test.dart::AC3/AC5: submitting a well-formed email...`; `::AC3: confirmation copy is identical for an unknown/unregistered-looking email (no enumeration)` | Pass |
| 4 | Network/5xx → generic error, retry works, never silent success | A | `forgot_password_screen_test.dart::AC4: network/5xx failure shows a generic error and allows retry; never silently succeeds` | Pass |
| 5 | Confirmation instructs "open link in phone's browser"; no in-app reset screen | A | `forgot_password_screen_test.dart::AC3/AC5: ...` (asserts `find.textContaining("phone's browser")`) | Pass |
| 6 | "Back to sign in" returns to `/login` without submitting | A | `forgot_password_screen_test.dart::AC6: Back to sign in from the form state...`; `::AC6: Back to sign in from the confirmation state...` | Pass |
| 7 | OpenAPI client regenerated; typed request/response + repository method exist | M | M-001 (code review) — `AuthRepository.forgotPassword` (`mobile/lib/features/auth/auth_repository.dart`) calls `forgotPasswordApiV1AuthForgotPasswordPost` with `ForgotPasswordRequest`/`MessageResponse` generated types, confirmed present via successful compilation (`flutter analyze` clean); no widget test exercises the real HTTP call | Pass (manual) |

**Coverage:** 7 / 7 AC mapped (6 automated, 1 manual/code-review).

---

## Backend tests

### Added
- None — no backend change in this slice; `/auth/forgot-password` unchanged since S-035.

### Run output
```
n/a — no backend changes in this slice
```

---

## Frontend tests

### Added
- n/a — web `/forgot-password` flow (S-035) unchanged.

### Mobile tests added
- `mobile/test/forgot_password_screen_test.dart` (8 widget tests)

### Run output
```
cd mobile && flutter analyze
Analyzing mobile...
No issues found! (ran in 11.4s)

cd mobile && flutter test
00:52 +149: All tests passed!
```
Both commands re-run directly by this Tester pass (Windows: `cmd //c "C:\src\flutter\bin\flutter.bat analyze"` / `... test`, per the workaround for `.bat` invocation on this machine). 149 is the full-suite count across all mobile test files, not just this slice's file.

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | Code review confirming `AuthRepository.forgotPassword` uses generated codegen types, not a hand-rolled `Dio.post` (AC 7) | Pass |
| M-002 | `docker compose up --build`; real device/emulator end-to-end submit against the live backend | Not run — no Docker/emulator available in this Tester pass; recommended before first production release of this flow, not blocking for Accept given AC 7's compile-time proof and the endpoint's own unchanged S-035 coverage |

---

## Regressions

- None observed. Full 149-test suite (covering all prior slices' widget tests) passed alongside this slice's new file.

---

## Build notes (not mapped to an S-054 AC — flagged for PM visibility)

- This slice's own OpenAPI regen (AC 7, planned and required) was executed in the same
  pass as S-055's phone-endpoint regen and the S-056 correction (Architect's S-056 spec
  incorrectly stated no regen was needed for that slice — see `TR-S-056`'s build notes
  for detail). One combined `merchanthub_api` regeneration now backs all three slices.
- The same regen surfaced a pre-existing latent nullability bug (`UserResponse.email`
  correctly nullable for phone-OTP accounts, but three account screens assumed
  non-null) — fixed with null-coalescing fallbacks in `account_screen.dart`,
  `profile_screen.dart`, `role_home_screen.dart`. This fix is not required by any S-054
  AC (S-054 has no email-nullability surface) but is noted here since it landed in the
  same regen pass. Full detail in `TR-S-055` and `TR-S-056`'s build notes, since it is
  most directly relevant to phone-OTP (S-055) accounts.

---

## Gaps / rework items

None blocking. Optional follow-up: run M-002 (live-backend device smoke test) before
this flow is relied on by real users, since no automated test in this pass exercises
the real generated Dio call end to end (all widget tests fake `AuthController` above
the repository layer, by design, to avoid real network calls in `flutter test`).

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested (trivially — public/unauthenticated endpoint, no negative RBAC case applies, confirmed in test plan)
- [x] AI disclaimer N/A (no AI content in this flow, per PM's UX notes)
- [x] Ready for PM acceptance
