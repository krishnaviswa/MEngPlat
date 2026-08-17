# TR-S-057: Mobile dark mode (parity for M-75)

## Summary

**Pass** (updated 2026-08-18 after re-verification). The Builder's 2026-08-18 changelog entry
fixes the sole blocker from the first pass: `FallbackPhotoStrip`'s broken-image placeholder
tile in `mobile/lib/features/businesses/photo_gallery.dart` now uses
`colorScheme.surfaceContainerHighest`/`onSurfaceVariant`, matching the already-correct
`PhotoGallery` sibling fix. Independent re-verification (see "Re-verification" section below)
confirms the fix is correct and complete, no new hardcoded-color regressions were introduced,
`flutter analyze` is clean, and `flutter test` is 154/154 passing. Recommend **Ship**.

Original first-pass finding (superseded, kept for history): **Fail — one concrete AC 6
blocker found by independent grep** (`FallbackPhotoStrip`'s broken-image placeholder tile in
`mobile/lib/features/businesses/photo_gallery.dart` was left hardcoded, contradicting the
Builder's changelog claim of fixing "the two broken-image placeholder tiles" — only one of the
two tiles in that file was actually fixed). Everything else checked out: `flutter analyze`
clean, `flutter test` 154/154 passing (149 pre-existing + 5 new, zero regressions), all other
hardcoded-color sweep items verified correct or legitimately justified, theme
infra/toggle/persistence/live-OS-tracking code matches the Architect's spec and is now covered
by automated widget tests that did not exist before this report. Recommend **Rework** (one
bug, narrow fix) rather than Ship.

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Cold start with OS dark, no stored choice → no flash of light theme | M (code inspection; not widget-testable) | Manual checklist M1; `mobile/lib/main.dart` reads persisted preference via `ThemePreferenceStorage().read()` **before** `runApp()`, so Flutter's first painted frame already carries the correct `themeMode`. No repaint-after-launch code path exists. | **Pass** (by code inspection — see Assessment below for why this can't be a widget test, and the honestly-documented native-splash caveat) |
| 2 | Cold start with OS light / no OS pref, no stored choice → light default | A | `mobile/test/theme_toggle_button_test.dart::AC2: with no explicit choice stored and the OS reporting light, the app renders light` | **Pass** |
| 3 | Explicit, discoverable theme control present for signed-in and guest users | A + code inspection | `mobile/test/theme_toggle_button_test.dart::AC3: the theme toggle is visible and discoverable in the app bar`; placement confirmed by reading `account_screen.dart` (line 20, `ThemeToggleButton()` in `AppBar.actions`) and `business_list_screen.dart` (line 66, same, guest-reachable per `router.dart`'s `isPublicBusinessRoute`) | **Pass** |
| 4 | Explicit choice persists across relaunch/background/new session, overrides OS pref | A (write path) + M (read-on-relaunch) | `mobile/test/theme_toggle_button_test.dart::AC4/AC8...` and `::AC4: selecting Light then System round-trips...` assert `ThemeModeController.setThemeMode` writes through to `ThemePreferenceStorage`; the read-on-next-launch half is verified only by code inspection of `main.dart` (no test harness in this repo exercises a real process restart with real `shared_preferences`) | **Pass** (write path automated; read-on-relaunch verified by code inspection only — see Assessment) |
| 5 | Live OS theme change while foregrounded (no explicit choice) is followed | A | `mobile/test/theme_toggle_button_test.dart::AC5: with no explicit choice stored, a live OS theme change while foregrounded is followed` (uses `tester.platformDispatcher.platformBrightnessTestValue`) | **Pass** |
| 6 | Full legibility sweep (all primary screens + sub-screens + empty/error states), WCAG AA-ish | A (grep) + M (visual) | Independent re-grep of `Colors\.\|Color\(0x` across `mobile/lib` (see Assessment); all hits cross-checked against the Architect's Tier-2 list and each Builder judgment call read in context | **Pass** (updated 2026-08-18) — re-verified `FallbackPhotoStrip`'s error-tile placeholder now uses `colorScheme.surfaceContainerHighest`/`onSurfaceVariant`; no `Color(0xFFE0E0E0)` or other unaddressed hardcoded literal remains anywhere in `photo_gallery.dart` or the rest of `mobile/lib`. See "Re-verification" section below. (First-pass result, superseded: **FAIL** — `FallbackPhotoStrip`'s error-tile placeholder, `photo_gallery.dart:112`, still hardcoded `Color(0xFFE0E0E0)`.) |
| 7 | AI disclaimer ("suggestion" language) stays legible in both themes | A (code inspection) | Confirmed `review_card.dart`'s `'AI summary (suggestion): '` label and `ai_insights_panel.dart`'s disclaimer both use `Theme.of(context).textTheme.*`, no hardcoded literal color — no dedicated widget test asserts this under a dark `ThemeData`, but the styling mechanism makes failure structurally unlikely | **Pass** (low-risk gap: no widget test explicitly renders these under dark theme and asserts visibility — noted, not blocking) |
| 8 | Toggle applies app-wide in one interaction, no restart, no screen left stuck | A + code inspection | `mobile/test/theme_toggle_button_test.dart::AC4/AC8: selecting Dark applies the theme app-wide...` proves a single tap+select updates `Theme.of(context)` with no restart; both `AccountScreen`/`BusinessListScreen` toggle instances read/write the *same* `themeModeProvider`, and `MaterialApp.router`'s `themeMode` is the single source every `Theme.of(context)` call resolves from — architecturally, a "stuck" screen isn't possible without a local override, and grep found none | **Pass** |
| 9 | Purely visual slice — no functional/data/navigation change | A (regression evidence) | Full `flutter test` suite: 154/154 passing, including all pre-existing feature suites unrelated to theming (`business_list_screen_test.dart`, `review_form_sheet_test.dart`, `notifications_screen_test.dart`, `favorites_controller_test.dart`, `admin_home_screen_test.dart`, etc.) — zero regressions from the AppBar/theme diff | **Pass** |

## Backend tests added

None — this slice is mobile-only, no backend touched (confirmed, matches "Out of scope" /
API contract "None" in the technical spec).

## Frontend tests added

- `mobile/test/theme_toggle_button_test.dart` (new — did not exist before this report):
  - `AC3: the theme toggle is visible and discoverable in the app bar`
  - `AC4/AC8: selecting Dark applies the theme app-wide and persists the explicit choice`
  - `AC4: selecting Light then System round-trips and persists each explicit/implicit choice`
  - `AC2: with no explicit choice stored and the OS reporting light, the app renders light`
  - `AC5: with no explicit choice stored, a live OS theme change while foregrounded is followed`

  Uses a fake `ThemePreferenceStorage` override (mirrors `favorite_toggle_button_test.dart`'s
  fake-repository convention) instead of exercising the real `shared_preferences` platform
  channel, and `tester.platformDispatcher.platformBrightnessTestValue` to simulate OS
  brightness for AC 2/5 — both are standard, supported `flutter_test` mechanisms, so AC 2 and
  AC 5 turned out to be automatable despite the task brief's caution that they might not be.

## Independent verification performed

1. **Re-grepped `Colors\.|Color\(0x` across `mobile/lib` independently** (not trusting the
   Builder's/Architect's list as exhaustive, per the S-057 tech spec's own instruction citing
   the S-045 postmortem). Full hit list cross-checked line-by-line against the changelog's
   claimed fixes/keeps:
   - Confirmed fixed as claimed: `photo_gallery.dart`'s `PhotoGallery` class error tile (→
     `colorScheme.surfaceContainerHighest`/`onSurfaceVariant`), `profile_screen.dart` (4×),
     `login_screen.dart`, `register_screen.dart`, `forgot_password_screen.dart` (all →
     `colorScheme.onSurfaceVariant`).
   - **Found unfixed, contradicting the changelog:** `photo_gallery.dart` line 112, inside the
     *separate* `FallbackPhotoStrip` widget (a second, distinct class in the same file, live and
     used from `business_detail_screen.dart` lines 359/373 for businesses without a full photo
     gallery) — still `ColoredBox(color: Color(0xFFE0E0E0), child: Icon(Icons.broken_image))`.
     The Builder's changelog says "fixed `photo_gallery.dart`'s two broken-image placeholder
     tiles," but there are two *classes* each with their own placeholder tile in that file —
     only `PhotoGallery`'s was fixed; `FallbackPhotoStrip`'s was missed. This is the exact AC 6
     failure mode the Architect explicitly flagged for this file ("a stray light-mode card on a
     dark screen"): a light-grey tile will render on a dark `Scaffold` background whenever an
     image fails to load in the fallback strip.
   - Confirmed legitimate keep-as-is (per Architect precedent, verified not just trusted):
     `Colors.amber` star ratings (`business_card.dart`, `business_detail_screen.dart`,
     `rating_stars.dart`), `Colors.red` favorite heart / map pin, `Colors.blue` unread dot,
     `review_card.dart`'s sentiment colors (used at full opacity as *text* over a `withValues
     (alpha: 0.15)` tinted chip background of the same hue — the tint stays close to the dark
     surface color while the full-strength text color provides contrast, consistent with the
     web `Badge.tsx` precedent; not screenshot-verified for exact contrast ratio, flagged as a
     visual/manual item below), `review_form_sheet.dart`'s white spinner (renders on
     `FilledButton`'s `colorScheme.primary` background, whose `onPrimary` foreground is
     near-white in both M3 light and dark schemes from the same indigo seed — legible in both),
     `photo_gallery.dart`'s full-screen lightbox black background / white icon (intentionally
     theme-independent full-bleed media viewer, same call as S-045's `Footer.tsx`).

2. **Read `osm_map_view.dart` in full** to independently assess the Builder's deviation from
   the Architect's "must swap `Colors.black87`" instruction. The `'© OpenStreetMap'` attribution
   `Text` is a `Positioned` child of a `Stack` whose *first* child is the `FlutterMap` itself,
   and that `Stack` is wrapped in a `SizedBox`/`SizedBox.expand` sized exactly to the map's
   `height` — i.e., the label's bounding box is geometrically constrained to sit only within the
   map widget's own area, never spilling onto the surrounding `Scaffold`. `flutter_map`'s
   `TileLayer` renders OSM raster tiles (always light-colored imagery, or its own light-grey
   "tiles loading" background before tiles arrive) as the base of that same `Stack`, so the
   label's backdrop is always the map surface, never the app's dark Scaffold. **The Builder's
   deviation is verified correct** — this is a legitimate, code-grounded exception, not an
   unverified assumption.

3. **Read the three new theme files in full** (`theme_provider.dart`,
   `theme_preference_storage.dart`, `theme_toggle_button.dart`) plus the `main.dart`/`app.dart`
   wiring — all match the Architect's spec: `Notifier<ThemeMode>` seeded via constructor
   override before `runApp()`, `shared_preferences`-backed storage wrapper mirroring
   `TokenStorage`'s shape, `PopupMenuButton<ThemeMode>` with `Key('themeToggle')` and
   `System`/`Light`/`Dark` options keyed `themeOptionSystem`/`themeOptionLight`/
   `themeOptionDark`, wired into both `AccountScreen` and `BusinessListScreen` app bars per the
   Architect's guest-reachability resolution.

4. **Ran `flutter analyze` and `flutter test` directly** (not trusted from the changelog):
   - `flutter analyze` → `No issues found!` (both before and after adding the new test file).
   - `flutter test` baseline (before this report's new test file existed) → **149/149 passing**,
     matching the changelog's claim exactly. After adding `theme_toggle_button_test.dart` (5 new
     tests), the full suite is **154/154 passing**, zero regressions.

## Re-verification (2026-08-18)

Performed after the Builder's 2026-08-18 changelog entry claiming the `FallbackPhotoStrip` fix
landed. Independent, not trusting the changelog claim:

1. **Re-read `mobile/lib/features/businesses/photo_gallery.dart` in full.** Confirmed
   `FallbackPhotoStrip`'s `errorBuilder` (now around line 109–114) reads:
   `ColoredBox(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: Icon(Icons
   .broken_image, color: Theme.of(context).colorScheme.onSurfaceVariant))` — identical pattern
   to the already-correct `PhotoGallery` class's fix a few lines above (lines 53–56). No
   remaining `Color(0xFFE0E0E0)` in the file. The only other literal `Color`/`Colors.*` usages
   left in this file are the full-screen lightbox's `Colors.black` background and
   `Colors.white` icon/close-button (lines 137, 148, 157) — previously verified as a legitimate,
   theme-independent full-bleed media-viewer exception (same call as S-045's `Footer.tsx`), not
   re-litigated here since nothing about that reasoning changed.
2. **Re-ran `Colors\.|Color\(0x` grep across `mobile/lib`.** Full hit list (17 matches across 9
   files) is identical in substance to the first pass's "confirmed legitimate keep-as-is" list
   plus the now-fixed `photo_gallery.dart` placeholder tiles — no new hardcoded literal
   appeared anywhere in `mobile/lib`, and no `Color(0xFFE0E0E0)` (or any other stray hex/dark-hostile
   literal) remains. Nothing to flag beyond what the first-pass report already dispositioned.
3. **Ran `flutter analyze` from `mobile/`:** `No issues found!`.
4. **Ran `flutter test` from `mobile/`:** **154/154 passing**, including
   `theme_toggle_button_test.dart`'s 5 AC2/AC3/AC4/AC5/AC8 tests from the first pass. Zero
   regressions, zero failures, zero skips.

**Result:** the AC 6 blocker is closed. No new gaps found. All other findings from the first
pass (the `osm_map_view.dart` deviation, the AC 7 dark-theme widget-test gap, the AC 4
relaunch-read code-inspection-only gap) are unchanged and remain non-blocking, as originally
assessed — not re-litigated in this pass since the Builder's changelog states no other change
was made and independent re-grep confirms nothing else shifted.

## Manual checklist

- [ ] **M1 (AC 1):** Cold-start the app on a physical device or emulator with the OS set to
      dark mode and no prior app data (fresh install), and visually confirm no flash of a light
      theme before the first Flutter frame — expected: any visible flash is limited to the
      unthemed native OS launch/splash screen (documented, non-blocking follow-up per the
      Architect's spec), not a light-themed *Flutter* frame.
- [ ] **M2 (AC 6):** Full manual sweep in dark mode across every primary shell screen and its
      sub-screens (Explore/list, business detail incl. reviews/AI insights, Favorites,
      Notifications, Account/Profile, Merchant home, Admin home, login) plus empty/error states
      (empty Favorites, empty Notifications, no-reviews-yet, and a broken/missing-photo state in
      `FallbackPhotoStrip`, now code-fixed as of 2026-08-18) to catch anything a grep-based
      sweep can't (e.g. subtle contrast issues, not just outright-invisible text). Still open —
      requires a device/emulator, not exercised by this re-verification pass (code-level fix
      confirmed instead; see Re-verification section).
- [ ] **M3 (AC 6):** Visually spot-check `review_card.dart`'s sentiment badge (`Colors.green`/
      `Colors.red`/`Colors.grey` text over a 15%-alpha tinted chip) against the dark
      `ColorScheme` surface for actual contrast, not just the code-review reasoning in this
      report.
- [ ] **M4:** Confirm the `FallbackPhotoStrip` fix (landed 2026-08-18) actually resolves the
      visible artifact on a real broken image (e.g. business detail screen for a business with
      only a broken storefront/logo URL and no gallery) — code-level fix confirmed correct in
      this re-verification pass; on-device visual confirmation still outstanding, folded into M2
      above.

## Regressions / gaps

1. **AC 6 gap — RESOLVED 2026-08-18.** (Original finding, kept for history:)
   `mobile/lib/features/businesses/photo_gallery.dart` line 112 — `FallbackPhotoStrip`'s
   `errorBuilder` still hardcoded `Color(0xFFE0E0E0)` for its broken-image placeholder tile.
   This was a live, reachable code path (`business_detail_screen.dart` lines 359/373, for
   businesses without a populated photo gallery) and reproduced exactly the failure mode the
   Architect called out for this file: a light-grey tile stranded on a dark `Scaffold`. The
   Builder's 2026-08-18 fix swaps it to `Theme.of(context).colorScheme
   .surfaceContainerHighest` / `.onSurfaceVariant`, matching the already-correct `PhotoGallery`
   fix a few lines above — confirmed correct and complete by independent re-read and re-grep in
   this pass (see Re-verification section). No longer blocking.
2. **Minor, non-blocking:** no widget test explicitly renders `review_card.dart`'s AI-summary
   disclaimer or `ai_insights_panel.dart` under a dark `ThemeData` and asserts the text is
   present/visible (AC 7). Verified safe by code inspection (theme-role-driven styling, no
   hardcoded color), but there's no regression guard if that changes later. Not blocking this
   slice; worth a follow-up test if `ai_insights_panel.dart`/`review_card.dart` are touched
   again.
3. **Minor, non-blocking:** AC 4's "read persisted preference on relaunch" half is verified by
   code inspection only, not an executable test — this repo's widget-test harness can't easily
   simulate a full process restart against real `shared_preferences` (the write half is
   covered; a true integration/round-trip test would need `SharedPreferences.setMockInitialValues`
   plus a second `pumpWidget` cycle reading from it fresh — reasonably addable as a fast follow
   if desired, not required to unblock this slice given the write-path coverage and the
   straightforwardness of the `main.dart` read-before-`runApp()` code).
4. No regressions found in the pre-existing 149-test suite; `flutter analyze` clean throughout.
   Re-confirmed 2026-08-18: still zero regressions across the full 154-test suite after the
   `FallbackPhotoStrip` fix; `flutter analyze` still clean.

## Recommendation

**Ship** (updated 2026-08-18). The sole blocker — `FallbackPhotoStrip`'s hardcoded
`Color(0xFFE0E0E0)` placeholder tile in `mobile/lib/features/businesses/photo_gallery.dart` —
is fixed and independently re-verified as correct and complete (code re-read, `Colors\.|Color
\(0x` re-grepped across `mobile/lib`, `flutter analyze` clean, `flutter test` 154/154 passing).
Everything else — theme infra, persistence, live OS tracking, toggle placement/discovery, the
`osm_map_view.dart` deviation, and the AI disclaimer — remains verified correct with automated
regression coverage. Remaining items are non-blocking: the manual checklist (M1–M4, primarily
on-device visual spot-checks including the fixed `FallbackPhotoStrip` state) and the two minor
gaps noted above (AC 7 dark-theme widget-test coverage, AC 4 relaunch-read verified by code
inspection only) are follow-ups, not blockers.

PM may now proceed to mark `README.md` §12 row M-75 `implemented` and set this slice's
`Status: Accepted`, per the "Pass → notify PM to set slice Status: Accepted" handoff protocol.

Original first-pass recommendation (superseded, kept for history): **Rework** — one blocker:
fix `FallbackPhotoStrip`'s hardcoded `Color(0xFFE0E0E0)` placeholder tile in
`mobile/lib/features/businesses/photo_gallery.dart` (line 112) to use theme-aware `ColorScheme`
roles, matching the already-correct sibling fix a few lines above in the same file. Do not mark
`README.md` §12 row M-75 `implemented` until this gap is closed — flagging for PM per the
"Fail → file gaps, assign rework to Builder" handoff protocol.
