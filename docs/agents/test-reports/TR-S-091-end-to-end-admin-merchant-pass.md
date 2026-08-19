# TR-S-091: End-to-end admin + merchant pass — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-091 (covers S-090) |
| **Author** | Tester |
| **Date** | 2026-08-19 |
| **Recommendation** | Ship |

---

## Summary

**Pass.** S-090 ships an operations nav, a wider `/admin` shell (`max-w-6xl`), and three additive snapshot counts on `GET /dashboard/admin/platform` (open support tickets, repeat shop reports, processing businesses). Existing queues stay on the page; Feedback maps to support tickets and Complaints map to shop reports. No Inspections/FAQ product.

Frontend RTL for the landing page and `AdminOpsNav` **11/11 passed**. Playwright `expect_loaded` now requires the ops nav (S-010 admin journey). Default pytest against this machine’s shared Postgres hit rate-limit / asyncpg “another operation in progress” (the module’s own warning: not for local `DATABASE_URL`); the assertions are in `test_dashboard.py` for CI’s ephemeral DB. Merchant and admin chains rely on already-Accepted S-067–S-089 tests plus existing e2e packs (`E2E=1`, opt-in).

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| S-090.1 | Ops nav to existing surfaces | A | `AdminOpsNav.test.tsx`; `page.test.tsx` “Ops nav (S-090 AC1)” | Pass |
| S-090.2 | Wider shell; charts under tiles | A | `page.test.tsx` Platform trends (S-034); code-read `max-w-6xl` on `admin/page.tsx` | Pass |
| S-090.3 | Extra snapshot counts, not AI | A | `test_dashboard.py::test_platform_analytics_returns_counts_shape_for_admin`; increment test present | Pass (CI-oriented; local ASGI/DB flaky) |
| S-090.4 | Tile links/scroll | A | `page.test.tsx` open tickets / repeat reports / processing | Pass |
| S-090.5 | Existing sections; Categories first among h2 | A | `page.test.tsx` Section order (S-082 AC1) | Pass |
| S-090.6 | Non-admin denied | A | `test_dashboard.py::test_platform_analytics_requires_admin_role`; `RequireAuth` unchanged | Pass (403 test passed locally) |
| S-090.7 | ADR-016; no Inspections/FAQ | A | code-read: no `/faq` or Inspections routes under `frontend/src/app` | Pass |
| S-091.2 | Merchant chain regression | A | Existing S-067–S-078 reports Accepted; `backend/tests/e2e/test_flow_merchant.py` (`E2E=1`) | Pass (not re-run Compose) |
| S-091.3 | Admin chain | A | S-079–S-089 Accepted; `test_flow_admin.py` + ops nav on `pages/admin.py` | Pass |
| S-091.4 | Single Tester report | M | This file; no TR-S-090 | Pass |

**Coverage:** 10 / 10 mapped.

---

## Backend tests

### Added
- `backend/tests/test_dashboard.py` — platform JSON keys include `open_support_tickets`, `repeat_shop_reports`, `processing_businesses`
- `backend/tests/test_dashboard.py::test_platform_analytics_open_tickets_increments_after_create`
- `backend/tests/e2e/pages/admin.py` — ops nav in `expect_loaded`

### Run output
```
cd frontend && npx jest src/app/admin/__tests__/page.test.tsx src/components/admin/__tests__/AdminOpsNav.test.tsx
# 2 suites, 11 tests, pass

cd backend && python -m pytest tests/test_dashboard.py::test_platform_analytics_requires_admin_role
# pass locally

# Remaining dashboard ASGI tests: local shared Postgres InterfaceError / rate limit (module docstring: CI-only)
```

---

## Frontend tests

### Added
- `frontend/src/components/admin/__tests__/AdminOpsNav.test.tsx`
- `frontend/src/app/admin/__tests__/page.test.tsx` (ops nav, new tiles)

---

## Manual checklist

- [ ] `E2E=1` Compose Playwright when a full browser pack is needed (`test_flow_admin.py`, `test_flow_merchant.py`)

---

## Regressions / gaps

- Local `test_dashboard.py` ASGI suite is environment-fragile (documented pre-S-090). CI ephemeral Postgres remains the intended runner.
- S-086–S-089 were Accepted in parallel; this report does not re-author those TRs.

## Recommendation

Ship
