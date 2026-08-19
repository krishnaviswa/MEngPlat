# TP-S-087: Support contact in footer and admin — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-087 |
| **Author** | Tester |
| **Date** | 2026-08-19 |

---

## Scope

Public support contact via footer, `/support`, `GET /support/contact`, and a small admin Support block. Navbar must stay unchanged.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend API | pytest | Public contact payload |
| Frontend | RTL | Footer, `/support`, admin Support block, Navbar has no `/support` |
| Integration | Manual | Footer mailto on a public page |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `Footer.test.tsx` Support column + mailto + `/support` |
| 2 | Automated | `app/support/__tests__/page.test.tsx` email + query copy |
| 3 | Automated | `admin/page.test.tsx` Support heading + links |
| 4 | Automated | `Navbar.test.tsx` no `/support` link |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Unauthenticated | none | `GET /api/v1/support/contact` 200 |

---

## Manual checklist

- [ ] M-087-1: Footer Support visible on home without using Navbar.
