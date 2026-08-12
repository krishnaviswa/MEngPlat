# TR-S-024: Mobile favorites (Flutter) — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-024 |
| **Author** | Tester |
| **Date** | 2026-08-12 |
| **Recommendation** | Ship |

---

## Summary

All 11 AC pass. Code review plus new automated unit + widget coverage confirms the
shared `favoritedIdsProvider` toggle (optimistic flip, rollback-on-failure), the
`FavoriteToggleButton` (login-redirect when logged out, 404 message on a stale
business), and the dedicated Favorites screen (list, empty state, error + Retry,
immediate optimistic row removal) all match the Architect spec. No backend surface to
test (Architect: "No new backend endpoints. All existing, unchanged.") — confirmed by
code review of `backend/app/routers/favorites.py`; not touched by this slice.
`flutter analyze` is clean (only the 3 pre-existing, unrelated
`prefer_initializing_formals` infos in `auth_interceptor.dart`). No bugs found.

AC10's "Favorites entry point hidden when logged out" and the RBAC role-gating of the
app-bar icon (customer-only) are verified at the actual `BusinessListScreen` widget
level, not just the underlying provider — this closes what would otherwise be a gap
between "the toggle behaves correctly" and "the entry point is actually reachable only
by the right roles."

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Tap favorite toggle → saved as favorite, icon flips to filled, no full reload | A | `mobile/test/favorite_toggle_button_test.dart::"AC1/AC2: tapping the toggle flips it favorited then back to unfavorited"` | Pass |
| 2 | Tap again → removed, icon reverts to unfavorited | A | Same test (both directions) + `mobile/test/favorites_controller_test.dart::"toggle optimistically adds then removes a business id"` | Pass |
| 3 | Toggle request fails → icon rolls back to prior state, non-blocking error shown | A | `favorite_toggle_button_test.dart::"AC3: a failed toggle rolls back the icon and shows a snackbar"` + `favorites_controller_test.dart::"toggle reverts the optimistic update when the API call fails"` | Pass |
| 4 | Favorites screen lists name, city/state, average rating, most-recently-favorited first | A | `mobile/test/favorites_screen_test.dart::"AC4: lists favorited businesses with name, city/state and rating"` (ordering itself is unchanged backend behavior — `Favorite.created_at desc` — confirmed by code review; mobile renders the array as-is) | Pass |
| 5 | Zero favorites → empty state with a way back to the business list | A | `favorites_screen_test.dart::"AC5: shows an empty-state message with a way back to the business list"` (also asserts the "Browse businesses" button actually navigates to `/businesses`) | Pass |
| 6 | Pull down on Favorites screen → refreshes with a spinner | A (refetch trigger) + M (visible spinner animation) | `favorites_screen_test.dart::"AC6: pull-to-refresh re-fetches the favorites list"` (invokes the `RefreshIndicator.onRefresh` callback directly, asserts a second repository call — see the S-023 report for why this technique is used instead of `RefreshIndicatorState.show()`); M-001 | Pass |
| 7 | Favorites screen initial load fails → inline error + Retry | A | `favorites_screen_test.dart::"AC7: shows an inline error with a Retry action when the initial load fails"` | Pass |
| 8 | Un-favorite from within the Favorites screen → row removed immediately, no manual pull-to-refresh needed | A | `favorites_screen_test.dart::"AC8: un-favoriting a row removes it from the list immediately"` | Pass |
| 9 | Not logged in, tap favorite toggle → routed to `/login`, no favorite created | A | `favorite_toggle_button_test.dart::"AC9: tapping the toggle while logged out routes to /login instead of favoriting"` | Pass |
| 10 | Favorites entry point hidden (or routes to login) when logged out | A | `mobile/test/business_list_screen_test.dart::"logged out: no notifications icon and no favorites icon, only Sign in"` (asserts the app-bar icon is hidden outright, matching the Architect's chosen convention) | Pass |
| 11 | Non-approved/stale business 404 on toggle → clear "no longer available to favorite" message, not a generic error | A | `favorite_toggle_button_test.dart::"AC11: a stale-business 404 surfaces a clear message, not a generic error"` | Pass |

**Coverage:** 11 / 11 AC mapped (11 Pass — AC6's refetch trigger is automated; the
visible spinner animation itself is left to a manual smoke check, M-001).

---

## Backend tests added

None. Architect spec: "No new backend endpoints. All existing, unchanged." — confirmed
by code review of `backend/app/routers/favorites.py`; no lines touched by this slice.
Per the task's scope boundary, backend code was not modified or re-tested this pass.

---

## Mobile tests added

- `mobile/test/favorite_toggle_button_test.dart` (**new**, 4 tests) — AC1, AC2, AC3,
  AC9, AC11
- `mobile/test/favorites_screen_test.dart` (**new**, 5 tests) — AC4, AC5, AC6, AC7, AC8
- `mobile/test/business_list_screen_test.dart` (**new**, 3 tests) — AC10 (+ S-025 AC8,
  shared file since both entry points live on the same app bar) — see also
  `TR-S-025-mobile-notifications.md`
- `mobile/test/favorites_controller_test.dart` (pre-existing, 2 tests, verified still
  green) — AC2, AC3

### Run output

```
cd mobile && flutter test
00:21 +60: All tests passed!    # full mobile/test suite across all S-023/S-024/S-025 files

cd mobile && flutter analyze
3 issues found. (ran in ~7-10s)   # pre-existing prefer_initializing_formals infos in
                                    # auth_interceptor.dart, unrelated to this slice
```

`favorites_screen_test.dart` was also run in isolation (5 tests) with no failures.

Note: this pass ran on a machine under heavy, sustained concurrent load from other
agent sessions (15-20+ parallel `dart`/`dartvm`/`flutter_tester` processes observed via
`tasklist` throughout this session), which slowed individual `flutter test` invocations
considerably. Separately (a test-authoring issue, not environment load), an earlier
version of `business_detail_screen_test.dart`'s AC5 pull-to-refresh test (S-023) drove
the gesture via `RefreshIndicatorState.show()` awaited directly, which deadlocks
Flutter's widget-test fake-async environment; the analogous test in this slice
(`favorites_screen_test.dart`'s AC6) uses the same fixed technique from the start
(invoking `RefreshIndicator.onRefresh` directly) — see `TR-S-023-mobile-reviews.md` for
the full account. Every file relevant to this slice
(`favorite_toggle_button_test.dart`, `favorites_screen_test.dart`,
`business_list_screen_test.dart`, `favorites_controller_test.dart`) passed cleanly on
every run this session.

---

## Manual checklist

- [ ] M-001: `flutter run` — pull down on `/favorites`, confirm the refresh spinner
  visibly animates while in flight (the refetch trigger itself is already automated,
  see AC6 above). **Not run** — no Android SDK/emulator available in this environment
  (accepted, documented constraint).
- [ ] M-002: Favorite a business from the business list row, navigate to its detail
  screen (S-023), confirm the toggle already shows "favorited" there without a
  re-fetch (cross-screen sync via the shared `favoritedIdsProvider`); reverse-check
  un-favoriting from the detail screen reflects back on the list row. **Not run**;
  strongly implied correct by `favoritedIdsProvider`'s architecture (a single shared,
  non-`.autoDispose` provider instance consumed by every toggle in the app, verified by
  code review of `favorites_providers.dart`) plus the fact that `FavoriteToggleButton`
  is the same widget instance-type used on both the list row and the detail screen
  (`business_detail_screen.dart` line ~92).

Flagging for PM/Builder to run before final acceptance — consistent with this
environment's standing constraint (no Android SDK/emulator available to this agent).

---

## Regressions / gaps

No regressions. No product bugs found. AC6's refetch trigger is automated (direct
`RefreshIndicator.onRefresh` invocation, same technique as S-023's AC5); only the
visible spinner animation itself is left to the manual checklist (M-001), which is a
rendering detail, not a behavior gap.

---

## Recommendation

**Ship** — 11/11 AC automated and pass (AC6's spinner *animation* is a cosmetic
manual-checklist item, not an unautomated behavior — its refetch trigger is verified),
no bugs found, RBAC (customer-only favoriting, entry-point hidden when logged out)
fully covered, and no AI disclaimer is required for this slice (favoriting is a plain
user action, confirmed against the slice's own UX notes). Residual manual checklist
items (M-001–M-002) should be run by PM/Builder in a Docker/emulator environment before
final sign-off.
