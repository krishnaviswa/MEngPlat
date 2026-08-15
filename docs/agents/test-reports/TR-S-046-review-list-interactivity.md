# TR-S-046: Review-list interactivity — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-046 |
| **Author** | Tester |
| **Date** | 2026-08-15 |
| **Recommendation** | Ship |

---

## Summary

All 8 AC verified. Builder's implementation matches the Architect's spec closely (filter-then-sort
`useMemo`, `MIN_RATING_OPTIONS` pills, `line-clamp-3` + 280-char toggle, `PhotoGallery` prop
extension defaulted to no-op for existing call sites, half-star overlay gated behind `readonly`).
This Tester pass added 15 new automated tests across 3 files that previously had zero coverage of
this slice's behavior (`ReviewsList.test.tsx` was net-new; `RatingWidget.test.tsx` and
`ReviewCard.test.tsx` extended). Full suite: **33 suites / 149 tests pass** (134 pre-existing + 15
new, none broken). `npm run build` compiles clean, 17/17 pages.

AC 5 (photo lightbox) and AC 8 (dark mode) are verified by code inspection only — no browser
available in this environment. AC 5's lightbox mechanism (`PhotoGallery`'s existing
`selected`-index state + `bg-black/80` overlay) is unchanged logic, only reused via two new
optional props; no new automated test added for it beyond confirming `ReviewCard.tsx` now calls
`PhotoGallery` instead of a raw `<img>` grid (code-verified) — see Gaps for a note on this.

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Sort control: Newest/Oldest/Highest/Lowest re-orders list, no page reload | A | `ReviewsList.test.tsx` — "defaults to Newest first", "re-orders to Oldest first when sort control changes, with no page reload", "re-orders to Highest rating first" | Pass |
| 2 | Min-rating filter shows only reviews ≥ threshold, combinable with sort | A | `ReviewsList.test.tsx` — "hides reviews below the selected minimum rating", "combines the min-rating filter with the sort control at the same time" | Pass |
| 3 | Distinct "no reviews match these filters" empty state, textually/visually different from "no reviews yet"; Clear-filters affordance | A | `ReviewsList.test.tsx` — "shows a distinct 'no reviews match these filters' empty state...", "'Clear filters' resets minRating and restores the full list" | Pass |
| 4 | Long review body truncates with Read more/Read less toggle | A | `ReviewCard.test.tsx` — "shows no Read more toggle for a review body under the threshold", "shows a Read more toggle for a review body over the threshold, and expands/collapses on click" | Pass |
| 5 | Photo thumbnail click opens a lightbox reusing `PhotoGallery`'s existing pattern | M | M-001: code inspection — `ReviewCard.tsx:111-120` now renders `<PhotoGallery photos={...} gridClassName="flex gap-2" thumbClassName="h-16 w-16" />` (was a raw `<img>` grid); `PhotoGallery.tsx`'s `selected`-index lightbox state/overlay (`:25`, `:38-45`) is unchanged, confirmed no duplicate lightbox logic was added | Pass (code-verified; no jsdom test added for the click-to-open interaction itself — see Gaps) |
| 6 | Fractional average rating renders a half-star glyph in readonly display | A | `RatingWidget.test.tsx` — "renders a half-star overlay on the correct star for an exact .5 value", "rounds a non-.5 value (4.3) to the nearest half-star (4.5) for display", "renders no half-star overlay for a whole-number value" | Pass |
| 7 | Interactive rating picker unchanged — whole-star only, no half-star | A | `RatingWidget.test.tsx` — pre-existing "calls onChange when interactive" / "does not call onChange when readonly" pass unmodified; new "the interactive picker never renders half-star overlay markup, even at a fractional value" confirms by construction | Pass |
| 8 | All new/changed elements use S-045 semantic tokens / `dark:` pairs, no new hardcoded light-only classes | M | M-002: grep of `ReviewsList.tsx`, `PhotoGallery.tsx`, and `ReviewCard.tsx`'s new truncation/gallery markup for `bg-white`/`text-gray-*`/`bg-gray-*` — zero hits in the two new files; the one hit in `ReviewCard.tsx:52` is the pre-existing (S-021) neutral sentiment-badge color, already `dark:`-paired, untouched by this slice | Pass |

**Coverage:** 8 / 8 AC mapped, 8 / 8 Pass

---

## Backend tests

None — frontend-only slice per Architect spec (no API/RBAC/data-model change). Not applicable.

---

## Frontend tests

### Added
- `frontend/src/components/__tests__/ReviewsList.test.tsx` (new, 7 tests): default Newest sort
  order, re-order on Oldest/Highest, min-rating filter hides below-threshold reviews, filter +
  sort combined, distinct zero-results empty state vs. "no reviews yet", Clear-filters reset.
