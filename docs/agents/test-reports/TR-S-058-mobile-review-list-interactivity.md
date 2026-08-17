# TR-S-058: Mobile review-list interactivity (parity for M-72)

## Summary

**Pass** — all 8 numbered AC are met by the implementation and are now covered by an automated
test (widget/unit-level `flutter_test`), verified independently against the actual diff (not
just the Builder's changelog claim). `flutter analyze`: clean, 0 issues. `flutter test`: **167/167
passing** (154 pre-existing + 13 new, 0 regressions). The Builder's own changelog flagged that no
widget-test coverage existed yet for AC 1-6 at hand-off — that gap is now closed for this report;
see "Backend/Frontend tests added" below for what was added and why.

One non-blocking gap found independently (not previously flagged): `README.md` §12's M-72 parity
row is still `unimplemented` and §14/§16 are not yet updated — required by the slice's own PM
Definition of Done before `Status: Accepted`. Flagged in Regressions/gaps.

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Sort control (Newest/Oldest/Highest/Lowest), in-memory re-sort, no refetch, no navigation | A | `mobile/test/business_detail_screen_test.dart::S-058 AC1/AC2/AC3 > AC1: default order is newest first; selecting Oldest re-orders with no refetch` | Pass |
| 2 | Min-rating filter, combinable with sort | A | `mobile/test/business_detail_screen_test.dart::S-058 AC1/AC2/AC3 > AC2: a min-rating filter combined with sort narrows and re-orders the list` | Pass |
| 3 | Distinct empty state when sort/filter yields zero results, "Clear filters" resets only `minRating`, visually/textually distinct from the zero-reviews empty state | A | `mobile/test/business_detail_screen_test.dart::S-058 AC1/AC2/AC3 > AC3: a filter matching zero reviews shows a distinct empty state with Clear filters` | Pass |
| 4 | Review body truncated (`maxLines: 3` + ellipsis) past 280 chars, "Read more"/"Read less" toggle | A | `mobile/test/review_card_test.dart::S-058 AC4 > a long body renders clamped to 3 lines with a Read more toggle`, `tapping Read more expands the body and flips the label to Read less`, `a short body renders with no Read more toggle` | Pass |
| 5 | Tapping a review photo thumbnail opens a full-screen lightbox (reused from `PhotoGallery`) | A | `mobile/test/review_card_test.dart::S-058 AC5 > tapping a review photo thumbnail opens photoLightbox`, `no photo strip is rendered when a review has no photos` | Pass |
| 6 | Readonly multi-star display renders a half-star glyph for fractional averages (business detail header + `BusinessCard`) | A | `mobile/test/rating_stars_test.dart` (4 cases: 4.3→4 full+1 half, 3.7→3 full+1 half+1 empty, whole number→no half, interactive branch unaffected) + code inspection of `business_detail_screen.dart`/`business_card.dart` call sites | Pass |
| 7 | Interactive whole-star submission picker (`ReviewFormSheet`) unchanged — whole-star only, `onChanged` | A | Pre-existing `mobile/test/review_form_sheet_test.dart` (uses `ratingStar4`/`ratingStar5`/`ratingStar3`/`ratingStar5` taps against the widened-to-`num` `RatingStars`) — re-ran and confirmed still passing unmodified; `mobile/test/rating_stars_test.dart::AC7` adds a direct regression check that the interactive branch never renders `Icons.star_half` regardless of a fractional `rating` value | Pass |
| 8 | No new hardcoded `Colors.*`/`Color(0x...)` in any new/changed element; renders correctly in light/dark via `ColorScheme` | A (mechanical) | `grep -rn "Colors\.\|Color(0x" mobile/lib` cross-referenced against `git diff` on the working tree (uncommitted S-058 changes) — see notes below | Pass |

**AC 8 verification detail (grepped independently, not trusted from the slice's own table):**
Ran `grep -rn "Colors\.\|Color(0x" mobile/lib` and cross-referenced every hit against
`git diff e46b20f -- <changed files>` (the pre-slice HEAD) to find exactly which `Colors.*` lines
are *new* in this slice's diff. Only two `+ color: Colors.amber` lines are new (both inside
`rating_stars.dart`'s `_readonly` half-star-icon block and the pre-existing interactive
`IconButton` block) — `Colors.amber` was already present pre-slice on the single old
`Icon(Icons.star / Icons.star_border)` lines it replaces, so this is not a new introduction, it's
the same accepted literal carried into the new branch, consistent with S-057's explicit
"`Colors.amber` star rating usually doesn't need to change" precedent cited in the tech spec. The
new file `review_filter_sheet.dart` has zero `Colors.*`/`Color(0x` hits. The new AC-3 empty-state
`Container` in `business_detail_screen.dart` uses only `Theme.of(context).colorScheme.outline` /
`.surfaceContainerHighest` tokens. `review_card.dart`'s pre-existing `Colors.green/red/grey`
(sentiment badge) and `photo_gallery.dart`'s pre-existing `Colors.black/white` (lightbox scrim) are
untouched by this slice's diff. **Verdict: zero new hardcoded colors, AC 8 satisfied.**

No AC required manual-only (M) verification or code-inspection-only fallback for this slice — all
8 were scriptable in `flutter_test`, including the bottom-sheet sort/filter flow the Architect
flagged as the highest widget-test-effort AC (a full `pumpAndSettle` script worked without
flakiness once the test viewport was widened to avoid the default 800×600 surface truncating the
`SliverList`, see gaps below).

## Backend tests added

None — this is a mobile-only slice, confirmed no backend routes/contracts changed (per the
Architect's own inspection of `backend/app/routers/reviews.py`, independently re-confirmed here by
reading the same file: `GET /business/{business_id}` still takes only `business_id`).

## Frontend/mobile tests added

- `mobile/test/rating_stars_test.dart` (new file, 4 tests) — AC 6/7
- `mobile/test/review_card_test.dart` (extended, +5 tests: 3 for AC 4, 2 for AC 5)
- `mobile/test/business_detail_screen_test.dart` (extended, +4 tests, new `_review()` params
  `rating`/`createdAt`/`body`) — AC 1/2/3

13 new tests added, 0 removed, 0 modified pre-existing test bodies (only the shared `_review()`
helper in `business_detail_screen_test.dart` and `_review()` in `review_card_test.dart` gained new
optional named parameters, backward-compatible with every existing call site).

## Manual checklist

- [x] `flutter analyze` — 0 issues
- [x] `flutter test` — 167/167 passing (independently re-run after adding coverage, not trusting
      the Builder's pre-slice "154/154" claim)
- [x] Read every changed file directly (`rating_stars.dart`, `review_card.dart`,
      `review_filter_sheet.dart`, `business_detail_screen.dart`, `business_card.dart`,
      `photo_gallery.dart`) and confirmed the implementation matches the changelog's description
      line-by-line — no discrepancies found
- [ ] `docker compose up --build` / manual device smoke test of the bottom sheet, lightbox
      pinch-zoom, and dark-mode rendering — **not performed this pass** (no device/emulator
      available in this environment); AC 8's dark/light rendering claim rests on the mechanical
      color-token audit above plus the fact `RatingStars`/`ReviewFilterSheet`/the new empty-state
      container all reuse `Theme.of(context).colorScheme.*` tokens already exercised by S-057's
      own (Accepted) dark-mode pass — reasonable but not a substitute for an on-device visual
      check if one becomes available later

## Regressions / gaps

- **No functional regressions.** All 154 pre-existing mobile tests still pass unmodified.
- **Minor code-quality gap found independently (not blocking, not one of the 8 AC):**
  `ReviewCard`'s new photo thumbnail `Image.network` calls have no `errorBuilder`, unlike
  `PhotoGallery`'s/`FallbackPhotoStrip`'s thumbnails (which do supply one, showing a broken-image
  placeholder icon on load failure). This isn't an AC requirement and doesn't block ship, but is
  an inconsistency worth a follow-up: today a broken review photo URL will surface as an unhandled
  image-load error in production logs/crash reporting rather than a placeholder, whereas the
  business-level gallery handles this gracefully. Recommend a small follow-up fix (add the same
  `errorBuilder` pattern) — not filed as a blocking gap for this slice.
- **README.md §12/§14/§16 not yet updated.** The M-72 row in §12's parity tracker is still
  `unimplemented` (verified via direct grep of `README.md`, not assumed), and §14/§16 don't yet
  reflect the closed mobile gap. This is an explicit item in the slice's own PM "Definition of
  done" checklist and must be completed (by Builder or PM, per `docs/CLAUDE.md`'s ownership note)
  in the same PR before `Status: Accepted` is set.
- **Viewport note for future maintainers:** the AC 1-3 widget tests widen the test surface
  (`tester.binding.setSurfaceSize`) to 500×2000 because the default 800×600 test surface only lays
  out the `SliverList`'s visible items, causing `find.textContaining` to miss off-screen review
  cards. This is a test-environment artifact, not a production bug — flagging so a future Tester
  extending this file doesn't need to re-diagnose it.

## Recommendation

**Ship** (AC-wise). Rework not required for any of the 8 AC. Before PM sets `Status: Accepted`,
the outstanding `README.md` §12/§14/§16 updates (PM's own Definition of Done) still need to land
in the same PR — that's a documentation/process gap, not a functional one, and is the only item
keeping this from being fully done per this slice's own checklist.
