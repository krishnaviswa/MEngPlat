# Slice: S-034 — Admin platform analytics + role-table truth

| Field | Value |
|-------|-------|
| **Slice ID** | S-034 |
| **Phase** | 4 Dashboards |
| **Status** | Specified |
| **Role(s)** | admin |
| **Owner** | PM / 2026-08-15 |

---

## User story

**As an** admin responsible for the health of the platform
**I want** real trend analytics on `/admin` (not five snapshot COUNT tiles), plus the category manager and account-suspend tools README §2 already promises
**So that** I can see how the platform is growing over time, add browse categories without a developer, and deactivate abusive customer/merchant accounts — closing the remaining S-007 Partial after S-021's browse work

---

## Acceptance criteria

1. **Given** I am signed in as admin on `/admin`, **when** platform analytics load, **then** I see time series (daily **or** weekly buckets — either is acceptable) for: new users, businesses moving pending → approved, new reviews, and new reports. Each series is derived from stored timestamps in the database, not from a static/mock series.
2. **Given** the existing stat tiles on `/admin` (S-021/S-022 already make some of those tiles scroll/navigate), **when** I view the page, **then** the time-series chart row sits **under** those tiles — tiles stay the snapshot row; charts do not replace them or sit above them.
3. **Given** I am signed in as admin, **when** I open the category admin surface and submit a new category name, **then** the category is created and appears in the admin category list. (Create + list APIs already exist — `POST /businesses/categories` and the existing category list; this slice ships the **admin UI**. Architect decides routing/layout, not a new product capability.)
4. **Given** I am signed in as admin viewing a non-admin user (customer or merchant), **when** I suspend that account, **then** `is_active` is set to false; **when** I reactivate that same account, **then** `is_active` is set to true. (The field already exists; only business suspend is wired today.)
5. **Given** a customer or merchant account has been suspended (`is_active` false), **when** that user attempts to log in, **then** login is rejected — they cannot obtain a session.
6. **Given** I am signed in as admin, **when** I attempt to suspend my own account, **then** the action is refused. **Given** the target user is another admin, **when** I attempt to suspend them, **then** the action is also refused — suspend/reactivate applies only to non-admin users.
7. **Given** I am not an admin (anonymous, customer, or merchant), **when** I attempt to load `/admin` analytics, the category admin surface, or the user suspend/reactivate surface (or the APIs behind them), **then** access is denied (redirect to login or 403) — same protection as the rest of `/admin`.
8. **Given** a brand-new platform with no (or insufficient) history for a series, **when** I view the analytics charts, **then** I see an empty-chart state (dashed empty treatment consistent with admin queues) — never an error, blank crash, or broken chart library message.
9. **Given** platform analytics are shown on `/admin`, **when** I read labels, titles, and empty copy, **then** none of it presents AI output as platform analytics. Counts and trends are operational facts (users, businesses, reviews, reports). Any existing review-level AI suggestion badges elsewhere on admin stay suggestion-language only and are not mixed into these charts.

---

## UX notes

- **Screens / routes:** `/admin` remains the home for platform analytics (tiles + new chart row). Add small **category** and **user** admin surfaces as needed (in-page sections, drawers, or short `/admin/...` pages — Architect/Builder choice) so an admin can list/add categories and suspend/reactivate users without leaving the admin area. Natural entries: a control near analytics / nav, and/or making the existing "Total users" tile a doorway into user admin (S-021 AC 9 left that tile static on purpose; this slice **replaces** that deferral).
- **Components to reuse:** existing `/admin` page shell, `StatCard` / clickable-tile pattern from S-021/S-022 (do not restyle the snapshot row), `PendingBusinessQueue` / `ReportedReviewsQueue` list-row and dashed empty-state patterns, `Badge`, `Dashboard`/`Card` shells. Prefer a simple chart that matches current admin visual density over a new analytics product look.
- **Empty states / errors:** empty series → empty chart, not an error (AC 8); empty category list → "No categories yet" (or equivalent queue-style copy) plus a way to add the first one; user list with no matching rows → empty list, not an error. Network failures stay inline, matching existing admin queue `error` handling.
- **AI disclaimer required?** No new AI surface. AC 9 forbids treating AI as platform analytics. Do not add an "AI insights" block to these charts. If a review row elsewhere still shows sentiment, keep existing "suggestion" language — that is not this slice's analytics.

