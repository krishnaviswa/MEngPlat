# ADR-016: Support tickets and shop-level reports as distinct tables

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-19 |
| **Slice** | S-088, S-089 |

---

## Context

The platform already has `review_reports` for flagging a **review**. Product needs (1) customer support queries that may optionally mention a merchant, and (2) reports against a **shop**, with repeat-count flagging and admin↔reporter messages. Reusing `ReviewReport` would mix unrelated entities and statuses.

## Decision

- New `support_tickets` table for F2 (name, phone, issue, optional `business_id`, optional `reporter_id`, string `status`, `admin_response`).
- New `business_reports` + `business_report_messages` for F3. Status is a string column (same pattern as `review_reports.status`) to avoid a Postgres enum migration.
- Repeat-shop flag is **computed** (count of reports for that `business_id` ≥ 3), not a stored column.
- Guest ticket create is allowed (`reporter_id` null); "my tickets" requires auth.

## Consequences

### Positive

- Review moderation queue stays untouched.
- Admin can count shop reports independently of review reports.

### Negative / tradeoffs

- Two queues instead of one mega-inbox (E2/G1 may unify later).

### Follow-ups

- E2/G1 operational dashboard surfaces both queues.

## Alternatives considered

1. Extend `ReviewReport` with a nullable `business_id` — rejected; different lifecycle and UI.
2. Postgres enums for ticket status — rejected; additive string statuses are cheaper to evolve.
