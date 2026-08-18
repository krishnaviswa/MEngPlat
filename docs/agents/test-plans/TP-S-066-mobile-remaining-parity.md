# TP-S-066: Mobile remaining web capability parity — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-066 |
| **Author** | Tester |
| **Date** | 2026-08-18 |

---

## Scope

One combined verification pass for remaining web capabilities on Flutter (M-66 checkout, M-69, M-70, M-78, M-79, M-80). No new backend.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Mobile | flutter_test | Dashboard panels, ReviewCard AI draft, public Google strip, admin WhatsApp queue |
| Backend / web | — | Unchanged APIs; not re-run this slice |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `merchant_dashboard_screen_test.dart` M-69 |
| 2 | Automated | `review_card_test.dart` M-70 |
| 3 | Automated | `merchant_dashboard_screen_test.dart` M-78 |
| 4 | Automated | `merchant_dashboard_screen_test.dart` M-66 checkout |
| 5 | Automated | dashboard Google panel + `business_detail_screen_test.dart` M-80 |
| 6 | Automated | WhatsApp panel + `admin_whatsapp_queue_screen_test.dart` |
| 7 | Automated | suggestion copy on insights / WhatsApp / draft |
| 8 | Inspection | README tracker: M-65/M-71 partial, M-67 n/a |

---

## Out of scope for this run

- Emulator / `flutter drive`
- Native Razorpay SDK
- App Links
