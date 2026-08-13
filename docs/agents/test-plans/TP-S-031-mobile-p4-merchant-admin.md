# TP-S-031: Mobile P4 merchant + admin — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-031 |
| **Author** | Tester |
| **Date** | 2026-08-14 |

---

## Scope

Replace `/merchant` and `/admin` stubs. Merchant dashboard (M-50–M-54) and admin queues/browse (M-57–M-60). Skip M-55/M-56.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Mobile | flutter_test | Dashboard empty/stats/insights, editor validation, admin stats |
| Backend | — | Unchanged |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `merchant_dashboard_screen_test.dart` dashboard not placeholder |
| 2 | Automated | multi-business selector |
| 3 | Automated | empty state + create CTA |
| 4 | Automated | tiles present |
| 5–7 | Manual | tile scroll / status navigation |
| 8 | Automated | sentiment breakdown key |
| 9 | Automated | AI disclaimer |
| 10 | Manual | refresh AI |
| 11–12 | Automated | `review_card_test.dart` S-031 reply composer |
| 13 | Automated | `business_editor_screen_test.dart` validation + create |
| 14 | Manual | edit save |
| 15 | Automated | router `startsWith('/merchant')` (app_shell merchant landing) |
| 16 | Automated | `admin_home_screen_test.dart` platform stats |
| 17–18 | Manual | approve/suspend/moderate |
| 19–20 | Manual | all businesses / all reviews lists |
| 21 | Automated | existing role redirect |
| 22 | Automated | `app_shell_test.dart` AC13 + unchanged tab keys |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Customer `/merchant` | customer | redirect Explore |
| Merchant `/admin` | merchant | redirect `/merchant` |
| Admin dashboard APIs | admin | 200 |

---

## Manual checklist

- [ ] M-001: Switch businesses; stats refresh
- [ ] M-002: Reply from dashboard attaches on card
- [ ] M-003: Admin approve pending listing
- [ ] M-004: Login and business detail still hide bottom nav

---

## Environment

- Tests authored; **`flutter analyze` / `flutter test` not executed this session**
