# TR-S-021: Admin business & review drill-down — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-021 |
| **Author** | Tester |
| **Date** | 2026-08-11 |
| **Recommendation** | Rework (1 blocker) |

---

## Summary

8 of 9 AC pass fully and are automated. AC 5 is **partially** unmet: the new "All
reviews" browse view (`AllReviewsQueue.tsx`) correctly shows a clickable business-name
link on every row, but the AC's explicit second clause — "today's `ReportedReviewsQueue`
also renders reviews with no business name at all — this fixes that gap too, not just
the new view" — is **not implemented**. The backend contract is correct
(`GET /reviews/reported` now carries `business` on every row, verified), but
`frontend/src/components/admin/ReportedReviewsQueue.tsx` never passes `showBusinessLink`
to `ReviewCard`, so the existing Reported reviews queue on `/admin` still shows no
business name — exactly the gap the slice named. This is a one-line fix (add
`showBusinessLink` to that one `<ReviewCard>` call), not a design problem. No other
bugs found. RBAC is enforced correctly (verified DB-free, and end-to-end in a new
CI-only test file) and the AI disclaimer/suggestion language is unchanged. All backend
and frontend tests added by this pass are green; no regressions in either suite.

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | "Total businesses" tile navigates to an "All businesses" browse view | A | `frontend/src/app/admin/__tests__/page.test.tsx::"renders 'Total businesses' as a link to /admin/businesses"` | Pass |
| 2 | "All businesses" view lists every status (approved/pending/rejected/suspended) with name, city, status badge, rating | A | `frontend/src/components/admin/__tests__/AllBusinessesQueue.test.tsx::"renders businesses of every status with a status badge"`; backend `backend/tests/test_admin_browse.py::TestListAllBusinessesAdmin::test_returns_every_status_not_just_approved`; end-to-end vs. public list `backend/tests/test_admin_browse_asgi.py::test_list_all_businesses_admin_includes_pending_not_just_approved` (CI-only, collection-checked) | Pass |
| 3 | Clicking a business row reaches shop name + full review history without a slug | A | `AllBusinessesQueue.test.tsx::"renders each business row as a link to its admin drill-down by id"` + `frontend/src/app/admin/businesses/__tests__/page.test.tsx::"shows the business's shop name and its review history without needing a slug"` | Pass |
| 4 | "Total reviews" tile navigates to an "All reviews" browse view | A | `admin/__tests__/page.test.tsx::"renders 'Total reviews' as a link to /admin/reviews"` | Pass |
| 5 | Review rows show a clickable business-name link opening the drill-down; also fixes `ReportedReviewsQueue`'s prior no-business-name gap | A | New-view portion: `AllReviewsQueue.test.tsx::"renders each review with a clickable business-name link to its drill-down"`, `ReviewCard.test.tsx` link-gating tests. Backend contract: `test_admin_browse_asgi.py::test_reported_reviews_now_carries_business_summary` (Pass, CI-only). `ReportedReviewsQueue` fix: **not implemented** — see Gaps below | **Fail** (partial — new view is correct; existing queue not fixed) |
| 6 | Zero-reviews drill-down shows "No reviews yet" empty state | A | `admin/businesses/__tests__/page.test.tsx::"shows a 'No reviews yet' empty state for a business with zero reviews"` | Pass |
| 7 | Non-admin (anonymous/customer/merchant) denied on both new browse routes and both new endpoints | A | Frontend: `RequireAuth.test.tsx` (existing, re-run — unauthenticated → `/login`, wrong role → `/`); all 3 new pages wrap `RequireAuth role="admin"`, confirmed by code review. Backend: `test_admin_browse.py::TestAdminBrowseRBAC` (DB-free, tests the exact `require_roles(UserRole.ADMIN)` dependency both new routes declare); `test_admin_browse_asgi.py::test_list_all_businesses_admin_requires_admin_role`, `*_anonymous_401`, `test_list_admin_reviews_requires_admin_role`, `*_anonymous_401` (CI-only, collection-checked) | Pass |
| 8 | AI sentiment badge / "AI summary (suggestion)" language unchanged | A (regression) | `ReviewCard.test.tsx` AI-disclaimer describe block; confirmed unchanged by diff review of `ReviewCard.tsx` (no lines touched in the sentiment-badge/summary block) | Pass |
| 9 | "Total users" tile stays non-interactive (no drill-down) | A | `admin/__tests__/page.test.tsx::"keeps 'Total users' as a static, non-interactive tile"` | Pass |

