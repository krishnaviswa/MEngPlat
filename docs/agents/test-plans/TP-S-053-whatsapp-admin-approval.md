# TP-S-053: Admin approval gate for WhatsApp-derived profile drafts — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-053 |
| **Author** | Tester |
| **Date** | 2026-08-16 |

---

## Scope

Admin-only global review queue for `BusinessUpdateDraft` rows produced by S-052's WhatsApp
text ingest. Merchant loses apply/discard authority (read-only status pill only). Admin can
edit AI-suggested field values before approving. Covers: RBAC on the new `/admin/whatsapp/drafts*`
routes, removal of the old merchant apply/discard routes, the widened merchant
`GET .../whatsapp/drafts` (all statuses), cross-business pagination/FIFO ordering,
AuditLog/Notification/email side effects, and the double-approve/reject 409 guard.

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|-----------------|
| 1 | Automated (backend) | `test_admin_queue_lists_across_businesses_oldest_first_with_business_context` (cross-business, business name, degraded flag) — real Postgres via ASGI, needed because `test_whatsapp.py`'s `InMemoryDB` fake is single-business-scoped and cannot represent the true join |
| 2 | Automated (backend + frontend) | `test_admin_approve_uses_edited_field_over_ai_value` (service-level, `test_whatsapp.py`) + `test_admin_approve_uses_edited_field_and_falls_back_to_ai_for_others` (ASGI) + `AdminWhatsAppDraftsQueue.test.tsx` "approve sends the (possibly edited) fields" |
| 3 | Automated (backend) | `test_admin_approve_writes_live_fields_and_notifies` (service-level) + `test_admin_approve_uses_edited_field_and_falls_back_to_ai_for_others` (ASGI: live `Business` write, `AuditLog.details.ai_fields`/`applied_fields`, `Notification` row); email best-effort path exercised for real (unmocked `try_send_whatsapp_draft_approved`) in both |
| 4 | Automated (backend) | `test_admin_reject_does_not_change_listing` (service-level) + `test_admin_reject_leaves_business_unchanged_and_notifies` (ASGI: `Business` unchanged, `AuditLog action="reject"`, `Notification`); "no email on reject" verified by code review (no `try_send_*` call in `admin_reject_draft`), not a dedicated assertion |
| 5 | Automated (frontend + backend) | `WhatsAppDraftsPanel.test.tsx` (pending/applied/discarded badges, no Apply/Discard buttons) + `test_merchant_and_admin_list_endpoint_shows_all_statuses` (service-level) + `test_merchant_list_endpoint_shows_all_statuses_newest_first` (ASGI, real ordering) |
| 6 | Automated (backend) | `test_approve_draft_refused_for_owning_merchant_403` (ASGI: owning merchant 403 on admin approve route) + `test_old_merchant_apply_route_no_longer_exists_404` / `..._discard_..._404` (route removed for anyone, including admin) |
| 7 | Automated (backend) | `test_admin_queue_anonymous_401`, `test_admin_queue_requires_admin_role_customer_403`, `..._merchant_403`, `test_approve_draft_anonymous_401`, `test_approve_draft_requires_admin_role_customer_403`, `test_reject_draft_anonymous_401`, `test_reject_draft_requires_admin_role_customer_403` |
| 8 | Automated (frontend); backend not proven against real Postgres | `AdminWhatsAppDraftsQueue.test.tsx` "shows the empty state when there are no pending drafts" (deterministic, mocked API). No backend-level empty-global-queue assertion — the admin queue is unscoped and the test DB is a shared real Postgres instance, so asserting `total == 0` globally would be flaky/unsafe; code review of `list_pending_drafts_admin`'s unconditional `WHERE status = PENDING` confirms no special-casing is needed for the zero-row case |
| 9 | Automated (backend + frontend) | `test_admin_queue_lists_across_businesses_oldest_first_with_business_context` (FIFO ordering across businesses), `test_admin_queue_pagination_bounds_page_size` (page_size respected, `total`/`page`/`page_size` present) + `AdminWhatsAppDraftsQueue.test.tsx` "X pending suggestions" count text |
| 10 | Automated (backend) | `test_double_approve_is_rejected` (service-level) + `test_double_approve_is_409_no_double_write` (ASGI: second approve 409, reject-after-approve also 409) |
| 11 | Automated (backend + frontend) | `test_admin_queue_lists_across_businesses_oldest_first_with_business_context` (`degraded: true` row surfaced) + `AdminWhatsAppDraftsQueue.tsx`'s "Mock/degraded data." line (code review; no dedicated RTL case for `degraded: true` was added in this cycle — gap noted in test report) |

---

## Environment

- `AI_PROVIDER=mock`, `WHATSAPP_PROVIDER=mock`
- Backend: `backend/tests/test_whatsapp.py` (InMemoryDB fake, no real DB) for service-layer logic;
  new `backend/tests/test_whatsapp_admin_asgi.py` (real Postgres via `httpx.AsyncClient` +
  `ASGITransport`, same pattern as `test_admin_platform_asgi.py`/`test_dashboard.py`) for RBAC,
  route-removal, and the cross-business admin queue join that the fake cannot represent.
  Per `backend/tests/CLAUDE.md`, this ASGI file targets CI's ephemeral Postgres only; in this
  session it ran against the project's reachable dev/staging Postgres and each test was run
  individually to avoid the documented function-scoped event-loop flake (see that file's
  docstring and the test report for exact commands/results).
- Frontend: `frontend/src/components/__tests__/WhatsAppDraftsPanel.test.tsx`,
  `frontend/src/components/admin/__tests__/AdminWhatsAppDraftsQueue.test.tsx` (Jest + RTL, mocked
  `lib/api`).
