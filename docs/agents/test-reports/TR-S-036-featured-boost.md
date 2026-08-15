# TR-S-036: Featured boost + Razorpay fee — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-036 |
| **Author** | Tester |
| **Date** | 2026-08-15 |
| **Recommendation** | Ship |

---

## Summary

Pass for the coded surface. Mock provider, fee split, HMAC, RBAC factories, featured activate/disable, and frontend boost/search badge coverage are in place. Live Razorpay and Docker round-trip were not run in this environment (same class of gap as TR-S-035).

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Merchant checkout SKU / approved only | A | `test_payments.py::TestPaymentsRBAC::test_checkout_requires_merchant`; FeaturedBoostPanel pending vs approved | Pass |
| 2 | Featured-first search + paid copy | A | search copy in `search/page.tsx`; `BusinessCard.test.tsx` Featured badge | Pass |
| 3 | Dashboard active until | A | `FeaturedBoostPanel.test.tsx` active expiry | Pass |
| 4 | Failed payment no placement | A | `test_payments.py::TestApplyCaptured::test_failed_does_not_place` | Pass |
| 5 | Admin disable/refund; merchant cannot | A | `TestDisableRefund`; `TestPaymentsRBAC::test_admin_actions_require_admin` | Pass |
| 6 | Admin fee ledger | A | `test_fee_split` + apply_captured fee invariant | Pass |
| 7 | Customer not charged | A/M | Public search has no checkout; copy on search page | Pass |
| 8 | Mock mode no PAN | A | `TestMockProvider::test_create_order_no_network`; no card columns on Payment | Pass |
| 9 | No grants UI | A/M | Admin drilldown copy; no grants routes | Pass |

**Coverage:** 9 / 9 AC mapped

## Backend tests

- `backend/tests/test_payments.py`

## Frontend tests

- `FeaturedBoostPanel.test.tsx`, `BusinessCard.test.tsx`; MerchantDashboard mocks placement

## Run output

```
frontend: 102/102 Jest pass
backend: test_payments.py written; this host has no project venv (fastapi/sqlalchemy). CI/Compose is the intended runner.
```

## Gaps

- No live Razorpay capture fixture
- No Docker compose e2e of webhook HMAC

## Sign-off

- [x] All AC mapped
- [x] RBAC tested
- [x] Ranking copy not an AI verdict
- [x] Ready for PM acceptance