**Coverage:** 9 / 9 AC mapped (8 Pass, 1 Fail — partial)

---

## Backend tests added

- `backend/tests/test_admin_browse.py` (existing file from Builder, extended):
  - `TestListAllBusinessesAdmin::test_returns_every_status_not_just_approved` (pre-existing)
  - `TestListAllBusinessesAdmin::test_caps_page_size_at_100` (pre-existing)
  - `TestListAdminReviews::test_returns_every_status_across_businesses` (pre-existing)
  - `TestListAdminReviews::test_response_carries_business_summary` (pre-existing)
  - `TestListAdminReviews::test_business_id_filter_scopes_to_one_business` (pre-existing)
  - `TestAdminBrowseRBAC::test_admin_only_dependency_rejects_non_admin_roles[customer]` (**new**)
  - `TestAdminBrowseRBAC::test_admin_only_dependency_rejects_non_admin_roles[merchant]` (**new**)
  - `TestAdminBrowseRBAC::test_admin_only_dependency_allows_admin` (**new**)
- `backend/tests/test_admin_browse_asgi.py` (**new file**, ASGI + real Postgres — CI-only,
  never run locally per `backend/tests/CLAUDE.md`; collection-checked only):
  - `test_list_all_businesses_admin_requires_admin_role`
  - `test_list_all_businesses_admin_anonymous_401`
  - `test_list_all_businesses_admin_includes_pending_not_just_approved`
  - `test_list_admin_reviews_requires_admin_role`
  - `test_list_admin_reviews_anonymous_401`
  - `test_list_admin_reviews_carries_business_summary_and_scopes_by_business_id`
  - `test_reported_reviews_now_carries_business_summary`

### Run output

```
cd backend && .venv/Scripts/python.exe -m pytest -q tests/test_admin_browse.py
........
8 passed in 1.32s

cd backend && .venv/Scripts/python.exe -m pytest -q --ignore=tests/test_s018_s020_login_profile.py \
  --ignore=tests/test_businesses_mine.py --ignore=tests/test_s011_s016_batch.py \
  --ignore=tests/test_api.py --ignore=tests/test_dashboard.py --ignore=tests/test_admin_browse_asgi.py
186 passed, 9 warnings in 5.73s   # no regressions (183 pre-existing + 3 new RBAC tests)

cd backend && .venv/Scripts/python.exe -m pytest --collect-only -q tests/test_admin_browse_asgi.py
7 tests collected in 1.87s   # imports cleanly; not executed (real-DB-only, per env constraint)

cd backend && .venv/Scripts/python.exe -m pytest --collect-only -q tests/test_dashboard.py
6 tests collected in 1.89s   # sanity check: dashboard.py's mechanical selectinload(Review.business)
                              # addition (merchant_dashboard's `recent` query) didn't break imports
```

---

## Frontend tests added

- `frontend/src/components/__tests__/ReviewCard.test.tsx` (**new** — component had no
  prior colocated test): business-link gating (4 tests) + AI disclaimer regression (3 tests)
- `frontend/src/components/admin/__tests__/AllBusinessesQueue.test.tsx` (**new**, 4 tests)
- `frontend/src/components/admin/__tests__/AllReviewsQueue.test.tsx` (**new**, 4 tests)
- `frontend/src/app/admin/__tests__/page.test.tsx` (**new**, 3 tests — stat tile AC1/AC4/AC9)
- `frontend/src/app/admin/businesses/__tests__/page.test.tsx` (**new**, 2 tests — drill-down AC3/AC6)

### Run output

```
cd frontend && npm test -- --watchAll=false

Test Suites: 17 passed, 17 total
Tests:       68 passed, 68 total
```

68 = 48 pre-existing (unchanged, no regressions) + 20 new (7 + 4 + 4 + 3 + 2 above).

