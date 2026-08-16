# TP-S-050: WhatsApp link foundation — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-050 |
| **Author** | Tester |
| **Date** | 2026-08-16 |

---

## Scope

Dashboard `wa.me` link/QR, webhook handshake + HMAC, session bind, mock provider. Photos and AI drafts are S-051 / S-052.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend API | pytest | Handshake, HMAC, RBAC, bind, silent unknown token |
| Frontend | RTL | Card + QR + unavailable empty state + print button |
| Integration | Manual | Docker + mock inbound (blocked if Docker missing) |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `MerchantDashboard.test.tsx` approved listing shows WhatsApp card beside collect QR |
| 2 | Automated | `test_whatsapp.py::TestLinkAndRbac::test_merchant_gets_wa_me_link_with_token` |
| 3 | Automated | `test_customer_cannot_create_link`, `test_other_merchant_cannot_create_link` |
| 4 | Automated | `TestWebhookHandshake` |
| 5 | Automated | `TestWebhookSignature` |
| 6 | Automated | `test_token_redeems_and_text_creates_pending_draft` (phone bound) |
| 7 | Automated | `test_unknown_token_does_not_bind` |
| 8 | Automated | `test_followup_from_bound_phone_without_token` (listing description still null until Apply) |
| 9 | Automated | mock `sha256=mock` + `wa.me/15551234567` |
| 10 | Automated (partial) | Print button present in `WhatsAppUpdateCard.test.tsx` (print window not asserted) |
| 11 | Automated | `WhatsAppUpdateCard` unavailable empty state |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Unauthenticated link POST | none | 401 (not yet a dedicated test) |
| Wrong role | customer | 403 |
| Other merchant | merchant | 403/404 |

---

## Environment

- `WHATSAPP_PROVIDER=mock`, `AI_PROVIDER=mock`
- Pytest needs Postgres + `alembic upgrade head` (same as `test_google_reviews.py`)