---

## Out of scope

- **Merchant time-series / merchant dashboard charts** — tracked separately as S-033. This slice is admin-only.
- Payments, billing, or payout analytics.
- Email / notification when an account is suspended or a category is created.
- Penetration testing, Sentry, or other observability product work.
- Changing business approve/suspend in `PendingBusinessQueue` (already shipped). This slice is **user** `is_active`, not a redesign of business status.
- Category edit/delete, category reorder, or merchant-facing category-create UI — admin create + list is enough to match README §2 "manage categories."
- Role changes (promote/demote to admin), password reset by admin, or deleting users.
- Pagination/sort/filter polish beyond a basic list that makes suspend and category-add usable.
- Replacing the five COUNT tiles — they stay; charts sit under them (AC 2).

---

## Dependencies

- **S-007** (Admin moderation + platform analytics) — status **Partial**. This slice is intended to close the remaining gap after S-021 browse (analytics still snapshot-only; no category manager UI; no user-suspend UI).
- **S-021** — **Accepted**. `/admin` tiles, All businesses / All reviews browse, and scroll-to-queue behavior must stay; this slice adds a chart row **under** those tiles and may finally wire "Total users" as a user-admin entry.
- Not blocking: S-022 (merchant tile interactivity) — cited only as the sibling pattern for interactive tiles; do not change merchant dashboard here.
- S-033 (merchant time-series) is a sibling, not a prerequisite — do not couple the two chart implementations in the product brief.

---

## Definition of done (PM)

- [ ] All AC verified in test report
- [ ] UX matches notes above
- [ ] Documented in `README.md` §7 API reference / §8 Frontend guide if new patterns
- [ ] README §2 / §14 (and §12 web ↔ mobile parity if these admin surfaces are user-facing web) updated when the S-007 Partial gap actually closes
- [ ] PM Status set to **Accepted**

---

## Technical specification (Architect)

Logic lives in `services/` (thin routers). All new REST under `/api/v1`. `require_roles(UserRole.ADMIN)` on every admin-only handler. No AI/storage/maps in this slice.

### API contract

Keep existing snapshot tiles. Add series + user admin. **No new category endpoints** — list/create already exist.

| Method | Path | Auth | Request | Response |
|--------|------|------|---------|----------|
| GET | `/dashboard/admin/platform` | Admin JWT | — | **Unchanged** `PlatformAnalytics`: `total_users`, `total_businesses`, `pending_businesses`, `total_reviews`, `reported_reviews` (five COUNT tiles). Do not extend this schema. |
| GET | `/dashboard/admin/platform/series` | Admin JWT | Query: `granularity` = `day` \| `week` (default `day`); `days` int default `90`, min `1`, max `365`. Register this **static** path next to `/platform` (never under a catch-all). | `PlatformAnalyticsSeries` (below). 401 unauthenticated, 403 non-admin, 422 invalid query. |
| GET | `/businesses/categories/all` | Public | — | **Existing** `list[CategoryResponse]`. Admin UI uses this for the category list. |
| POST | `/businesses/categories` | Admin JWT | **Existing** `CategoryCreate`: `name`, `slug` required; `description`, `icon` optional. | **Existing** `201 CategoryResponse`. 401/403 as today. Duplicate name/slug → 409 if unique constraint surfaces (Builder: map IntegrityError; do not silently 500). |
| GET | `/admin/users` | Admin JWT | Query: `page` default `1`, `page_size` default `20` cap `100` (same as `GET /businesses/admin/all`). Optional `q` substring on `email` or `full_name` (case-insensitive) is allowed if cheap; not required for AC. | `list[UserResponse]` newest `created_at` first. **Never** serialize `totp_secret`, `hashed_password`, or `google_sub`. `UserResponse` already omits those; do not add a parallel schema unless needed to drop extra PII. 401/403. |
| POST | `/admin/users/{id}/suspend` | Admin JWT | Path UUID. Empty body. Static `/suspend` and `/reactivate` suffixes (no overlapping `/{id}` GET required). | `200 UserResponse` with `is_active=false`. 404 unknown id. **400** if `id == caller.id` or `target.role == admin`. Idempotent: already inactive → `200` same user, **no** extra AuditLog. |
| POST | `/admin/users/{id}/reactivate` | Admin JWT | Path UUID. Empty body. | `200 UserResponse` with `is_active=true`. 404 unknown id. **400** if self or `role=admin`. Idempotent: already active → `200`, no extra AuditLog. |

