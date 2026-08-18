# TP-S-060: Mobile merchant dashboard analytics (parity for M-61)

## Scope

Verify the 8 numbered AC on `docs/agents/slices/S-060-mobile-dashboard-analytics.md` against the
Builder's implementation: `DashboardRepository.merchantStats`/`reviewsCsv` (`range` forwarding +
new CSV fetch), `ReviewVolumeChart` (new), `RatingDistributionChart` (new), and the
`merchant_dashboard_screen.dart` additions (date-range selector, reply-rate tile, CSV export
button). No backend change in scope (Architect confirmed no gap) — this is a mobile-client-only
slice; no new backend tests.

## Test approach

- **Widget tests (`flutter_test`)** in `mobile/test/merchant_dashboard_screen_test.dart`, extending
  the existing fake-repository pattern established there (S-031/S-059). A new
  `_RecordingDashboardRepository` records every `range` argument passed to `merchantStats`/
  `reviewsCsv` and can return per-range `DashboardStats`, proving the screen performs a live
  refetch on range change (AC 3) rather than a client-side filter.
- **CSV export / share-sheet:** `share_plus`'s own documented testing seam
  (`SharePlatform.instance` setter, `@visibleForTesting`-adjacent by design) is used to fake the
  platform layer and assert the exact `ShareParams` (files, mime type, file-name override) the
  screen hands to it — no real device/platform channel needed.
- **AI disclaimer (AC 4):** confirmed by direct code read of `ai_insights_panel.dart` (already
  covered by an existing S-031 test, `aiInsightsDisclaimer`) — no new test needed since no code
  changed for this AC per the Architect's explicit confirmation.
- **RBAC (AC 7):** no new client-side surface introduced; verified by code inspection of
  `router.dart`'s existing `/merchant` route gate (unchanged) plus confirming the new range
  selector/CSV button live inside the same already-gated screen tree, not a new route.
- No real LLM/API calls — `AiInsightsPanel` fixture data is fully static/mocked, matching repo
  convention (`AI_PROVIDER=mock` equivalent for mobile fakes).

## Planned cases

| # | Case | AC |
|---|------|----|
| 1 | Selecting a date-range segment triggers a live `merchantStats` refetch with the new `range`, and reply-rate reflects the newly-fetched value | 3, 5 |
| 2 | Volume chart shows empty-state copy (`reviewVolumeChartEmpty`) when `review_volume_by_month` is empty/all-zero | 1, 8 |
| 3 | Volume chart renders `BarChart` bars when volume data is present | 1 |
| 4 | Rating-mix chart shows empty-state copy (`ratingDistributionChartEmpty`) when `rating_distribution` totals zero | 2, 8 |
| 5 | Rating-mix chart renders `BarChart` bars when rating data is present | 2 |
| 6 | Reply-rate tile shows "No reviews in this range" (never `0%`) when `reply_rate` is `null` | 5, 8 |
| 7 | Reply-rate tile renders a percentage when `reply_rate` is present | 5 |
| 8 | Export CSV button calls `reviewsCsv` with the current business id + range, and hands the result to `SharePlus.instance.share` with the correct mime type and file name | 6 |
| 9 | Export CSV button shows a busy state ("Exporting...") while the request is in flight, then resets | 6 |
| 10 | CSV export failure surfaces through the existing `_error` text, not a silent/empty file | 6 |
| 11 (code inspection, not a new test) | AI disclaimer still renders unconditionally on `AiInsightsPanel`; range selector/CSV controls only reachable inside the existing merchant-only `/merchant` route gate | 4, 7 |

## Out of scope for this test pass

- New backend tests (no backend change).
- `docker compose` / on-device manual smoke test (no device/emulator in this environment; not
  required since no new native platform-channel behavior is introduced beyond what `share_plus`
  already ships and is exercised via its own test seam).
