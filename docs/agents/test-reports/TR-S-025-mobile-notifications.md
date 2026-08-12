# TR-S-025: Mobile notifications (Flutter) — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-025 |
| **Author** | Tester |
| **Date** | 2026-08-12 |
| **Recommendation** | Ship |

---

## Summary

All 10 AC pass. Code review plus new automated unit + widget coverage confirms the
app-bar bell entry point + unread badge (`NotificationBadge`, `unreadCountProvider`),
the dedicated Notifications screen (list, unread styling, mark-one, mark-all, empty
state, error + Retry, pull-to-refresh), and the 30-second background poll all match the
Architect spec. No backend surface to test (Architect: "No new backend endpoints. All
existing, unchanged.") — confirmed by code review of
`backend/app/routers/notifications.py`; not touched by this slice. `flutter analyze` is
clean (only the 3 pre-existing, unrelated `prefer_initializing_formals` infos in
`auth_interceptor.dart`). No product bugs found.

AC9 (the 30-second poll) is fully automated despite this being a background-timer
behavior: `flutter_test`'s `testWidgets` runs inside a fake-clock zone, so
`tester.pump(const Duration(seconds: 30))` deterministically advances the real
`Timer.periodic(30s)` in `UnreadCountController` without an actual 30-second wall-clock
wait or any new fake-time dependency. This also gives higher-confidence coverage of
AC9 than the test plan originally scoped (which anticipated deferring this to manual
verification).

AC3/AC4's badge-decrement wiring (`unreadCountProvider.notifier.decrement()`/`.clear()`
called from inside `markRead()`/`markAllRead()`) is verified directly by reading
`container.read(unreadCountProvider)` before and after the mark-read/mark-all
interaction, not just by code review — this closes what an earlier draft of this report
flagged as a minor coverage gap. AC6 (pull-to-refresh) is likewise now automated at the
refetch-trigger level, using the same `RefreshIndicator.onRefresh`-direct-invocation
technique adopted after the deadlock found and fixed in S-023's equivalent test (see
`TR-S-023-mobile-reviews.md`) — the visible spinner *animation* itself remains a
Manual/cosmetic check (M-001).

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Entry point shows an unread-count badge, hidden when the count is 0 | A | `mobile/test/notification_badge_test.dart` (4 tests: hidden at 0, hidden if negative, exact single-digit count, "9+" cap above 9) | Pass |
| 2 | Notifications screen lists title/message/relative time, most recent first, unread visually distinguished | A | `mobile/test/notifications_screen_test.dart::"AC2: lists notifications with unread items visually distinguished from read ones"` (bold vs. non-bold title asserted); relative-time formatting — `mobile/test/relative_time_test.dart` (5 tests, pre-existing, still green); ordering itself is unchanged backend behavior (`Notification.created_at.desc()`), confirmed by code review — mobile renders the array as-is | Pass |
| 3 | Tap unread → marked read via API, unread styling clears, badge decrements, no navigation/reload | A | `notifications_screen_test.dart::"AC3: tapping an unread notification marks it read, clears its styling, and decrements the badge"` — asserts `unreadCountProvider`'s value directly (1 → 0), not just the local list mutation | Pass |
| 4 | "Mark all as read" clears the badge and all unread styling | A | `notifications_screen_test.dart::"AC4: \"Mark all as read\" clears unread styling from every item and zeroes the badge"` (asserts `unreadCountProvider` goes to 0) + `"\"Mark all as read\" is disabled when there is nothing unread"` | Pass |
| 5 | Zero notifications → empty state ("No notifications yet") | A | `notifications_screen_test.dart::"AC5: shows an empty-state message when there are zero notifications"` | Pass |
| 6 | Pull down on Notifications screen → refreshes with a spinner | A (refetch trigger) + M (visible spinner animation) | `notifications_screen_test.dart::"AC6: pull-to-refresh re-fetches the notifications list"` (invokes `RefreshIndicator.onRefresh` directly, asserts a second repository call); M-001 | Pass |
| 7 | Notifications screen initial load fails → inline error + Retry | A | `notifications_screen_test.dart::"AC7: shows an inline error with a Retry action when the initial load fails"` | Pass |
| 8 | No notifications entry point reachable anywhere when logged out | A | `mobile/test/business_list_screen_test.dart::"logged out: no notifications icon and no favorites icon, only Sign in"` + `mobile/test/unread_count_provider_test.dart::"never polls the API while logged out (AC8)"` (asserts zero API calls, not just a hidden icon) | Pass |
| 9 | Unread badge re-fetched and updated every 30s in the background while foregrounded | A (fake-clock) | `unread_count_provider_test.dart::"polls immediately on first watch, then again every 30s while logged in (AC9)"` (asserts a second repository call and an updated count after `tester.pump(Duration(seconds: 30))`) + `"a failed poll leaves the last-known count in place instead of crashing/blanking"` | Pass |
| 10 | Notification `type`/`title`/`message` shown plainly, no AI-suggestion framing | A (regression) + code review | Confirmed by direct inspection of `notifications_screen.dart`, `notification_badge.dart`, `notifications_repository.dart` — no "AI"/"suggestion" text or logic anywhere in this feature; `notifications_screen_test.dart`'s title/message assertions render the fields as plain `Text`, no badge/prefix | Pass |

