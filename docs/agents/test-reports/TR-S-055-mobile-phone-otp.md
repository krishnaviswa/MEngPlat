# TR-S-055: Mobile phone OTP sign-in (M-74) — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-055 |
| **Author** | Tester |
| **Date** | 2026-08-17 |
| **Recommendation** | Ship |

---

## Summary

Pass. All 8 ACs mapped: 7/8 automated and passing (`phone_otp_panel_test.dart`, 12
widget tests; `phone_otp_router_redirect_test.dart`, 2 widget tests; plus one
pre-existing regression test reused for AC 7), 1/8 (AC 8, the OpenAPI-regen
requirement) verified by code review + `flutter analyze` for the same reason as
S-054's AC 7 — panel-level and router-level widget tests both fake `AuthController`
above the repository layer. `flutter analyze` → "No issues found!" and `flutter test`
→ "All tests passed!" (**149 tests** total across the mobile suite), both re-run and
confirmed directly by this Tester pass. One real bug (`phone_otp_router_redirect_test.dart`'s
`_FakeAuthController` missing a `requestPhoneOtp` override, causing a real network call
that silently failed in the test harness) was fixed by the Builder mid-session
(commit `5e55c1c`) before this verification pass; re-run confirms it is now clean.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|-----------------|--------|
| 1 | Phone panel (country code, number field, Send SMS code) on login screen | A | `phone_otp_panel_test.dart::AC1: shows country code selector (+91 default), number field, and Send SMS code button`; `::AC1: panel is present below the credentials fields` | Pass |
| 2 | Same panel on register screen | A | `phone_otp_panel_test.dart::AC2: panel is present in the equivalent position on the register screen` | Pass |
| 3 | Send SMS code always shows generic confirmation, reveals code field + verify button | A | `phone_otp_panel_test.dart::AC3: sending a code always shows the generic confirmation flow and reveals code field + verify button` | Pass |
| 4 | Verify from register: full_name/role sent, signed in, TOTP skipped, `postLoginPath` routing | A | `phone_otp_panel_test.dart::AC4: verify from register sends the in-progress full_name and role, updated live as name changes`; `::AC4: on success the user is signed in (JWT/session state set), TOTP step skipped`; `phone_otp_router_redirect_test.dart::AC4: phone sign-in from login (customer, default role) lands on Explore...`; `::AC4: phone sign-in from register (merchant role) lands on the merchant home...` | Pass |
| 5 | Verify from login (new number, no full_name): backend 400 surfaced as-is, no fallback UI | A | `phone_otp_panel_test.dart::AC5: verifying a brand-new number from login omits full_name and surfaces the backend 400 as-is` | Pass |
| 6 | Invalid/expired code (401): plain error, code field stays editable for retry | A | `phone_otp_panel_test.dart::AC6: invalid/expired code (401) shows a plain error and the code field remains editable for retry` | Pass |
| 7 | Admin self-register blocked (403); mobile has no admin option in register role dropdown | A (existing regression) | `register_google_auth_test.dart::AC2/AC3: merchant register is offered; admin is not` — pre-existing, unmodified by this slice, confirms the UI-unreachable premise this AC relies on | Pass |
| 8 | OpenAPI client regenerated; typed models + repository methods for both endpoints | M | M-001 (code review) — `AuthRepository.requestPhoneOtp`/`verifyPhoneOtp` (`mobile/lib/features/auth/auth_repository.dart`) call `phoneOtpRequestApiV1AuthPhoneRequestPost`/`phoneOtpVerifyApiV1AuthPhoneVerifyPost` with `PhoneOtpRequest`/`PhoneOtpVerifyRequest` generated types, confirmed via clean `flutter analyze` compilation; no widget test exercises the real HTTP call | Pass (manual) |

**Coverage:** 8 / 8 AC mapped (7 automated, 1 manual/code-review).

---

## Backend tests

### Added
- None — no backend change in this slice; `/auth/phone/request` and `/auth/phone/verify` unchanged since S-044/ADR-011.

### Run output
```
n/a — no backend changes in this slice
```

---

## Frontend tests

### Added
- n/a — web `PhoneOtpPanel.tsx` (S-044) unchanged.

### Mobile tests added
- `mobile/test/phone_otp_panel_test.dart` (12 widget tests: 6 standalone-panel, 3 embedded-in-LoginScreen, 3 embedded-in-RegisterScreen)
- `mobile/test/phone_otp_router_redirect_test.dart` (2 widget tests, full-app-router level)

### Run output
```
cd mobile && flutter analyze
Analyzing mobile...
No issues found! (ran in 11.4s)

cd mobile && flutter test
00:52 +149: All tests passed!
```
Both commands re-run directly by this Tester pass. 149 is the full-suite count across all mobile test files.

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | Code review confirming `AuthRepository.requestPhoneOtp`/`verifyPhoneOtp` use generated codegen types (AC 8) | Pass |
| M-002 | `docker compose up --build`; real device/emulator send+verify against live backend (mock SMS provider) | Not run — no Docker/emulator available in this Tester pass; recommended before first production reliance, not blocking for Accept given AC 8's compile-time proof |

---

## Regressions

- None observed. `register_google_auth_test.dart` (reused as AC 7 evidence) still passes unmodified, confirming the admin-not-offered UI fact this slice depends on was not disturbed.
- Full 149-test suite passed, including all prior slices' widget tests.

---

## Build notes (not mapped to an S-055 AC — flagged for PM visibility)

- This slice's own OpenAPI regen (AC 8, planned and required) was executed in the same
  combined pass as S-054's forgot-password endpoint and the S-056 correction (Architect's
  S-056 spec incorrectly stated no regen was needed — see `TR-S-056`'s build notes).
- That same regen surfaced a pre-existing latent nullability bug: `UserResponse.email`
  is correctly nullable (a brand-new phone-OTP account genuinely has `email=None`, per
  this slice's own flow — a customer or merchant signing up via phone never supplies
  one), but three account screens (`account_screen.dart`, `profile_screen.dart`,
  `role_home_screen.dart`) assumed it was always non-null. Fixed with null-coalescing
  fallbacks (`user.email ?? user.phone ?? ''` / `user.email ?? 'No email on file'`).
  This is directly relevant to this slice's own feature area (phone-only accounts are
  exactly the accounts that would have hit the bug) even though it's not covered by any
  of this slice's own written ACs — no dedicated regression test was added for it in
  this pass since it's outside AC 1–8's scope; flagging here for PM awareness and as a
  candidate for a follow-up regression test (e.g., an account/profile/role-home screen
  test using a `UserResponse` fixture with `email: null`).

---

## Gaps / rework items

1. No dedicated automated regression test for the nullable-`email` fallback fix in
   `account_screen.dart`/`profile_screen.dart`/`role_home_screen.dart` (see Build notes
   above). Not a blocker for this slice's own ACs, but recommended as a small follow-up.
2. M-002 (live-backend device smoke test) not run in this pass — recommended before
   heavy production reliance.

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested (target-role matrix per Architect spec; admin-blocked path confirmed UI-unreachable via existing regression test)
- [x] AI disclaimer N/A (no AI content in this flow, per PM's UX notes)
- [x] Ready for PM acceptance
