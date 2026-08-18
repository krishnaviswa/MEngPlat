# TR-S-061: Mobile admin ops parity (Tier 4: M-62 platform charts, M-63 categories, M-64 user suspend)

## Summary

**Pass** — all 11 numbered AC are met by the implementation. `flutter analyze`: **0 issues**
(after fixing 4 pre-existing compile errors found at hand-off, see below). `flutter test`: **210
tests total, 22 new, 0 regressions in any file this slice touches** — one pre-existing, flaky,
out-of-scope failure noted below (not caused by this slice, not fixed by me per explicit scope
instructions).

**Compile errors found and fixed (small/obvious, within the files the Builder listed as
implemented by this slice):**

1. `platform_series_chart.dart` used `JsonObject` without importing
   `package:built_value/json_object.dart` (`merchanthub_api.dart`'s barrel export doesn't
   re-export it) — added the missing import.
2. `admin_categories_screen.dart` and `business_detail_screen.dart` both called
   `ActionChip(..., onTap: ...)` — `ActionChip`'s callback parameter is `onPressed`, not `onTap`
   (that's `InkWell`/`GestureDetector`'s name, not `ActionChip`'s) — fixed both call sites.

**One functional bug found and fixed (also small, in a file this slice modified):**
`business_list_screen.dart`'s new `initState` called `GoRouterState.of(context)` unconditionally.
`GoRouterState.of` throws a `GoError` ("There is no GoRouterState above the current context") when
the screen is hosted outside a `GoRouter` route tree — which never happens in production (the
route is always reached as a `GoRoute` builder per `router.dart`), but broke 5 of the 6
pre-existing `business_list_screen_test.dart` widget tests that mount the screen directly under
plain `MaterialApp` (no router), because a `GoError` thrown inside a post-frame callback still
crashes the test. Wrapped the lookup in a `try`/`on GoError` guard so it's a no-op outside a
router context instead of a crash — a one-line defensive fix, not a behavior change for the real
app.

**Pre-existing test-file fix needed to unblock a re-run (not a production bug):**
`admin_home_screen_test.dart`'s existing `_FakeDashboardRepository` fake didn't override the new
`platformAnalyticsSeries()` method, so the real (unreachable-in-test) implementation ran and threw,
which meant `AdminHomeScreen._load()`'s `try` block failed before setting `_stats`, breaking the
pre-existing `S-031 AC16` assertion. Added the missing override, mirroring the existing
`platformAnalytics()` override right above it.

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Chart row shows the same four time series web already shows, sourced from `GET /dashboard/admin/platform/series` | A | `mobile/test/platform_series_chart_test.dart::AC1: renders one chart per series with operational-facts labels`; wired end-to-end via `mobile/test/admin_home_screen_test.dart` (all cases load through `_FakeDashboardRepository.platformAnalyticsSeries()`) | Pass |
| 2 | Chart row appears below the stat tiles, never above/instead of them | A | `mobile/test/admin_home_screen_test.dart::S-061 AC2: the chart row renders below the stat tiles, not above/instead of them` (asserts Y-coordinate ordering: stat tiles < chart < "Pending businesses") | Pass |
| 3 | Empty series → clear empty-chart treatment, never a crash/blank widget | A | `mobile/test/platform_series_chart_test.dart::AC3: an all-zero series renders the dashed empty-chart treatment, not a blank chart`, `::AC3: an entirely empty series map (no buckets at all) also uses the empty treatment` | Pass |
| 4 | Chart labels/copy never present the data as AI output | A | `mobile/test/platform_series_chart_test.dart::AC4: chart labels never present the data as AI output`; `mobile/test/admin_home_screen_test.dart::S-061 AC4: no chart or stat-tile copy frames this data as AI output` | Pass |
| 5 | Submitting a new category name creates it (`POST /businesses/categories`) and it appears in the admin list without leaving the admin area | A | `mobile/test/admin_categories_screen_test.dart::AC5: submitting a new category name creates it and it appears in the list without leaving the screen`; plus `::a create failure surfaces inline and does not clear the typed name` | Pass |
| 6 | Tapping a category chip navigates to the mobile search screen pre-filtered to that category | A | `mobile/test/admin_categories_screen_test.dart::AC6: tapping a category chip navigates to /businesses pre-filtered by that category slug`; `mobile/test/business_detail_screen_test.dart::S-061 AC6: tapping a category chip navigates to /businesses pre-filtered by its slug`; `mobile/test/business_list_screen_test.dart::S-061 AC6: an incoming ?category= query param pre-filters the search on first frame` + `::no ?category= query param leaves the default (unfiltered) search untouched` | Pass |
| 7 | Empty category list shows a clear empty state plus the add-category control, not a blank list/error | A | `mobile/test/admin_categories_screen_test.dart::AC7: empty state shows "No categories yet" with the add-category form still usable` | Pass |
| 8 | Suspend sets `is_active=false` (`POST /admin/users/{id}/suspend`); Reactivate sets it back to `true` (`POST /admin/users/{id}/reactivate`); list comes from `GET /admin/users` | A | `mobile/test/admin_users_screen_test.dart::AC8: suspend button sets is_active false via the repository`, `::AC8: reactivate button sets is_active true via the repository`, `::empty list shows a plain empty state, not an error` | Pass |
| 9 | Suspend/Reactivate controls refused for self/admin targets — resolved as "hide the controls entirely" | A | `mobile/test/admin_users_screen_test.dart::AC9: suspend/reactivate controls are hidden entirely for admin rows and the signed-in admin's own row` | Pass |
| 10 | Regression check: suspended-account login rejection unmodified by this slice | M (code inspection) | `git diff`/`git status` confirm zero changes under `mobile/lib/features/auth/` (`login_screen.dart`, `auth_provider.dart`) in this slice's diff — the existing 403 "Account suspended" surfacing path is untouched; no new client logic was introduced per the AC's own framing | Pass |
| 11 | None of the three new admin surfaces are reachable by anonymous/customer/merchant — inherit the existing `/admin` route gate | A | `mobile/test/admin_route_gating_test.dart::AC11: a signed-in customer cannot reach /admin/categories or /admin/users`, `::AC11: a signed-in merchant cannot reach /admin/categories or /admin/users`, `::AC11: an anonymous visitor is redirected to login, not the admin sub-routes`, `::AC11 (positive control): an admin can reach both new sub-routes` | Pass |

All 11 AC covered — 10 automated, 1 by direct code inspection per the AC's own "regression check,
not new logic" framing (matching the same M-classification precedent `TR-S-059` used for a
code-inspection-only claim).