- `frontend/src/components/ui/__tests__/RatingWidget.test.tsx` (extended, +5 tests): half-star
  overlay at exact `.5`, rounding `4.3` → `4.5` half-star, no overlay at whole-number value,
  readonly stars stay disabled buttons (5 total, preserving the existing structural assumption),
  interactive picker never renders half-star markup. Existing 3 tests ("renders five stars",
  "calls onChange when interactive", "does not call onChange when readonly") pass unmodified.
- `frontend/src/components/__tests__/ReviewCard.test.tsx` (extended, +3 tests): no toggle under
  280 chars, toggle appears + expands/collapses over 280 chars, "Quick take" AI-disclaimer block
  stays after the toggle in DOM order (`compareDocumentPosition`), confirming the truncation
  layout change doesn't sandwich or reorder the disclaimer. Existing tests in this file (business
  link gating, AI sentiment badge/summary, reply drafting) pass unmodified.

### Run output
```
cd frontend && npx jest --ci src/components/__tests__/ReviewsList.test.tsx src/components/ui/__tests__/RatingWidget.test.tsx src/components/__tests__/ReviewCard.test.tsx
PASS x3 — 30 passed, 30 total

cd frontend && npm test -- --ci
Test Suites: 33 passed, 33 total
Tests:       149 passed, 149 total
```
(134 pre-existing + 15 new this pass; unrelated pre-existing `act(...)` console warning in
`ReviewCard.test.tsx`'s reply-drafting async test predates this slice, not introduced by it, not
a failure.)

### Build
```
cd frontend && npm run build
✓ Compiled successfully, 17/17 pages generated, no type errors
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | AC 5 — `ReviewCard.tsx` wires `PhotoGallery` (not a raw `<img>` grid) with `gridClassName="flex gap-2"` / `thumbClassName="h-16 w-16"`; `PhotoGallery`'s lightbox state/overlay logic is unchanged, no duplicate lightbox added | Pass (code-verified, no browser available) |
| M-002 | AC 8 — grep `ReviewsList.tsx` / `PhotoGallery.tsx` / new `ReviewCard.tsx` markup for `bg-white`/`text-gray-*`/`bg-gray-*`; zero new unpaired hits | Pass |
| M-003 | AI disclaimer placement risk (Architect-flagged) — `ReviewCard.tsx:106-110` "Quick take" block renders after the Read more/less toggle (`:97-105`) in JSX/DOM order, not sandwiched between body and toggle | Pass |
| M-004 | RBAC — sort/filter/truncate/lightbox/half-star are uniform across roles per Architect spec (no gated action); spot-checked `ReviewsList`/`ReviewCard` render paths for customer/merchant/admin call sites — no role branching touches this slice's new code | Pass (no RBAC surface introduced; not applicable per Architect spec) |
| M-005 | `docker compose up --build` / live browser smoke test (real lightbox click-to-open, live theme toggle on the new elements) | Not executed — no Docker/browser in this environment |

---

## Gaps / rework items

1. **AC 5 has code-inspection coverage only, no automated jsdom test for the click-to-open
   lightbox interaction on `ReviewCard`.** `PhotoGallery`'s own existing lightbox logic is
   unchanged (not this slice's risk surface), and the wiring change (raw `<img>` grid → `
   PhotoGallery` call) is confirmed by reading the diff, but no new test asserts that clicking a
   thumbnail inside a `ReviewCard` opens the overlay. Low risk — `PhotoGallery` itself is a
   generic, already-used component — but flagging so PM/Builder can add one if desired. Not a
   Ship blocker.
2. **`README.md` §12 Web ↔ mobile parity tracker has no row yet for this slice** (grepped, zero
   `S-046`/"review-list" hits in `README.md`). This is a PM Definition-of-done item, not a test
   failure — flagging so it isn't missed before `Status: Accepted`.
3. **Not a bug, a heuristic to watch:** the 280-char truncation threshold is untested against
   real review-body length distribution (per Architect's own flagged risk) — my tests use
   synthetic bodies well above/below the threshold, not a boundary-value assertion at exactly 280
   vs. 281 chars. If Builder wants that precision, a boundary test is a one-line addition.

None of the above are AC failures — all 8 AC pass. No RBAC issue (uniform, display-only feature,
confirmed by Architect spec and code inspection). No AI disclaimer regression.

---

## Regressions

None. Full pre-existing Jest suite (134 tests) still passes unchanged; `npm run build` unaffected.

---

## Sign-off

- [x] All AC mapped to tests (8 / 8 Pass)
- [x] RBAC not applicable — uniform display/interaction feature across roles, confirmed by
      Architect spec and code inspection (no gated action introduced)
- [x] AI disclaimer verified — "Quick take" block placement confirmed unchanged/legible relative
      to the new truncation toggle (AC 4 risk called out by Architect), no new AI surface
      introduced
- [x] Ready for PM acceptance — no AC unmapped, no RBAC gap, no AI disclaimer regression. Two
      non-blocking notes (AC 5 lightbox-click automated coverage, missing §12 parity row) listed
      above for PM/Builder to pick up, neither is a Ship blocker.
