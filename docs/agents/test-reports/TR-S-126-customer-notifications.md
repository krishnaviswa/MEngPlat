# TR-S-126: Customer notifications for review replies, review moderation and shop edits — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-126 |
| **Author** | Tester |
| **Date** | 2026-11-08 |
| **Recommendation** | Ship with conditions (Pass-with-conditions): no failing AC and no blocking product defect found, but 7 ACs are only Partial and 1 is Not run. PM should not set `Status: Accepted` until the conditions below are closed or explicitly waived |

---

## Summary

**Verdict: Pass-with-conditions.**

What ran and passed:

- Backend, 7 files named by the Architect: **100 passed in 1.97 s**.
- Jest `NotificationBell.test.tsx`: **3 passed**.
- `alembic heads`: single head `o9p0q1r2s3t4`.
- GitHub `web-workflows` `suite=all` ([run 42496564566](https://github.com/krishnaviswa/MEngPlat/actions/runs/42496564566), dispatched on the branch 2026-11-08): **10 passed, 1 skipped** (whatsapp, fresh stack). The three chains `wf-review-reply`, `wf-shop-edit`, `wf-review-moderation` now assert the customer's bell with no `xfail` and no `_gap` test left in `chains/` (grep confirms). The merchant chains `wf-new-review` and `wf-listing-approval` are unchanged and passed (AC 16 regression).

What did NOT run, stated plainly:

- **No PostgreSQL on this machine.** DB-backed tests and the migration upgrade/downgrade were **not run locally**. Every S-126 backend test uses an in-memory `FakeDB` (the rules are plain Python), so none of them touches a real database. The upgrade path was exercised implicitly by the GitHub Compose stack booting (fresh volume) but I did not inspect the migration log lines. **Downgrade (including `DELETE ... WHERE dedupe_key <> ''`) has never been run anywhere.**
- Mobile Notifications tab rendering: **Not run** (deferred by the slice; no Flutter change).
- README AC 20 PM review: **Not run** (PM task). I did diff the README and found stale sections, see D7.
- GitHub `web-e2e` `suite=all` ([run 42496567467](https://github.com/krishnaviswa/MEngPlat/actions/runs/42496567467)): 51 passed, 1 failed, 2 errors. **External blocker, not an S-126 failure**: the failure and errors ("Invalid credentials" right after register, "Call /mfa/totp/setup first" right after setup, plus a coverage-guard teardown error) come from an existing race introduced when FastAPI 0.162 began running the `get_db` commit after the response is sent; a separate fix is in progress and is not part of this slice. S-126 writes its notices inside the request transaction (no background task), so it is not affected by that ordering. I did not independently triage those three failures beyond the description provided.

### Conditions before PM sets `Status: Accepted`

1. Add or consciously waive the tests named by the Architect that do not exist (AC 7, AC 12; see "Gaps").
2. Add one test that actually executes the recipient query (AC 8, 11, 13), or accept that it is covered only by one positive e2e case (D2).
3. Run migration upgrade and downgrade on a Postgres (Compose or CI) and record it (M-002).
4. Fix the stale README sections (D7) before the PR merges.
5. Land the separate get_db commit-ordering fix, then re-run `web-e2e` `suite=all` and record it green (external dependency, not Builder work for this slice).
6. PM to rule on AC 12 wording (foreign `read` is a 200 no-op, not 403/404) and on Open decisions 1-5 (builder followed the defaults).

---

## AC coverage matrix

Result key: **Pass** = proven by a test that ran (or a GitHub run) at the level the AC describes. **Partial** = the core rule is proven, but a named part of the AC has no test. **Not run** = not executed. "Service-level" means the rule function in `customer_notices.py` is tested with a fake db; the router hook itself is covered only by the e2e chain (where one exists).

| AC# | Description | Type | Test reference / evidence | Result |
|-----|-------------|------|---------------------------|--------|
| 1 | First reply: author gets one unread notice naming the shop; merchant and other customers none | A | `test_customer_notices.py::test_reply_first_notifies_author_only` (only the author row, copy "Cafe A replied to your review.", key = review id); wiring: `chains/test_wf_review_reply.py::test_wf_review_reply` (GH run, title "Reply to your review" in the author's bell) | **Pass** |
| 2 | Reply edit with different text re-notifies same row; same text sends nothing | A | `::test_reply_edit_different_text_refreshes_same_row`, `::test_reply_edit_same_text_is_noop` (3 params, see D5), `::test_normalise_text`, `::test_upsert_same_key_refreshes_and_marks_unread`. The router's **edit branch** (captures `previous_body` before assignment) has no test: `test_reviews.py` calls it twice but asserts nothing about notices and its FakeDB has no Business, so notify is skipped. No e2e for an edited reply | **Partial** — rule Pass; edit-branch wiring untested (D3) |
| 3 | Reply on a non-active review (hidden, removed, held as reported) sends nothing | A | `::test_reply_on_non_active_review_sends_nothing[HIDDEN/REMOVED/REPORTED]` | **Pass** (service-level) |
| 4 | Admin hide notifies author, naming the shop | A | `::test_moderate_hide_and_remove_notify_author[hide]` (title, scenario, type `MODERATION`, shop in message); wiring: `chains/test_wf_review_moderation.py` (report then hide, author's bell shows "Your review was hidden"; previous status REPORTED, GH run) | **Pass** |
| 5 | Admin remove notifies author, naming the shop | A | `::test_moderate_hide_and_remove_notify_author[remove]`. No e2e for remove | **Pass** (service-level) |
| 6 | Restore replaces the hide notice ("visible again"); restoring a never-hidden/active review sends nothing | A | `::test_moderate_restore_replaces_hide_notice` (one row, title replaced), `::test_moderate_restore_of_active_or_reported_sends_nothing[ACTIVE/REPORTED]`, `::test_moderate_repeat_action_sends_nothing`. Edge defect D1 (hidden then reported then restored leaves a stale "hidden" notice) | **Pass** (service-level) with D1 |
| 7 | Profanity auto-hold at submit or a user report sends no notice to anyone | A | **No test.** The Architect named `test_report_review_notifies_nobody` and `test_flagged_create_review_sends_no_customer_notice`; neither exists in `test_customer_notices.py`. By code read: `report_review` and the `create_review` flag path have no S-126 call (git diff of `reviews.py` shows hooks only in `reply_to_review` and `moderate_review`) | **Partial** — static inspection only, no automated test |
| 8 | Shop edit of description/phone/hours/address notifies each active reviewer once; non-reviewers and hidden/removed reviewers get none | A | `::test_shop_edit_notifies_active_reviewers_only[description/phone/hours/address]` (each group, `extra_data.changed`). Recipient selection is stubbed by the `reviewers` fixture (`monkeypatch` of `_active_reviewer_ids`) in **every** shop-edit test, so the SQL (status ACTIVE, source != partner, author != actor, order, limit) is never executed by a test. I compiled the statement for PostgreSQL by hand and the predicates are right; that is not a test. E2E `wf-shop-edit` proves one positive case (one active reviewer notified). Hidden/removed/non-reviewer exclusion not executed | **Partial** (D2) |
| 9 | No-op saves, and saves changing only name/website/email/categories/coordinates, notify nobody | A | `::test_shop_edit_ignored_fields_notify_nobody[name/website/email]`, `::test_shop_edit_noop_and_cosmetic_whitespace_notifies_nobody`, `::test_normalise_phone`, `::test_normalise_hours`. Categories and coordinates are not in the snapshot (by construction; no explicit test). `update_business` snapshot hook is executed (no reviewers) by `test_business_address_reverify.py` and `test_businesses_cache_invalidation.py`, both green | **Pass** (service-level) |
| 10 | Several edits in a row: one notice per shop, latest wording, unread | A | `::test_shop_edit_repeated_keeps_one_row_per_shop`, `::test_upsert_same_key_refreshes_and_marks_unread` | **Pass** |
| 11 | Pending (not approved) shop edit notifies nobody | A | `::test_shop_edit_pending_business_notifies_nobody[PENDING/REJECTED]` | **Pass** |
| 12 | Notices contain only shop name, own-review context and fixed copy; a user can never read or change another user's notice | A | `::test_notice_payload_has_no_foreign_pii` (no reply text, no new phone, no shop email; `extra_data` keys limited to ids/`changed`/`action`). **Missing:** `test_notifications.py::test_list_returns_only_own_keyed_notices` and `::test_mark_read_ignores_foreign_keyed_notice` named by the Architect (file not modified; its 7 existing tests, including `test_scopes_to_current_user` and `test_does_not_mark_another_users_notification`, pass and the router is unchanged, but none uses keyed rows). Spec mismatch: a foreign/unknown id on `read` returns 200 no-op, AC text says 403/404 (Open decision 2) | **Partial** — payload Pass; keyed isolation tests missing; wording mismatch needs PM ruling |
| 13 | Actor who is also the recipient gets no notice | A | `::test_reply_actor_is_author_sends_nothing`, `::test_moderate_own_review_by_admin_sends_nothing`, `::test_shop_edit_excludes_actor`. The shop-edit test's fake implements the exclusion itself, so it does not prove the SQL excludes the actor; partner-author exclusion in the shop-edit query is also unexecuted (the Architect's `test_shop_edit_excludes_actor_and_partner_authors` was split and the partner half dropped). Partner reply/moderation covered: `::test_reply_partner_review_sends_nothing`, `::test_moderate_without_business_or_partner_sends_nothing` | **Partial** (D2) |
| 14 | A second notice about a different shop/review leaves the earlier one; same entity refreshes instead of duplicating | A | `::test_upsert_keyed_rows_do_not_overwrite_each_other`, `::test_shop_edit_two_shops_keep_two_rows`, `::test_upsert_same_key_refreshes_and_marks_unread`; model: `::test_notification_unique_constraint_columns` (constraint columns `user_id, scenario, dedupe_key`). Real DB constraint behaviour not exercised (no Postgres) | **Pass** (fake db; DB constraint Not run) |
| 15 | Reply and hide on the same review are separately visible | A | `::test_reply_and_moderation_for_same_review_coexist` | **Pass** |
| 16 | Six merchant scenarios unchanged | A + e2e | `tests/test_notification_scenarios.py` unmodified (`git diff main --stat` does not list it) and green inside the 100 passed; `::test_upsert_without_key_is_legacy_behaviour` (key stored as `''`), `::test_customer_scenarios_are_separate_from_merchant_scenarios` (`SCENARIOS` still 6, disjoint); GH: `wf-new-review` and `wf-listing-approval` passed (run 42496564566) | **Pass** |
| 17 | Badge counts the notice (30 s poll or reload), listed unread newest first, mark read drops badge, later event makes unread again | A | Backend refresh-to-unread: `::test_upsert_same_key_refreshes_and_marks_unread`. Jest: `NotificationBell.test.tsx` "renders customer notices (reply, moderation, shop edit) newest first without crashing" (3 customer rows render with nested `extra_data`; order assertion only proves the component keeps the API's order, the sort itself is the existing router). Not tested in Jest: 30 s poll, badge number, mark-read, mark-all-read. E2E `bell_expect` proves "unread row visible after reload/open" for all three notices | **Partial** — render, unread-on-arrival and refresh Pass; badge drop / mark read not covered by an S-126 test |
| 18 | No notices: existing empty state | A | Existing Jest case renders the bell with `list` resolving `[]` but only checks the control exists; the string "No notifications yet" (`NotificationBell.tsx:114`) is not asserted anywhere. Component unchanged by the slice | **Partial** — no new UI (true by diff), empty text not asserted |
| 19 | S-125 `_gap` xfail tests flipped to pass; `wf-review-moderation` customer check added, passes | A (GH) | `grep xfail\|_gap backend/tests/e2e/chains/*.py` finds only the generic `XPASS_MESSAGE` in `summary.py`. GH run 42496564566 `suite=all`: 10 passed, 1 skipped, no xfail. Chains: `test_wf_review_reply.py::test_wf_review_reply`, `test_wf_shop_edit.py::test_wf_shop_edit`, `test_wf_review_moderation.py::test_wf_review_moderation`. `test_workflow_summary.py` 8 passed (unchanged; synthetic names) | **Pass** |
| 20 | README §5, §7, §11 (index + chain note), §12, §14 updated in the same PR | M | Diff shows §5 (table + "Customer notices (S-126)" subsection), §7 (list semantics), §11 index row, §12 row M-96 + rollup, §14 row replaced. **Stale/missing items found, see D7** (§6 chain tables and "Cross-role effects" paragraph still say reply/hide/edit are silent; "5 full, 3 partial / known-gap" status row; the "Chains that exist today" table did not gain the three rows the Architect listed). PM review itself not done | **Not run** (PM review) |

**Coverage:** 20 / 20 AC mapped to a concrete test or evidence item. Tally: **Pass 12** (1, 3, 4, 5, 6, 9, 10, 11, 14, 15, 16, 19), **Partial 7** (2, 7, 8, 12, 13, 17, 18), **Not run 1** (20), **Fail 0**.

---

## Backend tests

### Added (by Builder; reviewed by Tester)
- `backend/tests/test_customer_notices.py` (new, 42 collected cases incl. parametrisation): `test_upsert_without_key_is_legacy_behaviour`, `test_upsert_keyed_rows_do_not_overwrite_each_other`, `test_upsert_same_key_refreshes_and_marks_unread`, `test_notification_unique_constraint_columns`, `test_customer_scenarios_are_separate_from_merchant_scenarios`, `test_normalise_text`, `test_normalise_phone`, `test_normalise_hours`, `test_reply_first_notifies_author_only`, `test_reply_edit_different_text_refreshes_same_row`, `test_reply_edit_same_text_is_noop`, `test_reply_on_non_active_review_sends_nothing`, `test_reply_actor_is_author_sends_nothing`, `test_reply_partner_review_sends_nothing`, `test_moderate_hide_and_remove_notify_author`, `test_moderate_restore_replaces_hide_notice`, `test_moderate_restore_of_active_or_reported_sends_nothing`, `test_moderate_repeat_action_sends_nothing`, `test_moderate_own_review_by_admin_sends_nothing`, `test_moderate_without_business_or_partner_sends_nothing`, `test_reply_and_moderation_for_same_review_coexist`, `test_shop_edit_notifies_active_reviewers_only`, `test_shop_edit_ignored_fields_notify_nobody`, `test_shop_edit_noop_and_cosmetic_whitespace_notifies_nobody`, `test_shop_edit_repeated_keeps_one_row_per_shop`, `test_shop_edit_two_shops_keep_two_rows`, `test_shop_edit_pending_business_notifies_nobody`, `test_shop_edit_excludes_actor`, `test_shop_edit_fanout_is_capped_at_200`, `test_notice_payload_has_no_foreign_pii`
- Fake extensions only (no new assertions): `test_reviews.py` (+`commit()` on FakeDB), `test_business_address_reverify.py` (`scalars()/all()` and an empty pool for other entities)
- `backend/tests/e2e/chains/test_wf_review_reply.py`, `test_wf_shop_edit.py`, `test_wf_review_moderation.py`, `helpers.py` (docstring): gap tests folded into the main chains

### Named by the Architect but absent
- `test_report_review_notifies_nobody`, `test_flagged_create_review_sends_no_customer_notice` (AC 7)
- `test_notifications.py::test_list_returns_only_own_keyed_notices`, `::test_mark_read_ignores_foreign_keyed_notice` (AC 12)
- `test_moderate_hide_notifies_author` / `test_moderate_remove_notifies_author` exist as one parametrised test (fine); `test_shop_edit_excludes_actor_and_partner_authors` exists as actor-only (partner half dropped)

### Run output
```
cd backend
python -m pytest tests/test_customer_notices.py tests/test_reviews.py tests/test_notification_scenarios.py \
  tests/test_notifications.py tests/test_business_address_reverify.py tests/test_businesses_cache_invalidation.py \
  tests/test_workflow_summary.py -q -p no:cacheprovider
-> 100 passed in 1.97s

python -m alembic heads
-> o9p0q1r2s3t4 (head)        (exactly one head)
```
Not run locally: any DB-backed test, migration upgrade, migration downgrade (no PostgreSQL on this machine). Full `pytest` not run (not requested; shared helper `upsert_notice` changed, its six merchant callers are covered by `test_notification_scenarios.py`, which passed).

---

## Frontend tests

### Added
- `frontend/src/components/__tests__/NotificationBell.test.tsx`: "renders customer notices (reply, moderation, shop edit) newest first without crashing"

### Run output
```
cd frontend && npx jest src/components/__tests__/NotificationBell.test.tsx
-> PASS, 3 passed (renders the notifications control; shows one row per scenario ...; renders customer notices ...)
   React "not wrapped in act(...)" warnings are printed from setOpen in the existing click-based tests (pre-existing style, not failures).
```
Full `npm test` not run.

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | `alembic heads` = single head `o9p0q1r2s3t4` | **Pass** |
| M-002 | Migration upgrade / downgrade / upgrade on real Postgres | **Not run** (no Postgres locally; downgrade never run anywhere) |
| M-010 | `web-workflows.yml` `suite=all` on the branch | **Pass** — [run 42496564566](https://github.com/krishnaviswa/MEngPlat/actions/runs/42496564566): 10 passed, 1 skipped (whatsapp, fresh stack), including the three flipped chains and the unchanged merchant chains |
| M-011 | `web-e2e.yml` `suite=all` | **Blocked by external issue** — [run 42496567467](https://github.com/krishnaviswa/MEngPlat/actions/runs/42496567467): 51 passed, 1 failed, 2 errors. Not S-126: "Invalid credentials" after register and "Call /mfa/totp/setup first" after setup are the known FastAPI >= 0.162 get_db-commit-after-response race (separate fix in progress); the third item is a coverage-guard teardown error. Re-run after that fix |
| M-015 | Mobile Notifications tab renders the new rows | **Not run** (mobile deferred; no Flutter change) |
| M-020 | PM review of README diff (AC 20) | **Not run** (PM task); Tester notes in D7 |

---

## Defects found (code review against the ACs; nothing fixed)

I read `services/customer_notices.py` and `git diff main -- backend/app` (models, `routers/reviews.py`, `routers/businesses.py`, `services/notifications.py`, the migration). Items you asked about:

- **Reply edit path:** `previous_body` is captured before `review.reply.body` is assigned, and `notify_review_reply` runs on both branches. Correct. Not covered by any test (D3).
- **Moderation previous_status for REPORTED:** captured before assignment (`previous_status = review.status`). hide/remove from REPORTED notify (this is the real path for an auto-held or user-reported review, and the e2e chain covers hide); restore from REPORTED sends nothing, matching the Architect's rule. Correct, except the stale-notice edge in D1.
- **Fan-out:** the cap and truncation logic are right (`LIMIT 201`, slice to 200, warning logs ids and counts only). The recipient query was compiled by me for Postgres and reads as specified. Never executed by a test (D2).
- **Normalisation:** matches the Architect's table. Info item D6.
- **Same transaction:** hooks run inside the request session and add no BackgroundTasks, so the PR #90 ordering hazard does not apply.

| # | Sev | AC | Description |
|---|-----|----|-------------|
| D1 | Low (edge, trigger is pre-existing) | 6 | `report_review` sets `status = REPORTED` unconditionally, even on a review that is already HIDDEN or REMOVED. If an admin then restores it, `previous_status` is REPORTED, so `notify_review_moderation` sends nothing and the old "Your review was hidden/removed" notice stays on the author's bell even though the review is public again. This breaks the AC 6 intent ("no stale hidden text left") for that sequence. Options: `report_review` should not demote hidden/removed reviews (changes existing behaviour, PM call), or restore should also refresh an existing moderation row. |
| D2 | Medium (test gap) | 8, 11, 13 | The only SQL that decides who is notified (`_active_reviewer_ids`) is monkeypatched in every shop-edit test, and the fake that replaces it applies the actor exclusion itself. A regression such as dropping `Review.status == ACTIVE`, dropping the `source != 'partner'` filter, or removing the actor exclusion would pass all unit tests; only the single positive `wf-shop-edit` case would exercise the query. Needs one test that runs the real statement (compile-and-inspect, or against Postgres in CI). |
| D3 | Medium (test gap) | 1-5, 2 | No test asserts that the three router hooks fire. `test_reviews.py` calls `reply_to_review` / `moderate_review` but its FakeDB has no `Business`, so `notify_review_moderation` returns early on `business is None`, and the reply tests never look at notices. A regression such as capturing `previous_body` after the assignment (every edit would become a "no-op") or deleting a hook would pass the backend suite. The reply **edit** branch has no e2e either; hide has one, remove and restore have none. |
| D4 | Low (spec) | 12 | AC 12 says reading or marking another user's notice returns 403/404; the router (unchanged) returns 200 with no state change, pinned by existing tests `test_does_not_mark_another_users_notification` and `test_unknown_id_is_a_no_op_not_an_error`. Architect recommends rewording the AC (Open decision 2). Behaviour is safe (no cross-user read or change); the AC text needs the PM ruling. |
| D5 | Low (test quality) | 2 | `test_reply_edit_same_text_is_noop` parametrises `"o ne".replace("o ne", "one")`, which is just `"one"` again, so there are only two distinct cases and no case with internal whitespace runs or a case-only change (which must notify). |
| D6 | Info | 9 | `normalise_phone` keeps a leading `+` only if it is the first character, so `"(+91) 98765 43210"` and `"+91 98765 43210"` differ, and `"+91..."` vs `"91..."` is treated as a change (the Architect's table allows the latter). Worst case is one extra notice, never a missed one for real changes. |
| D7 | Low (doc, AC 20) | 20 | README is only partly updated. Still stale: (a) §6/§11 "Cross-role effects with no proactive notice" paragraph (README ~line 2288) still lists reply, business edit and hide/remove as "author not told"; (b) the "Chains that exist today (6 scenarios, all notify a merchant)" table did not gain the three customer-notice rows the Architect specified; (c) the §11 status row at ~line 2266 still reads "5 full, 3 partial / known-gap"; (d) the §12 row M-96 is placed before M-95 (cosmetic). Also check `README` §11 index row e2e column: the three chain files are not named there. |
| D8 | Info | - | Spec'd trade-offs confirmed in code, no change requested: notice failures roll back the primary action; a concurrent first insert can hit the unique constraint (`IntegrityError`); admin edits also fan out (Open decision 3 default); WhatsApp-applied drafts do not notify (Open decision 4); the slice file still has `Status: Specified` with the five Open decisions unanswered, so the Builder followed the defaults. |

No defect in the privacy rule: notice text and `extra_data` use only the shop name, ids and fixed copy (`test_notice_payload_has_no_foreign_pii`), and `dedupe_key` is not in any response schema (diff has no `schemas/` change).

---

## Regressions

- None found. `test_notification_scenarios.py` is untouched and green; `test_workflow_summary.py` green; `wf-new-review` and `wf-listing-approval` still pass on GitHub.
- Existing FakeDB-based tests needed small fake extensions (`commit`, `scalars/all`, empty pool); these only widen the fakes and weaken no assertion.
- `web-e2e` `suite=all` shows 1 failure and 2 errors that I attribute, per the information given, to the external get_db commit-ordering race. Not verified by me; to be re-run after that fix.

---

## Gaps / rework items

1. AC 7: add `test_report_review_notifies_nobody` and `test_flagged_create_review_sends_no_customer_notice` (or waive in writing).
2. AC 12: add the two keyed-row isolation cases to `test_notifications.py`; PM to reword AC 12 (D4).
3. AC 8/11/13 (D2): one test that executes or inspects the real `_active_reviewer_ids` statement, including a partner-author case.
4. AC 1-5 (D3): at least one handler-level test per hook with a Business present in the fake (reply first, reply edit same text, reply edit new text, hide, update_business).
5. AC 17/18: Jest cases for empty state text and for mark-read / badge drop with a customer notice, or accept the existing coverage.
6. AC 20 / D7: finish the README edits.
7. D1: PM/Architect decision on `report_review` demoting hidden/removed reviews.
8. M-002: record migration upgrade/downgrade on Postgres.

---

## Sign-off

- [ ] All AC mapped to tests: **mapped 20 / 20**, but 7 are Partial and 1 is Not run (see matrix)
- [x] README §11 feature → test index updated if tests were added or moved (Notifications row lists `test_customer_notices.py`; chain files not named, see D7)
- [x] RBAC tested: trigger-role 403s are existing tests on unchanged routers (reply merchant-only and owner-only in `test_reviews.py`, moderate admin-only, edit owner-only in `test_business_address_reverify.py`); recipient-side isolation is router code unchanged; keyed isolation cases missing (Gap 2)
- [x] AI disclaimer verified: N/A (no AI content in any notice)
- [ ] Ready for PM acceptance: **Not yet** — close conditions 1-6 above or have the PM waive them

---

## Addendum — Builder follow-up after this review (2026-11-08/09)

Closed from the findings above, in the same PR:
- **D2/D3 (Medium):** added `test_active_reviewer_query_filters_status_source_actor_and_limit` (compiles the real recipient query for Postgres and asserts the ACTIVE, non-partner, non-actor, per-shop, newest-first, LIMIT clauses) and router-hook tests (`test_reply_router_hook_*`, `test_moderation_router_hook_passes_previous_status[hide|remove|restore]`, `test_moderation_router_invalid_action_notifies_nobody`) that call `reply_to_review` / `moderate_review` and assert the values captured before mutation. `update_business` is covered end to end by `wf-shop-edit`. Backend file now 49 tests.
- **D5:** duplicate parameter replaced. **D7:** README chain table gained rows 7-9, stale "no proactive notice" paragraph and status row rewritten, M-96 moved after M-95. **D8:** the five Open decisions are recorded in the slice as resolved to the Architect's defaults, for the PM to confirm.
- **External blocker (not S-126):** the 3 failures in web-e2e run 42496567467 come from a commit-after-response race (FastAPI >= 0.118 runs `get_db`'s commit after the response). Fixed separately by `Depends(get_db, scope="function")` on branch `fix/commit-before-response`; this PR's chain results are unaffected (run 42496564566: 10 passed, 1 skipped).
- **Still open:** D1 (a user report on an already hidden/removed review flips it to REPORTED, so a later restore sends nothing; pre-existing behaviour, Low, follow-up), D6 (`(+91)` phone formatting), migration upgrade/downgrade on Postgres (exercised by the Compose stack in the GitHub runs, never run as a downgrade), mobile tab rendering, PM acceptance.
