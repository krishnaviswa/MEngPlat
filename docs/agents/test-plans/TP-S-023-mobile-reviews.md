# TP-S-023: Mobile reviews (Flutter) — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-023 |
| **Author** | Tester |
| **Date** | 2026-08-12 |

---

## Scope

The new business detail screen (`mobile/lib/features/businesses/business_detail_screen.dart`,
route `/businesses/:slug`) and the review submission flow (`review_form_sheet.dart`,
`review_card.dart`, `review_providers.dart`, `review_repository.dart`). No backend
changes — all existing, unchanged endpoints (`GET /businesses/{slug}`,
`GET /reviews/business/{business_id}`, `POST /reviews`, `POST /photos/upload`,
`GET /businesses/mine`), consumed via the generated `merchanthub_api` Dart client.
Also covers the `myBusinessIdsProvider` async-dependency race fix (commit `207abb7`,
landed just before this pass) that backs AC12.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Mobile unit (Riverpod) | `flutter test` | `ReviewsController` (prepend-on-create, photo upload success/failure), `hasAlreadyReviewed` derivation, `myBusinessIdsProvider` (race regression) |
| Mobile widget | `flutter test` + `flutter_test` | `ReviewCard` AI disclaimer rendering, `ReviewFormSheet` validation/submit/error states, `BusinessDetailScreen` header/empty/error/eligibility states (with a real `GoRouter` for AC13's tap-to-login) |
| Backend | n/a | Zero backend surface — Architect spec: "No new backend endpoints. All existing, unchanged." No `pytest` run; not in scope. |
| Manual | `flutter run` / `docker compose up --build` | Pull-to-refresh gesture, full router public-route carve-out (ADR-003) end-to-end, `image_picker` device permission prompts — **not run this session**, no Android SDK/emulator available (accepted environment constraint) |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1. Tap business row → detail screen shows name, avg rating, review count, reviews most-recent-first | Automated (header) + code review (row-tap wiring, unchanged backend ordering) | `mobile/test/business_detail_screen_test.dart::"AC1: shows business name, average rating, review count and its reviews"` |
| 2. Review shows reviewer name/"Customer" fallback, rating, title, body, "AI: {sentiment}" badge | Automated | `mobile/test/review_card_test.dart` (6 tests) |
| 3. Empty state ("No reviews yet") | Automated | `business_detail_screen_test.dart::"AC3: shows an empty-state message..."` |
| 4. Inline error + Retry | Automated | `business_detail_screen_test.dart::"AC4: shows an inline error with a Retry action..."` |
| 5. Pull-to-refresh with spinner | Automated (refetch trigger) + Manual (visible spinner) | `business_detail_screen_test.dart::"AC5: pull-to-refresh re-fetches the reviews list"` (invokes `RefreshIndicator.onRefresh` directly, asserts a second `listForBusiness` call — see test report for why this is used instead of `RefreshIndicatorState.show()`, which deadlocks the fake-async test environment); actual spinner animation — M-001 |
| 6. "Add review" shown when eligible | Automated | `business_detail_screen_test.dart::"AC6: shows \"Add review\" for an eligible customer..."` |
| 7. Review form: rating required, body min 10 chars, submit disabled until valid | Automated | `mobile/test/review_form_sheet_test.dart::"submit stays disabled until a rating and a 10+ char comment are provided"` |
| 8. Valid submit → prepends to list, form closes, success confirmation | Automated | `mobile/test/reviews_controller_test.dart::"createReview prepends the new review without a refetch"` + `review_form_sheet_test.dart::"a successful submit closes the sheet and shows a success confirmation (AC8)"` |
| 9. Photo attach/upload; failed upload doesn't roll back the review, shows non-blocking warning | Automated (controller) | `reviews_controller_test.dart::"a failed photo upload does not roll back the already-created review (AC9)"` + `"a successful photo upload merges the url into the matching review (AC9)"` |
| 10. Already-reviewed hides "Add review"; stale duplicate submit shows clear 409 error | Automated | `business_detail_screen_test.dart::"AC10: hides \"Add review\"..."` + `reviews_controller_test.dart::"hasAlreadyReviewed matches on authorId"` + `review_form_sheet_test.dart::"AC10: a stale duplicate submission surfaces the backend's clear \"already reviewed\" message"` (simulates the 409 `ApiException`, asserts the exact inline text renders); backend `detail="You have already reviewed this business"` confirmed unchanged in `backend/app/routers/reviews.py` |
| 11. Submit failure shows inline error, preserves entered fields | Automated | `review_form_sheet_test.dart::"a failed submit shows an inline error and preserves entered fields (AC11)"` |
| 12. Merchant viewing own business hides "Add review" | Automated (provider regression + widget) | `mobile/test/my_business_ids_provider_test.dart` (3 tests) + `business_detail_screen_test.dart::"AC12: hides \"Add review\"..."` + `"a merchant viewing a business they do not own still sees \"Add review\""` |
| 13. Anonymous can view reviews; tapping "Add review" routes to `/login` | Automated | `business_detail_screen_test.dart::"AC13: an anonymous visitor sees the reviews list, and tapping \"Add review\" routes to /login"` (real `GoRouter`, asserts actual navigation) |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Business detail + reviews list | anonymous, customer, merchant, admin | All can view (public route, ADR-003) — confirmed by `business_detail_screen_test.dart` scenarios with `user: null` and each role |
| "Add review" own-business gate | merchant on own business | Hidden — `my_business_ids_provider_test.dart` + `business_detail_screen_test.dart::AC12` |
| "Add review" own-business gate | merchant on a different business | Shown — `business_detail_screen_test.dart::"a merchant viewing a business they do not own..."` |
| Submit review | anonymous | Not possible — form only reachable after `/login` push, per AC13 |
| Backend `403 "Cannot review your own business"` / `409 "You have already reviewed this business"` | merchant / any repeat reviewer | Defense-in-depth server check, unchanged (`backend/app/routers/reviews.py:167,173,187`) — confirmed via code read, not independently re-tested (no backend change) |

---

## Edge cases

- Zero reviews (AC3) — covered.
- Reviews-fetch failure (AC4) — covered.
- Photo upload failure after a successful review create (AC9) — covered, review is never rolled back.
- Anonymous guest with reviews present (AC13) — covered; reviews render, "Add review" routes to login.
- Merchant on their own vs. another merchant's business (AC12) — both branches covered.
- Async-dependency race: `myBusinessIdsProvider` resolving to `{}` before `authControllerProvider` settles (pre-fix bug) — explicit regression coverage in `my_business_ids_provider_test.dart`.
- Pull-to-refresh re-triggers the fetch (AC5) — covered at the `RefreshIndicator` wiring level (invoking `RefreshIndicator.onRefresh` directly drives a real second `listForBusiness` call); the visible spinner animation itself is a rendering detail left to Manual (M-001).
- Stale duplicate submission (already-reviewed customer resubmits via a stale form) surfaces the backend's exact 409 message rather than a generic error (AC10) — covered.

---

## Manual checklist (if applicable)

- [ ] M-001: `flutter run` (web or a real device/emulator, not available this session) — pull down on the reviews list on `/businesses/:slug`, confirm the refresh spinner *animates* while in flight (the refetch trigger itself is already automated — see AC5 above).
- [ ] M-002: Full router flow — from `/login`, tap "Continue without signing in", confirm `/businesses` and `/businesses/:slug` are reachable without a session (ADR-003 public carve-out) and every other route still redirects to `/login`.
- [ ] M-003: `image_picker` device permission prompts (camera/gallery) on a real Android device — AC9's OS picker integration; `AndroidManifest.xml` permissions reviewed and present (`CAMERA`, `READ_MEDIA_IMAGES`), not exercised against real OS dialogs this session.

Not executed this pass — no Android SDK/emulator available in this environment (accepted,
documented constraint, not a defect). Flagged for PM/Builder to run before final acceptance.

---

## Environment

- `AI_PROVIDER=mock` — n/a, no AI-provider code touched; `ai_analysis` is read-only pass-through data already present on `ReviewResponse`.
- `docker compose up --build` — not run this session (no isolated environment for a live backend + emulator here).
- `flutter analyze` / `flutter test` — run locally, both clean (see test report).
