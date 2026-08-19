# Slice: S-088 — Customer feedback / support tickets

| Field | Value |
|-------|-------|
| **Slice ID** | S-088 |
| **Phase** | 2 Core |
| **Status** | Accepted |
| **Role(s)** | customer, merchant, admin |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As a** customer (or merchant)
**I want** to submit a support query with my name, phone, issue, and optional shop link
**So that** an admin can respond and I can see the ticket status

---

## Acceptance criteria

1. **Given** I am on `/support`, **when** I submit name, phone, and issue, **then** a ticket is created (`201`) even if I am not logged in.
2. **Given** I optionally pick or paste a business id/slug the form supports, **when** I submit, **then** the ticket stores that `business_id` when valid, or omits it when blank.
3. **Given** I am logged in, **when** I open `/support`, **then** I see my previous tickets including status and any admin response.
4. **Given** I am admin on `/admin/support`, **when** the queue loads, **then** I see open/in-progress/resolved tickets and can set status and write a response.
5. **Given** a customer, **when** they call admin list/respond endpoints, **then** they receive `403`.
6. **Given** an anonymous caller, **when** they call `GET /support-tickets/mine`, **then** they receive `401`.

---

## UX notes

- Form on `/support`; admin queue mirrors reported-reviews chrome.
- Empty: "No tickets yet".
- AI disclaimer required? no

---

## Out of scope

- Email/SMS notify on respond (best-effort later)
- E2 dashboard redesign

---

## Dependencies

- S-087 page shell; ADR-016

---

## Definition of done (PM)

- [x] Tester chat maps every AC
- [x] README §5/§7/§12
- [x] Not Accepted until Tester

---

## Technical specification (Architect)

### API contract

| Method | Path | Auth | Request | Response |
|--------|------|------|---------|----------|
| POST | `/api/v1/support-tickets` | optional | `{ name, phone, issue, business_id? }` | ticket |
| GET | `/api/v1/support-tickets/mine` | user | — | list |
| GET | `/api/v1/admin/support-tickets` | admin | `status?` | list |
| PATCH | `/api/v1/admin/support-tickets/{id}` | admin | `{ status?, admin_response? }` | ticket |

Statuses: `open`, `in_progress`, `resolved`. `404` unknown id. `400` invalid business_id.

### RBAC matrix

| Action | anon | customer | merchant | admin |
|--------|------|----------|----------|-------|
| Create ticket | yes | yes | yes | yes |
| List mine | no | own | own | own |
| Admin queue / respond | no | 403 | 403 | yes |

### Data model impact

- [x] New table(s): `support_tickets`

### Cache / side effects

None (not on search cache).

### Frontend

- `/support`, `/admin/support`
- Components: `SupportTicketForm`, `AdminSupportQueue`

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
| 2026-08-19 | Tester | TR-S-088 Ship; refresh ticket after admin PATCH |
| 2026-08-19 | PM | Status Accepted |
