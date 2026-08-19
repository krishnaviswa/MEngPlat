# Slice: S-089 — Shop / merchant reporting

| Field | Value |
|-------|-------|
| **Slice ID** | S-089 |
| **Phase** | 2 Core |
| **Status** | Accepted |
| **Role(s)** | customer, merchant, admin |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As a** signed-in customer
**I want** to report a shop (not a review) and hear back from admin
**So that** repeat-problem listings are visible to operators

---

## Acceptance criteria

1. **Given** I am signed in on a public business profile, **when** I submit a shop report with a reason, **then** a `business_reports` row is created (`201`).
2. **Given** I am not signed in, **when** I try to report, **then** I am sent to login (UI) and the API returns `401`.
3. **Given** I own the listing (merchant of that shop), **when** I POST a report for it, **then** the API returns `403`.
4. **Given** a shop has 3 or more reports, **when** an admin views the shop-report queue, **then** that shop is flagged as a repeat report.
5. **Given** I reported a shop, **when** I (or admin) post a message on that report, **then** both sides can see the thread on the admin queue and on my `/support` or report-status list.
6. **Given** the existing review-report flow, **when** this slice ships, **then** `POST /reviews/{id}/report` and `ReportedReviewsQueue` are unchanged.

---

## UX notes

- `ReportShopButton` on public profile (client).
- Admin `/admin/business-reports`.
- AI disclaimer required? no

---

## Out of scope

- Merging into review reports
- Auto-suspend shops

---

## Dependencies

- ADR-016; S-088 for `/support` "my reports" listing chrome (optional same page)

---

## Definition of done (PM)

- [x] Tester chat
- [x] README §5/§7/§12
- [x] Not Accepted until Tester

---

## Technical specification (Architect)

### API contract

| Method | Path | Auth | Notes |
|--------|------|------|-------|
| POST | `/api/v1/businesses/{id}/reports` | user | `{ reason }` |
| GET | `/api/v1/business-reports/mine` | user | reporter's reports + messages |
| POST | `/api/v1/business-reports/{id}/messages` | reporter | `{ body }` |
| GET | `/api/v1/admin/business-reports` | admin | includes `report_count`, `is_repeat` (≥3) |
| POST | `/api/v1/admin/business-reports/{id}/messages` | admin | `{ body }` |
| PATCH | `/api/v1/admin/business-reports/{id}` | admin | `{ status }` |

Repeat threshold: 3. `404` unknown. `403` own shop or not the reporter.

### RBAC matrix

| Action | anon | customer | merchant | admin |
|--------|------|----------|----------|-------|
| Report shop | 401 | yes | other shops only | yes |
| Report own shop | — | — | 403 | n/a |
| Admin queue | no | 403 | 403 | yes |

### Data model impact

- [x] New tables: `business_reports`, `business_report_messages`

### Frontend

- `ReportShopButton` on `[slug]/page.tsx`
- `/admin/business-reports`

### Architect checklist

- [x] API contract defined
- [x] RBAC matrix complete
- [x] Data model impact documented
- [x] Cache invalidation considered
- [x] Uses AI/storage abstractions where applicable
- [x] ERD/API/FLOWS updates noted

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-19 | PM / Architect / Builder | Created and implemented |
| 2026-08-19 | Tester | TR-S-089 Ship |
| 2026-08-19 | PM | Status Accepted |