**New Pydantic (`PlatformAnalyticsSeries`):**

```json
{
  "granularity": "day",
  "days": 90,
  "series": {
    "new_users": [{"bucket": "2026-05-17", "count": 2}],
    "businesses_approved": [{"bucket": "2026-05-17", "count": 1}],
    "new_reviews": [{"bucket": "2026-05-17", "count": 4}],
    "new_reports": [{"bucket": "2026-05-17", "count": 0}]
  }
}
```

- `bucket`: UTC calendar date `YYYY-MM-DD` (week granularity: Monday of that ISO week via PostgreSQL `date_trunc('week', …)`).
- Zero-fill every bucket in `[now - days, now]` so the array length is stable. Frontend treats **all four series all zeros** as empty-chart (AC 8), not a library error.
- Aggregation in `app/services/` (e.g. `platform_analytics.py` or extend dashboard service). Router only validates query params and RBAC.

**Honest series sources (no `Business.updated_at`):**

| Series key | Timestamp source | Notes |
|------------|------------------|--------|
| `new_users` | `User.created_at` | Registrations per bucket. |
| `businesses_approved` | `AuditLog.created_at` where `action='approve'` and `entity_type='business'` | This is the **pending → approved** event. `POST /businesses/{id}/approve` already writes that row. **Do not** group `Business.status=approved` by `updated_at` (lossy: any later edit moves the bucket). Seeded/historical approvals with **no** audit row will not appear — current pending COUNT stays on the tile. Optional extra `businesses_created` (`Business.created_at`) is **out of the four AC series**; do not add unless UI labels it separately. |
| `new_reviews` | `Review.created_at` | All statuses (create time, not hide/remove). |
| `new_reports` | `ReviewReport.created_at` | Report submissions, not current `Review.status=reported` stock. |

**User admin module:** new `app/routers/admin.py` prefix `/admin`, mounted in `main.py` at `/api/v1`. Service `app/services/admin_users.py` (list, suspend, reactivate + AuditLog). Do not put this logic in the router.

**AuditLog on user actions** (same table; no schema change):

| Action | `action` | `entity_type` | `entity_id` | `details` |
|--------|----------|---------------|-------------|-----------|
| Suspend (state actually changed) | `suspend` | `user` | user UUID string | optional `{ "previous_is_active": true }` |
| Reactivate (state actually changed) | `reactivate` | `user` | user UUID string | optional `{ "previous_is_active": false }` |

`admin_id` = acting admin. Distinct from business `action=suspend` / `entity_type=business`.

**Login (already implemented — do not rework):** password login and Google sign-in return 403 `"Account suspended"` when `is_active` is false; `get_current_user` / refresh reject inactive. AC 5 is satisfied by existing `auth.py` + `dependencies.py` once `is_active` is flipped. Existing access tokens fail the next authenticated call (inactive check); no Redis search-cache work.

**Errors:** 401 missing/invalid token; 403 wrong role; 400 self or admin target; 404 unknown user; 422 bad query. Never return TOTP secrets or stack traces.

