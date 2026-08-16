# Slice: S-053 — Admin approval gate for WhatsApp-derived profile drafts

| Field | Value |
|-------|-------|
| **Slice ID** | S-053 |
| **Phase** | 4 Dashboards |
| **Status** | Specified |
| **Role(s)** | admin \| merchant |
| **Owner** | PM / 2026-08-16 |

---

## User story

**As an** admin
**I want** a single review queue where I approve or reject every AI-extracted WhatsApp profile suggestion across all businesses — editing the suggested values first if the AI got something wrong
**So that** no unreviewed, possibly-wrong AI output can reach a live listing while we onboard 50-60 merchants/day by WhatsApp

**As a** merchant (secondary)
**I want** to see the status of my WhatsApp-submitted updates (pending admin review / applied / discarded)
**So that** I know what's happening to my listing even though I can no longer apply the changes myself

---

## Background / context

S-050 (link/bind), S-051 (photo ingestion), and S-052 (AI text → `BusinessUpdateDraft` → merchant Apply/Discard) are built on `feature/s050-whatsapp-ingestion`, currently **Status: Testing** (19/19 tests pass in `backend/tests/test_whatsapp.py`), not yet Accepted. Today the merchant who sent the WhatsApp message is also the one who approves it onto their own live listing (`backend/app/routers/dashboard.py:293-330`, `backend/app/services/whatsapp_ingest_service.py:68-111`, `WhatsAppDraftsPanel.tsx`).

At 50-60 merchants/day, the stakeholder wants a **mandatory admin gate**: a `BusinessUpdateDraft` may never reach the live `Business` row without an admin reviewing it first, regardless of business owner. This closes that gap by:

