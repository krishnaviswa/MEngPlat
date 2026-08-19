# TR-S-087: Support contact in footer and admin — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-087 |
| **Author** | Tester |
| **Date** | 2026-08-19 |
| **Recommendation** | Ship |

---

## Summary

**Pass.** Footer Support column, `/support` page, public `GET /support/contact`, and a small admin Support block. Navbar has no `/support` link.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Footer Support + mailto + `/support` | A | `Footer.test.tsx` | Pass |
| 2 | `/support` shows email and query copy | A | `app/support/__tests__/page.test.tsx` | Pass |
| 3 | Admin Support block | A | `admin/__tests__/page.test.tsx` Support block | Pass |
| 4 | Navbar unchanged | A | `Navbar.test.tsx` no `/support` link | Pass |

**Coverage:** 4 / 4 AC mapped

---

## Backend tests

### Added
- `backend/tests/test_support_tickets_and_reports.py::test_support_contact_is_public`

### Run output
```
alembic upgrade head — applied m7n8o9p0q1r2
Isolated pytest: test_support_contact_is_public passed
```

---

## Frontend tests

### Added
- `Footer.test.tsx`, `app/support/__tests__/page.test.tsx`, Navbar negative assertion, admin Support section

### Run output
```
cd frontend && npm test — 58 suites, 324 passed
```

S-082 heading-order test was updated to include the new Support `h2` (Categories still first).

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-087-1 | Footer on home | Not run in browser; covered by Footer RTL |

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested (public contact)
- [x] AI disclaimer verified (N/A)
- [x] Ready for PM acceptance
