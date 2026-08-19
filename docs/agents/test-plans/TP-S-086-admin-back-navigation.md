# TP-S-086: Consistent admin back navigation — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-086 |
| **Author** | Tester |
| **Date** | 2026-08-19 |

---

## Scope

Shared `AdminBackLink` on admin drill-downs. No API changes. S-084/S-085 files are out of scope.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend API | — | None |
| Frontend | RTL | Link href/label on pages + component |
| Integration | Manual | Click-through as admin |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `AdminWhatsAppDraftsPage` + `AdminBackLink` href `/admin` |
| 2 | Automated | `AdminAllReviewsPage` back link `/admin` |
| 3 | Automated | `AdminAllBusinessesPage` back link `/admin` |
| 4 | Automated | drill-down page link `/admin/businesses` |
| 5 | Automated | existing `RequireAuth` role mismatch + page still wraps `role="admin"` |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Customer on `/admin/whatsapp` | customer | Redirect home; no drill-down content |

---

## Manual checklist (if applicable)

- [ ] M-086-1: As admin, each listed drill-down shows ← and returns to the parent view.
