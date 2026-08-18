# TP-S-061: Mobile admin ops parity (Tier 4: M-62 platform charts, M-63 categories, M-64 user suspend)

## Scope

Verify the 11 numbered AC on `docs/agents/slices/S-061-mobile-admin-ops-parity.md`:

- **M-62** platform time-series charts on `admin_home_screen.dart` (AC1-4: data/placement/empty
  state/no-AI-framing)
- **M-63** category create/list on the new `/admin/categories` sub-route, plus the S-041-parity
  chip-tap-to-search wiring on both that new screen and the existing
  `business_detail_screen.dart` (AC5-7)
- **M-64** user suspend/reactivate on the new `/admin/users` sub-route, including the "hide, don't
  surface-then-refuse" self/admin control-hiding rule (AC8-9)
- **Regression check** that suspended-account login rejection is unmodified (AC10)
- **RBAC** — the new `/admin/categories` and `/admin/users` sub-routes inherit the existing
  `/admin` route's role gate for anonymous/customer/merchant (AC11)

## Approach

- `flutter_test` widget tests only — no backend/API contract changed per the Architect's spec
  (confirmed again by reading `admin_repository.dart`, `dashboard_repository.dart`,
  `business_repository.dart`: every new method is a thin wrapper over an already-generated,
  already-Accepted `merchanthub_api` Dio client call), so no backend `pytest` coverage is needed
  for this slice.
- Riverpod `ProviderContainer` + `overrides` for `authControllerProvider`,
  `dashboardRepositoryProvider`, `businessRepositoryProvider`, `reviewRepositoryProvider`, and the
  new `adminRepositoryProvider`, following the existing pattern in `admin_home_screen_test.dart`,
  `business_list_screen_test.dart`, `business_detail_screen_test.dart`.
- `GoRouter`-wrapped `MaterialApp.router` pumps for every navigation assertion (chip tap →
  `/businesses?category=`, "Manage categories"/"Total users" tile → sub-routes, AC11's role
  redirect), matching `business_detail_screen_test.dart`'s and `app_shell_test.dart`'s router
  patterns. AC11 specifically is exercised against the **full app `routerProvider`**, not an
  isolated stub router, mirroring `app_shell_test.dart`'s own role-gating coverage shape.
- The chart component (`PlatformSeriesChart`) is tested standalone (constructing
  `PlatformAnalyticsSeries` fixtures directly) as well as through `AdminHomeScreen`'s full load, to
  isolate AC1/AC3/AC4 (chart-only concerns) from AC2 (screen-placement concern).
- `AI_PROVIDER=mock` is N/A — this slice introduces no new AI-facing surface (AC4 explicitly rules
  it out for the charts; categories/user-suspend are pure CRUD/moderation, same as their web
  counterparts in S-034).

## Planned cases

| AC# | Case | Type |
|-----|------|------|
| 1 | The chart row renders one chart per series (new users, businesses approved, new reviews, new reports) with operational-facts labels | A |
| 2 | The chart row sits below the `_AdminStat` tile row and above "Pending businesses" — never above/instead of the tiles | A |
| 3 | An all-zero (or entirely bucket-less) series renders the dashed/bordered empty-chart treatment, not a blank `fl_chart` widget or a crash | A |
| 4 | No chart or surrounding copy contains "AI", "suggestion", or "insight" framing | A |
| 5 | Submitting a name on `/admin/categories` creates the category and it appears in the list without leaving the screen | A |
| 5 | A category-create failure surfaces inline without losing the typed name | A |
| 6 | Tapping a category chip on `/admin/categories` navigates to `/businesses?category={slug}` | A |
| 6 | Tapping a category chip on `business_detail_screen.dart` navigates to `/businesses?category={slug}` | A |
| 6 | `/businesses` reached with an incoming `?category=` seeds `SearchQuery.category` on first frame; no incoming param leaves search unfiltered | A |
| 7 | `/admin/categories` with zero categories shows "No categories yet" with the add-category form still usable, not a blank list or error | A |
| 8 | Suspend sets `is_active=false` via `AdminRepository.suspendUser`; Reactivate sets it back to `true` via `reactivateUser` | A |
| 8 | An empty/short user list shows a plain empty state, not an error | A |
| 9 | Suspend/Reactivate controls are hidden entirely (not merely disabled) for `role=admin` rows and for the signed-in admin's own row | A |
| 10 | Regression check: suspended-account login rejection is unmodified by this slice | M (code inspection — see report) |
| 11 | A signed-in customer/merchant cannot reach `/admin/categories` or `/admin/users` (redirected by the existing `/admin` gate); an anonymous visitor is redirected to `/login`; an admin can reach both | A |
| — | "Manage categories" button and the "Total users" stat tile navigate to the two new sub-routes | A (supporting coverage, not independently numbered) |

## Non-AC notes for the record

- AC10 is explicitly framed by the PM as "regression check, no new mobile work expected" — the
  slice's diff does not touch `login_screen.dart`, `auth_provider.dart`, or any other
  login/session-error-surfacing code (confirmed by `git diff`/`git status` showing zero changes
  under `mobile/lib/features/auth/`), so this AC is verified by code inspection rather than a new
  automated test, consistent with the AC's own "not to introduce new client logic" framing.
- Backend: no new/changed backend contract (Architect's own "confirmed by direct inspection"
  conclusion, re-confirmed here) — no `pytest` coverage added for this slice.
