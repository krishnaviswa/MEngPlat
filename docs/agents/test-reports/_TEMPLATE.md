# TR-S-XXX: [Title] — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-XXX |
| **Author** | Tester |
| **Date** | YYYY-MM-DD |
| **Recommendation** | Ship \| Rework |

---

## Summary

Brief outcome. List blockers if Rework.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | | A / M | | Pass / Fail |
| 2 | | | | |

**Coverage:** X / Y AC mapped

---

## Backend tests

### Added
- `backend/tests/test_*.py::test_name`

### Run output
```
cd backend && pytest — [pass/fail summary]
```

---

## Frontend tests

### Added
- `frontend/src/components/__tests__/*.test.tsx`

### Run output
```
cd frontend && npm test — [pass/fail summary]
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | | Pass / Fail |

---

## Regressions

-

---

## Gaps / rework items

1. AC# — description of failure

---

## Sign-off

- [ ] All AC mapped to tests
- [ ] RBAC tested
- [ ] AI disclaimer verified (if applicable)
- [ ] Ready for PM acceptance
