# Slice: S-087 — Support contact in footer and admin

| Field | Value |
|-------|-------|
| **Slice ID** | S-087 |
| **Phase** | 5 Polish |
| **Status** | Accepted |
| **Role(s)** | customer, merchant, admin |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As a** visitor or signed-in user
**I want** to find how to contact platform support
**So that** I can ask a question without hunting through the admin console

---

## Acceptance criteria

1. **Given** any public page with the site footer, **when** I look at the footer, **then** a Support column (or equivalent links) includes a mailto to the published support email and a link to `/support`.
2. **Given** I open `/support`, **when** the page loads, **then** it shows the support email and explains I can submit a query (form shipped in S-088).
3. **Given** I am an admin on `/admin`, **when** the page loads, **then** a short Support block is visible (email + link to `/support` and to the ticket queue once S-088 exists) without redesigning the whole landing layout.
4. **Given** this slice, **when** implemented, **then** `Navbar.tsx` is unchanged (S-085 owns header/avatar).

---

## UX notes

- Footer only for global chrome. Admin block is a small section, not E2.
- AI disclaimer required? no

---

## Out of scope

- Navbar support link
- Full `/admin` redesign (E2)

---

## Dependencies

- S-088 for the live ticket form on `/support` (this slice can ship the page shell; Builder may land form in the same pass)

---

## Definition of done (PM)

- [x] All AC verified in Tester chat
- [x] README §8 Footer description + §12 tracker row
- [x] Not Accepted until Tester

---

## Technical specification (Architect)

### API contract

| Method | Path | Auth | Notes |
|--------|------|------|-------|
| GET | `/api/v1/support/contact` | Public | `{ email, support_path }` from `Settings.support_email` |

### RBAC matrix

| Action | anonymous | customer | merchant | admin |
|--------|-----------|----------|----------|-------|
| Read contact | yes | yes | yes | yes |

### Data model impact

- [x] None (config only)

### Frontend

- `Footer.tsx` Support column (static mailto matching default email; no Navbar edits)
- `/support` page
- Small section on `/admin`

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
| 2026-08-19 | Tester | TR-S-087 Ship |
| 2026-08-19 | PM | Status Accepted |
