# TR-S-027: Mobile P0 chrome — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-027 |
| **Author** | Tester |
| **Date** | 2026-08-13 |
| **Recommendation** | Ship |

---

## Summary

Pass. All 16 AC mapped and passing. Flutter widget/unit suite is green (`71` tests). `flutter analyze` is clean after removing two unused imports. No backend surface. Widget tests avoid `pumpAndSettle` on logged-in shell routes so `UnreadCountController`'s `Timer.periodic(30s)` cannot hang the fake-async clock; containers are disposed at the end of each shell test to cancel the timer.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Customer tabs Explore / Favorites / Notifications / Account | A | `app_shell_test.dart` AC1 | Pass |
| 2 | Merchant tabs Home / Explore / Notifications / Account, no Favorites | A | `app_shell_test.dart` AC2/AC6 | Pass |
| 3 | Admin tabs Home / Explore / Notifications / Account, no Favorites | A | `app_shell_test.dart` AC3/AC7 | Pass |
| 4 | Guest Explore + Sign in only | A | `app_shell_test.dart` AC4/AC10 | Pass |
| 5 | Customer post-login → Explore | A | `post_login_path_test.dart` + `app_shell_test.dart` AC5 | Pass |
| 6 | Merchant post-login → `/merchant` stub | A | `app_shell_test.dart` AC2/AC6 | Pass |
| 7 | Admin post-login → `/admin` stub | A | `app_shell_test.dart` AC3/AC7 | Pass |
| 8 | Account identity + Profile link + Logout | A | `app_shell_test.dart` AC8/AC9/AC12/AC16 | Pass |
| 9 | Logout clears session → login | A | `app_shell_test.dart` AC8/AC9/AC12/AC16 | Pass |
| 10 | Guest Sign in → login | A | `app_shell_test.dart` AC4/AC10 | Pass |
| 11 | Unread badge on Notifications tab; hidden at 0 | A | `app_shell_test.dart` AC11 | Pass |
| 12 | MerchantHub AI brand → Explore | A | `app_shell_test.dart` AC8/AC9/AC12/AC16 | Pass |
| 13 | Login / business detail: bottom nav not hit-testable | A | `app_shell_test.dart` AC13 | Pass |
| 14 | Role home placeholder, no AI insights | A | `role_home_screen_test.dart` | Pass |
| 15 | Explore app bar has no logout/favorites/notifications icons | A | `business_list_screen_test.dart` | Pass |
| 16 | Profile read-only (no edit fields) | A | `app_shell_test.dart` AC8/AC9/AC12/AC16 | Pass |

**Coverage:** 16 / 16 AC mapped

---

## Backend tests

### Added
- None — no API changes.

### Run output
```
n/a
```

---

## Frontend tests

### Added
- `mobile/test/app_shell_test.dart`
- `mobile/test/post_login_path_test.dart`
- `mobile/test/role_home_screen_test.dart`
- `mobile/test/business_list_screen_test.dart` (rewritten for AC15)

### Run output
```
cd mobile && flutter analyze
  No issues found.

cd mobile && flutter test
  00:18 +71: All tests passed!
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | Device thumb-reach bottom nav | Not run (no local emulator; CI `app_test.dart` still asserts business list after customer login) |
| M-002 | Merchant demo login lands on stub Home | Not run locally; covered by widget AC6 |

---

## Regressions

- S-023–S-025 widget tests still pass (reviews, favorites, notifications).
- Integration smoke still looks for `Businesses` app-bar title on Explore.

---

## Gaps / rework items

None.

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested (tab sets + role landing + guest)
- [x] AI disclaimer verified (N/A — no AI UI; AC14 asserts no AI copy)
- [x] Ready for PM acceptance
