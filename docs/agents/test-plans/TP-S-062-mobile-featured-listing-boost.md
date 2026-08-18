# TP-S-062: Mobile featured listing boost, browse-only (M-66 parity)

## Scope

Verify the 10 numbered AC on `docs/agents/slices/S-062-mobile-featured-listing-boost.md`:
read-only SKU catalog + placement status panel on the merchant dashboard, a `Featured` badge
on `BusinessCard`, an always-shown non-AI-judgment disclaimer on `business_list_screen.dart`,
and — critically — that no mobile code calls `POST /payments/featured/checkout` or bundles a
Razorpay SDK.

## Approach

- Widget tests (`flutter_test`) extending the existing fake-repository pattern in
  `mobile/test/merchant_dashboard_screen_test.dart`, `business_card_test.dart`,
  `business_list_screen_test.dart`.
- No backend tests — no backend route/schema changed (Architect-confirmed, independently
  re-verified against `backend/app/routers/payments.py`).
- AC 8's checkout-boundary requirement is verified by direct code inspection (`grep`), not a
  widget test — a widget test cannot prove the *absence* of a call site across the whole app;
  a static grep is the correct tool here and is what the Architect's spec explicitly asked for.

## AC coverage plan

| AC# | Verification |
|-----|--------------|
| 1 | Widget test: panel renders live SKU prices/durations + static web-handoff copy near the tiles (not just the button) |
| 2 | Widget tests: `featuredBadge` shown only when `isFeatured == true`; `featuredDisclaimerText` always shown (empty and non-empty results) |
| 3 | Widget test: `active == true` → "Active until {expiry}" |
| 4 | Widget tests: no placement → "Not currently featured"; `awaitingApproval == true && active == false` → distinct "awaiting admin approval" copy, never "Active until" |
| 5 | Code inspection: no persistent client-side cache of `isFeatured`/placement (Architect-confirmed; each screen refetches per load) |
| 6 | Code inspection: `PaymentsRepository`/`FeaturedBoostPanel` never request or render `platform_fee_paise`/`gateway_fee_paise` |
| 7 | Trivially true — no checkout UI exists on mobile in this slice (covered by AC 8's grep) |
| 8 | Code inspection: `grep -r featuredCheckoutApiV1PaymentsFeaturedCheckoutPost mobile/lib` → zero hits; `pubspec.yaml` has no razorpay/payment-SDK package |
| 9 | Code inspection: `FeaturedBoostPanel` renders only the existing 3-SKU catalog, no grant/sponsorship UI |
| 10 | Widget test: panel not shown for a pending business |

## Risk-flagged assertions (explicit per Architect)

- Dedicated test asserting the "Buy on web dashboard" button's label and the static note both
  read as an honest hand-off (contain "web dashboard"/"web", never "Buy now"/"Start checkout").
- Dedicated test asserting `awaiting_approval` and `active` are never conflated.

## Out of scope for this test plan

- Real device / `docker compose` smoke test — no new native platform-channel behavior
  introduced (matches S-060's own conclusion for this kind of read-only, no-new-package slice).
