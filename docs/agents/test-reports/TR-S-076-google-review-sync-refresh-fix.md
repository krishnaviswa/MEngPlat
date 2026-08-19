# TR-S-076: Google review sync — refresh dashboard stats & AI insights after sync — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-076 |
| **Author** | Tester |
| **Date** | 2026-08-19 |
| **Recommendation** | Ship |

---

## Summary

**Pass.** All 7 acceptance criteria are met. I independently re-ran the frontend test
suite and read the current source of `handleSyncGoogleReviews` in
`frontend/src/components/MerchantDashboard.tsx` line by line against the AC/spec.

The implementation matches the Architect's spec almost verbatim: a successful
`dashboard.syncGoogleReviews()` call is followed by `Promise.all([getGoogleReviewsStatus,
dashboard.merchant()])` (AC1/AC3), then `loadBusiness(business)` reused unmodified for
insights/topics (AC2/AC7). The Architect's flagged edge case — a sync that succeeds but
whose subsequent insights refetch fails must not surface a misleading "Couldn't sync"
error — was correctly implemented: the Builder wrapped the `loadBusiness(business)` call
in its own `.catch(() => {})` (line 193), so only the `dashboard.syncGoogleReviews` /
`getGoogleReviewsStatus` / `dashboard.merchant` calls are inside the outer `try` that sets
`googleError` on failure. This is confirmed by a dedicated new test
(`"does not show a sync error when only the post-sync insights refetch fails"`) that was
not explicitly required by any single AC but was flagged by the Architect as its own case
— present and passing.

AC6 (no second loading indicator) and AC7 (disclaimer continues to render) are correct by
code read — `syncingGoogle` is unchanged and still the only loading flag wrapping the
entire handler, and `AIInsights` itself is untouched, reading from the same `insights`
state set via the same `loadBusiness` path as initial load — but neither is asserted by an
explicit new test (see gaps below); this is a minor coverage gap, not a functional defect.

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Successful sync refetches and re-renders stats section (`dashboard.merchant()`) without reload | A | `MerchantDashboard.test.tsx::"MerchantDashboard Google sync refresh (S-076)" > "refetches stats and insights/topics after a successful sync, alongside the sync-status card"` — asserts `merchantStatsMock` called >1 time and rendered "Total reviews" card updates from 10 to 12 | Pass |
| 2 | Successful sync refetches AI insights/topics section without reload | A | Same test — asserts `insightsMock.mock.calls.length` increases post-sync | Pass |
| 3 | Existing Google-sync status card continues to update, no regression | A | Same test — asserts `googleReviewsStatusMock.mock.calls.length` > 1 (called on load, then again post-sync) | Pass |
| 4 | Failed sync leaves stats/insights untouched, existing error path preserved | A | `"does not refetch stats or insights when the sync request fails"` — asserts stats/insights mock call counts unchanged, error text shown | Pass |
| 5 | Refetch just re-requests existing endpoints, doesn't change what they aggregate | M (code-read) | No backend endpoint touched — confirmed via `git status` (no `dashboard.py`/`review_sync_service.py` changes) and code read of `handleSyncGoogleReviews`, which calls only the three pre-existing endpoint wrappers | Pass |
| 6 | No second/conflicting loading indicator introduced alongside `syncingGoogle` | M (code-read) | Code read: `setSyncingGoogle(true)`/`finally { setSyncingGoogle(false) }` still wraps the whole handler; no new loading state variable added; `Charts`/`StatCard`/`AIInsights` take no new loading props | Pass — **not asserted by a dedicated test; flagged as minor gap below** |
| 7 | AI disclaimer continues to render exactly as before after refetch | M (code-read) | Code read: `AIInsights.tsx` unmodified (`git status` confirms); disclaimer (`"Suggestions only — not definitive judgments..."`) is unconditional inside the component, driven only by `insights` state truthiness, unaffected by *how* `insights` gets set | Pass — **not asserted by a dedicated test; flagged as minor gap below** |

**Coverage:** 7 / 7 AC mapped (4 automated, 3 code-read/manual — all pass).

---

## Frontend tests

### Re-run (independent verification)
```
cd frontend && npx jest src/components/__tests__/MerchantDashboard.test.tsx src/components/__tests__/WhatsAppUpdateCard.test.tsx
Test Suites: 2 passed, 2 total
Tests:       33 passed, 33 total
```

### Full suite
```
cd frontend && npx jest --silent
Test Suites: 47 passed, 47 total
Tests:       284 passed, 284 total
```

### New tests confirmed in `frontend/src/components/__tests__/MerchantDashboard.test.tsx`, describe block `"MerchantDashboard Google sync refresh (S-076)"`
- `"refetches stats and insights/topics after a successful sync, alongside the sync-status card"` (AC1/AC2/AC3)
- `"does not refetch stats or insights when the sync request fails"` (AC4)
- `"does not show a sync error when only the post-sync insights refetch fails"` (Architect-flagged edge case, distinct from AC4)

All three assert against mock call counts and/or rendered DOM text, not implementation
internals — consistent with repo testing conventions.

---

## Regressions

None found. Full suite green (284/284), including the pre-existing
`"MerchantDashboard Google reviews card (S-048)"` describe block (unrelated sync-card
tests, still passing) and all other suites.

---

## Gaps / rework items

1. **AC6 and AC7 have no dedicated assertion** — both are satisfied by code read (no new
   loading state added; `AIInsights` untouched) but there is no test that explicitly
   fails if a regression were introduced later (e.g. a second spinner appearing next to
   "Sync now", or the disclaimer text being dropped from a future `AIInsights` edit). Low
   risk given how narrowly scoped the change is, but worth a follow-up test if this area
   is touched again. Not a blocker.
2. **Known gap carried forward from the slice itself, not a defect**: per the PM's
   background section, `ExternalReview` rows still don't feed `dashboard.merchant()`'s
   aggregation or AI insights/topics generation — post-sync numbers may look unchanged
   from pre-sync in a live app even though the refetch fix works correctly. This is
   explicitly out of scope for this slice (AC5) and not treated as a failure here.

Neither gap blocks shipping.

---

## Sign-off

- [x] All AC mapped to tests (4/7 automated, 3/7 code-read/manual — all pass)
- [x] RBAC — N/A per Architect spec (no new endpoint, no new role gate; three
      pre-existing owner-scoped endpoints re-invoked, unchanged auth)
- [x] AI disclaimer verified — confirmed unchanged/still rendering (code-read, AC7)
- [x] Ready for PM acceptance
