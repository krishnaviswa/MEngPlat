# TP-S-126: Customer notifications for review replies, review moderation and shop edits — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-126 |
| **Author** | Tester |
| **Date** | 2026-11-08 |

---

## Scope

Three new customer-facing bell notices (`review_reply`, `review_moderation`, `shop_details_updated`), the
`notifications.dedupe_key` column and widened unique constraint (migration `o9p0q1r2s3t4`), the rules module
`services/customer_notices.py`, the three router hooks (`reply_to_review`, `moderate_review`, `update_business`),
the web bell rendering, and the three flipped S-125 chains. Out of scope: email/push, deep links, mobile code
(deferred), WhatsApp-applied edits, AI content (none shown, so no AI disclaimer check).

The merchant-scenario regression (AC 16) is part of scope: `test_notification_scenarios.py` must stay untouched and green.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Rules (unit) | pytest, in-memory `FakeDB` | Each notify function: send / skip conditions, copy, keying, normalisers, fan-out cap |
| Router handlers | pytest, direct handler calls with fake db (house style) | Existing `test_reviews.py`, `test_business_address_reverify.py`, `test_businesses_cache_invalidation.py` must keep passing with the new calls |
| Model / migration | pytest (constraint columns) + Alembic | One head; constraint columns; upgrade/downgrade on Postgres |
| Frontend | Jest + RTL | Bell renders customer rows with nested `extra_data`; empty state |
| Cross-role e2e | `web-workflows.yml` dispatch | `wf-review-reply`, `wf-shop-edit`, `wf-review-moderation` assert the customer's bell; `wf-new-review`, `wf-listing-approval` regression for AC 16 |
| Static review | Tester code read | Defects against ACs (reply edit path, moderation previous status, fan-out query, normalisation) |

---

## AC to planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated + e2e | `test_customer_notices.py::test_reply_first_notifies_author_only`; `chains/test_wf_review_reply.py` |
| 2 | Automated | `::test_reply_edit_different_text_refreshes_same_row`, `::test_reply_edit_same_text_is_noop`, `::test_normalise_text` |
| 3 | Automated | `::test_reply_on_non_active_review_sends_nothing[hidden/removed/reported]` |
| 4 | Automated + e2e | `::test_moderate_hide_and_remove_notify_author[hide]`; `chains/test_wf_review_moderation.py` |
| 5 | Automated | `::test_moderate_hide_and_remove_notify_author[remove]` |
| 6 | Automated | `::test_moderate_restore_replaces_hide_notice`, `::test_moderate_restore_of_active_or_reported_sends_nothing`, `::test_moderate_repeat_action_sends_nothing` |
| 7 | Automated (planned by Architect) | `test_report_review_notifies_nobody`, `test_flagged_create_review_sends_no_customer_notice` (verify they exist) |
| 8 | Automated | `::test_shop_edit_notifies_active_reviewers_only[description/phone/hours/address]` plus a check that the recipient query is exercised |
| 9 | Automated | `::test_shop_edit_ignored_fields_notify_nobody`, `::test_shop_edit_noop_and_cosmetic_whitespace_notifies_nobody`, `::test_normalise_phone`, `::test_normalise_hours` |
| 10 | Automated | `::test_shop_edit_repeated_keeps_one_row_per_shop` |
| 11 | Automated | `::test_shop_edit_pending_business_notifies_nobody` |
| 12 | Automated | `::test_notice_payload_has_no_foreign_pii`; `test_notifications.py` keyed-notice isolation cases (verify they exist) |
| 13 | Automated | `::test_reply_actor_is_author_sends_nothing`, `::test_moderate_own_review_by_admin_sends_nothing`, `::test_shop_edit_excludes_actor` (+ partner exclusion in recipient query) |
| 14 | Automated | `::test_upsert_keyed_rows_do_not_overwrite_each_other`, `::test_shop_edit_two_shops_keep_two_rows` |
| 15 | Automated | `::test_reply_and_moderation_for_same_review_coexist` |
| 16 | Automated + e2e | `test_notification_scenarios.py` (unchanged), `::test_upsert_without_key_is_legacy_behaviour`, `::test_notification_unique_constraint_columns`; `wf-new-review`, `wf-listing-approval` |
| 17 | Automated | `::test_upsert_same_key_refreshes_and_marks_unread`; `NotificationBell.test.tsx` customer-notice case (poll / badge / mark-read behaviour to be checked) |
| 18 | Automated | `NotificationBell.test.tsx` empty-state (verify the text "No notifications yet" is actually asserted) |
| 19 | e2e (GitHub) | `chains/test_wf_review_reply.py`, `test_wf_shop_edit.py`, `test_wf_review_moderation.py`; no `xfail`/`_gap` left |
| 20 | Manual (PM review) | M-020: README §5 / §7 / §11 / §12 / §14 diff |

After tests land, README §11 **Feature → test index** row "Notifications" must list `test_customer_notices.py`.
Day-to-day run: only the files named in the report's Run output; full pytest/npm test only pre-merge.

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Read own notices | customer / merchant / admin | 200, only own rows |
| Read or mark-read another user's keyed notice | any | not listed; `read` is a 200 no-op (existing behaviour, AC 12 wording to be reworded by PM) |
| Reply (trigger) | customer | 403 (`require_roles(MERCHANT)`, existing) |
| Reply on another merchant's review | merchant | 403 (existing `test_reviews.py`) |
| Moderate (trigger) | non-admin | 403 (existing) |
| Edit shop (trigger) | non-owner merchant | 403 (existing `test_business_address_reverify.py`) |
| Actor is recipient | merchant reviewing own shop, admin who authored the moderated review | no notice |
| Partner-channel author | shadow user | no notice |

---

## Edge cases

- Reply edit with identical text after whitespace changes: no notice. Case-only change: counts as different.
- Moderation previous status REPORTED (user report or profanity auto-hold): hide/remove notify; restore sends nothing.
- Report of an already hidden/removed review flips it to REPORTED (existing behaviour), then restore: no "visible again" and a stale "hidden" notice stays.
- Shop edit that resends identical form values (the web form posts everything every save): no notice.
- Phone formatting variants (`+91 98765-43210`), hours key case, address casing/whitespace.
- More than 200 active reviewers: capped, warning logged.
- Customer with reviews on several shops: one entry per shop/review, earlier ones not overwritten.
- Pending / rejected shop edited: nobody notified.
- Recipient query: only ACTIVE, non-partner, non-actor authors, newest first, limited.

---

## Manual checklist

- [ ] M-001: `python -m alembic heads` shows exactly one head `o9p0q1r2s3t4`.
- [ ] M-002: Migration upgrade then downgrade then upgrade on a real Postgres (existing rows get `dedupe_key=''`; downgrade deletes keyed rows).
- [ ] M-010: Dispatch `web-workflows.yml` suite `all` on the branch; record per-chain result.
- [ ] M-011: Dispatch `web-e2e.yml` suite `all`; confirm no S-126 regression (record failures that belong to other causes separately).
- [ ] M-015: Mobile Notifications tab renders a reply / moderation / shop-edit row (deferred product work; render check only).
- [ ] M-020: PM reviews README diff for AC 20 (§5, §7, §11, §12, §14, and §6 chain tables).

---

## Environment

- `AI_PROVIDER=mock`; no AI content in this slice.
- Local machine has no PostgreSQL: DB-backed tests and migration up/down cannot run here; GitHub Compose runs cover the live path.
- `docker compose up --build` on GitHub runners via `web-workflows.yml` / `web-e2e.yml` (`workflow_dispatch`).