### RBAC matrix

| Action | anonymous | customer | merchant | admin |
|--------|-----------|----------|----------|-------|
| GET `/dashboard/admin/platform` | 401 | 403 | 403 | 200 |
| GET `/dashboard/admin/platform/series` | 401 | 403 | 403 | 200 |
| GET `/businesses/categories/all` | 200 | 200 | 200 | 200 |
| POST `/businesses/categories` | 401 | 403 | 403 | 201 |
| GET `/admin/users` | 401 | 403 | 403 | 200 |
| POST `/admin/users/{id}/suspend` | 401 | 403 | 403 | 200 / 400 self-or-admin / 404 |
| POST `/admin/users/{id}/reactivate` | 401 | 403 | 403 | 200 / 400 self-or-admin / 404 |
| CSR `/admin` (analytics, categories panel, users panel) | redirect login (`RequireAuth`) | 403 / redirect | 403 / redirect | render |
| Suspend/reactivate **another admin** | — | — | — | 400 |
| Suspend/reactivate **self** | — | — | — | 400 |
| Suspend/reactivate customer or merchant | — | — | — | 200 |

Frontend: existing `RequireAuth role="admin"` on `/admin`. New `/admin/users` or `/admin/categories` pages (if added) use the same guard.

### Data model impact

- [x] None  [ ] Extend existing  [ ] New table(s)

**Details:** No migration. Series reads `users.created_at`, `reviews.created_at`, `review_reports.created_at`, `audit_logs` (`action`, `entity_type`, `created_at`). User suspend uses existing `users.is_active`. Categories unchanged (`categories` + existing POST). ERD: no update. README §5: no new tables; Builder may note user suspend in §9 / §6 when shipping.

### Cache / side effects

- Snapshot COUNTs and series: **no Redis**. Live SQL each request.
- User suspend/reactivate: **do not** `cache_delete_pattern("search:*")`. Search keys are business listings, not account activity. Suspended merchants keep existing business rows until separately business-suspended (out of scope).
- Category create: leave as today (if create does not already bust search, do not add it in this slice unless Builder finds category filter cache depends on it — current `POST /categories` does not invalidate).
- AuditLog rows on user suspend/reactivate (state change only).
- No email/notification (PM out of scope).
- No AI provider calls.

### Frontend

- **Route:** keep CSR `frontend/src/app/admin/page.tsx`. Add in-page sections (preferred): chart row **immediately under** the existing five tiles (AC 2); then `#admin-categories` and `#admin-users` panels. Optional extra routes `/admin/categories` or `/admin/users` only if the panels overflow — not required. Wire **Total users** tile to scroll to `#admin-users` (replaces S-021 static-tile deferral). Optional small nav/control to `#admin-categories`.
- **Rendering:** CSR (`"use client"`) — charts, forms, `apiFetch` + localStorage JWT. Same as current `/admin`.
- **Components (reuse first):** page shell, `StatCard` / clickable-tile pattern (do not restyle snapshot row), dashed empty-state from queues, `Badge`, `RequireAuth`. Reuse `Charts` (Recharts) or a thin wrapper with `{ name, value }` per series; empty = dashed empty copy, never a Recharts crash. New small presentational panels e.g. `AdminCategoryPanel`, `AdminUserPanel` under `frontend/src/components/admin/`.
- **Category UI:** GET `/api/v1/businesses/categories/all` + POST `/api/v1/businesses/categories` with `name` + `slug` (existing `CategoryCreate`; slugify in the form if needed). Empty list: “No categories yet” + add control.
- **User UI:** paginated GET `/admin/users`; Suspend / Reactivate by `is_active`. Hide those buttons for `role=admin` and for the signed-in admin’s own row. Show `is_active` clearly. Network errors: inline, same as queues.
- **Copy:** operational facts only (AC 9). No “AI insights” on these charts. Existing review sentiment badges elsewhere stay suggestion language.

