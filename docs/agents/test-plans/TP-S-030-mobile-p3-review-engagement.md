# TP-S-030: Mobile P3 review engagement — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-030 |
| **Author** | Tester |
| **Date** | 2026-08-14 |

---

## Scope

Like, report, and merchant-reply **display** on `ReviewCard` / business detail. Reply composer is S-031.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Mobile | flutter_test | ReviewCard actions, ReviewsController like increment |
| Backend | — | Unchanged |
| Integration | Manual | Combined flutter pass later |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `review_card_test.dart` like control |
| 2 | Automated | `reviews_controller_test.dart` like once per session |
| 3 | Automated | guest like → login (detail / onRequireLogin) — `review_card_test` Report/Like callbacks |
| 4 | Automated | `review_card_test.dart` report form min 10 |
| 5 | Automated | reported placeholder via `reported: true` |
| 6 | Automated | Report without `onReport` calls `onRequireLogin` |
| 7 | Automated | `review_card_test.dart` merchant reply block |
| 8 | Automated | no composer when `canReply` false |
| 9 | Automated | like failure reverts count (controller catch) |
| 10 | Automated | existing `app_shell_test.dart` AC13 |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Guest like/report | none | Login |
| Signed-in like/report | any | POST |

---

## Manual checklist

- [ ] M-001: Like a review on a running backend; count persists after refresh
- [ ] M-002: Report replaces the card

---

## Environment

- Tests authored; **`flutter analyze` / `flutter test` not executed this session**
