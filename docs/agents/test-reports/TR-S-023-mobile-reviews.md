# TR-S-023: Mobile reviews (Flutter) — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-023 |
| **Author** | Tester |
| **Date** | 2026-08-12 |
| **Recommendation** | Ship |

---

## Summary

All 13 AC pass. Code review plus new automated coverage (unit + widget) confirms the
business detail screen, review form, and their eligibility/error/empty edge cases match
the Architect spec exactly, including the `myBusinessIdsProvider` async-dependency race
fix from commit `207abb7` (verified sound, with a new dedicated regression test —
`mobile/test/my_business_ids_provider_test.dart`, which did not exist before this pass).
No backend surface to test (Architect: "No new backend endpoints. All existing,
unchanged.") — confirmed by code review of `backend/app/routers/reviews.py`,
`photos.py`, `businesses.py`; none were touched. `flutter analyze` is clean (only the
3 pre-existing, unrelated `prefer_initializing_formals` infos in
`auth_interceptor.dart`). No product bugs found. One design-parity check verified
explicitly: mobile's photo cap (`_maxPhotos = 5` in `review_form_sheet.dart`) matches
`frontend/src/components/ReviewForm.tsx`'s `MAX_PHOTOS = 5` exactly, as the Architect
spec required.

AC9 (photo attach/upload) is **partially** automated: the business-logic guarantee that
a failed photo upload never rolls back the already-posted review, and that a successful
upload merges the photo URL into the review, are both automated at the
`ReviewsController` unit level. The actual OS gallery/camera picker interaction
(`image_picker`) cannot be exercised in this environment (no Android SDK/emulator, a
documented, accepted constraint) and is not mockable without adding new test
infrastructure this pass didn't scope in; it is Manual (M-003), with
`AndroidManifest.xml`/`Info.plist` permission entries confirmed present by code review.

**One test-authoring bug found and fixed during this pass (not a product bug):** the
first version of `business_detail_screen_test.dart`'s AC5 pull-to-refresh test drove the
gesture via `await RefreshIndicatorState.show(); await tester.pumpAndSettle();`, which
deadlocks Flutter's widget-test fake-async environment — `show()`'s internal
`AnimationController` never advances because nothing pumps a frame while it's being
awaited directly. This reproduced deterministically (`TimeoutException: Test timed out
after 10 minutes`) across two independent runs, not intermittently, ruling out
environment load as the cause. Fixed by invoking the `RefreshIndicator.onRefresh`
callback directly instead of simulating the gesture/animation — a standard, documented
pattern for this exact scenario. Reconfirmed reliable and fast (whole suite in ~20s)
across multiple subsequent full-suite runs. See the AC5 row below.

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Tap a business row → detail screen shows name, average rating, review count, reviews list | A | `mobile/test/business_detail_screen_test.dart::"AC1: shows business name, average rating, review count and its reviews"` (ordering itself is unchanged backend behavior, confirmed by code review — mobile renders the array as-is) | Pass |
| 2 | Each review shows reviewer name/"Customer" fallback, star rating, title, body, and a clearly-labeled "AI: {sentiment}" suggestion badge | A | `mobile/test/review_card_test.dart` (6 tests: sentiment badge, "AI summary (suggestion):" text, no badge when absent, name fallback, name present, title present) | Pass |
| 3 | Zero reviews → empty-state message, not a blank list | A | `business_detail_screen_test.dart::"AC3: shows an empty-state message when the business has zero reviews"` | Pass |
| 4 | Reviews request fails → inline error + Retry, not a blank screen/crash | A | `business_detail_screen_test.dart::"AC4: shows an inline error with a Retry action when the reviews request fails"` | Pass |
| 5 | Pull down on reviews list → refreshes with a spinner | A (refetch trigger) + M (visible spinner animation) | `business_detail_screen_test.dart::"AC5: pull-to-refresh re-fetches the reviews list"` (invokes the `RefreshIndicator.onRefresh` callback directly, asserts a second repository call — see the deadlock note above for why this technique was chosen over simulating the gesture/animation); M-001 | Pass |
| 6 | Not-yet-reviewed, eligible customer/merchant/admin → "Add review" action shown | A | `business_detail_screen_test.dart::"AC6: shows \"Add review\" for an eligible customer who has not reviewed yet"` | Pass |
| 7 | Review form: 1–5 star rating required, optional title, body min 10 chars required, submit disabled until valid | A | `mobile/test/review_form_sheet_test.dart::"submit stays disabled until a rating and a 10+ char comment are provided"` | Pass |
| 8 | Valid submit succeeds → new review at top without manual refresh, form closes, brief success confirmation | A | `mobile/test/reviews_controller_test.dart::"createReview prepends the new review without a refetch"` + `review_form_sheet_test.dart::"a successful submit closes the sheet and shows a success confirmation (AC8)"` | Pass |
| 9 | Optional photo attach (up to the web's 5-photo cap); upload after create; failed upload doesn't lose the posted review, shows a non-blocking N-failed warning | A (business logic) + M (device picker UI) | `reviews_controller_test.dart::"a failed photo upload does not roll back the already-created review (AC9)"` + `"a successful photo upload merges the url into the matching review (AC9)"`; cap parity confirmed by code review (`review_form_sheet.dart`'s `_maxPhotos = 5` == `ReviewForm.tsx`'s `MAX_PHOTOS = 5`); OS picker interaction — M-003 | Pass |
| 10 | Already-reviewed → "Add review" hidden; stale duplicate submit → clear "already reviewed" error, not generic | A | `business_detail_screen_test.dart::"AC10: hides \"Add review\" once the current user has already reviewed this business"` + `reviews_controller_test.dart::"hasAlreadyReviewed matches on authorId"` + `review_form_sheet_test.dart::"AC10: a stale duplicate submission surfaces the backend's clear \"already reviewed\" message"` | Pass |
| 11 | Submit fails (offline/server error) → inline error, entered rating/title/comment preserved (not cleared) | A | `review_form_sheet_test.dart::"a failed submit shows an inline error and preserves entered fields (AC11)"` | Pass |
| 12 | Merchant viewing their own business → "Add review" hidden | A | `mobile/test/my_business_ids_provider_test.dart` (3 tests, regression coverage for the commit `207abb7` race fix) + `business_detail_screen_test.dart::"AC12: hides \"Add review\" for a merchant viewing their own business"` + `"a merchant viewing a business they do not own still sees \"Add review\""` | Pass |
| 13 | Not logged in → reviews list still visible; tapping "Add review" routes to `/login`, not the form | A | `business_detail_screen_test.dart::"AC13: an anonymous visitor sees the reviews list, and tapping \"Add review\" routes to /login"` (real `GoRouter`, asserts actual navigation) | Pass |

**Coverage:** 13 / 13 AC mapped (13 Pass).

---

## `myBusinessIdsProvider` race-fix review (commit `207abb7`)

Reviewed `mobile/lib/features/businesses/business_list_provider.dart`. The fix changes
`build()` to `await ref.watch(authControllerProvider.future)` instead of peeking
`.valueOrNull`, so the provider suspends until auth actually settles instead of racing a
still-loading `authControllerProvider` and resolving early to `{}`. This now matches the
already-correct `FavoritedIdsController.build()` pattern in `favorites_providers.dart`
(same fix, same reasoning, same code shape). Sound — no remaining early-resolve path
found by code review. No prior test existed for `myBusinessIdsProvider` itself
(`favorites_controller_test.dart` only covered the favorites side, per the task brief);
added `mobile/test/my_business_ids_provider_test.dart` with 3 tests:
- stays in a loading state (never resolves early to `{}`) while auth is still settling,
  and does not call `GET /businesses/mine` until it does
- resolves to `{}` for a non-merchant once auth settles (no `listMine` call)
- resolves to `{}` while logged out (no `listMine` call)

---

## Backend tests added

None. Architect spec: "No new backend endpoints. All existing, unchanged." — confirmed
by code review of `backend/app/routers/reviews.py`, `backend/app/routers/photos.py`,
`backend/app/routers/businesses.py`; no lines touched by this slice. Per the task's
scope boundary, backend code was not modified or re-tested this pass.

---

## Mobile tests added

- `mobile/test/business_detail_screen_test.dart` (**new**, 9 tests) — AC1, AC3, AC4,
  AC5, AC6, AC10, AC12 (+ the "not own business" branch), AC13
- `mobile/test/review_form_sheet_test.dart` (**new**, 4 tests) — AC7, AC8, AC10, AC11
- `mobile/test/my_business_ids_provider_test.dart` (**new**, 3 tests) — AC12 regression
  (commit `207abb7`)
- `mobile/test/reviews_controller_test.dart` (extended, +2 tests) — AC9 photo
  upload success/failure (existing 2 tests unchanged: `createReview` prepend,
  `hasAlreadyReviewed`)
- `mobile/test/review_card_test.dart` (pre-existing from Builder, 6 tests, verified
  still green) — AC2

### Run output

```
cd mobile && flutter test
00:21 +60: All tests passed!    # full mobile/test suite across all S-023/S-024/S-025 files

cd mobile && flutter analyze
3 issues found. (ran in ~7-10s)   # pre-existing prefer_initializing_formals infos in
                                    # auth_interceptor.dart, unrelated to this slice
```

`business_detail_screen_test.dart` and `review_form_sheet_test.dart` were each also run
in isolation (9 and 4 tests respectively) with no failures, confirming AC5's fix (see
Summary) is reliable and not a one-off.

---

## Manual checklist

- [ ] M-001: `flutter run` (web or a real device/emulator) — pull down on the reviews
  list on `/businesses/:slug`, confirm the refresh spinner visibly animates while in
  flight (the refetch trigger itself is already automated, see AC5 above). **Not run**
  — no Android SDK/emulator available in this environment (accepted, documented
  constraint).
- [ ] M-002: Full router flow — from `/login`, tap "Continue without signing in",
  confirm `/businesses` and `/businesses/:slug` are reachable without a session
  (ADR-003 public carve-out) and every other route still redirects to `/login`. **Not
  run**; strongly implied correct by `router.dart` code review (explicit
  `isPublicBusinessRoute` carve-out) plus `business_detail_screen_test.dart`'s AC13
  scenario, which exercises the same redirect logic via a real `GoRouter`.
- [ ] M-003: `image_picker` device permission prompts (camera/gallery) and the
  "N photo(s) failed to upload" snackbar against a real picker selection, on a real
  Android device. **Not run** — no Android SDK/emulator available; `AndroidManifest.xml`
  (`CAMERA`, `READ_MEDIA_IMAGES`) and `Info.plist` permission entries reviewed and
  present.

Flagging for PM/Builder to run before final acceptance — consistent with this
environment's standing constraint (no Android SDK/emulator available to this agent).

---

## Regressions / gaps

No product regressions or bugs found. AC9's device-picker UI interaction is the only AC
not fully automatable in this environment; its business-logic guarantees are automated
and its UI wiring (permissions, cap, snackbar copy) is verified by code review, so this
is not treated as a gap blocking Ship — see Manual checklist M-003. (One test-authoring
deadlock was found and fixed in this pass's own new AC5 test — see Summary; it never
affected product code and is called out here only for traceability.)

---

## Recommendation

**Ship** — 13/13 AC pass, no bugs found, RBAC/eligibility edge cases (AC6/10/12/13) all
covered, AI disclaimer language (AC2) unchanged and correctly labeled as a suggestion,
and the `myBusinessIdsProvider` race fix is sound with new regression coverage.
Residual manual checklist items (M-001–M-003) are environment-constrained, not
functional doubts, and should be run by PM/Builder in a Docker/emulator environment
before final sign-off, consistent with this project's standing constraint in this
session.
