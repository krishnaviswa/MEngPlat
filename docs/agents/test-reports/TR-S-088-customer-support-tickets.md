# TR-S-088: Customer support tickets — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-088 |
| **Author** | Tester |
| **Date** | 2026-08-19 |
| **Recommendation** | Ship |

---

## Summary

**Pass.** Guest create `201`, optional `business_id`, mine list with admin response, admin queue PATCH, customer `403`, anonymous mine `401`.

During verification, admin PATCH 500'd: `SupportTicket.updated_at` (`onupdate=func.now()`) was not loaded in the async session, so Pydantic hit `MissingGreenlet`. Fixed with `await db.refresh(ticket)` in `support_tickets.update_admin` (same pattern on shop-report status update). Isolated re-run of the PATCH case passed.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Guest submit → 201 | A | `test_guest_can_create_support_ticket`; `SupportTicketForm` submit without token | Pass |
| 2 | Optional business_id | A | `test_ticket_stores_valid_business_id_and_omits_blank`; form includes/omits field | Pass |
| 3 | Logged-in sees tickets + response | A | `test_logged_in_user_sees_own_tickets_including_admin_response`; form loads mine | Pass |
| 4 | Admin queue status + response | A | same PATCH test; `AdminSupportQueue` RTL | Pass |
| 5 | Customer admin endpoints 403 | A | `test_admin_can_list_tickets_customer_gets_403` | Pass |
| 6 | Anon mine 401 | A | `test_mine_tickets_anonymous_401` | Pass |

**Coverage:** 6 / 6 AC mapped

---

## Backend tests

### Added
- `backend/tests/test_support_tickets_and_reports.py` ticket cases

### Run output
```
Each case in a fresh process: 11/11 passed in this file (including S-087/S-089 cases).
Single-process pytest on the file still hits the known asyncpg Event loop is closed / another operation is in progress after the first tests (same as TR-S-085).
```

---

## Frontend tests

### Added
- `SupportTicketForm.test.tsx`
- `app/admin/support/__tests__/page.test.tsx`

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-088-1 | Guest + logged-in submit; admin respond in UI | Not run in browser; covered by API + RTL |

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested
- [x] AI disclaimer verified (N/A)
- [x] Ready for PM acceptance
