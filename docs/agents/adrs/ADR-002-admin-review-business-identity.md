# ADR-002: Admin business/review browse — dedicated endpoints and shared review→business identity

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-11 |
| **Slice** | S-021 |

---

## Context

The admin panel's "Total businesses"/"Total reviews" stat tiles are currently dead, and
the only existing browse surfaces (`PendingBusinessQueue`, `ReportedReviewsQueue`) show
narrow status-filtered subsets (`pending` only, `reported` only). Admins need to browse
businesses and reviews of *every* status and drill from a review into its business's shop
name and full review history. Separately, `ReportedReviewsQueue` renders reviews via
`ReviewCard` with no business name shown at all — a pre-existing gap the PM asked this
slice to close alongside the new browse views.

Two structural questions had more than one reasonable answer:

1. How to expose "every status, paginated" business/review listings without disturbing
   the existing public/merchant-facing list endpoints, which already have load-bearing
   defaults (`GET /businesses` defaults `status_filter=approved`; `GET
   /reviews/business/{business_id}` always filters `ACTIVE`).
2. How a review payload should carry its parent business's identity (name, for the
   "shop name" requirement), given `ReviewResponse` is already shared by five call sites
   across `backend/app/routers/reviews.py` and `dashboard.py`.

## Decision

1. **Add two new admin-only endpoints** — `GET /api/v1/businesses/admin/all` and
   `GET /api/v1/reviews/admin/all` — rather than overloading the existing public
   `GET /businesses` (`status_filter`) or `GET /reviews/business/{business_id}`
   endpoints with an "all statuses" sentinel value. This leaves the existing,
   already-relied-upon default behavior of those public/merchant-facing endpoints
   completely untouched.
2. **`GET /reviews/admin/all` accepts an optional `business_id` filter** and serves
   *both* the new "All reviews" browse view and the per-business drill-down's review
   history — one endpoint, not two — since both need "every status, admin-only,
   optionally scoped to one business."
3. **`ReviewResponse`** (the schema shared by `create_review`, `update_review`,
   `list_business_reviews`, `list_reported_reviews`, and
   `dashboard.merchant_dashboard`'s `recent_reviews`) **gains a new optional
   `business: BusinessSummary | None` field**, populated by eager-loading the existing
   `Review.business` relationship at every call site — rather than introducing a
   separate `AdminReviewResponse` variant used only by the two new admin endpoints.

## Consequences

### Positive

- Fixes the `ReportedReviewsQueue` "no business name shown" gap for free: it already
  renders `ReviewResponse` via `ReviewCard`; once `list_reported_reviews` eager-loads
  `business`, the field simply starts arriving with no route change.
- One shared review DTO and one `ReviewCard` prop change, instead of a parallel
  "admin review" type/component family.
- Existing public `/businesses` and `/reviews/business/{id}` contracts, and their
  current callers (search-adjacent code, the business detail page), are untouched —
  zero regression risk there.
- `/reviews/admin/all`'s optional `business_id` filter means one query shape, one
  endpoint to test, for two AC (browse-all and drill-down).

### Negative / tradeoffs

- `ReviewResponse.business` is eager-loaded (and present in the payload) even for call
  sites that don't need it — e.g. `GET /reviews/business/{business_id}`, where the
  frontend already knows the business (it's the page it's on). Minor, bounded extra
  query cost (`selectinload(Review.business)` is a cheap indexed join), accepted for
  schema simplicity.
- Five call sites (not one) needed the same one-line `selectinload(Review.business)`
  addition — mechanical, but easy to miss one. Builder should grep `_review_response(`
  to confirm full coverage before considering S-021 done.
- `/businesses/admin/all` and `/reviews/admin/all` are plain paginated lists
  (`page`/`page_size`, no total-count envelope), matching this codebase's only other
  paginated endpoint (`/search/businesses`) rather than introducing a new response
  envelope pattern.

### Follow-ups

- If a future slice adds admin user management (explicitly out of scope for S-021), it
  should reuse this same `/{prefix}/admin/all`, admin-only, paginated, no-envelope
  shape for consistency.
- If `ReviewResponse.business` payload weight becomes a measurable concern on
  high-traffic customer-facing endpoints (e.g. `GET /reviews/business/{business_id}` on
  a popular business detail page), consider an `include_business` opt-in flag at that
  point — not needed today.

## Alternatives considered

1. **Overload existing `GET /businesses` (`status_filter`) and
   `GET /reviews/business/{business_id}`** with an "all"/`None`-means-everything
   sentinel, admin-gated. Rejected: those endpoints are public/semi-public with
   load-bearing defaults (`APPROVED`, `ACTIVE`) already depended on by search,
   business-detail, and customer flows; changing their filter semantics for an admin
   edge case is riskier than adding two new routes.
2. **Separate `AdminReviewResponse(ReviewResponse)`** with `business` only for the two
   new endpoints, leaving the shared `ReviewResponse` untouched. Rejected: this would
   *not* fix the `ReportedReviewsQueue` gap the PM explicitly called out (AC 5), since
   that queue calls the existing `/reviews/reported`, not a new endpoint — it would
   require either forking `ReportedReviewsQueue`/`ReviewCard` per response shape or
   migrating `/reviews/reported` to the new type anyway, which is most of this
   decision's cost without its reuse benefit.
3. **Two separate endpoints** for "All reviews" vs. business drill-down review
   history. Rejected: identical query shape (all statuses, paginated, optionally
   scoped to a business) — one endpoint with an optional filter is less surface area
   to keep in sync.
