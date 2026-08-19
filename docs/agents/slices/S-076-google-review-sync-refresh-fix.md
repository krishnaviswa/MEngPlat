# Slice: S-076 — Google review sync: refresh dashboard stats & AI insights after sync

| Field | Value |
|-------|-------|
| **Slice ID** | S-076 |
| **Phase** | 2 Core |
| **Status** | Accepted |
| **Role(s)** | merchant |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As a** merchant
**I want** my dashboard's review stats and AI insights to update automatically right after I sync my Google reviews
**So that** I see current numbers immediately, instead of stale figures until I manually reload the page

---

## Background / context

Roadmap item **C1** (`docs/agents/plans` roadmap, item #10). Root cause already located by
exploration and confirmed by this brief's own code read: `handleSyncGoogleReviews` in
`frontend/src/components/MerchantDashboard.tsx` (currently lines ~177–191) calls
`dashboard.syncGoogleReviews(business.id)` and then only refetches
`dashboard.getGoogleReviewsStatus(business.id)` — it never refetches `dashboard.merchant(...)`
(the stats query already driving the charts/stat cards on the same page) or
`dashboard.insights(...)` / `dashboard.topics(...)` (the AI insights/topics query already used by
`loadBusiness`). A merchant who clicks "Sync now" sees the Google-sync card update, but the rest
of the dashboard (review counts, rating distribution, sentiment breakdown, AI insights/topics)
stays frozen at whatever it showed before the sync, until the merchant manually reloads the page.

### Known gap — flagged, not fixed by this slice (needs a separate product decision)

Reading `backend/app/services/review_sync_service.py` end to end: `ExternalReview` rows (created
by a Google sync) are used in exactly two places — `get_google_reviews_status` (a `COUNT`/`MAX` for
the sync card itself) and the public `list_external_reviews` (the "Also reviewed on Google" section
on the business profile, per S-048). **No query in this file, in `dashboard.py`, or anywhere else
in the backend joins `ExternalReview` rows into `dashboard.merchant()`'s stats aggregation or into
the AI insights/topics generation used by `dashboard.insights()` / `dashboard.topics()`.** In other
words: even after this slice's fix, refetching stats/insights post-sync will show the *same*
numbers as before the sync, because those endpoints don't read `ExternalReview` at all today — this
matches S-048's deliberate "external reviews never blend into native aggregates" rule for
`average_rating`/`review_count`, but it was never explicitly decided one way or the other for
*dashboard stats* or *AI insights/topics* specifically. **Whether synced Google reviews should ever
feed into merchant dashboard stats or AI insight/topic aggregation is a product decision this slice
does not make** — it is called out here so it isn't silently assumed either way. See "Out of scope"
below.

---

## Acceptance criteria

1. **Given** a merchant on their dashboard with a business that has a linked Google Business Profile, **when** they click "Sync now" and the sync request succeeds, **then** the dashboard's stats section (the same data currently rendered from `dashboard.merchant()` — stat cards, charts, rating distribution, sentiment breakdown) is refetched and re-rendered without the merchant needing to reload the page.
2. **Given** the same successful sync, **when** it completes, **then** the AI insights/topics section (the same data currently rendered from `dashboard.insights()` / `dashboard.topics()`, as already wired in `loadBusiness`) is also refetched and re-rendered without the merchant needing to reload the page.
3. **Given** a successful sync, **when** the AC1/AC2 refetches run, **then** the existing Google-sync status card (linked state, review count, last-synced timestamp) continues to update exactly as it does today — no regression to current behavior.
4. **Given** a sync attempt that fails (provider timeout/error, existing `502`/error-toast path), **when** the failure occurs, **then** stats and AI insights are **not** refetched and their previously displayed values are left untouched — same "leave existing state untouched on error" principle already applied to the sync card's own error handling in `handleSyncGoogleReviews`.
5. **Given** today's `dashboard.merchant()` / `dashboard.insights()` / `dashboard.topics()` responses do not currently include anything derived from `ExternalReview` rows (see Known gap above), **when** this slice's refetch runs, **then** it simply re-requests those same existing endpoints and displays whatever they already return — this AC is scoped to fixing the *refetch timing*, not to changing what those endpoints aggregate.
6. **Given** the "Sync now" button's existing loading/disabled state (`syncingGoogle`), **when** the AC1/AC2 refetches are in flight after a sync completes, **then** the button's own loading indicator remains the primary in-progress feedback for the sync action — the added refetches must not introduce a second, conflicting loading indicator for the same user action.
7. **Given** the AI insights section already carries a "suggestion" disclaimer (existing `AIInsights` component behavior), **when** insights are refetched and re-rendered by this fix, **then** that disclaimer continues to render exactly as it does on initial page load — this fix must not bypass or duplicate the existing AI-disclaimer rendering path.

---

## UX notes

- Screens / routes: `/merchant/dashboard` only (`MerchantDashboard.tsx`). No new screens, routes, or components.
- Components to reuse: existing `Charts`, `StatCard`, `AIInsights` — this slice only changes *when* their backing data is refetched, not their rendering.
- Empty states / errors: no new empty states. AC4 preserves the existing sync-error handling (`googleError` state, inline error text) unchanged.
- AI disclaimer required? Yes — already present via `AIInsights`; AC7 requires it continues to render after the new refetch, not a new disclaimer.

---

## Out of scope

- Deciding whether `ExternalReview` (Google-synced) rows should be included in `dashboard.merchant()` stats aggregation or in AI insight/topic generation. This is a product decision that needs explicit human sign-off (see Known gap above) — this slice's AC only requires that the refetch faithfully reflects whatever those endpoints currently return, whether or not that includes external reviews.
- Any backend changes to `review_sync_service.py`, `dashboard.py`'s stats/insights queries, or the AI insight-generation pipeline.
- Automatic/scheduled Google review polling (still out of scope per S-048 — this remains a manual "Sync now" trigger).
- Any change to the WhatsApp drafts/sync refresh behavior on the same dashboard page (unrelated feature, `WhatsAppDraftsPanel`).
- Changing the Google-sync debounce/lock behavior (`try_acquire_lock` / `release_lock` in `review_sync_service.py`) — unaffected by this slice.

---

## Dependencies

- S-048 (Multi-platform review aggregator foundation — Google Places) — Accepted. This slice is a bug-fix on top of the dashboard sync card S-048 shipped.

---

## Definition of done (PM)

- [ ] All AC verified in test report
- [ ] UX matches notes above
- [ ] Documented in `README.md` §7 API reference / §8 Frontend guide if new patterns
- [x] PM Status set to **Accepted**

---

## Technical specification (Architect)

Frontend-only fix. Confirmed by reading `backend/app/routers/dashboard.py` and
`backend/app/schemas/__init__.py`: `POST /dashboard/merchant/{business_id}/google-reviews/sync`
returns `GoogleReviewsSyncResponse` (`synced_count`, `last_synced_at`, `debounced`) only — it does
**not** carry stats/insights/topics data, and there is no Redis cache on `dashboard.py`'s
stats/insights endpoints to invalidate (only the sync-debounce lock, unaffected by this slice). So
the only correct fix is exactly what the PM's background section identifies: after a successful
sync, the client must issue fresh `GET` calls to the same endpoints the page already calls on
initial load. No backend endpoint needs a new field, and no new endpoint is needed.

### API contract

No new/changed endpoints — N/A. This slice re-invokes three **existing, unmodified** endpoints
from `handleSyncGoogleReviews` instead of only one:

| Method | Path | Auth | Notes |
|--------|------|------|-------|
| `POST` | `/api/v1/dashboard/merchant/{business_id}/google-reviews/sync` | merchant (owner) / admin | unchanged — existing trigger call |
| `GET` | `/api/v1/dashboard/merchant/{business_id}/google-reviews` | merchant (owner) / admin | unchanged — existing sync-card refetch (AC3), kept as-is |
| `GET` | `/api/v1/dashboard/merchant/{business_id}?range=...` | merchant (owner) / admin | **newly called from this handler** (AC1) — same call `dashboard.merchant(business.id, { range })` already makes in the `useEffect` at line ~106-112; no contract change |
| `GET` | `/api/v1/dashboard/merchant/{business_id}/insights` | merchant (owner) / admin | **newly called from this handler** (AC2) — same call `dashboard.insights(b.id)` already makes in `loadBusiness` (line ~86); no contract change |
| `GET` | `/api/v1/dashboard/merchant/{business_id}/topics` | merchant (owner) / admin | **newly called from this handler** (AC2) — same call `dashboard.topics(b.id)` already makes in `loadBusiness` (line ~87), including its existing `.catch(() => null)` degrade-gracefully pattern; no contract change |

### RBAC matrix

Unchanged — no new endpoint, no new role gate. Existing `require_roles(MERCHANT, ADMIN)` +
owner-scoping on all four endpoints above already applies and is untouched by this slice.

| Action | customer | merchant | admin |
|--------|----------|----------|-------|
| Trigger sync + refetch stats/insights/topics | 403 (unchanged) | yes, owner only (unchanged) | yes (unchanged) |

### Data model impact

- [x] None  [ ] Extend existing  [ ] New table(s)

**Details:** None. No schema, migration, or model change.

### Cache / side effects

None. `dashboard.py`'s stats/insights/topics endpoints have no Redis cache layer to invalidate
(confirmed by reading the router — the only Redis use on this router is the sync debounce lock,
`try_acquire_lock`/`release_lock` in `review_sync_service.py`, explicitly out of scope and
untouched). `search:*` cache invalidation is irrelevant here — these are merchant-owned dashboard
reads, not the public search index.

### Frontend

- **Route:** `/merchant/dashboard` (existing, no new route).
- **Rendering:** CSR — `MerchantDashboard.tsx` is already `"use client"`.
- **Components:** No new components. Reuses `Charts`, `StatCard`, `AIInsights` exactly as today
  (AC7) — only the data feeding them changes timing, not their props/rendering path.

**Change, scoped to `handleSyncGoogleReviews` (`frontend/src/components/MerchantDashboard.tsx`,
currently lines ~177-191):**

```ts
async function handleSyncGoogleReviews() {
  if (!business) return;
  setSyncingGoogle(true);
  setGoogleError(null);
  try {
    await dashboard.syncGoogleReviews(business.id);
    const [status, freshStats] = await Promise.all([
      dashboard.getGoogleReviewsStatus(business.id),   // AC3 — unchanged sync card refetch
      dashboard.merchant(business.id, { range }),       // AC1 — new stats refetch
    ]);
    setGoogleStatus(status);
    setStats(freshStats);
    await loadBusiness(business);                       // AC2 — reuses existing insights+topics loader
  } catch (err) {
    // AC4: on failure, none of the above setters run — existing state is left untouched,
    // same principle already applied to the sync card's own error handling.
    setGoogleError(err instanceof Error ? err.message : "Couldn't sync Google reviews right now");
  } finally {
    setSyncingGoogle(false);
  }
}
```

Reusing `loadBusiness` (already defined via `useCallback` at line ~84-97) for the AI
insights/topics refetch — rather than duplicating its `dashboard.insights()` +
`dashboard.topics()` + merge-into-`insights`-state logic inline — keeps AC2's refetch byte-for-byte
identical to the initial-load path, satisfying AC7 (disclaimer rendering is a property of
`AIInsights` reading from `insights` state, unaffected by *how* that state gets set) without any
new merge logic to get wrong. `loadBusiness` calls `setBusiness(b)` too, which is a harmless no-op
re-set of the same object reference's *value* (not a new object) here since `business` is already
loaded — no extra render cost worth guarding against.

AC6 (no second loading indicator): `syncingGoogle` already wraps this entire `try` block including
the new calls (`setSyncingGoogle(true)` before, `setSyncingGoogle(false)` in `finally`) — the
"Sync now" button's existing `disabled={syncingGoogle}` / `"Syncing..."` label already covers the
full duration of the extended handler with zero additional state. `Charts`/`StatCard`/`AIInsights`
have no loading props being introduced — they simply re-render with new data when `stats`/
`insights` change, identical to how they already re-render on business switch.

### Flow

```mermaid
sequenceDiagram
    participant Merchant
    participant Dashboard as MerchantDashboard
    participant API

    Merchant->>Dashboard: clicks "Sync now"
    Dashboard->>API: POST /dashboard/merchant/{id}/google-reviews/sync
    alt sync succeeds
        API-->>Dashboard: 200 {synced_count, last_synced_at, debounced}
        par existing sync-card refetch (AC3)
            Dashboard->>API: GET /dashboard/merchant/{id}/google-reviews
            API-->>Dashboard: GoogleReviewsStatusResponse
        and new stats refetch (AC1)
            Dashboard->>API: GET /dashboard/merchant/{id}?range=...
            API-->>Dashboard: stats
        and new insights/topics refetch (AC2, via loadBusiness)
            Dashboard->>API: GET /dashboard/merchant/{id}/insights
            Dashboard->>API: GET /dashboard/merchant/{id}/topics
            API-->>Dashboard: insights, topics
        end
        Dashboard-->>Merchant: stat cards, charts, sentiment, AI insights all re-render (no reload)
    else sync fails (502/timeout)
        API-->>Dashboard: error
        Dashboard-->>Merchant: googleError shown; stats/insights untouched (AC4)
    end
```

### Architect checklist

- [x] API contract defined — no new endpoints; three existing endpoints newly re-invoked, contracts unchanged
- [x] RBAC matrix complete — unchanged, no new gate
- [x] Data model impact documented — none
- [x] Cache invalidation considered — none applicable (no cache layer on these reads)
- [x] Uses AI/storage abstractions where applicable — N/A, no AI/storage call added; existing `AIInsights` disclaimer path reused unmodified (AC7)
- [x] ERD/API/FLOWS updates noted — no README §5/§7 changes needed (no schema/endpoint change); README §6 flow description for "Google review sync" can optionally note the stats/insights refetch, at Builder/PM's discretion post-merge, but is not required since no new API surface exists

### Risks / tradeoffs

- **Known gap carried forward, not fixed here** (per PM's background section): `ExternalReview`
  rows still don't feed `dashboard.merchant()`'s aggregation or AI insights/topics generation, so
  post-sync numbers may appear unchanged from pre-sync even though this fix is working correctly
  (AC5 explicitly scopes around this). Do not treat "numbers look the same after sync" as a test
  failure unless the underlying native review data actually changed.
- Switching the two AC3/AC1 refetches to `Promise.all` (rather than sequential awaits, as the
  original code did for the single status call) is a minor behavior change: if the stats call is
  slower than the status call, the status card updates slightly before stats/insights finish,
  instead of everything being strictly sequential. This doesn't violate any AC (all three still
  land before `finally` clears `syncingGoogle`) and is a reasonable latency improvement, but
  flagging it as a deliberate implementation choice, not spec-mandated — the Builder may instead
  sequence them if that's simpler to reason about, since no AC requires a specific ordering.
- `loadBusiness`'s own error handling (`.catch(() => setInsights(null))` at the call site in the
  existing `useEffect`, line ~103) is *not* reused here — calling `loadBusiness(business)` directly
  inside this handler's `try` means an insights/topics failure here throws into this handler's own
  `catch`, which sets `googleError` (misleading: a sync-succeeded-but-insights-refetch-failed case
  would show a "Couldn't sync Google reviews" message, which is inaccurate). This is a real edge
  case AC4 doesn't explicitly cover (AC4 only covers *sync* failure) — Builder should wrap the
  `loadBusiness(business)` call in its own local `try/catch` that swallows the error silently
  (matching `loadBusiness`'s existing call-site behavior) rather than letting it bubble into
  `setGoogleError`, so a partial insights-refetch failure doesn't produce a misleading sync-error
  message. Flagging this explicitly so the Tester checks it as its own case, not folded into AC4.

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-076-*.md`
- Test report: `docs/agents/test-reports/TR-S-076-*.md`
- ADR: `docs/agents/adrs/ADR-XXX-*.md` (if any)

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-19 | PM | Created slice. Confirmed root cause by reading `MerchantDashboard.tsx` (`handleSyncGoogleReviews`) and `review_sync_service.py`; flagged the ExternalReview-not-in-aggregations question as an explicit out-of-scope known gap rather than assuming an answer. |
| 2026-08-19 | Architect | Filled technical specification. Confirmed via `dashboard.py`/`schemas/__init__.py` that the sync endpoint's response carries no stats/insights data and there's no cache layer to invalidate — the fix is purely calling `dashboard.merchant()` and reusing `loadBusiness()` (existing hook names) after a successful sync. No new endpoints, no data model change, no ADR needed. Flagged a `loadBusiness` error-handling edge case (partial insights-refetch failure shouldn't surface as a misleading sync-error message) for Tester attention. Checklist complete; Status left as **Proposed** pending Builder/Tester per PM instruction. |
| 2026-08-19 | Builder | Implemented in `MerchantDashboard.tsx`'s `handleSyncGoogleReviews` exactly per spec, including the flagged edge case (post-sync insights refetch wrapped in its own swallowed `.catch`). |
| 2026-08-19 | Tester | 33/33 targeted tests pass (284/284 full suite). All 7 AC verified (4 automated, 3 by direct code read). See `docs/agents/test-reports/TR-S-076-google-review-sync-refresh-fix.md`. |
| 2026-08-19 | PM | Accepted. Ship-ready, no gaps found. |
