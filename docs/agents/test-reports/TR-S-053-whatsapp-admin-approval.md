# TR-S-053: Admin approval gate for WhatsApp-derived profile drafts — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-053 |
| **Author** | Tester |
| **Date** | 2026-08-17 (updated same day after fix) |
| **Recommendation** | **Accept** |

---

## Summary

**Update (post-fix, independently re-verified):** the Builder applied the exact fix suggested
below — `values_callable=lambda members: [m.value for m in members]` (+ explicit `name="draftstatus"`)
on `BusinessUpdateDraft.status` in `backend/app/models/__init__.py`, no migration needed. I
independently re-ran (not just trusted the Builder's spot-check): all **20/20**
`backend/tests/test_whatsapp_admin_asgi.py` tests individually against the real Postgres
database (previously 12/20; the 8 that failed before all now pass), the fake-DB
`backend/tests/test_whatsapp.py` suite (**21/21**, unchanged, no regression), and the frontend
suite (**197/197 across 41 suites**, unchanged, no regression). See "Bug found and fixed" and
the updated AC coverage matrix below. Recommendation changed from Rework to **Accept**.

RBAC, route-removal, read-only-merchant-view behavior, and — now that the bug is fixed —
the full approve/reject/pagination/cross-business-queue functionality are all verified
end-to-end against the real FastAPI DI chain and a real Postgres database, not just the
`InMemoryDB` fake.

---

## Bug found and fixed (was blocking; now resolved)

**`BusinessUpdateDraft.status` cannot be written to a real Postgres database.**

- **Where:** `backend/app/models/__init__.py`, `BusinessUpdateDraft.status` column:
  ```python
  status: Mapped[DraftStatus] = mapped_column(Enum(DraftStatus), default=DraftStatus.PENDING, nullable=False)
  ```
- **Root cause:** The Postgres enum type `draftstatus` was created in
  `alembic/versions/20260816_1845-i3j4k5l6m7n8_add_whatsapp_sessions.py` with **lowercase**
  labels: `postgresql.ENUM("pending", "applied", "discarded", name="draftstatus")` — matching
  `DraftStatus`'s Python `.value`s. But the SQLAlchemy column above has no `values_callable`, so
  SQLAlchemy's default `Enum` type serializes using the Python enum member's **`.name`**
  (`"PENDING"`, `"APPLIED"`, `"DISCARDED"`) instead. Every *other* enum column in this codebase
  (`UserRole`, `BusinessStatus`, `ReviewStatus`, `NotificationType`, `PaymentStatus`) has its
  Postgres enum type created with **uppercase** labels precisely so the SQLAlchemy default
  matches (see `alembic/versions/20260809_0030-3a5749360a88_initial_schema.py`, e.g.
  `sa.Enum('PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED', name='businessstatus')`). `draftstatus`
  is the one enum in the schema that breaks this established convention, and no
  `values_callable` was added to compensate.
- **Evidence (reproduced live against the project's real Postgres in this session):**
  ```
  sqlalchemy.exc.DBAPIError: (sqlalchemy.dialects.postgresql.asyncpg.Error)
  <class 'asyncpg.exceptions.InvalidTextRepresentationError'>:
  invalid input value for enum draftstatus: "PENDING"
  [SQL: INSERT INTO business_update_drafts (..., status, ...) VALUES (..., $5::draftstatus, ...)]
  [parameters: (..., 'PENDING', ...)]
  ```
- **Why the existing suite never caught this:** every test that exercises draft creation/apply/
  discard/approve/reject in `backend/tests/test_whatsapp.py` uses the file's `InMemoryDB` fake,
  which never touches a real database — `DraftStatus.PENDING` there is just a Python object
  compared with `==`, never serialized to SQL. This slice's dependency on S-050/051/052 (all
  "Status: Testing", **not yet Accepted** per the slice file's own Dependencies section) means
  this bug has been present and unverified against real Postgres since S-050/052's migration
  landed, not introduced by this slice's Builder — but S-053's new `admin_approve_draft`/
  `admin_reject_draft` (`draft.status = DraftStatus.APPLIED` / `.DISCARDED`) hit the exact same
  wall.
- **Blast radius in production:** `_ingest_text`'s `db.flush()` (draft creation on inbound
  WhatsApp text, S-052) is **not** wrapped in the surrounding try/except (only the AI-provider
  call is) — the exception propagates to `handle_inbound`'s per-message catch-all, is logged, and
  swallowed. Net effect: a merchant's WhatsApp message silently produces **no draft** and **no
  ack** is sent, while the webhook itself still returns `200` to the WhatsApp provider (so Meta
  never retries). The admin `approve`/`reject` endpoints have no such catch — they would 500 the
  request outright.
- **Fix applied (Builder, this cycle):** exactly the suggested one-line fix, no migration:
  ```python
  # Persist enum *values* (`pending`), matching Alembic's draftstatus.
  # SQLAlchemy's default is member *names* (`PENDING`), which Postgres rejects.
  status: Mapped[DraftStatus] = mapped_column(
      Enum(
          DraftStatus,
          name="draftstatus",
          values_callable=lambda members: [m.value for m in members],
      ),
      default=DraftStatus.PENDING,
      nullable=False,
  )
  ```
  (`backend/app/models/__init__.py`, same pattern already used elsewhere in this file for
  `national_id_type`.) I independently confirmed the fix in the file (not just trusting the
  Builder's description) and independently re-ran every test that previously failed because of
  this bug — see "Backend tests" below.
- **Verification:** all 8 previously-failing `test_whatsapp_admin_asgi.py` tests now pass
  individually against real Postgres, plus the other 12 that already passed still pass (20/20
  total), plus `test_whatsapp.py`'s 21/21 fake-DB tests are unchanged (no regression). This also
  unblocks S-050/051/052 (draft creation, `_ingest_text`), which shared the exact same root
  cause and were never previously provable against real Postgres either — worth flagging to PM
  alongside this slice's acceptance, since their own status is still "Testing" per this slice's
  Dependencies section.

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Global cross-business pending queue, business name + AI-labeled fields + submitted-at + degraded flag | A | `test_admin_queue_lists_across_businesses_oldest_first_with_business_context` (ASGI) | **Pass** — cross-business join, `business_id`/`business_name`, `degraded` flag all verified against real Postgres |
| 2 | Admin edits are used, not silently discarded | A | `test_admin_approve_uses_edited_field_over_ai_value` (service/fake, **Pass**) + `test_admin_approve_uses_edited_field_and_falls_back_to_ai_for_others` (ASGI, **Pass**) + `AdminWhatsAppDraftsQueue.test.tsx` "approve sends the (possibly edited) fields" (**Pass**, frontend) | **Pass** |
| 3 | Approve: live field write, `applied` status, `AuditLog`, `Notification`, best-effort email | A | `test_admin_approve_writes_live_fields_and_notifies` (service/fake, **Pass**) + `test_admin_approve_uses_edited_field_and_falls_back_to_ai_for_others` (ASGI, **Pass** — live `Business` row, `AuditLog.details.ai_fields`/`applied_fields`, `Notification` row all asserted directly against real Postgres) | **Pass** |
| 4 | Reject: no live change, `discarded` status, `Notification`, `AuditLog`, no email | A | `test_admin_reject_does_not_change_listing` (service/fake, **Pass**) + `test_admin_reject_leaves_business_unchanged_and_notifies` (ASGI, **Pass**); "no email" still verified by code review only (no `try_send_*` call in `admin_reject_draft`), not a positive assertion | **Pass** (email-absence sub-claim remains code-review-only, see Gaps) |
| 5 | Merchant read-only status pill, no Apply/Discard controls | A | `WhatsAppDraftsPanel.test.tsx` (4 tests, **Pass**) + `test_merchant_and_admin_list_endpoint_shows_all_statuses` (service/fake, **Pass**) + `test_merchant_list_endpoint_shows_all_statuses_newest_first` (ASGI, **Pass** — real status transition + newest-first ordering) | **Pass** |
| 6 | Merchant (even owning) cannot apply/discard; route removed | A | `test_approve_draft_refused_for_owning_merchant_403` (ASGI, **Pass** — owning merchant gets 403 on the new admin approve route) + `test_old_merchant_apply_route_no_longer_exists_404` (**Pass**) + `test_old_merchant_discard_route_no_longer_exists_404` (**Pass**) + code review confirms no apply/discard route exists in `dashboard.py` | **Pass** |
| 7 | Customer/logged-out 401/403 on the new admin queue routes | A | `test_admin_queue_anonymous_401`, `test_admin_queue_requires_admin_role_customer_403`, `test_admin_queue_requires_admin_role_merchant_403`, `test_approve_draft_anonymous_401`, `test_approve_draft_requires_admin_role_customer_403`, `test_reject_draft_anonymous_401`, `test_reject_draft_requires_admin_role_customer_403` — all **Pass** (ASGI, real DI chain) | **Pass** |
| 8 | Empty-queue plain-language empty state | A (frontend) | `AdminWhatsAppDraftsQueue.test.tsx` "shows the empty state when there are no pending drafts" — **Pass** | **Pass** (frontend); backend empty-case still not independently asserted against real Postgres — see plan's rationale (shared DB, unconditional `WHERE` clause needs no special-casing per code review) |
| 9 | Pagination (bounded, oldest-first FIFO) + pending count indicator | A | `test_admin_queue_pagination_bounds_page_size` (ASGI, **Pass**) + `test_admin_queue_lists_across_businesses_oldest_first_with_business_context` (ASGI, **Pass** — FIFO ordering confirmed) + `AdminWhatsAppDraftsQueue.test.tsx` count text (**Pass**, frontend) | **Pass** |
| 10 | Double approve/reject fails cleanly (409, no double-write) | A | `test_double_approve_is_rejected` (service/fake, **Pass**) + `test_double_approve_is_409_no_double_write` (ASGI, **Pass** — second approve 409, reject-after-approve also 409) | **Pass** |
| 11 | `degraded` flag/labeling carries into admin queue | A | code review of `AdminWhatsAppDraftsQueue.tsx` ("Mock/degraded data." line reused from `WhatsAppDraftsPanel.tsx`'s pattern) + `test_admin_queue_lists_across_businesses_oldest_first_with_business_context` (ASGI, **Pass** — asserts `degraded: true` propagates through `AdminWhatsAppDraftResponse` end-to-end) | **Pass** at the API/data level; no dedicated frontend RTL case with `degraded: true` was added this cycle (component-level gap only, see Gaps) |

**Coverage:** 11/11 AC mapped to at least one automated test. **11/11 Pass.** Two residual,
non-blocking gaps remain and are called out per-row above and in "Regressions / gaps": AC4's
"no email on reject" is a code-review claim rather than a positive spy-based assertion, and
AC11 has no frontend RTL case for `degraded: true` in the admin queue component (its
propagation through the API/backend is proven).

---

## Backend tests

### Added

- `backend/tests/test_whatsapp_admin_asgi.py` — **new file**, 20 tests, real Postgres via
  `httpx.AsyncClient` + `ASGITransport` (same pattern as `test_admin_platform_asgi.py`). Covers
  RBAC (401/403) on all three new `/admin/whatsapp/drafts*` routes, the two removed merchant
  routes (404), merchant ownership on the widened `GET .../whatsapp/drafts`, admin-edit-vs-AI-
  fallback, `AuditLog`/`Notification` side effects, 404 on unknown draft, 409 on double-approve/
  reject, and the cross-business pagination/FIFO-ordering join that `test_whatsapp.py`'s fake
  cannot represent.
- No changes were made to `backend/tests/test_whatsapp.py` — the Builder's existing 21 tests
  (including the 6 new S-053 cases: `test_admin_approve_writes_live_fields_and_notifies`,
  `test_admin_approve_uses_edited_field_over_ai_value`, `test_admin_reject_does_not_change_listing`,
  `test_double_approve_is_rejected`, `test_customer_cannot_list_drafts`,
  `test_merchant_and_admin_list_endpoint_shows_all_statuses`) were reviewed and re-run, not
  modified.

### Run output

`test_whatsapp.py` (InMemoryDB fake, no real DB — safe to run as a normal batch):

```
21 passed in 7.04s
```

`test_whatsapp_admin_asgi.py` (real Postgres — per this file's and `test_admin_platform_asgi.py`'s
documented event-loop flake, run **one test per process**; a batched run of the whole file was
attempted first and reproduced the exact same flake described in `test_whatsapp.py`'s module
docstring, confirming it's environmental, not new — see "Pre-fix run" below):

**Post-fix run (current, independently re-verified by Tester after the Builder's model change):**

| Test | Result |
|------|--------|
| `test_admin_queue_anonymous_401` | Pass |
| `test_admin_queue_requires_admin_role_customer_403` | Pass |
| `test_admin_queue_requires_admin_role_merchant_403` | Pass |
| `test_approve_draft_anonymous_401` | Pass |
| `test_approve_draft_requires_admin_role_customer_403` | Pass |
| `test_approve_draft_refused_for_owning_merchant_403` | **Pass** (was Fail, `draftstatus` bug — now fixed) |
| `test_reject_draft_anonymous_401` | Pass |
| `test_reject_draft_requires_admin_role_customer_403` | Pass |
| `test_old_merchant_apply_route_no_longer_exists_404` | Pass |
| `test_old_merchant_discard_route_no_longer_exists_404` | Pass |
| `test_merchant_cannot_list_another_merchants_drafts_403` | Pass |
| `test_merchant_list_endpoint_shows_all_statuses_newest_first` | **Pass** (was Fail — now fixed) |
| `test_admin_approve_uses_edited_field_and_falls_back_to_ai_for_others` | **Pass** (was Fail — now fixed) |
| `test_admin_reject_leaves_business_unchanged_and_notifies` | **Pass** (was Fail — now fixed) |
| `test_admin_approve_unknown_draft_404` | Pass |
| `test_admin_reject_unknown_draft_404` | Pass |
| `test_double_approve_is_409_no_double_write` | **Pass** (was Fail — now fixed) |
| `test_admin_queue_lists_across_businesses_oldest_first_with_business_context` | **Pass** (was Fail — now fixed) |
| `test_admin_queue_pagination_bounds_page_size` | **Pass** (was Fail — now fixed) |
| `test_admin_queue_pending_only_excludes_resolved_drafts` | **Pass** (was Fail — now fixed) |

**20/20 pass.** Each test above was re-run individually, in its own process, against the same
real Postgres database used for the pre-fix run — same methodology, same environment, only the
`backend/app/models/__init__.py` change is different. `test_whatsapp.py` (fake DB) re-run: still
**21/21 pass**, no regression. Frontend suite re-run: still **197/197 tests, 41/41 suites pass**,
no regression (no frontend code changed by this fix).

**Pre-fix run (superseded, kept for audit trail):** 12/20 pass, 8/20 fail, all 8 failures the
identical `draftstatus` enum bug (`InvalidTextRepresentationError: invalid input value for enum
draftstatus: "PENDING"` on the `INSERT`/`UPDATE` that sets `BusinessUpdateDraft.status`). A fuller
`pytest --ignore=tests/e2e` batch run at that time also showed `408 passed, 68 failed` — confirmed
to be the same pre-existing shared-event-loop/`AsyncSessionLocal` flake already documented in
`test_whatsapp.py`'s and `test_admin_platform_asgi.py`'s module docstrings (many unrelated,
individually-passing files also failed en masse in that batch), not a real regression signal; the
individually-run results were what fed the AC matrix at that time, and remain the correct
methodology now. The fuller batch run was not re-attempted post-fix since the individual re-runs
above already give a definitive, methodologically-consistent answer for every test that matters
to this slice's AC coverage.

---

## Frontend tests

### Added / reviewed

- `frontend/src/components/__tests__/WhatsAppDraftsPanel.test.tsx` (4 tests — Builder-authored,
  reviewed, not modified: renders nothing when empty, suggestion labels + pending badge + no
  Apply/Discard buttons, Applied badge, Discarded badge)
- `frontend/src/components/admin/__tests__/AdminWhatsAppDraftsQueue.test.tsx` (4 tests —
  Builder-authored, reviewed, not modified: empty state, list with business name + suggestion
  labels, approve with edited field, reject)
- No new frontend tests were added this cycle. Gap: no RTL case exercises `degraded: true` in
  `AdminWhatsAppDraftsQueue` (AC11's admin-queue half is unverified at the component level).

### Run output

```
Test Suites: 41 passed, 41 total
Tests:       197 passed, 197 total
Time:        17.7s / 18.4s (pre-fix and post-fix runs, both identical)
```

Independently re-run twice in this session (not just re-quoted from the Builder's summary) — both
before and after the backend model fix, matching 41/197 each time. No frontend code was touched by
the fix, so this is a no-op confirmation, not new coverage.

---

## Manual checklist

- [ ] `docker compose up --build` smoke test of the admin queue against a fresh Postgres —
  **still not run this cycle**; no longer expected to fail on the first real draft write (root
  cause fixed and proven via `test_whatsapp_admin_asgi.py`'s real-Postgres round trip), but a
  literal Compose/fresh-DB pass was not performed — recommend before/alongside deploy as normal
  due diligence, not because a failure is anticipated
- [ ] `/admin/whatsapp` reachable from `/admin` via the "Open review queue →" link — verified by
  code review of `frontend/src/app/admin/page.tsx` (`#whatsapp-drafts` section), not click-tested
  in a browser
- [ ] Swagger `/docs` matches implemented routes — verified by code review of `admin.py`/
  `dashboard.py` route decorators against the slice's API contract table; not opened in a browser

---

## Regressions / gaps

1. ~~**Blocking bug**: `BusinessUpdateDraft.status` cannot be persisted to real Postgres.~~
   **Fixed and independently re-verified this cycle** (see "Bug found and fixed" above). This
   also unblocks S-050/051/052 (draft creation shared the identical root cause) — worth flagging
   to PM alongside this slice, since their own status is still "Testing" per this slice's
   Dependencies section, and they can now be verified/accepted on the same basis.
2. No RTL test for `degraded: true` in `AdminWhatsAppDraftsQueue` (AC11 admin-queue half) — minor,
   non-blocking; the underlying data propagation (backend → API → component prop) is proven by
   `test_admin_queue_lists_across_businesses_oldest_first_with_business_context`, only the
   component's conditional render of the "Mock/degraded data." string for that prop lacks a
   dedicated Jest case.
3. AC4's "no email on reject" is verified only by code review, not a positive assertion (no
   spy/mock on the email provider was wired up to prove *absence* of a call) — minor, non-blocking;
   the code path (`admin_reject_draft`) plainly has no `try_send_*` call to review.
4. AC8's empty-queue state is proven at the frontend/component level only; a true empty-global-
   queue backend assertion isn't safe against the shared, non-isolated dev/staging Postgres this
   session had access to — non-blocking, same reasoning as before.
5. The `test_whatsapp_admin_asgi.py` file inherits the same environmental event-loop flake
   documented in `test_whatsapp.py`/`test_admin_platform_asgi.py` when run as a batch; it must be
   run test-by-test locally, same as those files, until CI's isolated ephemeral-Postgres
   per-test-module setup is confirmed to sidestep this (out of scope for this slice to fix;
   pre-existing project-wide condition, not specific to this slice's tests).
6. Manual `docker compose` / Swagger / browser click-through was not performed this cycle (see
   checklist above) — recommend as normal pre-deploy due diligence, not because a failure is
   anticipated (root cause is fixed and proven against real Postgres via pytest).

---

## Recommendation

**Accept.** The Builder applied the exact fix I suggested — `values_callable` on
`BusinessUpdateDraft.status` (`backend/app/models/__init__.py`), zero migration — and I
independently re-ran every previously-failing test individually against real Postgres (not just
trusting the Builder's own spot-check): all 8 now pass, bringing `test_whatsapp_admin_asgi.py` to
20/20. `test_whatsapp.py` (21/21) and the frontend suite (197/197) remain unchanged, confirming no
regression from the fix. All 11 AC are now mapped to a Pass automated test, with only two minor,
non-blocking coverage gaps noted above (AC4 email-absence assertion, AC11 frontend `degraded`
case) that don't warrant blocking acceptance. This also unblocks S-050/051/052 on the same basis —
recommend PM consider accepting all four together, or at minimum note in their records that the
shared root-cause bug no longer blocks any of them.

---

## Sign-off

- [x] All 11 AC mapped to at least one automated test
- [x] All 11 AC now Pass (verified post-fix, independently re-run)
- [x] RBAC executed (401/403, all Pass)
- [x] AI disclaimer present in both merchant panel and admin queue (code review + RTL)
- [x] No regressions in `test_whatsapp.py` (21/21) or the frontend suite (197/197) post-fix
- [x] Ready for PM acceptance
