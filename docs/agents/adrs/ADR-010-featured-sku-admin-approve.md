# ADR-010: Featured SKU catalog and admin-approved placement

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-15 |
| **Slice** | S-042 |

---

## Context

S-036 / ADR-008 locked one SKU (₹499 / 7 days) and activated featured rank on payment capture. Operators need three prices, a payment list on `/admin`, and a human approve step so capture is not the same as boosting search.

---

## Decision

1. Keep Razorpay + `PAYMENTS_PROVIDER=mock|razorpay`. Never store cards.
2. Catalog: `featured_7d` ₹299, `featured_15d` ₹499, `featured_30d` ₹899.
3. Capture (`paid` + fee split) does **not** insert `featured_placements`.
4. `payments.approved_at` / `rejected_at` gate the boost. Approve creates the window from `duration_days`. Reject does not refund.
5. One active placement per business (checkout 409 if already featured).

---

## Consequences

### Positive
- Admin can see every charge and choose when a listing is featured.
- Mock checkout no longer implies Razorpay.

### Negative / tradeoffs
- Paid money can sit without a boost until an admin acts.
- S-036 tests that assumed capture = placement are superseded.

### Follow-ups
- Live Razorpay keys remain ops, not this ADR.

---

## Alternatives considered

1. Auto-feature on capture (S-036) — rejected; founder needs approval.
2. Auto-refund on reject — rejected; keep refund explicit.
