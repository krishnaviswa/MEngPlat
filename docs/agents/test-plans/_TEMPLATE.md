# TP-S-XXX: [Title] — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-XXX |
| **Author** | Tester |
| **Date** | YYYY-MM-DD |

---

## Scope

Brief description of what this plan covers.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend API | pytest | Auth, RBAC, happy path, errors |
| Frontend | RTL | Interactive components |
| Integration | Manual | Docker smoke, role flows |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `test_*.py::test_name` |
| 2 | Manual | M-001 |
| 3 | Automated | `Component.test.tsx` |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Unauthenticated | none | 401 |
| Wrong role | customer | 403 |

---

## Edge cases

-

---

## Manual checklist (if applicable)

- [ ] M-001: …
- [ ] M-002: …

---

## Environment

- `AI_PROVIDER=mock`
- `docker compose up --build`