**Implementation note (test infra, not a product bug):** the drill-down page
(`frontend/src/app/admin/businesses/[id]/page.tsx`) reads its dynamic-route id via
React's `use(params)` on a Promise (Next.js 15's async-params client-component
pattern). A bare `Promise.resolve(...)` never un-suspends inside jsdom + RTL in this
project's React 19 setup (confirmed via an isolated minimal repro — the Suspense
retry ping is scheduled through the "scheduler" package's `MessageChannel`, which does
not flush within jsdom/RTL's `act()` regardless of how many microtask/macrotask ticks
are awaited). Worked around by passing a pre-tagged `{status: "fulfilled", value, then(){}}`
thenable — the same shape React itself writes onto a promise the first time `use()`
reads it — which makes `use()` return synchronously and skip Suspense entirely. This is
purely a test-authoring detail; the page code itself is unmodified and correct.

---

## Manual checklist

- [ ] M-001: `docker compose up --build`; sign in as admin, click "Total businesses" and
  "Total reviews" tiles from `/admin`, confirm navigation and data load. **Not run** — no
  Docker/isolated-DB environment available this session.
- [ ] M-002: As a signed-in customer or merchant, attempt to load `/admin/businesses`
  and `/admin/reviews` directly by URL — confirm redirect, not a 500/blank page. **Not
  run** this session; strongly implied correct by `RequireAuth` code review (identical
  wrapper on all three new pages) plus `RequireAuth.test.tsx`'s existing coverage of the
  exact same guard.
- [ ] M-003: Swagger `/docs` — confirm `GET /businesses/admin/all` and
  `GET /reviews/admin/all` match the implemented routes/response shapes. **Not run**
  this session; route signatures/response models reviewed directly in
  `backend/app/routers/businesses.py` and `backend/app/routers/reviews.py` and match
  the Architect's API contract exactly.

Flagging for PM/Builder to run before final acceptance — consistent with this
environment's standing constraint (no isolated local Postgres/Docker available to this
agent; see slice handoff notes).

---

## Regressions / gaps

**No regressions.** Full backend safe subset (186 tests) and full frontend suite (68
tests) both pass with no failures relative to pre-existing baselines.

**Gap — AC 5 (Rework blocker):** `frontend/src/components/admin/ReportedReviewsQueue.tsx`
line 59 renders `<ReviewCard review={r} showActions={false} />` without
`showBusinessLink`. The Architect's technical spec explicitly called this out as
required: *"`ReportedReviewsQueue.tsx` — no route/logic change; automatically starts
showing the business-name link once `/reviews/reported`'s payload carries `business`
and `ReviewCard` renders it (closes the AC 5 gap with a one-line prop pass-through, not
a fork)."* The backend half of that fix is done and verified (`/reviews/reported` now
returns `business` on every row — `test_admin_browse_asgi.py::test_reported_reviews_now_carries_business_summary`),
but the frontend prop pass-through was never added, so the existing Reported reviews
queue on `/admin` still shows no business/shop name today, unchanged from before this
slice. Fix: add `showBusinessLink` to that one `<ReviewCard>` call.

**Minor doc-sync nit (non-blocking):** `README.md`'s slice-status table still lists
S-021 as `Draft` (line ~1903) even though the slice file itself is well past Draft
(Architect completed "Specified" before Builder implemented; I set it to `Testing` to
start this pass). §7 API reference *is* correctly updated with both new endpoints. Not
a functional gap, but worth Builder/PM syncing before acceptance per `docs/CLAUDE.md`.

---

## Recommendation

**Rework** — 1 blocker: add the `showBusinessLink` prop to `ReportedReviewsQueue.tsx`'s
`<ReviewCard>` call (line 59) so AC 5's explicit "fixes that gap too" clause is
actually satisfied. This is a one-line, low-risk change with no API/schema impact —
the backend and the rest of the frontend (all 8 other AC) are fully verified and
Ship-ready. Recommend: Builder applies the one-line fix, then re-run
`AllReviewsQueue`/`ReportedReviewsQueue`-adjacent frontend suite (already green
elsewhere) to confirm, and PM re-reviews AC 5 before setting slice `Status: Accepted`.
