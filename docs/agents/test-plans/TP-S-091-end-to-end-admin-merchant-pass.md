# TP-S-091: End-to-end admin + merchant pass — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-091 (covers S-090 AC) |
| **Author** | Tester |
| **Date** | 2026-08-19 |

---

## Scope

One batched verification after S-090: operational `/admin` console plus regression of merchant and admin chains. No TR-S-090.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend API | pytest | Platform snapshot new fields, 403 non-admin |
| Frontend | RTL | Ops nav, new tiles, S-082 heading order, S-087 support block |
| Integration | Playwright `E2E=1` | Admin journey + ops nav; merchant journey if Compose up |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| S-090.1 | Automated | `AdminOpsNav.test.tsx`, `page.test.tsx` ops nav |
| S-090.2 | Automated | `page.test.tsx` trends still under tiles; code-read `max-w-6xl` |
| S-090.3 | Automated | `test_dashboard.py` keys + open-ticket increment |
| S-090.4 | Automated | `page.test.tsx` ticket/report links + processing scroll |
| S-090.5 | Automated | `page.test.tsx` S-082 heading order |
| S-090.6 | Automated | `test_dashboard.py::test_platform_analytics_requires_admin_role` |
| S-090.7 | Automated / code-read | ADR-016 tables unchanged; no Inspections/FAQ routes |
| Merchant chain | Automated | existing S-067–S-078 Jest/pytest; `test_flow_merchant.py` when E2E=1 |
| Admin chain | Automated | S-079–S-089 tests + `test_flow_admin.py` ops nav |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| GET `/dashboard/admin/platform` | merchant | 403 |
| `/admin` | customer | RequireAuth deny |

---

## Out of scope

Live Compose required for default pytest. Playwright remains opt-in.
