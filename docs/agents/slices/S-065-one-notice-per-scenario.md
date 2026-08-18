# Slice: S-065 — One in-app notice per workflow scenario

| Field | Value |
|-------|-------|
| **Slice ID** | S-065 |
| **Phase** | 4 Dashboards |
| **Status** | In Progress |
| **Role(s)** | merchant |
| **Owner** | Builder 2026-08-18 |

---

## User story

**As a** merchant  
**I want** one bell notice per kind of workflow event  
**So that** listing approval, reviews, WhatsApp review, and featured payment do not pile up as duplicate rows

---

## Acceptance criteria

1. **Given** a merchant already has a `listing_approved` notice, **when** another listing is approved for them, **then** that scenario still has exactly one row (copy refreshed, unread).
2. **Given** the same for `new_review`, `whatsapp_applied`, `whatsapp_rejected`, `payment_captured`, and `payment_boost_approved`, **when** a second event of that scenario fires, **then** still one row each.
3. **Given** all six scenarios have fired once, **when** the merchant lists notifications, **then** they see six distinct rows (one per scenario).
4. **Given** two merchants, **when** each gets a `new_review` notice, **then** they do not share a row.
5. **Given** the Alembic upgrade, **when** duplicate notice rows exist, **then** only `notifications` is pruned — businesses, photos, and addresses are unchanged.

---

## UX notes

- Bell UI unchanged; fewer stacked rows.
- AI disclaimer: WhatsApp copy already says suggestion.

---

## Out of scope

- Deleting or editing seed shops, photos, addresses
- Email volume (transactional mail still one send per event)
- Customer-facing notices (reply / moderation unused)

---

## Technical specification (Architect)

### API contract
Existing `/notifications` list/read. Response may include `scenario`. No new routes.

### RBAC matrix
Unchanged (Bearer, own notices).

### Data model impact
- Extend `notifications`: `scenario` VARCHAR(64) NOT NULL, unique `(user_id, scenario)`
- Migration `j4k5l6m7n8o9` backfills, deletes duplicate **notification** rows, does not touch listings/media

### Cache / side effects
None beyond existing search invalidation on payment approve.

### Frontend
`Notification.scenario?` on the API type. Bell still lists whatever GET returns.

---

## Definition of done (PM)

- [x] Scenario table in README §5
- [x] One pytest case per scenario in `test_notification_scenarios.py`
- [ ] Status Accepted after Tester
