# TR-S-060: Mobile merchant dashboard analytics (parity for M-61)

## Summary

**Pass** — all 8 numbered AC are met, independently verified against the actual diff (not just
the Builder's hand-off description) and now covered by automated `flutter_test` widget tests that
did not exist at hand-off. `flutter analyze`: **0 issues**. `flutter test`: **210/210 passing**
(200 pre-existing + 10 new, 0 regressions).

**One real bug found and fixed during testing (not a test-infrastructure issue):**
`_exportCsv`'s `XFile.fromData(bytes, name: 'reviews-$businessId-$_range.csv', mimeType:
'text/csv')` passed `name:`, but `cross_file`'s `io` implementation of `XFile.fromData`
documents `name` as **ignored on every non-web platform** (`XFile.name` getter derives from
`path`, and no `path` was passed, so it resolves to `''` — confirmed by reading
`cross_file-0.3.5+4/lib/src/types/io.dart` directly, and independently reproduced by my own first
version of the CSV-export test, which failed asserting the file name for exactly this reason).
On a real Android/iOS device this means the shared CSV file would arrive with **no filename or
`.csv` extension**. Fixed by adding `ShareParams.fileNameOverrides: [fileName]` — `share_plus`'s
own documented mechanism for exactly this case (its doc comment names `XFile.fromData` naming as
the reason the parameter exists). This is a one-line fix in `merchant_dashboard_screen.dart`'s
`_exportCsv`, re-verified by the corrected test asserting `fileNameOverrides` rather than
`XFile.name`.

**Test-infra addition:** `share_plus_platform_interface` was added as a direct `dev_dependency` in
`pubspec.yaml` (was already present transitively via `share_plus`) so the CSV-export test can
import it directly to fake `SharePlatform.instance` — this satisfies the analyzer's
`depend_on_referenced_packages` lint, matching `share_plus`'s own documented testing seam (the
`instance` setter exists specifically for platform implementations/tests to substitute).

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Review-volume-over-months series rendered as a visible chart | A | `mobile/test/merchant_dashboard_screen_test.dart::S-060 AC1: review volume chart renders bars when review_volume_by_month has data` | Pass |
| 2 | 1-5 star rating distribution rendered as counts/proportions per bucket | A | `...::S-060 AC2: rating distribution chart renders bars when rating_distribution has data` | Pass |
| 3 | Date-range selector (30/90/all) updates volume, rating mix, reply-rate via a live `range=` refetch, not a client-side filter | A | `...::S-060 AC3/AC5: choosing a date range triggers a live refetch with that range, and reply-rate reflects it` (asserts the fake repo receives `['all', '30']` in order, and that the re-rendered reply-rate tile reflects the second fetch's data) | Pass |
| 4 | AI trend figures carry suggestion/disclaimer language, never a definitive judgment | A (pre-existing, reconfirmed) | `...::S-031 AC1/AC4/AC9: dashboard tiles and suggestion-only insights` already asserts `aiInsightsDisclaimer`/"Suggestions only"; independently reconfirmed by reading `ai_insights_panel.dart` in full — the disclaimer renders unconditionally (not gated on `monthly_trends`/`degraded`), matching the Architect's explicit "no code change needed" conclusion | Pass |
| 5 | Reply-rate equals the `reply_rate` field for the selected range; `null` (zero reviews) renders as clear copy, never `0%` | A | `...::S-060 AC5/AC8: reply rate shows "No reviews in this range" (never 0%) when reply_rate is null`, `...::S-060 AC5: reply rate renders as a percentage when reply_rate is present` | Pass |
| 6 | Optional CSV export of own business's reviews via the existing endpoint, via the device's native share/save mechanism; own-business-only | A | `...::S-060 AC6: export CSV calls the repository with the current business/range and shares the resulting file`, `...::S-060 AC6: export button shows a busy state while the CSV request is in flight`, `...::S-060 AC6: CSV export failure surfaces through the existing _error pattern, not a silent failure`. Own-business-only enforced entirely by the existing, unmodified backend ownership check (confirmed unchanged by reading `backend/app/routers/dashboard.py`) — no new client-side bypass introduced. | Pass (bug found + fixed, see Summary) |
| 7 | Customer / non-owner merchant denied (existing backend RBAC, no new client-side bypass) | M (code inspection) | Confirmed by reading `mobile/lib/router.dart`'s existing `redirect` gate on `/merchant` (unchanged by this slice — grep confirms no diff to that block) and confirming the new range selector/CSV button/charts live entirely inside `MerchantDashboardScreen`'s existing tree, reachable only through that same gate and `ownedBusinessesProvider` (which only lists the signed-in merchant's own businesses, unchanged). No new route, no new server-side check added or needed. | Pass |
| 8 | Empty range → empty chart + beginner-friendly copy, no crash, no fake series | A | `...::S-060 AC1/AC8: review volume chart shows empty-state copy when there is no volume data`, `...::S-060 AC2/AC8: rating distribution chart shows empty-state copy when there are no ratings`, `...::S-060 AC5/AC8: reply rate shows "No reviews in this range"...` | Pass |

No AC required a `docker compose`/on-device manual pass beyond the code-inspection noted for AC 7
— no new native platform-channel behavior is introduced that a widget test + code read can't
cover (the CSV/share path is verified against `share_plus`'s own documented platform-interface
test seam, not a real device).

## Backend tests added

None — confirmed no backend routes/contracts changed (Architect's own inspection, independently
re-confirmed here by reading `backend/app/routers/dashboard.py`): both endpoints (`GET
/dashboard/merchant/{business_id}` with `range`, `GET .../reviews.csv` with `range`) are
unmodified, already-Accepted S-033 contract.

## Frontend/mobile tests added

- `mobile/test/merchant_dashboard_screen_test.dart` (extended, +10 tests) — AC 1, 2, 3, 5, 6, 8;
  added `_RecordingDashboardRepository` (records every `range` passed to
  `merchantStats`/`reviewsCsv`, supports per-range stats) and `_FakeSharePlatform` (fakes
  `share_plus`'s `SharePlatform.instance` seam) as new test fixtures.

## Manual checklist

- [x] `flutter analyze` — 0 issues
- [x] `flutter test` — 210/210 passing (200 pre-existing + 10 new, independently re-run)
- [x] Read every new/changed S-060 file directly (`dashboard_repository.dart`,
      `review_volume_chart.dart`, `rating_distribution_chart.dart`,
      `merchant_dashboard_screen.dart`, `pubspec.yaml`) against the Architect's technical
      specification — one real discrepancy found (CSV file-naming, see Summary), fixed, re-tested
- [x] Verified the CSV `JsonObject`-unwrapping risk the Architect explicitly flagged as
      unverified: confirmed `DashboardRepository.reviewsCsv` defensively checks `value is! String`
      and throws a clear `StateError` if built_value's `JsonObject` pass-through doesn't hold,
      rather than silently miscasting — an acceptable, already-implemented fallback posture per
      the Architect's own risk note; a widget test cannot exercise the real Dio/JsonObject
      behavior against a live backend (documented, not a silent gap — same conclusion the task
      brief pre-reached)
- [x] Confirmed the S-059-era `Row`→`Wrap` change (Edit business / Share review link buttons,
      unrelated to M-61's AC but touching the same screen) does not regress either of S-059's own
      two tests for that row — both still pass unmodified
- [ ] `docker compose up --build` / on-device smoke test — not performed (no device/emulator
      available in this environment); not required for any of the 8 AC per the coverage matrix
      above

## Regressions / gaps

- **No functional regressions.** All 200 pre-existing mobile tests still pass unmodified.
- **Real bug found and fixed** (see Summary): CSV export's shared file would have had no
  filename/extension on real Android/iOS devices. Fixed via `ShareParams.fileNameOverrides` in
  `merchant_dashboard_screen.dart`. Re-tested and passing.
- **README.md §8/§12/§14/§16 not yet updated** — per the slice's own PM Definition of Done, these
  must land in the same PR before `Status: Accepted`: §8 (new `fl_chart` charting-package
  convention), §12 (M-61 row `unimplemented` → `implemented` — no partial-deferral flag needed
  this time, unlike S-059's QR/deep-link carve-out; all 8 AC are met in full with no scoped-out
  capability), §14/§16 (mobile gap closed).

## Recommendation

**Ship** — all 8 AC pass, no rework required. Before PM sets `Status: Accepted`: (1) complete the
outstanding README §8/§12/§14/§16 updates noted above; (2) confirm the `pubspec.yaml` addition of
`share_plus_platform_interface` as a direct `dev_dependency` (test-only, no runtime behavior
change) travels with this PR.
