# TR-S-036: Featured listing boost + platform transaction fee — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-036 |
| **Author** | Tester |
| **Date** | 2026-08-15 |
| **Recommendation** | Ship |
| **Shot** | Test shot 1 (S-036 only) |

---

## Summary

Pass. All 9 AC mapped and verified. This report **replaces** the previous stub TR (file-mapping only, pytest never run, Builder-set PM Accepted). Backend coverage is DB-free (`backend/tests/test_payments.py`, 30 tests, all green). Frontend S-036 surfaces are covered by RTL/Jest (boost panel, search copy + Featured badge, admin ledger, dashboard host).

**Environment constraint (same class as `TR-S-035` / `TR-S-018`):** `backend/.env` `DATABASE_URL` points at the **live Railway** Postgres instance. This pass did **not** run ASGI + real Postgres, and did **not** run the ignored live-DB files (`test_admin_browse_asgi.py`, `test_api.py`, etc.). Assertions use direct router/service calls + fakes, matching the dominant repo convention. `PAYMENTS_PROVIDER` default is `mock`; no live Razorpay account was used.

**Alembic `d5e6f7a8b9c0`:** the revision now uses `postgresql.ENUM(..., create_type=False)` plus a single `payment_status.create(..., checkfirst=True)`. Confirmed by code read and `test_migration_creates_enum_once`. That DuplicateObjectError is **not** a product AC fail.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Merchant checkout: one SKU ₹499 / 7 days; own **approved** listing only | A | `test_payments.py::TestSkuAndSchema::test_sku_is_single_499_7d`; `::TestFeaturedCheckoutRouter::test_approved_checkout_uses_fixed_sku` (49900 paise, `featured_7d`); `::test_pending_listing_is_400`; `::test_active_placement_is_409`; `::TestPaymentsRBAC::test_checkout_requires_merchant[customer]` and `[admin]` (403); `FeaturedBoostPanel.test.tsx` pending hides Boost button; `MerchantDashboard.test.tsx` hosts ₹499 CTA | Pass |
| 2 | Active featured ranks first; search copy is **paid placement**, not AI verdict | A + M | A: `search/__tests__/page.test.tsx` (paid 7-day boost, not AI quality, not “better”; Featured badge + helper copy; no customer checkout); `BusinessCard.test.tsx` Featured badge only when `is_featured`; `test_payments.py::TestApplyCaptured::test_paid_creates_placement_and_invalidates_search`; `::TestPlacementActive::test_disabled_or_expired_is_not_active`. M-001: `search.py` SQL `order_by` featured-first then `ends_at` then secondary sort; geo path sorts `(0, ends_at, dist)` before non-featured | Pass (rank SQL not executed on Postgres — see Gaps) |
| 3 | Merchant dashboard shows active + expiry | A | `FeaturedBoostPanel.test.tsx` “Active until”; no second Boost button while active | Pass |
| 4 | Failed / cancelled payment does not feature | A | `test_payments.py::TestApplyCaptured::test_failed_does_not_place`; `::TestApplyCapturedAlreadyPaid::test_already_paid_does_not_stack_placement` (replay does not insert a second week) | Pass |
| 5 | Admin disable/refund drops rank immediately; merchant cannot | A | `::TestDisableRefund::test_disable_sets_disabled_at`; `::test_refund_disables_linked_placement`; `::test_refund_rejects_created` (409 path); `::TestPaymentsRBAC::test_admin_actions_require_admin[customer]` and `[merchant]`; admin drilldown Disable/Refund buttons | Pass |
| 6 | Admin ledger shows `platform_fee` and `gateway_fee`; not a customer UI | A | `::TestFeeSplit::test_mock_estimate_sums_to_captured`; `::test_webhook_fee_not_double_counted`; `::TestPlacementLedgerRBAC::test_admin_response_includes_fee_split`; `::test_merchant_response_omits_fee_split`; admin page “platform ₹ / gateway ₹” | Pass |
| 7 | Customer search is not charged | A + M | A: search page has no pay/checkout/boost control. M-002: public `GET /search/businesses`; no customer payments routes; admin copy “Customers are not charged” | Pass |
| 8 | Mock/test mode demos AC 2–4; **no card PAN stored** | A | `::TestMockProvider::test_create_order_no_network`; `::test_verify_rejects_bad_signature`; `::TestWebhookAndMockComplete::test_webhook_missing_signature_is_400`; `::test_mock_complete_404_when_debug_false`; `::TestPaymentsStartup::test_mock_needs_no_razorpay_keys`; `::test_razorpay_without_keys_fails_startup`; `::test_payment_and_placement_tables_store_no_card_pan`; FeaturedBoostPanel “Cards never go to this app” | Pass |
| 9 | No event grants / sponsorships SKU | A + M | A: dashboard/boost panel have no grant/sponsorship copy; admin “Event grants are not offered here”. M-003: no grants routes or tables in this slice | Pass |

**Coverage:** 9 / 9 AC mapped

---

## Backend tests

### Added / expanded
- `backend/tests/test_payments.py` — **30 tests** (Builder seed + this Tester pass):
  - Fee split invariant (mock ~2%+GST and webhook `fee` not double-counted)
  - HMAC round-trip + captured payload parse
  - Mock provider: no network; bad signature rejected
  - RBAC: checkout merchant-only (customer + **admin not a buyer**); disable/refund admin-only (customer + merchant)
  - `apply_captured_payment` inserts placement + `search:*` invalidation; `mark_payment_failed` does not
  - Disable + refund disable placement; refund of `created` raises
  - SKU lock; Payment/FeaturedPlacement columns have no card/PAN fields
  - `is_placement_active` false when disabled or expired
  - Checkout router: 400 pending, 409 already featured, happy path 49900 INR
  - Webhook 400 without signature; mock-complete 404 when `DEBUG=false`
  - GET placement: merchant omits ledger; admin includes platform+gateway
  - Startup: mock needs no keys; razorpay missing keys fails; `stripe` rejected
  - Alembic: `create_type=False` + one `create(checkfirst=True)`

