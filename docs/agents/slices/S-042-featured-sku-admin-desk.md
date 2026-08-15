# Slice: S-042 — Featured SKU catalog + admin payment desk

| Field | Value |
|-------|-------|
| **Slice ID** | S-042 |
| **Phase** | 5 Polish |
| **Status** | Accepted |
| **Role(s)** | merchant, admin |
| **Owner** | PM / 2026-08-15 |

---

## User story

**As a** merchant I want three featured boost prices. **As an** admin I want a payment list, mock complete, and approve/reject before search rank changes.

---

## Acceptance criteria

1. **Given** an approved listing, **when** the merchant opens the boost panel, **then** they see three tiles: ₹299/7d, ₹499/15d, ₹899/30d (not an AI score).
2. **Given** checkout with a `sku_code`, **when** capture succeeds, **then** the payment is `paid` with fee split and **no** featured placement until admin approve.
3. **Given** an active placement, **when** checkout is attempted, **then** 409.
4. **Given** mock provider, **when** checkout starts, **then** the merchant sees a demo-order / wait-for-admin message and Razorpay.js is not required.
5. **Given** `/admin` Payments, **when** charges exist, **then** admin sees shop, merchant, SKU, amount, status, and per-merchant count, and can mock-complete, approve, reject, or refund.
6. **Given** approve, **when** processed, **then** a placement window matching `duration_days` is created and search cache is invalidated.
7. **Given** reject, **when** processed, **then** no placement and no automatic refund.
8. **Given** a customer, **when** they call admin payment APIs, **then** 403.

---

## Out of scope

Apple/Facebook login, KYC, live Razorpay keys, stacking boosts, auto-refund.

---

## Technical specification (Architect)

See ADR-010. Endpoints in README §7 Payments. Columns: `sku_code`, `duration_days`, `approved_at`, `rejected_at`.

### Architect checklist

- [x] API contract defined
- [x] RBAC matrix complete
- [x] Data model impact documented

---

## Links

- ADR: `docs/agents/adrs/ADR-010-featured-sku-admin-approve.md`
- Test plan: `docs/agents/test-plans/TP-S-042-featured-sku-admin-desk.md`
- Test report: `docs/agents/test-reports/TR-S-042-featured-sku-admin-desk.md`

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-15 | PM / Architect / Builder / Tester | Specified, built, accepted. |
