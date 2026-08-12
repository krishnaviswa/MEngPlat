# TP-S-025: Mobile notifications (Flutter) — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-025 |
| **Author** | Tester |
| **Date** | 2026-08-12 |

---

## Scope

The app-bar bell entry point + unread badge on `BusinessListScreen`
(`notification_badge.dart`, `unreadCountProvider` in `notifications_providers.dart`),
and the dedicated Notifications screen (`notifications_screen.dart`, route
`/notifications`). No backend changes — reuses S-008/S-015's existing
`GET /notifications`, `POST /notifications/{id}/read`,
`POST /notifications/read-all` endpoints unchanged.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Mobile unit (Riverpod) | `flutter test` (`testWidgets`, using `flutter_test`'s fake-clock `pump(duration)`) | `UnreadCountController`'s 30s poll (AC9), failed-poll degradation, no-poll-while-logged-out (AC8) |
| Mobile widget | `flutter test` + `flutter_test` | `NotificationBadge` hidden/shown/capped display, `NotificationsScreen` list/unread-styling/mark-one/mark-all/empty/error, `BusinessListScreen` entry-point role gating |
| Backend | n/a | Zero backend surface — Architect spec: "No new backend endpoints. All existing, unchanged." |
| Manual | `flutter run` / `docker compose up --build` | Pull-to-refresh gesture, full app-bar bell → `/notifications` navigation, real 30s-interval behavior over an actual elapsed wall-clock minute — **not run this session**, no Android SDK/emulator available |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1. Entry point with unread badge, hidden at count 0 | Automated | `mobile/test/notification_badge_test.dart` (4 tests: hidden at 0, hidden if negative, exact count, "9+" cap) |
| 2. Notifications screen lists title/message/relative time, most recent first, unread visually distinguished | Automated | `mobile/test/notifications_screen_test.dart::"AC2: lists notifications with unread items visually distinguished from read ones"`; relative-time formatting: `mobile/test/relative_time_test.dart` (5 tests) |
| 3. Tap unread → marked read via API, unread styling clears, badge decrements, no navigation/reload | Automated | `notifications_screen_test.dart::"AC3: tapping an unread notification marks it read, clears its styling, and decrements the badge"` (asserts `unreadCountProvider`'s value directly, not just the local list mutation) |
| 4. "Mark all as read" clears all unread styling and the badge | Automated | `notifications_screen_test.dart::"AC4: \"Mark all as read\" clears unread styling from every item and zeroes the badge"` (asserts `unreadCountProvider` goes to 0) + `"\"Mark all as read\" is disabled when there is nothing unread"` |
| 5. Empty state ("No notifications yet") | Automated | `notifications_screen_test.dart::"AC5: shows an empty-state message..."` |
| 6. Pull-to-refresh with spinner | Automated (refetch trigger) + Manual (visible spinner) | `notifications_screen_test.dart::"AC6: pull-to-refresh re-fetches the notifications list"` (invokes `RefreshIndicator.onRefresh` directly, asserts a second repository call — see test report for why this is used instead of `RefreshIndicatorState.show()`, which deadlocks the fake-async test environment); actual spinner animation — M-001 |
| 7. Inline error + Retry on initial load failure | Automated | `notifications_screen_test.dart::"AC7: shows an inline error with a Retry action..."` |
| 8. No entry point reachable anywhere when logged out | Automated | `mobile/test/business_list_screen_test.dart::"logged out: no notifications icon and no favorites icon, only Sign in"` + `mobile/test/unread_count_provider_test.dart::"never polls the API while logged out (AC8)"` |
| 9. Unread badge re-polled every 30s while foregrounded | Automated (fake-clock) | `unread_count_provider_test.dart::"polls immediately on first watch, then again every 30s while logged in (AC9)"` + `"a failed poll leaves the last-known count in place instead of crashing/blanking"` |
| 10. No AI-suggestion framing on notification type/title/message | Automated (regression) + code review | Confirmed by direct inspection of `notifications_screen.dart` / `notification_badge.dart` / `notifications_repository.dart` — no AI-related text or logic anywhere in this feature; `notifications_screen_test.dart`'s title/message assertions render the fields plainly with no badge/prefix |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Notifications entry point / badge | customer, merchant, admin | Shown — endpoint is role-agnostic (`get_current_user`), matches slice scope; `business_list_screen_test.dart` covers customer and merchant explicitly (admin follows the same `isLoggedIn` gate, not role-specific) |
| Notifications entry point / badge | anonymous | Hidden (AC8) — `business_list_screen_test.dart::"logged out..."` |
| Mark one / mark all read | any authenticated role, own notifications only | Server-enforced by `user_id`, unchanged (`backend/app/routers/notifications.py`) — confirmed via code read, not independently re-tested (no backend change) |

---

## Edge cases

- Zero notifications (AC5) — covered.
- Notifications-fetch failure (AC7) — covered.
- Failed unread-count poll (degrade to last-known count, no crash) — covered.
- Logged out — poll never starts, no API call made (AC8) — covered.
- "Mark all as read" with nothing unread (button disabled, no-op) — covered.
- 30s recurring poll (not just the first fetch) — covered via `flutter_test`'s fake-clock `pump(Duration(seconds: 30))`, which advances the real `Timer.periodic` deterministically without a real 30s wall-clock wait.
- Badge-decrement wiring between `NotificationsListController.markRead`/`markAllRead` and the shared `unreadCountProvider` — covered by directly reading `unreadCountProvider`'s value in the AC3/AC4 tests, not just the local list mutation.
- Pull-to-refresh re-triggers the fetch (AC6) — covered at the `RefreshIndicator` wiring level; the visible spinner animation itself is a rendering detail left to Manual (M-001).

---

## Manual checklist (if applicable)

- [ ] M-001: `flutter run` — pull down on `/notifications`, confirm the refresh spinner *animates* while in flight (the refetch trigger itself is already automated — see AC6 above).
- [ ] M-002: Leave the app foregrounded on `BusinessListScreen` for over 30 real seconds with a backend that has unread notifications appearing server-side (e.g. another session posts a review), confirm the badge count updates without navigating to `/notifications` (real-clock sanity check on top of the fake-clock unit coverage in M-001... see AC9 test).

Not executed this pass — no Android SDK/emulator available in this environment (accepted,
documented constraint, not a defect). Flagged for PM/Builder to run before final acceptance.

---

## Environment

- `AI_PROVIDER=mock` — n/a, notifications are explicitly non-AI (AC10).
- `docker compose up --build` — not run this session (no isolated environment for a live backend + emulator here).
- `flutter analyze` / `flutter test` — run locally, both clean (see test report).