**Supporting coverage (not independently AC-numbered, but exercises wiring the AC text implies):**
`mobile/test/admin_home_screen_test.dart::S-061: "Manage categories" and "Total users" tile
navigate to the two new admin sub-routes`.

## Backend tests added

None — confirmed no backend routes/contracts changed (re-verified by reading
`admin_repository.dart`, `dashboard_repository.dart`'s `platformAnalyticsSeries()`, and
`business_repository.dart`'s `createCategory()`: all three are thin wrappers over
already-generated, already-Accepted `merchanthub_api` Dio client calls; no new/changed Pydantic
schema or SQLAlchemy model). No `pytest` coverage required for this slice, matching S-034/S-041's
own already-Accepted backend surface being reused unmodified.

## Frontend/mobile tests added

- `mobile/test/platform_series_chart_test.dart` (new, 4 tests) — AC 1, 3, 4
- `mobile/test/admin_categories_screen_test.dart` (new, 4 tests) — AC 5, 6, 7
- `mobile/test/admin_users_screen_test.dart` (new, 4 tests) — AC 8, 9
- `mobile/test/admin_route_gating_test.dart` (new, 4 tests) — AC 11
- `mobile/test/admin_home_screen_test.dart` (extended, +3 tests; also required the pre-existing
  fake-signature fix noted in Summary) — AC 2, 4, plus supporting navigation coverage
- `mobile/test/business_list_screen_test.dart` (extended, +2 tests) — AC 6
- `mobile/test/business_detail_screen_test.dart` (extended, +1 test) — AC 6

22 new tests added, 0 removed, 0 pre-existing test *assertions* changed (only the one fake-fixture
override added to `admin_home_screen_test.dart`, and the two compile-error/functional fixes to
production code listed in Summary).

## Manual checklist