### Run output
```
cd backend && .venv/Scripts/python.exe -m pytest -q tests/test_payments.py

30 passed in 6.28s
```

**Not run (on purpose):** full `pytest` including ASGI files that hit Railway `DATABASE_URL`. Same policy as TR-S-035.

---

## Frontend tests

### Added / expanded
- `frontend/src/components/__tests__/FeaturedBoostPanel.test.tsx` — pending blocks CTA; active expiry; ₹499 / 7-day paid copy, not AI, no grants
- `frontend/src/components/__tests__/BusinessCard.test.tsx` — Featured badge gated on `is_featured`
- `frontend/src/app/search/__tests__/page.test.tsx` — paid-boost copy + badge; no customer checkout
- `frontend/src/app/admin/businesses/__tests__/page.test.tsx` — ledger fees, disable/refund, customers not charged, no grants
- `frontend/src/components/__tests__/MerchantDashboard.test.tsx` — dashboard hosts boost panel (S-036); S-037 chart cases in the same file are **out of this slice**

### Run output
```
cd frontend && npx jest --ci src/app/search/__tests__/page.test.tsx \
  src/components/__tests__/FeaturedBoostPanel.test.tsx \
  src/components/__tests__/BusinessCard.test.tsx \
  src/app/admin/businesses/__tests__/page.test.tsx

PASS (4 suites; S-036 files above)

cd frontend && npx jest --ci src/components/__tests__/MerchantDashboard.test.tsx
29 passed, 1 failed
  FAIL: "renders review volume as an area chart (not bars)" — S-037, not S-036
  S-036 case "hosts the featured boost panel..." passed
```

Full `npx jest --ci` also failed **Charts.test.tsx** (3 S-037 variant tests). Those are the parallel S-037 plan, not S-036 blockers.

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | Code review: `backend/app/routers/search.py` ranks active featured first (`disabled_at IS NULL` and `ends_at > now`), then existing sort; geo applies featured-first **after** the distance filter; `is_featured` on `BusinessResponse` | Pass (static) |
| M-002 | Public search has no checkout; payments routes are merchant/admin/webhook only | Pass (static) |
| M-003 | No grants/sponsorship routes, tables, or merchant SKU besides `featured_7d` | Pass (static) |
| M-004 | `docker compose up --build` happy-path mock checkout → webhook/mock-complete → search badge | Not executed — no Docker in this environment. Covered by mock provider + apply_captured + UI tests |
| M-005 | Swagger `/docs` matches `/api/v1/payments/*` contract | Not executed live. Router paths/auth match the slice API table |
| M-006 | Live Razorpay `payment.captured` fixture (`fee` vs `tax`) | Not executed — no production/test Razorpay keys in this pass |

---

## RBAC / PCI / ranking copy

- **401:** not exercised via ASGI (no anonymous client against a live app). Unauthenticated callers still hit `require_roles` / `get_current_user` the same way as the rest of the API. Flagged as the TR-S-035-class infrastructure gap, not a missing `Depends`.
- **403:** checkout rejects customer and **admin**; disable/refund reject customer and **merchant**. Merchant GET placement omits fee split.
- **Ownership:** checkout uses `get_owned_business` (existing 404-not-owned). Not re-proven with a second-merchant ASGI case in this pass.
- **Card PAN:** `payments` / `featured_placements` have no card/last4/CVV columns. Checkout.js / mock complete never posts PAN to our API. `users.national_id_type=pan` is **Indian tax ID** from S-018/S-020, not a card number.
- **Ranking copy:** search helper + boost panel state paid 7-day placement, **not** an AI quality score and **not** “better business.” Home `FeaturedGrid` title remains editorial.

---

## Alembic note (Builder fix)

`backend/alembic/versions/20260815_1037-d5e6f7a8b9c0_add_payments_and_featured_placements.py`:

- `create_type=False` on `postgresql.ENUM`
- `payment_status.create(op.get_bind(), checkfirst=True)` once before `create_table`
- `test_migration_creates_enum_once` asserts that shape

Does **not** fail product AC. Railway DuplicateObjectError should not recur on a fresh upgrade.

---

## Regressions

No S-036 product regressions found.

**Out of slice (do not block S-036 Ship):** Jest failures in `Charts.test.tsx` and one MerchantDashboard S-037 area-chart assertion. Assign to the S-037 Tester/Builder shot.

---

## Gaps / rework items

None block shipping S-036. Awareness only:

1. **No live Postgres/Redis/ASGI round trip** for checkout → webhook → search rank. Rank SQL is code-reviewed (M-001), not executed. Same isolated-test-DB gap as TR-S-035.
2. **M-004 / M-005 / M-006 not live** — no Docker, no Swagger process, no Razorpay capture fixture.
3. **401 unauthenticated** not separately asserted on the new routes (Depends chain exists; no ASGI client this pass).
4. **Second-merchant ownership 404** relies on `get_owned_business` rather than a dedicated S-036 test.

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested (merchant vs admin; admin not a buyer; merchant cannot disable/refund)
- [x] Ranking copy is paid placement, not an AI verdict
- [x] No card PAN on payment tables
- [x] Ready for PM acceptance (PM owns `Status: Accepted`; this pass does not set it)