### Flow

```mermaid
sequenceDiagram
    participant Admin
    participant UI as AdminPage CSR
    participant API as FastAPI
    participant Svc as services
    participant DB as PostgreSQL

    Admin->>UI: GET /admin
    UI->>API: GET /dashboard/admin/platform
    API-->>UI: five COUNT tiles
    UI->>API: GET /dashboard/admin/platform/series?granularity=day&days=90
    API->>Svc: aggregate buckets
    Svc->>DB: User.created_at, AuditLog approve+business, Review.created_at, ReviewReport.created_at
    Svc-->>API: zero-filled series
    API-->>UI: PlatformAnalyticsSeries
    Note over UI: charts under tiles; all-zero → empty chart

    UI->>API: GET /businesses/categories/all
    API-->>UI: categories
    Admin->>UI: create category
    UI->>API: POST /businesses/categories
    API-->>UI: 201 CategoryResponse

    Admin->>UI: open users (Total users tile)
    UI->>API: GET /admin/users?page=1
    API-->>UI: UserResponse[] (no TOTP secrets)
    Admin->>UI: suspend customer/merchant
    UI->>API: POST /admin/users/{id}/suspend
    API->>Svc: reject if self or admin else is_active=false + AuditLog
    API-->>UI: 200 UserResponse
    Note over API: login/refresh/get_current_user already reject inactive
```

### Architect checklist

- [x] API contract defined (README §7 table style; Builder updates §7 when shipping)
- [x] RBAC matrix complete (all roles + anonymous)
- [x] Data model impact documented (none; no ERD change)
- [x] Cache invalidation considered (none required for counts/series/user `is_active`)
- [x] Uses AI/storage abstractions where applicable (N/A — no AI/storage/maps)
- [x] ERD/API/FLOWS updates noted (Builder: README §7 new rows; §6 admin flow + series; §9 audit + account suspend; §12 M-62/M-63/M-64; §14 S-007; §2 already distinguishes counts-today vs S-034 UI)

### Risks / tradeoffs

- **Approve series vs listing stock:** `businesses_approved` is audit events, not “how many businesses are approved today.” Pre-audit seed approvals under-count. Document in UI subtitle (e.g. “Approvals logged”) rather than inventing `updated_at` buckets.
- **Week vs day:** AC allows either; API supports both, UI may default to `day` / 90 days with a simple toggle.
- **In-page vs extra routes:** one `/admin` page avoids new nav; lists stay basic (PM out of scope for polish).
- **No ADR:** reuses `AuditLog`, `User.is_active`, `require_roles`, existing category routes. Not a new auth or schema pattern.
- **Sibling S-033:** do not share merchant-dashboard chart product code beyond existing `Charts` if it stays generic `{name,value}`.
- **JWT after suspend:** inactive users cannot refresh or call authenticated APIs; password/Google login already 403. Tokens are not globally revoked in Redis (acceptable; next use fails).

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-034-*.md`
- Test report: `docs/agents/test-reports/TR-S-034-*.md`
- ADR: none (reuse AuditLog + `User.is_active`; no schema/auth/AI change)

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-15 | PM | Created slice. Admin platform analytics (time series under existing `/admin` tiles) plus category create/list UI and user suspend/reactivate (`is_active`) to match README §2 and close remaining S-007 Partial after S-021. 9 numbered AC, UX notes, out of scope (incl. S-033 merchant charts, payments, email, pentest, Sentry). Status: Draft. Architect section left as template. |
| 2026-08-15 | Architect | Technical spec: keep `GET /dashboard/admin/platform`; add `GET /dashboard/admin/platform/series` from DB timestamps (approvals via AuditLog `approve`+`business`, not `updated_at`); no new category API; `GET/POST /admin/users` suspend/reactivate with 400 self-or-admin + AuditLog; CSR `/admin` panels; cache none; README §7/§9/§12 M-62–M-64/§14 on build. Status: Specified. Checklist complete. |
