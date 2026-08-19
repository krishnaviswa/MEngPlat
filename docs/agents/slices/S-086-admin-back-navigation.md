# Slice: S-086 — Consistent admin back navigation

| Field | Value |
|-------|-------|
| **Slice ID** | S-086 |
| **Phase** | 5 Polish |
| **Status** | Accepted |
| **Role(s)** | admin |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As an** admin on a drill-down screen
**I want** a consistent back link to the parent admin view
**So that** I can return to the panel without using the browser Back button

---

## Acceptance criteria

1. **Given** I am signed in as admin on `/admin/whatsapp`, **when** the page loads, **then** a back link labeled toward the Admin panel is visible and goes to `/admin`.
2. **Given** I am on `/admin/reviews`, **when** the page loads, **then** the same back affordance goes to `/admin`.
3. **Given** I am on `/admin/businesses`, **when** the page loads, **then** the back link goes to `/admin`.
4. **Given** I am on `/admin/businesses/{id}`, **when** the page loads, **then** the back link goes to `/admin/businesses` (the list I drilled in from).
5. **Given** a customer or merchant, **when** they hit these URLs, **then** `RequireAuth role="admin"` still denies access as today.

---

## UX notes

- Shared `AdminBackLink` component; do not restyle queues.
- AI disclaimer required? no

---

## Out of scope

- E2 / G1 admin landing redesign
- S-084 / S-085

---

## Dependencies

- None (D is already Accepted)

---

## Definition of done (PM)

- [x] All AC verified in test report (Tester chat)
- [x] UX matches notes above
- [x] README §8 if a new shared pattern is listed
- [x] PM Status set to **Accepted** (after Tester)

---

## Technical specification (Architect)

### API contract

No API changes.

### RBAC matrix

| Action | customer | merchant | admin |
|--------|----------|----------|-------|
| See back link on admin drill-downs | — | — | yes (page already admin-gated) |

### Data model impact

- [x] None

### Cache / side effects

None.

### Frontend

- **Route:** existing `/admin/*` drill-downs
- **Rendering:** CSR (existing pages)
- **Components:** new `AdminBackLink.tsx`

### Architect checklist

- [x] API contract defined
- [x] RBAC matrix complete
- [x] Data model impact documented
- [x] Cache invalidation considered
- [x] Uses AI/storage abstractions where applicable
- [x] ERD/API/FLOWS updates noted

### Risks / tradeoffs

None.

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-19 | PM | Created slice |
| 2026-08-19 | Architect | Spec filled |
| 2026-08-19 | Builder | Implementation |
| 2026-08-19 | Tester | TR-S-086 Ship |
| 2026-08-19 | PM | Status Accepted |
