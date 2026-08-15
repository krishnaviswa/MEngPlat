# ADR-008: Razorpay-only featured listing fee (mock + live port)

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-15 |
| **Slice** | S-036 |

---

## Context

MerchantHub AI has no product payments today (README §14 hold list: “Payments / PCI (Stripe etc.) — no product payments”). Slice S-036 needs a **VC-readable transaction fee** without marketplace GMV, Stripe, subscriptions, or storing cards.

Locked commercial terms:

- One SKU: **featured listing, 7 days, ₹499 INR inclusive** listed price (`49900` paise).
- **One gateway: Razorpay** (India-first). Not Stripe. Not two processors.
- `gateway_fee` = what the gateway actually deducts (~2% + GST; persist webhook figures).
- `platform_fee` = `amount_captured - gateway_fee` (platform take).
- Local/demo must work **without production keys**.
- PAN/card data must never be stored (or logged) in our systems.
- Event grants / sponsorships are a later slice.

This is a new integration (payments) and a schema pattern (ledger + time-bounded placement), so it needs an ADR before build.

---

## Decision

### 1. Single provider: Razorpay, behind a Protocol port

Implement `app/services/payments/` with a `PaymentProvider` Protocol and factory `get_payment_provider()`, selected by `PAYMENTS_PROVIDER=mock|razorpay` (default **`mock`**).

- **`RazorpayPaymentProvider`:** Orders API for checkout, webhook HMAC verification, refunds. Env: `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`. Fail startup if provider is `razorpay` and keys are missing.
- **`MockPaymentProvider`:** Same checkout/webhook/refund shape so Compose and pytest need no Razorpay account. Signed test webhook header **or** `POST /api/v1/payments/mock/complete` (**DEBUG-only**, admin).

Routers stay thin. No Stripe client, no second SKU, no grants tables.

### 2. Hosted Checkout — PAN never on our origin

Browser uses Razorpay Checkout.js with `order_id` + `key_id` returned from `POST /payments/featured/checkout`. We persist `provider_order_id`, amounts in paise, and fee columns only. No card vault, last4, or network tokens.

### 3. Ledger math

On verified `payment.captured` (or mock paid complete):

- `amount_paise` ← `amount_captured`
- `gateway_fee_paise` ← Razorpay `fee` (do not add `tax` on top if `fee` already includes GST)
- `platform_fee_paise` ← `amount_captured - gateway_fee_paise`

Mock may substitute an estimated 2%+GST deduction when `fee` is absent. Invariant on `paid`: fees sum to captured amount.

### 4. Placement, not a rank score

`featured_placements` is a time window (`starts_at` / `ends_at` / optional `disabled_at`). Search ranks **active** rows first (`now < ends_at` and `disabled_at IS NULL`), then existing sort. This is a **paid boost**, not an AI judgment. Webhook (or DEBUG mock-complete) is the only activator.

### 5. Idempotency and admin levers

Unique `payments.provider_order_id`. Replayed webhooks return 200 and do not double-insert placements. Admin `disable` removes rank without refund; admin `refund` calls the provider and disables the placement.

---

## Consequences

### Positive

- India-first checkout without PCI card storage; SAQ surface is hosted Checkout + webhook HMAC.
- Local demo and CI stay offline via `mock`, matching `AI_PROVIDER` / `STORAGE_PROVIDER`.
- Fee split is auditable per payment (`platform_fee` vs `gateway_fee`) for the monetization story.
- Featured rank is data-driven and reversible (expiry, disable, refund) with `search:*` invalidation.

### Negative / tradeoffs

- Razorpay lock-in for v1; adding Stripe later is a new ADR and a new provider class, not a flag on this slice.
- Placement activates only after webhook (or DEBUG complete) — Checkout UI success is not source of truth (safer, slightly delayed rank).
- `DEBUG=true` plus mock-complete is powerful; production must run `DEBUG=false`.
- Duplicate successful captures while a week is active: payment may record, second placement is not created (no stacking). Ops refunds the extra via admin.
- Home page “Featured businesses” copy remains editorial; paid meaning is the search **Featured** badge to avoid mixing products.

### Follow-ups

- Receipt / refund email (S-035) is explicitly out of S-036.
- Mobile Checkout / merchant boost UI: §12 parity `unimplemented` / `future`.
- Grants / event sponsorships: later slice, not this SKU.
- If Razorpay payload variants disagree on `fee` vs `tax`, tighten the parser with a fixture from a live test capture.
- PCI / lawyer review remains on the commercial hold list; this ADR does not claim SOC 2.

---

## Alternatives considered

1. **Stripe (or Stripe + Razorpay).** Rejected: PM/out-of-scope lock is India-first, one gateway; README hold-list Stripe wording is historical, not the design.
2. **Inline card fields posted to our API.** Rejected: would make us a card data environment; violates “never store PAN.”
3. **Percentage take-rate on marketplace GMV.** Rejected: no cart/orders product; this slice is a listing boost SKU only.
4. **Hard-code Razorpay in the router with no mock.** Rejected: local demo and tests could not run without keys (same reason AI/storage use ports).
5. **Activate featured from Checkout `handler` success without webhook.** Rejected: spoofable; webhook HMAC is the trust boundary.
6. **Stack or auto-renew weeks.** Rejected: one SKU, one active week; 409 on checkout if already featured.
