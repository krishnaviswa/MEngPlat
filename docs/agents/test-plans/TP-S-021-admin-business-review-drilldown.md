# TP-S-021: Admin business & review drill-down — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-021 |
| **Author** | Tester |
| **Date** | 2026-08-11 |

---

## Scope

Two new admin-only browse endpoints (`GET /businesses/admin/all`, `GET /reviews/admin/all`),
an extended `ReviewResponse.business` field (also surfaced on the existing
`GET /reviews/reported`), and three new admin-only frontend routes
(`/admin/businesses`, `/admin/businesses/[id]`, `/admin/reviews`) plus `/admin`'s
"Total businesses"/"Total reviews" tiles becoming navigating links. See the slice's 9
numbered AC and Architect technical specification for full contract.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend API (DB-free) | pytest, fake db, direct router calls | Query/filter logic of both new endpoints, `business` summary serialization (existing `test_admin_browse.py`, extended with RBAC-checker tests) |
| Backend API (RBAC + real serialization) | pytest, ASGI + real Postgres, **CI-only** | 401/403 for both new endpoints, every-status inclusion vs. the public list, `business` round-trips through real JSON on `/reviews/admin/all` and the now-extended `/reviews/reported` |
| Frontend | Jest + RTL | Stat tile navigation, browse-view rendering (every status), drill-down (shop name + review history + empty state), `ReviewCard` business-link gating, AI disclaimer regression |
| Manual | Docker smoke / code review | RBAC route-guard behavior already covered by `RequireAuth.test.tsx` (AC7); full role-flow smoke deferred to `docker compose up --build` per role's standing manual checklist |

No isolated local Postgres is available in this environment — `backend/tests/test_admin_browse.py`
(existing) and `backend/tests/test_admin_browse_asgi.py` (new, RBAC + happy-path,
ASGI + real DB) are written for CI's ephemeral Postgres only; the ASGI file is
collection-checked (`pytest --collect-only`) but not executed locally, per
`backend/tests/CLAUDE.md`.

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1. "Total businesses" tile navigates to an "All businesses" browse view | Automated | `frontend/src/app/admin/__tests__/page.test.tsx::"renders 'Total businesses' as a link to /admin/businesses"` |
| 2. "All businesses" view lists every status (approved/pending/rejected/suspended) with name, city, status badge, rating | Automated | `frontend/src/components/admin/__tests__/AllBusinessesQueue.test.tsx::"renders businesses of every status with a status badge"`; backend: `test_admin_browse.py::TestListAllBusinessesAdmin::test_returns_every_status_not_just_approved`, `test_admin_browse_asgi.py::test_list_all_businesses_admin_includes_pending_not_just_approved` |
| 3. Clicking a business row reaches shop name + full review history without a slug | Automated | `AllBusinessesQueue.test.tsx::"renders each business row as a link to its admin drill-down by id"` + `frontend/src/app/admin/businesses/__tests__/page.test.tsx::"shows the business's shop name and its review history without needing a slug"` |
| 4. "Total reviews" tile navigates to an "All reviews" browse view | Automated | `page.test.tsx (admin)::"renders 'Total reviews' as a link to /admin/reviews"` |
| 5. Review rows show a clickable business-name link opening the drill-down (incl. fixing `ReportedReviewsQueue`'s prior no-business-name gap) | Automated (new view) / **Fail — see report** (`ReportedReviewsQueue` fix) | `AllReviewsQueue.test.tsx::"renders each review with a clickable business-name link to its drill-down"`; `ReviewCard.test.tsx` link-gating tests; backend: `test_admin_browse_asgi.py::test_reported_reviews_now_carries_business_summary` (backend contract is correct — gap is frontend-only, see report) |
| 6. Zero-reviews drill-down shows "No reviews yet" empty state | Automated | `admin/businesses/__tests__/page.test.tsx::"shows a 'No reviews yet' empty state for a business with zero reviews"` |
| 7. Non-admin denied on both new browse routes | Automated (existing, re-run) + code review | `RequireAuth.test.tsx` (unauthenticated → `/login`, wrong role → `/`) — all three new pages wrap `RequireAuth role="admin"` identically to `/admin`, confirmed by code review; backend RBAC: `test_admin_browse.py::TestAdminBrowseRBAC`, `test_admin_browse_asgi.py::test_list_all_businesses_admin_requires_admin_role` + `*_anonymous_401`, `test_list_admin_reviews_requires_admin_role` + `*_anonymous_401` |
| 8. AI sentiment badge / "AI summary (suggestion)" language unchanged | Automated (regression) | `ReviewCard.test.tsx` AI-disclaimer describe block — confirms unchanged rendering; also confirmed unchanged by diff review |
| 9. "Total users" tile stays non-interactive | Automated | `page.test.tsx (admin)::"keeps 'Total users' as a static, non-interactive tile"` |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| `GET /businesses/admin/all` | anonymous | 401 |
| `GET /businesses/admin/all` | customer/merchant | 403 |
| `GET /reviews/admin/all` | anonymous | 401 |
| `GET /reviews/admin/all` | customer/merchant | 403 |
| `require_roles(UserRole.ADMIN)` dependency (shared by both new routes) | customer, merchant | 403 (DB-free direct dependency check) |
| `/admin/businesses`, `/admin/businesses/[id]`, `/admin/reviews` frontend routes | anonymous | redirect to `/login` (`RequireAuth`, existing coverage) |
| same frontend routes | customer/merchant | redirect to `/` (`RequireAuth`, existing coverage) |

---

## Edge cases

- Business with zero reviews on drill-down (AC6) — covered.
- `review.business` present but `showBusinessLink` omitted/false on a non-admin
  `ReviewCard` call site (e.g. public business-detail page) — must never render the
  admin link. Covered explicitly in `ReviewCard.test.tsx`.
- `review.business` absent while `showBusinessLink` is true (should not crash) — covered.
- Pagination cap (`page_size` > 100 clamped to 100) — already covered by the existing
  `test_admin_browse.py::test_caps_page_size_at_100`.
- `business_id` filter scoping `/reviews/admin/all` to one business (also powers the
  drill-down) — already covered by `test_admin_browse.py` and re-verified end-to-end
  in `test_admin_browse_asgi.py`.

---

## Manual checklist (if applicable)

- [ ] M-001: `docker compose up --build`; sign in as admin, click "Total businesses" and
  "Total reviews" tiles from `/admin`, confirm navigation and data load.
- [ ] M-002: As a signed-in customer or merchant, attempt to load `/admin/businesses`
  and `/admin/reviews` directly by URL — confirm redirect, not a 500/blank page.
- [ ] M-003: Swagger `/docs` — confirm `GET /businesses/admin/all` and
  `GET /reviews/admin/all` match the implemented routes/response shapes.

Not executed this pass (no Docker/isolated-DB environment available here); flagged for
PM/Builder to run before final acceptance, consistent with prior slices in this
environment (see Known environment constraints in the slice handoff).

---

## Environment

- `AI_PROVIDER=mock` — n/a, no AI-provider code touched by this slice (existing
  `ai_analysis` pass-through only).
- `docker compose up --build` — not run in this session (no isolated local DB); backend
  RBAC/happy-path ASGI+DB tests added for CI, not executed locally, per
  `backend/tests/CLAUDE.md`.
