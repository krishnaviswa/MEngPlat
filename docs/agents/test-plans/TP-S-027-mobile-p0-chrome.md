# TP-S-027: Mobile P0 chrome — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-027 |
| **Author** | Tester |
| **Date** | 2026-08-13 |

---

## Scope

Flutter primary shell (`AppShell` + `GoRouter` `ShellRoute`), role-aware `postLoginPath`, Account + read-only Profile + logout, merchant/admin Home placeholders. No backend changes.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Mobile unit | `flutter test` | `postLoginPath` |
| Mobile widget | `flutter test` + `GoRouter` | Tab sets by role, post-login redirect, Account logout, guest Sign in, badge on Notifications dest, no tabs on login/detail, app-bar icons gone from Explore |
| Backend | n/a | No new endpoints |
| Integration | `integration_test/app_test.dart` | Still reaches business list after demo customer login; now via Explore shell |
| Manual | `flutter run` | Thumb-reach bottom nav on a device — **not run this session** (no Android SDK locally) |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `app_shell_test.dart` customer tabs |
| 2 | Automated | `app_shell_test.dart` merchant tabs |
| 3 | Automated | `app_shell_test.dart` admin tabs |
| 4 | Automated | `app_shell_test.dart` guest tabs |
| 5 | Automated | `post_login_path_test.dart` + `app_shell_test.dart` customer lands Explore |
| 6 | Automated | `app_shell_test.dart` merchant lands Home |
| 7 | Automated | `app_shell_test.dart` admin lands Home |
| 8 | Automated | `app_shell_test.dart` Account identity + Logout + Profile link |
| 9 | Automated | `app_shell_test.dart` logout → login |
| 10 | Automated | `app_shell_test.dart` guest Sign in → login |
| 11 | Automated | `app_shell_test.dart` unread badge on Notifications dest; hidden at 0 |
| 12 | Automated | `app_shell_test.dart` brand control → Explore |
| 13 | Automated | `app_shell_test.dart` login / detail: `primaryNav` not hit-testable |
| 14 | Automated | `role_home_screen_test.dart` placeholder copy, no AI insights |
| 15 | Automated | `business_list_screen_test.dart` no app-bar logout/favorites/notifications keys |
| 16 | Automated | `app_shell_test.dart` read-only Profile, no TextField |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Favorites tab | customer | Shown |
| Favorites tab | merchant, admin, guest | Hidden |
| Merchant `/merchant` | merchant | Landing |
| Merchant `/merchant` | customer/admin | Redirect to `postLoginPath` |
| Admin `/admin` | admin | Landing |
| Notifications | any authenticated | Shown + poll |
| Notifications / Account | guest | Not in nav; direct `/notifications` still → `/login` |

---

## Edge cases

- Session restore while `matchedLocation == '/login'` uses `postLoginPath`, not hardcoded `/businesses`.
- Guest `/account` redirects to login (auth-gated).
- Logout still clears local tokens even if POST logout fails (existing repository `finally`).

---

## Manual checklist (if applicable)

- [ ] M-001: On a device/emulator, confirm bottom nav is thumb-reachable and tab switches preserve Explore list scroll.
- [ ] M-002: Merchant demo login lands on Merchant home, then Explore still lists businesses.

Not executed in CI-less local agent environment if Flutter test host has no emulator — widget tests cover logic.

---

## Environment

- `AI_PROVIDER=mock` (N/A — no AI UI)
- `cd mobile && flutter analyze && flutter test`