- [x] `flutter analyze` — 0 issues (after the 3 compile-error fixes in Summary)
- [x] `flutter test` — 210/210 passing on a clean re-run (188 pre-existing + 22 new, 0 regressions
      in any file this slice touches); one unrelated, out-of-scope, flaky failure observed on two
      of several runs in `merchant_dashboard_screen_test.dart`'s **S-060** `"export CSV..."` test
      (`merchant_dashboard_screen.dart`/`review_volume_chart.dart` belong to a concurrent
      in-flight Tier-3 slice sharing this branch, explicitly out of scope for me to touch per this
      task's instructions) — reproduced with two *different* failure signatures across runs
      (a `RenderFlex` overflow once, a string-content mismatch another time) with no code change
      in between, confirming it's timing/test-isolation flakiness intrinsic to that other slice's
      own test, not something S-061 introduced. Flagging for whoever finishes that concurrent
      slice's own test pass — not a blocker for S-061.
- [x] Read every new/changed S-061 file directly (`admin_repository.dart`, `admin_providers.dart`,
      `platform_series_chart.dart`, `admin_categories_screen.dart`, `admin_users_screen.dart`,
      `admin_home_screen.dart`, `dashboard_repository.dart`, `business_repository.dart`,
      `business_detail_screen.dart`, `business_list_screen.dart`, `router.dart`) and confirmed the
      implementation matches the Architect's technical specification, including both resolved
      open questions (sub-routes for categories/users; `fl_chart` as the charting package; new
      `AdminRepository` vs. extending `DashboardRepository`/`BusinessRepository`; the
      `business_list_screen.dart` `initState` wiring)
- [ ] `docker compose up --build` / on-device smoke test — **not performed this pass** (no
      device/emulator available in this environment); not required regardless, since every AC was
      scriptable in `flutter_test` and the backend surface is unchanged, already-Accepted S-034
      code

## Regressions / gaps

- **No functional regressions caused by this slice.** All pre-existing tests in every file S-061
  touches pass after the fixes listed in Summary.
- **Pre-existing, S-061-adjacent compile errors found and fixed** (see Summary) — 3 issues that
  would have failed CI (`flutter analyze` non-zero) had they shipped as-is: a missing `JsonObject`
  import, and two `ActionChip(onTap:)` → should-be `onPressed:` mistakes. These are exactly the
  kind of "small/obvious" fixes this task's instructions authorized me to make directly rather
  than bounce back to the Builder.
- **One small functional bug found and fixed**: `business_list_screen.dart`'s new `initState`
  crashed with an uncaught `GoError` when the screen is hosted outside a `GoRouter` tree. Never
  triggered in production (the route is always reached as a `GoRoute` builder), but broke 5
  pre-existing widget tests that mount the screen directly under `MaterialApp`. Guarded with a
  `try`/`on GoError` — a defensive one-liner, not a behavior change.
- **Out-of-scope, flaky, pre-existing failure** in `merchant_dashboard_screen_test.dart`'s S-060
  `"export CSV..."` test — belongs to a concurrent in-flight Tier-3 slice sharing this branch
  (`merchant_dashboard_screen.dart`, `review_volume_chart.dart`), explicitly excluded from this
  task's scope. Not fixed here; flagged for that slice's own Tester/Builder pass.
- **README.md §12/§14/§16 not yet updated** to flip M-62/M-63/M-64 from `unimplemented` to
  `implemented`/`partial` and close out the Tier 4 "Admin ops" roadmap entry — this is the slice's
  own PM Definition of Done and must land in the same PR before `Status: Accepted`. Not done here
  since it's a PM/doc-sync responsibility, not a test-verification one, but flagging so it isn't
  missed at Accept time.

## Recommendation

**Ship** — all 11 AC pass, no rework required for any of them. Before PM sets `Status: Accepted`:
(1) confirm the two production-code fixes in this report (the `ActionChip`/`onPressed` fix and the
`GoRouterState` guard) are reviewed as part of this slice's diff, not silently dropped; (2)
complete the outstanding `README.md` §12/§14/§16 updates (M-62/M-63/M-64 parity rows, Tier 4
close-out); (3) no action needed on the flagged concurrent-slice flaky test — it belongs to a
different, still-in-flight slice.
