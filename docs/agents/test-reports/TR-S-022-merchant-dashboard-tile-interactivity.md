# TR-S-022: Merchant dashboard tile interactivity — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-022 |
| **Author** | Tester |
| **Date** | 2026-08-11 |
| **Recommendation** | Ship |

---

## Summary

Pass. All 7 AC verified — 6 fully automated (RTL), 1 (AC7, role-gating) verified by
code review as a genuine no-op, matching the slice's own technical spec. No bugs
found in the implementation; no code changes made. Full frontend suite (12 suites /
48 tests) passes with no regressions.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|-----------------|--------|
| 1 | "Total reviews" tile renders as an interactive element (`<button>`), not a static `<div>` | A | `frontend/src/components/__tests__/MerchantDashboard.test.tsx::"renders 'Total reviews' as a button that scrolls to #recent-reviews on click"` (asserts `tagName === "BUTTON"`); "Average rating" button-role covered by its own test below | Pass |
| 2 | Clicking "Total reviews" scrolls to the existing "Recent reviews" section | A | `MerchantDashboard.test.tsx::"renders 'Total reviews' as a button that scrolls to #recent-reviews on click"` | Pass |
| 3 | Clicking "Average rating" scrolls to the "Sentiment breakdown" chart section | A | `MerchantDashboard.test.tsx::"renders 'Average rating' as a button that scrolls to #sentiment-breakdown on click"` | Pass |
| 4 | Clicking "Status" navigates to edit page (pending/rejected/suspended) or public profile (approved) | A | `MerchantDashboard.test.tsx::"links the 'Status' tile to the public profile when the business is approved"`, `"...to the edit page when the business is pending"`, `"...to the edit page when the business is suspended"` | Pass |
| 5 | Switching the business selector updates the tiles' click targets to the newly selected business (no stale references) | A | `MerchantDashboard.test.tsx::"updates the Status tile's href when the business selector changes"` | Pass |
| 6 | Zero-reviews / single-business case: "Total reviews" tile still lands on the "No reviews yet." empty state, no crash | A | `MerchantDashboard.test.tsx::"shows the existing empty state under #recent-reviews and does not crash when clicked, for a business with zero reviews"` | Pass |
| 7 | Role-gating for `/merchant/dashboard` is unchanged by this slice | A (existing, re-run) + code review | `RequireAuth` (`frontend/src/components/RequireAuth.tsx`) wraps `MerchantDashboardPage` in `frontend/src/app/merchant/dashboard/page.tsx`, unmodified by this slice — confirmed by diff review; `RequireAuth.test.tsx`'s existing 5 tests (unauthenticated → `/login`, wrong role → `/`, matching role renders children, token-revoked handling, bfcache re-verify) re-ran unchanged as part of the full suite | Pass |

**Coverage:** 7 / 7 AC mapped

---

## Backend tests

### Added
None. This slice has zero backend surface — confirmed against the Architect's
technical spec ("No new or modified endpoint... No RBAC change... No backend/schema
change of any kind") and against the actual diff, which touches only
`frontend/src/components/MerchantDashboard.tsx`. Per the task scope, `backend/` was
not touched and no pytest was run.

### Run output
```
Not applicable — no backend change in this slice.
```

---

## Frontend tests

### Added
- `frontend/src/components/__tests__/MerchantDashboard.test.tsx` — new file (7 tests)

Notes on the test setup:
- `@/lib/api`'s `auth`, `businesses`, `dashboard`, and `reviews` exports are mocked
  (no network calls), following the existing mocking convention in
  `RequireAuth.test.tsx` / `ProfilePage.test.tsx`.
- jsdom doesn't implement `Element.prototype.scrollIntoView`; it's stubbed on
  `window.HTMLElement.prototype` in `beforeAll`. Because the stub is a single shared
  `jest.fn()` across all elements, each test asserts *which* DOM node was scrolled to
  via `scrollIntoView.mock.instances[0]` (the `this` context Jest records per call)
  rather than just that scrolling happened somewhere — this is what makes the
  AC2/AC3/AC6 assertions target-specific instead of a weaker "scrolled to something"
  check.
- jsdom also doesn't implement `ResizeObserver`, which the pre-existing "Sentiment
  breakdown" `<Charts>` (recharts `ResponsiveContainer`) section requires to mount
  without throwing; a minimal stub class is installed in `beforeAll` alongside the
  `scrollIntoView` stub. This is incidental to making the *existing* chart section
  render in jsdom at all — it isn't new coverage of the chart itself, which is out of
  scope for this slice.

### Run output
```
cd frontend && npx jest src/components/__tests__/MerchantDashboard.test.tsx

PASS src/components/__tests__/MerchantDashboard.test.tsx
  MerchantDashboard tile interactivity (S-022)
    √ renders 'Total reviews' as a button that scrolls to #recent-reviews on click
    √ renders 'Average rating' as a button that scrolls to #sentiment-breakdown on click
    √ links the 'Status' tile to the public profile when the business is approved
    √ links the 'Status' tile to the edit page when the business is pending
    √ links the 'Status' tile to the edit page when the business is suspended
    √ updates the Status tile's href when the business selector changes
    √ shows the existing empty state under #recent-reviews and does not crash when clicked, for a business with zero reviews

Test Suites: 1 passed, 1 total
Tests:       7 passed, 7 total
```
Full suite (`cd frontend && npx jest`) also run: **12 suites / 48 tests, all passed**
— no regressions. (Recharts' `ResponsiveContainer` prints benign `width(0)/height(0)`
console warnings under jsdom's zero-size layout; this is a pre-existing characteristic
of testing the untouched Sentiment breakdown chart in jsdom, not a test failure.)

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| — | None required this pass | No new network calls, routes, or sections were introduced (interactivity-only slice against already-rendered content); no Docker/live-browser environment is available here to run one anyway (no isolated DB, no CORS-approved local origin). Fully covered by the automated RTL suite above. |

---

## Regressions

None observed. Full frontend suite (12 suites / 48 tests) passes.

---

## Gaps / rework items

None. All 7 AC map to a Pass result; no implementation defects found.

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested — n/a change confirmed by code review (AC7); existing `RequireAuth`
      coverage (unauthenticated/wrong-role) re-verified via full-suite re-run
- [x] AI disclaimer verified (if applicable) — N/A per slice UX notes: none of the
      three tiles show AI-generated content (review count, average rating, approval
      status are all deterministic, non-AI fields); the dashboard's separate AI
      Insights section is untouched by this slice and already carries its own
      disclaimer (`AIInsights.tsx`: "Suggestions only — not definitive judgments")
- [x] Ready for PM acceptance
