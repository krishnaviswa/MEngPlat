# Slice: S-094 — Mobile support + shop reports (M-87–M-89)

| Field | Value |
|-------|-------|
| **Slice ID** | S-094 |
| **Phase** | 5 Polish |
| **Status** | Accepted |
| **Role(s)** | customer \| merchant \| admin |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As a** customer or merchant on the phone  
**I want** support contact, tickets, and shop reports  
**So that** I do not need the website for help or complaints

**As an** admin  
**I want** ticket and shop-report queues on mobile  
**So that** I can triage feedback away from a desk

---

## Acceptance criteria

1. **Given** Account, **when** I tap Support, **then** I open `/support` with contact email from `GET /support/contact` (native list, not a cloned footer).
2. **Given** `/support` is public, **when** I am signed out, **then** I can still open it and submit a ticket (name, phone, issue ≥10 chars, optional business id).
3. **Given** I submit a valid ticket, **when** `POST /support-tickets` succeeds, **then** I see confirmation with status and a short id prefix.
4. **Given** I am signed in, **when** Support loads, **then** I see my tickets (`GET /support-tickets/mine`) and my shop reports (`GET /business-reports/mine`).
5. **Given** I am admin, **when** I open `/admin/support`, **then** I see tickets oldest-first and can set status `open` / `in_progress` / `resolved` and optional admin response via `PATCH`.
6. **Given** a public business I do not own, **when** I am signed in, **then** I see Report this shop (distinct from review report); reason ≥10 chars; `POST /businesses/{id}/reports`.
7. **Given** I own the listing, **when** I view it, **then** Report this shop is hidden.
8. **Given** I am signed out, **when** I tap Report this shop, **then** I am sent to login.
9. **Given** I am admin, **when** I open `/admin/business-reports`, **then** I see shop reports with repeat flag when count ≥3, and I can update status.
10. **Given** a customer, **when** they open admin support/report routes, **then** they are redirected (existing `/admin` gate).

---

## UX notes

- New `mobile/lib/features/support/`
- Reuse WhatsApp queue patterns for admin lists
- Report shop as a sheet/dialog on business detail

---

## Out of scope

- M-90 ops tiles and M-91 avatar (S-095)
- Report message threads beyond listing existing messages on admin cards if already in the payload

---

## Dependencies

- S-087–S-089 web Accepted; S-093 regen so generated Support APIs exist

---

## Definition of done (PM)

- [x] AC numbered
- [ ] Tester report + README §12 M-87–M-89
- [ ] PM Accepted

---

## Technical specification (Architect)

### API contract

| Method | Path | Auth |
|--------|------|------|
| GET | `/api/v1/support/contact` | public |
| POST | `/api/v1/support-tickets` | optional |
| GET | `/api/v1/support-tickets/mine` | user |
| GET/PATCH | `/api/v1/admin/support-tickets` | admin |
| POST | `/api/v1/businesses/{id}/reports` | user; 403 own shop |
| GET | `/api/v1/business-reports/mine` | user |
| GET/PATCH | `/api/v1/admin/business-reports` | admin |

### RBAC matrix

| Action | anon | customer | merchant | admin |
|--------|------|----------|----------|-------|
| Contact + create ticket | yes | yes | yes | yes |
| My tickets/reports | 401 | yes | yes | yes |
| Report shop | login | yes | not own | yes |
| Admin queues | no | no | no | yes |

### Data model impact

- [x] None

### Cache / side effects

None new.

### Frontend

- **Routes:** `/support` public carve-out; `/admin/support`; `/admin/business-reports`
- **Components:** `SupportScreen`, `AdminSupportQueueScreen`, `AdminBusinessReportsScreen`, `ReportShopButton`

### Architect checklist

- [x] API contract defined
- [x] RBAC matrix complete
- [x] Data model impact documented
- [x] Cache invalidation considered
- [x] Uses AI/storage abstractions where applicable
- [x] ERD/API/FLOWS updates noted

### Risks / tradeoffs

- Optional-auth ticket create uses the same Dio client; unauthenticated POST must not require a token.

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-094-mobile-support-and-shop-reports.md`
- Test report: `docs/agents/test-reports/TR-S-094-mobile-support-and-shop-reports.md`

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-19 | PM | Created |
| 2026-08-19 | Architect | Specified |
| 2026-08-19 | Builder | Support feature + shop reports + admin queues |
| 2026-08-19 | Tester | TR-S-094 Ship |
| 2026-08-19 | PM | Accepted |