**Coverage:** 10 / 10 AC mapped (10 Pass — AC6's refetch trigger is automated; the
visible spinner animation itself is left to a manual smoke check, M-001).

---

## Backend tests added

None. Architect spec: "No new backend endpoints. All existing, unchanged." — confirmed
by code review of `backend/app/routers/notifications.py`; no lines touched by this
slice. Per the task's scope boundary, backend code was not modified or re-tested this
pass.

---

## Mobile tests added

- `mobile/test/notification_badge_test.dart` (**new**, 4 tests) — AC1
- `mobile/test/notifications_screen_test.dart` (**new**, 7 tests) — AC2, AC3, AC4, AC5,
  AC6, AC7
- `mobile/test/unread_count_provider_test.dart` (**new**, 3 tests) — AC8 (provider
  half), AC9
- `mobile/test/business_list_screen_test.dart` (**new**, 3 tests, shared with S-024) —
  AC8 (entry-point visibility half) — see also `TR-S-024-mobile-favorites.md`
- `mobile/test/relative_time_test.dart` (pre-existing, 5 tests, verified still green) —
  AC2's relative-time formatting

### Run output

```
cd mobile && flutter test
00:21 +60: All tests passed!    # full mobile/test suite across all S-023/S-024/S-025 files

cd mobile && flutter analyze
3 issues found. (ran in ~7-10s)   # pre-existing prefer_initializing_formals infos in
                                    # auth_interceptor.dart, unrelated to this slice
```

`notifications_screen_test.dart` was also run in isolation (7 tests) with no failures.
Its AC6 pull-to-refresh test uses the same `RefreshIndicator.onRefresh`-direct-invoke
technique as S-023/S-024's equivalents, avoiding the `RefreshIndicatorState.show()`
deadlock documented in `TR-S-023-mobile-reviews.md` from the start.

---

## Manual checklist

- [ ] M-001: `flutter run` — pull down on `/notifications`, confirm the refresh spinner
  visibly animates while in flight (the refetch trigger itself is already automated,
  see AC6 above). **Not run** — no Android SDK/emulator available in this environment
  (accepted, documented constraint).
- [ ] M-002: Leave the app foregrounded on `BusinessListScreen` for over 30 real
  seconds with a backend that has unread notifications appearing server-side (e.g.
  another session posts a review), confirm the badge count updates without navigating
  to `/notifications` — a real-wall-clock sanity check on top of the fake-clock unit
  coverage already automated for AC9. **Not run** — no Docker/live-backend environment
  available this session.

Flagging for PM/Builder to run before final acceptance — consistent with this
environment's standing constraint (no Android SDK/emulator available to this agent).

---

## Regressions / gaps

No product regressions or bugs found. AC6's spinner *animation* (as opposed to its
refetch trigger, which is automated) is the only item left to the manual checklist
(M-001) — a rendering detail, not a behavior gap.

---

## Recommendation

**Ship** — 10/10 AC automated and pass (AC6's spinner *animation* is a cosmetic
manual-checklist item, not an unautomated behavior — its refetch trigger is verified),
no bugs found, RBAC (entry point hidden when logged out, verified at both the
icon-visibility and no-API-call levels) fully covered, and AC10's "no AI-suggestion
framing" confirmed both by code review and by the plain-text rendering asserted in the
widget tests. Residual manual checklist items (M-001–M-002) should be run by PM/Builder
in a Docker/emulator environment before final sign-off.
