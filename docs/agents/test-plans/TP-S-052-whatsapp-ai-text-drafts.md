# TP-S-052: WhatsApp AI text drafts — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-052 |
| **Author** | Tester |
| **Date** | 2026-08-16 |

---

## Scope

Extract → pending draft → Apply/Discard. Suggestions only.

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `test_token_redeems_and_text_creates_pending_draft` (live description still null) |
| 2 | Automated | `WhatsAppDraftsPanel.test.tsx` labels + Apply/Discard |
| 3 | Automated | `TestDrafts::test_apply_writes_live_fields` (whole-draft; optional `fields` API not in UI) |
| 4 | Automated | `test_discard_does_not_change_listing` |
| 5 | Automated | `test_customer_cannot_list_or_apply_drafts` |
| 6 | Code review / gap | empty extract skips insert; no dedicated pytest |
| 7 | Automated (UI) | `degraded` banner in panel; mock AI default |
| 8 | Gap | extract exception still acks `Got it, thanks!`; no dedicated failure test |
| 9 | Automated | `test_admin_can_list_drafts` (admin apply not separately asserted) |

---

## Environment

- `AI_PROVIDER=mock`, `WHATSAPP_PROVIDER=mock`
