# TP-S-024: Mobile favorites (Flutter) — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-024 |
| **Author** | Tester |
| **Date** | 2026-08-12 |

---

## Scope

The shared favorite toggle (`mobile/lib/features/favorites/favorite_toggle_button.dart`),
the `favoritedIdsProvider`/`favoritesListProvider` pair
(`favorites_providers.dart`), and the dedicated Favorites screen
(`favorites_screen.dart`, route `/favorites`), plus the extracted `BusinessCard`
shared row widget. No backend changes — reuses S-011's existing
`GET/POST/DELETE /favorites` endpoints unchanged.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Mobile unit (Riverpod) | `flutter test` | `FavoritedIdsController.toggle` optimistic flip + rollback-on-failure |
| Mobile widget | `flutter test` + `flutter_test` | `FavoriteToggleButton` tap behavior (flip/rollback/snackbar/login-redirect/404 message), `FavoritesScreen` list/empty/error/optimistic-removal, `BusinessListScreen` app-bar entry-point role gating |
| Backend | n/a | Zero backend surface — Architect spec: "No new backend endpoints. All existing, unchanged." |
| Manual | `flutter run` / `docker compose up --build` | Pull-to-refresh gesture, full app-bar-icon → `/favorites` navigation, cross-screen sync (toggle on list row reflected on detail screen) — **not run this session**, no Android SDK/emulator available |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1. Tap toggle → favorited, icon flips, no full reload | Automated | `mobile/test/favorite_toggle_button_test.dart::"AC1/AC2: tapping the toggle flips it favorited then back to unfavorited"` |
| 2. Tap again → un-favorited, icon reverts | Automated | Same test (covers both directions) + `mobile/test/favorites_controller_test.dart::"toggle optimistically adds then removes a business id"` |
| 3. Failed toggle reverts icon + shows snackbar | Automated | `favorite_toggle_button_test.dart::"AC3: a failed toggle rolls back the icon and shows a snackbar"` + `favorites_controller_test.dart::"toggle reverts the optimistic update when the API call fails"` |
| 4. Favorites screen lists name, city/state, rating, newest-favorited first | Automated | `mobile/test/favorites_screen_test.dart::"AC4: lists favorited businesses with name, city/state and rating"` |
| 5. Empty state with a way back to the business list | Automated | `favorites_screen_test.dart::"AC5: shows an empty-state message with a way back to the business list"` |
| 6. Pull-to-refresh with spinner | Automated (refetch trigger) + Manual (visible spinner) | `mobile/test/favorites_screen_test.dart::"AC6: pull-to-refresh re-fetches the favorites list"` (invokes `RefreshIndicator.onRefresh` directly, asserts a second repository call — see test report for why this is used instead of `RefreshIndicatorState.show()`, which deadlocks the fake-async test environment); actual spinner animation — M-001 |
| 7. Inline error + Retry on initial load failure | Automated | `favorites_screen_test.dart::"AC7: shows an inline error with a Retry action..."` |
| 8. Un-favoriting from within the Favorites screen removes the row immediately | Automated | `favorites_screen_test.dart::"AC8: un-favoriting a row removes it from the list immediately"` |
| 9. Not logged in, tap toggle → routes to `/login` | Automated | `favorite_toggle_button_test.dart::"AC9: tapping the toggle while logged out routes to /login instead of favoriting"` |
| 10. Favorites entry point hidden when logged out | Automated | `mobile/test/business_list_screen_test.dart::"logged out: no notifications icon and no favorites icon, only Sign in"` |
| 11. Stale/non-approved business 404 → clear message, not generic error | Automated | `favorite_toggle_button_test.dart::"AC11: a stale-business 404 surfaces a clear message, not a generic error"` |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Favorite toggle visible | customer | Yes — `business_list_screen_test.dart::"logged in as customer: shows notifications and favorites entry points"` |
| Favorite toggle visible | merchant | No (hidden, customer-only) — `business_list_screen_test.dart::"logged in as merchant: shows notifications but not favorites (customer-only)"` |
| Favorite toggle visible | anonymous | Shown, tap routes to `/login` (AC9) — `favorite_toggle_button_test.dart::AC9` |
| Favorites entry point (app-bar icon) | anonymous | Hidden — `business_list_screen_test.dart::"logged out..."` |
| Favorites entry point (app-bar icon) | merchant/admin | Hidden — implied by the same customer-only role check (`user?.role == UserRole.customer`), confirmed by `business_list_screen_test.dart::"...merchant: shows notifications but not favorites"` |
| Backend `require_roles(UserRole.CUSTOMER)` on all 3 favorites routes | merchant/admin | 403, unchanged (`backend/app/routers/favorites.py`) — confirmed via code read, not independently re-tested (no backend change) |

---

## Edge cases

- Toggle failure mid-flight (optimistic rollback) — covered both at controller and widget level.
- Zero favorites (AC5) — covered.
- Favorites list load failure (AC7) — covered.
- Un-favorite from within the Favorites screen itself vs. from a list/detail row elsewhere — AC8 (within-screen) covered; cross-screen sync via the shared `favoritedIdsProvider` is architecturally guaranteed (same provider instance) but not exercised in a single combined widget test — see Manual checklist M-002.
- 404 on a stale/no-longer-approved business (AC11) — covered.

---

## Manual checklist (if applicable)

- [ ] M-001: `flutter run` — pull down on `/favorites`, confirm the refresh spinner visibly animates while in flight (the refetch trigger itself is already automated — see AC6 above).
- [ ] M-002: Favorite a business from the business list row, navigate to its detail screen (S-023), confirm the toggle already shows "favorited" there without a re-fetch (cross-screen sync via the shared `favoritedIdsProvider`); reverse-check un-favoriting from the detail screen reflects back on the list row.

Not executed this pass — no Android SDK/emulator available in this environment (accepted,
documented constraint, not a defect). Flagged for PM/Builder to run before final acceptance.

---

## Environment

- `AI_PROVIDER=mock` — n/a, no AI-generated content involved (per slice UX notes).
- `docker compose up --build` — not run this session (no isolated environment for a live backend + emulator here).
- `flutter analyze` / `flutter test` — run locally, both clean (see test report).
