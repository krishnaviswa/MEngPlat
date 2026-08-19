# TP-S-093: Mobile admin queue polish — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-093 |
| **Author** | Tester |
| **Date** | 2026-08-19 |

## Scope

Flutter port of M-81–M-86. No new backend.

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Mobile | flutter_test | queue, search, errors, back, merchant banner |
| RBAC | existing admin_route_gating_test | unchanged gate |

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1–3 | A | `admin_home_screen_test.dart` merge + start/return |
| 4 | A | processing badge on all-businesses or home |
| 5 | A | `merchant_dashboard_screen_test.dart` under review |
| 6–7 | A | `admin_users_screen_test.dart` |
| 8–10 | A | `admin_categories_screen_test.dart` |
| 11 | A | admin back key on drill-down |
| 12 | A | existing route gating |
| 13 | A | no AI suggestion copy on new labels |
