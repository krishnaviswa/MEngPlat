# TP-S-088: Customer support tickets — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-088 |
| **Author** | Tester |
| **Date** | 2026-08-19 |

---

## Scope

Guest and authenticated ticket create, mine list, admin queue/respond, RBAC.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend API | pytest | 201 guest, optional business_id, 401 mine, 403 admin, admin PATCH |
| Frontend | RTL | `SupportTicketForm`, `AdminSupportQueue` |
| Integration | Manual | Guest + logged-in submit; admin respond |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `test_guest_can_create_support_ticket` + form submit |
| 2 | Automated | valid `business_id` stored; blank omitted; unknown 400 |
| 3 | Automated | form loads `myTickets` when token present; shows status + admin_response |
| 4 | Automated | admin queue lists tickets and PATCH status/response |
| 5 | Automated | customer GET/PATCH admin tickets 403 |
| 6 | Automated | anonymous GET mine 401 |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Create ticket | anon | 201 |
| List mine | none | 401 |
| Admin list/respond | customer / merchant | 403 |
| Admin list/respond | admin | 200 |

---

## Manual checklist

- [ ] M-088-1: Submit as guest and as logged-in user; admin writes a response.
