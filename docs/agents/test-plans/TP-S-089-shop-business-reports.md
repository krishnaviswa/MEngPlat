# TP-S-089: Shop / merchant reporting — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-089 |
| **Author** | Tester |
| **Date** | 2026-08-19 |

---

## Scope

Shop-level reports distinct from review reports. Repeat flag at 3. Message thread. Do not change `ReportedReviewsQueue`.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend API | pytest | 201, 401, own-shop 403, is_repeat, messages, review-report still 200 |
| Frontend | RTL | `ReportShopButton`, admin shop-report queue, review queue still on `/admin` |
| Integration | Manual | Report a shop; admin sees count/repeat |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | POST `/{id}/reports` 201 + ReportShopButton submit |
| 2 | Automated | API 401; UI pushes `/login` without token |
| 3 | Automated | owning merchant 403 |
| 4 | Automated | admin list `is_repeat` true at count ≥ 3 |
| 5 | Automated | reporter + admin messages on mine and admin list |
| 6 | Automated | `POST /reviews/{id}/report` still 200; admin page still stubs/renders Reported reviews |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Report shop | none | 401 |
| Report own shop | merchant | 403 |
| Admin queue | customer | 403 |
| Admin queue | admin | 200 |

---

## Manual checklist

- [ ] M-089-1: Report a shop; admin queue shows repeat at 3; review-report queue unchanged.
