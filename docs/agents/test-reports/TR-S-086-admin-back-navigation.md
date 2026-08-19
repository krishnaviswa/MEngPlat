# TR-S-086: Consistent admin back navigation — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-086 |
| **Author** | Tester |
| **Date** | 2026-08-19 |
| **Recommendation** | Ship |

---

## Summary

**Pass.** Shared `AdminBackLink` is on the four listed drill-downs with the correct parent hrefs. Non-admin access is still `RequireAuth role="admin"`.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | `/admin/whatsapp` back to `/admin` | A | `drilldown-back-links.test.tsx` WhatsApp; `AdminBackLink.test.tsx` default href | Pass |
| 2 | `/admin/reviews` back to `/admin` | A | `drilldown-back-links.test.tsx` All reviews | Pass |
| 3 | `/admin/businesses` back to `/admin` | A | `drilldown-back-links.test.tsx` All businesses | Pass |
| 4 | `/admin/businesses/{id}` back to `/admin/businesses` | A | `admin/businesses/__tests__/page.test.tsx` All businesses link; `AdminBackLink.test.tsx` custom href | Pass |
| 5 | customer/merchant denied | A | `drilldown-back-links.test.tsx` customer on WhatsApp; existing `RequireAuth.test.tsx` role mismatch | Pass |

**Coverage:** 5 / 5 AC mapped

---

## Backend tests

None (no API change).

---

## Frontend tests

### Added
- `frontend/src/components/__tests__/AdminBackLink.test.tsx`
- `frontend/src/app/admin/__tests__/drilldown-back-links.test.tsx`
- assertion on existing drill-down page test

### Run output
```
cd frontend && npm test — 58 suites, 324 passed
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-086-1 | Click-through as admin in a browser | Not run in this session; AC covered by RTL |

---

## Regressions

None on S-076–S-085 files owned elsewhere.

---

## Gaps / rework items

None.

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested
- [x] AI disclaimer verified (N/A)
- [x] Ready for PM acceptance