1. Removing the merchant's own Apply/Discard authority over `BusinessUpdateDraft` rows (merchant becomes read-only on drafts).
2. Adding a **global** admin review queue (not scoped to one business — the merchant dashboard's per-business panel isn't sufficient at this volume).
3. Letting the admin **edit** the AI-suggested field values before approving — this is the "AI is a suggestion, not a verdict" requirement (root `CLAUDE.md` non-negotiable #1) satisfied at the point of admin review, not by inventing a new AI capability.
4. Mirroring the existing `POST /businesses/{business_id}/approve` pattern already in `backend/app/routers/businesses.py:320-357`: `require_roles(UserRole.ADMIN)`, an `AuditLog` row, an in-app `Notification`, and a best-effort email to the merchant.

No new AI operation, prompt, or provider is introduced. `extracted_fields` (already produced by S-052's `get_ai_provider().extract_business_profile`) is simply surfaced editable in the new admin queue instead of editable-and-applicable by the merchant.

---

## Acceptance criteria

1. **Given** pending `BusinessUpdateDraft` rows exist across several different businesses, **when** an admin opens the new WhatsApp drafts review queue, **then** all pending drafts are listed **regardless of which business they belong to** — each row shows the business name, the extracted fields (labeled as AI suggestions, not facts), when it was submitted, and whether it was flagged `degraded` (mock/fallback AI, per S-052).
2. **Given** a queued draft, **when** the admin edits one or more of the AI-suggested field values before approving, **then** the edited values are what get used — the UI does not silently discard admin edits, and the values written on approval (AC3) are the admin-edited ones, not the raw AI extraction.
3. **Given** an admin approves a draft (with or without edits), **when** the approval succeeds, **then**: only the non-empty (possibly edited) fields are written to the live `Business` row; the draft's status becomes `applied`; an `AuditLog` row is written recording the admin and the draft/business; the owning merchant receives an in-app `Notification`; and a best-effort email is sent to the merchant — mirroring `businesses.approve` (`backend/app/routers/businesses.py:320-357`). Fields the admin left blank/unedited-and-empty are not written.
4. **Given** an admin rejects a draft, **when** the rejection succeeds, **then** no live `Business` field changes, the draft's status becomes `discarded`, the owning merchant receives an in-app `Notification` explaining the WhatsApp suggestion was not applied, and an `AuditLog` row records the rejection.
5. **Given** a merchant viewing their own dashboard's WhatsApp updates panel, **when** they view a draft, **then** they see a read-only status (e.g. "Pending admin review" / "Applied" / "Discarded") for each of their drafts and **no Apply or Discard controls are rendered or reachable** — the panel is informational only.
6. **Given** a merchant (even the owning merchant) attempts to invoke the previous apply/discard capability against a draft on their own business, **when** the request is made, **then** it is rejected — merchant is no longer an authorized role for applying or discarding `BusinessUpdateDraft` rows; only admin can move a draft out of `pending`.
7. **Given** a customer or a logged-out visitor, **when** they attempt to list, approve, or reject drafts via the new admin queue, **then** the request is rejected (401/403) regardless of business ownership; the queue is not reachable outside `/admin`.
8. **Given** no pending drafts exist across any business, **when** an admin opens the queue, **then** a plain-language empty state is shown ("No WhatsApp suggestions waiting for review") — not an empty table or error.
9. **Given** the expected 50-60 merchants/day submission volume, **when** an admin opens the queue, **then** drafts are paginated (not one unbounded list) and ordered oldest-first (FIFO) so nothing ages unreviewed indefinitely, and the admin can see how many drafts are pending (a count or "X of Y" indicator).
10. **Given** a draft has already been approved or rejected (e.g. by another admin, or a duplicate click), **when** a second approve/reject request targets that same draft, **then** it fails cleanly (no double-write to the live `Business`, no duplicate `Notification`/email) — consistent with the existing pending-only guard already used in S-052 apply/discard.
11. **Given** a draft flagged `degraded` (S-052 mock/fallback AI), **when** it appears in the admin queue, **then** the same "Mock/degraded data." labeling carries over so the admin can weigh the suggestion's reliability before approving or editing it.

---

## UX notes

- **Screens / routes:** New admin-only queue, e.g. under `/admin` alongside the existing `/admin/businesses` (pending business approvals) and `/admin/reviews` (moderation) queues — reuse that moderation-queue visual pattern (list + row actions) rather than inventing a new layout. Exact route path is the Architect's call.
- **Components to reuse:** `AIInsights.tsx` suggestion-card chrome / `(suggestion)` labeling convention already used in `WhatsAppDraftsPanel.tsx`; existing admin queue table/row pattern from `admin/businesses/page.tsx` and `admin/reviews/page.tsx`; `Dashboard` shell.
- **Merchant dashboard:** `WhatsAppDraftsPanel.tsx` keeps its disclaimer text and per-field suggestion display, but drops the `Apply`/`Discard` buttons in favor of a status pill per draft. Empty state (no drafts at all) stays hidden as today.
- **Empty states / errors:** Empty queue → quiet single line, not a blank table (AC8). Approve/reject failure (e.g. already-resolved draft, AC10) → inline error, no partial writes.
- **AI disclaimer required?** Yes — every field shown in the admin queue, edited or not, remains labeled as an AI suggestion until the admin's Approve click; the admin edit surface itself must not read as "the AI said so," but as "review and correct before approving."

---

## Out of scope

- AI extraction from WhatsApp **images** — `_ingest_image` continues to only store photos with no AI parsing; deferred to a future slice (confirmed with stakeholder).
- Any new AI vendor/provider selection or config work (e.g. `AI_PROVIDER=deepseek`) — that's a separate, already-settled config-only conversation, unrelated to this slice's AC.
- A new AI operation/prompt — this slice reuses S-052's existing `extracted_fields` output; it does not ask the AI provider anything new.
- Per-field partial approve granularity beyond what S-052 already supports (whole-draft apply with admin-editable values) — Architect may extend if trivial, but it's not a required AC here.
- Bulk approve/reject of multiple drafts in one action — v1 is one-at-a-time from the queue.
- Any change to how S-050/S-051 bind sessions or ingest photos.
- General business-edit form / hours-editor / address-map picker (still M-56, unrelated).

---

## Dependencies

- **S-050, S-051, S-052** must be Accepted first per the standard workflow (`CLAUDE.md` "Definition of done (full cycle)"). As of this brief they are built and passing all tests on `feature/s050-whatsapp-ingestion` (Status: Testing) but **not yet Accepted** — flagging this explicitly since it's a departure from the usual "depends on Accepted slice" rule; PM will accept S-050/051/052 (or confirm they're accepted in the same cycle) before or alongside this slice reaching Accepted.
- Existing `AuditLog`, `Notification` (+ `NotificationType`), and best-effort email pattern already used by `businesses.approve` — no new infrastructure, reuse only.
- No new AI vendor/provider work (see Out of scope).

---

## Definition of done (PM)

- [ ] All 11 AC verified in test report (`docs/agents/test-reports/TR-S-053.md`), including admin-edit-before-approve, merchant read-only enforcement, and 403 cases for customer/merchant/logged-out on the new queue endpoints
- [ ] UX matches notes — admin queue uses existing moderation-queue visual pattern; merchant panel is read-only with no reachable apply/discard action; suggestion labeling preserved throughout
- [ ] `README.md` §5 (draft entity — any status/RBAC note), §6 (flow), §7 (new admin endpoints), §9 (RBAC change: merchant loses apply/discard on drafts), §12 (mobile parity row), §14 / §16 updated in the same PR
- [ ] No new product `.md`/`.txt` checklist outside `docs/agents/`
- [ ] PM Status set to **Accepted**

---

## Technical specification (Architect)

### Resolutions to PM's 4 open questions

1. **Endpoint removal vs RBAC-lock:** **Remove outright.** `POST /merchant/{business_id}/whatsapp/drafts/{draft_id}/apply` and `.../discard` (`backend/app/routers/dashboard.py:305-330`) are deleted, along with `whatsapp_ingest_service.apply_draft` / `discard_draft` / `_load_pending`. Locking them to `require_roles(UserRole.ADMIN)` at a `/merchant/...` path would leave two admin-capable routes doing the same thing at two different resource paths — confusing REST surface and unnecessary diff to maintain. Admin actions get a single new home under `/admin` (§ API contract). The merchant-scoped `GET .../whatsapp/drafts` list endpoint is **kept** (see AC5 change below) since it's still how the merchant dashboard panel reads status.
2. **Where admin edits are stored:** **No new column.** `BusinessUpdateDraft.extracted_fields` stays exactly as AI-written (already immutable today — nothing currently mutates it) and is never overwritten by an admin edit. The admin's final (possibly edited) values are captured **only** in the `AuditLog.details` JSONB of the approve action: `{"business_id": ..., "ai_fields": {...raw extraction...}, "applied_fields": {...what was actually written...}}`. `AuditLog.details` already exists for exactly this purpose (nullable JSONB, unused by any current caller) — reusing it costs zero migration and gives the PM's desired "AI said X, admin approved Y" trail without a schema change. This is the minimal option per `backend/CLAUDE.md`'s bias toward extending/reusing existing tables over adding new ones.
3. **`AuditLog.entity_type`:** `"business_update_draft"` (not `"business"`) for both approve and reject actions — the entity being acted on is the draft, not the business record directly, and this keeps the audit trail queryable per-draft. `entity_id` = the draft's UUID. **No second `AuditLog` row** for the underlying `Business` field write: one row per admin action is the existing convention everywhere else in this codebase (e.g. `businesses.approve`, `businesses.suspend` each write exactly one row), and `details.business_id` + `details.applied_fields` already links back to what changed on the `Business` row without a duplicate row.
4. **Pagination:** Mirror `GET /admin/users` (`backend/app/routers/admin.py:16-31`): `page: int = Query(1, ge=1)`, `page_size: int = Query(20, ge=1, le=100)`. One deliberate deviation: `list_users` orders newest-first, but AC9 requires FIFO (oldest-first) so nothing ages unreviewed — the new queue orders `created_at asc`. The response also carries a `total` count (list_users doesn't) because AC9 explicitly requires a visible "X of Y" / count indicator and no existing admin list endpoint currently exposes one to reuse.

### API contract

| Method | Path | Auth | Request | Response |
|--------|------|------|---------|----------|
| `GET` | `/api/v1/admin/whatsapp/drafts` | `require_roles(ADMIN)` | Query: `page` (default 1, ≥1), `page_size` (default 20, 1-100) | `AdminWhatsAppDraftQueueResponse { items: AdminWhatsAppDraftResponse[], total: int, page: int, page_size: int }`. Always status=`pending` only (AC1, AC8); ordered `created_at asc` (AC9, FIFO). `AdminWhatsAppDraftResponse` = existing `WhatsAppDraftResponse` fields (`id`, `source`, `extracted_fields`, `status`, `degraded`, `created_at`) **plus** `business_id: UUID`, `business_name: str` (AC1: "each row shows the business name"). Empty `items` + `total: 0` → frontend renders AC8's empty state. |
| `POST` | `/api/v1/admin/whatsapp/drafts/{draft_id}/approve` | `require_roles(ADMIN)` | `AdminWhatsAppDraftApproveRequest { fields: dict[str, str \| dict \| None] \| None = None }` — admin-edited final values keyed by the same fixed field set (`description`, `address`, `business_hours`, `phone`, `website`). Any key omitted from `fields` (or `fields: null` entirely) falls back to that key's raw `extracted_fields` value, matching today's apply-as-is behavior (AC2: edits are optional, not mandatory). | `200` → `WhatsAppDraftResponse` (draft now `applied`). `404` draft not found. `409` draft not `pending` (AC10 — no double-write). |
| `POST` | `/api/v1/admin/whatsapp/drafts/{draft_id}/reject` | `require_roles(ADMIN)` | none | `200` → `WhatsAppDraftResponse` (draft now `discarded`). `404` / `409` as above (AC10). |
| `GET` | `/merchant/{business_id}/whatsapp/drafts` *(unchanged path, changed behavior)* | `require_roles(MERCHANT, ADMIN)` + `_load_owned_business` | — | **Was:** pending-only. **Now:** all drafts for the business regardless of status (`pending`/`applied`/`discarded`), ordered `created_at desc`, unpaginated (per-business WhatsApp draft volume is small; global 50-60/day volume is what the new admin queue paginates, not this per-business list) — needed so AC5's status pill has something to render for non-pending drafts. |
| ~~`POST /merchant/{business_id}/whatsapp/drafts/{draft_id}/apply`~~ | removed | — | — | **410-equivalent by removal** — route no longer exists (satisfies AC6/AC7: no route, at any auth level, lets a merchant or anyone else apply/discard). |
| ~~`POST /merchant/{business_id}/whatsapp/drafts/{draft_id}/discard`~~ | removed | — | — | same as above. |

### RBAC matrix

| Action | customer | merchant | admin |
|--------|----------|----------|-------|
| List own business's WhatsApp drafts (`GET /merchant/{id}/whatsapp/drafts`, any status, read-only) | ✗ 401/403 | ✓ own business only | ✓ |
| List global pending-drafts queue (`GET /admin/whatsapp/drafts`) | ✗ 401/403 | ✗ 401/403 | ✓ |
| Approve draft (`POST /admin/whatsapp/drafts/{id}/approve`) | ✗ 401/403 | ✗ 401/403 | ✓ |
| Reject draft (`POST /admin/whatsapp/drafts/{id}/reject`) | ✗ 401/403 | ✗ 401/403 | ✓ |
| Apply/discard a draft directly | ✗ | ✗ — routes removed (AC6) | ✗ — no such route for anyone; superseded by approve/reject |

### Data model impact

- [x] None  [ ] Extend existing  [ ] New table(s)

**Details:** No migration. `BusinessUpdateDraft` (`id`, `business_id`, `source`, `extracted_fields`, `status`, `degraded`, `created_at`) is unchanged — `status` already covers `pending`/`applied`/`discarded`, which is all AC5's read-only pill needs. Admin edits ride in `AuditLog.details` (existing nullable JSONB), not a new column — see resolution 2 above. `Business` row writes reuse the existing fixed allowed-field set (`description`, `address`, `business_hours`, `phone`, `website`); no new `Business` columns.

### Cache / side effects

- **Approve:** `cache_delete_pattern("search:*")` (mirrors today's `apply_draft` — a business field write can affect search-card content/index). One `AuditLog` row (`action="approve"`, `entity_type="business_update_draft"`, `entity_id=str(draft_id)`, `details={"business_id": ..., "ai_fields": ..., "applied_fields": ...}`). One `Notification` (`type=NotificationType.APPROVAL`, mirrors `businesses.approve`) to `merchant.user_id`. Best-effort email — new `try_send_whatsapp_draft_approved(to, business_name)` in `backend/app/services/email/` (new template alongside `listing_approved_email`; same `_try_send` never-raises wrapper) — reusing `try_send_listing_approved` verbatim would be semantically wrong copy ("your listing is now live" vs. "your WhatsApp update was applied").
- **Reject:** No cache invalidation (no `Business` row changes). One `AuditLog` row (`action="reject"`, `entity_type="business_update_draft"`, `entity_id=str(draft_id)`, `details={"business_id": ...}`). One `Notification` (`type=NotificationType.SYSTEM` — no dedicated "rejection" `NotificationType` exists and inventing one is out of proportion for this slice; `SYSTEM` is already used for exactly this kind of informational, non-approval notice). No email (AC4 only requires the in-app notification; PM's AC text doesn't ask for one, unlike AC3).
- Both: guarded by the existing pending-only check (refactored `_load_pending` → `_load_pending_any(db, draft_id)`, no longer business-scoped since admin drafts span all businesses) — `409` on a second approve/reject against the same draft (AC10).

### Frontend

- **Route:** New `/admin/whatsapp` page (`frontend/src/app/admin/whatsapp/page.tsx`), sibling to `/admin/businesses` and `/admin/reviews` (PM's UX note). Add a discoverability link from `/admin` (`frontend/src/app/admin/page.tsx`) — simplest is a new entry in that page's `STAT_LINKS`-style card once a pending-count stat is available, or a plain nav link near the other queue sections; exact placement is Builder's call, but the queue must be reachable from `/admin` without typing the URL.
- **Rendering:** CSR (`"use client"`) — matches every existing admin queue page (`admin/businesses/page.tsx`, `admin/reviews/page.tsx`); admin-only, not SEO/SSR-relevant, client-fetched via `RequireAuth role="admin"`.
- **Components (reuse first):**
  - New `frontend/src/components/admin/AdminWhatsAppDraftsQueue.tsx` — list + inline edit + Approve/Reject, following `PendingBusinessQueue.tsx`'s load/act/error/busy-state shape and button styling (green Approve, red-bordered Reject), and `WhatsAppDraftsPanel.tsx`'s `FIELD_LABELS` map + "(suggestion)" labeling + `degraded` → "Mock/degraded data." line (AC11). Each row: business name, submitted-at, degraded flag, editable inputs per extracted field (pre-filled with the AI value, admin can overwrite before Approve — AC2), Approve/Reject buttons, and pagination controls + "`X of Y` pending" count (AC9) using the new `total`/`page`/`page_size` response fields.
  - Empty state (AC8): reuse the existing dashed-border empty-state pattern (e.g. `PendingBusinessQueue`'s `"No pending businesses"` block) with copy "No WhatsApp suggestions waiting for review".
  - `frontend/src/components/ui/Badge.tsx` (`tone="neutral"|"positive"|"negative"`) for the merchant-side read-only status pill (`WhatsAppDraftsPanel.tsx` change below) — e.g. `neutral` for pending, `positive` for applied, `negative` for discarded.
- **Merchant-side change:** `WhatsAppDraftsPanel.tsx` drops its `apply`/`discard` handlers and the two buttons; renders a `Badge` per draft based on `draft.status` ("Pending admin review" / "Applied" / "Discarded") instead (AC5). It now also needs to render non-pending drafts (see API contract change to the merchant `GET` endpoint above) instead of returning `null` once a draft leaves `pending`.
- **API client:** `frontend/src/lib/api.ts` — extend the `dashboard` object with `adminListWhatsAppDrafts(page, pageSize)`, `adminApproveWhatsAppDraft(draftId, fields)`, `adminRejectWhatsAppDraft(draftId)`; remove `applyWhatsAppDraft`/`discardWhatsAppDraft` (no longer callable); `listWhatsAppDrafts` return type gains `business` fields are not needed on the merchant-scoped call (no change to its response shape, only its status filter server-side).

### Flow

```mermaid
sequenceDiagram
    participant Merchant as Merchant (WhatsApp)
    participant WA as WhatsApp provider
    participant Backend
    participant Admin
    participant AdminUI as Admin queue (/admin/whatsapp)

    Merchant->>WA: sends profile text
    WA->>Backend: webhook inbound (S-050/S-052)
    Backend->>Backend: AI extract -> BusinessUpdateDraft(status=pending)
    Admin->>AdminUI: open /admin/whatsapp
    AdminUI->>Backend: GET /admin/whatsapp/drafts?page=1
    Backend-->>AdminUI: pending drafts, oldest-first, total count
    Admin->>AdminUI: edit field(s), click Approve
    AdminUI->>Backend: POST /admin/whatsapp/drafts/{id}/approve {fields}
    Backend->>Backend: write non-empty fields to Business; draft=applied
    Backend->>Backend: AuditLog(ai_fields, applied_fields); Notification; best-effort email
    Backend->>Backend: cache_delete_pattern("search:*")
    Backend-->>AdminUI: 200 WhatsAppDraftResponse
    Backend-->>Merchant: in-app Notification + email
```

### Architect checklist

- [x] API contract defined and matches `README.md` §7 API reference style
- [x] RBAC matrix for all roles
- [x] Data model impact documented; ERD update noted if needed (none needed — no schema change)
- [x] Cache invalidation considered
- [x] AI/storage/maps use existing abstraction layers (no new AI operation; reuses S-052's `extracted_fields`, no storage/maps involved)
- [x] No secrets in design

### Risks / tradeoffs

- **Audit trail lives in JSONB, not a queryable column.** Putting `ai_fields`/`applied_fields` inside `AuditLog.details` (resolution 2) is minimal-diff but means "show me every admin edit that changed field X" requires scanning JSONB rather than a joinable column. Acceptable at current volume (50-60 merchants/day, not 50-60 *edits* — most approvals are likely unedited); revisit with a dedicated audit table if per-field edit analytics become a real product need.
- **Merchant `GET .../whatsapp/drafts` becomes unpaginated all-statuses.** Fine at per-business scale (a handful of WhatsApp submissions per business), but if a business somehow accumulates hundreds of drafts over time this endpoint has no cap — low risk given WhatsApp ingestion is not high-frequency per single business, but flagged in case that assumption changes.
- **Removing the old apply/discard routes is a breaking API change**, not just an RBAC tightening — any external client (mobile, if it ever called these directly) hitting the old paths gets `404` instead of `403`. Mobile parity tracker (§12) doesn't show WhatsApp draft apply/discard as implemented on mobile today, so no known mobile client breaks; still worth a scan before merge.
- **No dedicated `NotificationType` for "draft rejected."** Reusing `SYSTEM` keeps this slice from touching the enum (a migration), but it's a slightly generic label in the merchant's notification feed; a future slice could add a more specific type if the product wants richer in-app notification filtering.
- **Two service functions (`admin_approve_draft`, `admin_reject_draft`) intentionally do not require the caller to already hold a `Business` object**, unlike the removed `apply_draft`/`discard_draft` — this is required for the admin queue to be truly global/unscoped (AC1), but it's a deliberate widening of what draft-mutating code can reach compared to today's ownership-checked pattern; RBAC (`require_roles(ADMIN)` only, no `_load_owned_business` call) is the sole gate, so this must not regress to accepting a non-admin caller.

---

## Open questions for Architect (flagged by PM)

1. Should the existing `/merchant/{business_id}/whatsapp/drafts/{draft_id}/apply|discard` endpoints be removed outright, or kept but now `require_roles(UserRole.ADMIN)` only (with a separate admin-facing path added)? PM has no preference as long as AC6/AC7 hold — merchant must not be able to reach apply/discard by any route.
2. Where should the admin-edited field values be diffed/stored — overwrite `extracted_fields` in place on approve, or keep the original AI output immutable and store admin edits separately (better audit trail of "AI said X, admin approved Y")? PM's preference is the latter if it's not disproportionate effort, since it strengthens the AuditLog's value, but defers to Architect on cost/benefit.
3. Confirm `AuditLog.entity_type` value for this action (e.g. `business_update_draft` vs reusing `business`) and whether a second `AuditLog` row for the underlying `Business` field write is also warranted.
4. Pagination page size / query params — align with any existing admin queue convention (`admin/businesses`, `admin/reviews`) if one exists, otherwise Architect's default (AC9 just requires *some* bounded, ordered pagination).

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-053-whatsapp-admin-approval.md`
- Test report: `docs/agents/test-reports/TR-S-053-whatsapp-admin-approval.md`
- ADR: n/a (no new infra; reuses existing AuditLog/Notification/email patterns)
- Depends on: `S-050-whatsapp-link-foundation.md`, `S-051-whatsapp-photo-ingestion.md`, `S-052-whatsapp-ai-text-drafts.md`

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-16 | PM | Created slice (Draft); technical specification left for Architect |
| 2026-08-16 | Architect | Filled technical specification: resolved all 4 open questions (remove old apply/discard routes outright; admin edits captured in `AuditLog.details`, no schema change; `AuditLog.entity_type="business_update_draft"`, single row per action; pagination mirrors `/admin/users` with `created_at asc` + `total` count for AC9). Defined new `/admin/whatsapp/drafts` (list/approve/reject) endpoints, widened merchant `GET .../whatsapp/drafts` to all statuses, RBAC matrix, cache/side-effect plan, frontend route/components, mermaid flow, risks. Status: Draft → Specified. |
