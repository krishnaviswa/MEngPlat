# TP-S-114: Mobile Home density + merchant find-shop — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-114 |
| **Author** | Tester |
| **Date** | 2026-08-20 |

---

## Scope

Alerts tab label, compact mobile Home, List-your-business routing, merchant Account shortcuts, merchant phone/national ID reauth (including Google credential).

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend API | pytest | Reauth methods; merchant NID 401; customer NID without token |
| Frontend | RTL | Merchant national ID save calls reauth then updateMe |
| Mobile | flutter test | Home IA, Alerts, Account tiles, profile reauth sheet |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `app_shell_test.dart` Alerts label |
| 2–5 | Automated | `home_screen_test.dart` |
| 6 | Automated | `app_shell_test.dart` merchant Account tiles |
| 7 | Automated | `merchant_dashboard_screen_test.dart` empty CTA |
| 8–9 | Automated | `backend/tests/test_reauth.py` |
| 10 | Automated | `profile_screen_test.dart` merchant NID reauth sheet |

Default verification: those files only, plus `MerchantNationalIdCard.test.tsx`.
