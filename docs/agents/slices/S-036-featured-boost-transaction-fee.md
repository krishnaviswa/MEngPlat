# Slice: S-036 — Featured listing boost + platform transaction fee

| Field | Value |
|-------|-------|
| **Slice ID** | S-036 |
| **Phase** | 5 Polish |
| **Status** | Specified |
| **Role(s)** | merchant, admin |
| **Owner** | PM / 2026-08-15 |

---

## User story

**As a** merchant with an approved listing  
**I want** to pay a one-time ₹499 fee for a 7-day featured / search boost on a business I own  
**So that** my listing appears first in customer search for that week, while the platform records a transaction fee (platform take plus gateway cost) without storing cards or charging customers

**As an** admin  
**I want** to see the fee split on successful payments and refund or disable a placement  
**So that** featured rank can be withdrawn and the ledger stays honest for a VC-ready monetization story

---

## Acceptance criteria

1. **Given** I am signed in as a merchant and I own an **approved** business, **when** I start checkout for a featured listing boost on that business, **then** I am offered exactly one SKU — a **fixed ₹499 for a 7-day featured week** — and checkout can begin for that listing only (not for businesses I do not own, and not for pending / rejected / suspended listings).
2. **Given** checkout completed and the payment success webhook has been processed, **when** a customer (or anyone) runs search, **then** businesses with an **active** featured placement (now until expiry) rank **before** non-featured results, and the search UI includes copy that this is a **paid featured placement for a fixed period**, not an AI quality judgment or a definitive ranking of which business is “better.”
3. **Given** that same successful payment, **when** I view the merchant dashboard for the boosted business, **then** I see that featured placement is **active** and I see the **expiry** (end of the 7-day week).
4. **Given** payment **fails** or is **cancelled** (or never reaches a successful webhook), **when** search and the merchant dashboard are viewed, **then** that listing is **not** featured — no placement, no rank boost, no “active until” expiry for that attempt.
5. **Given** an active featured placement, **when** an **admin** refunds or disables it, **then** the listing **loses featured rank** immediately (search no longer treats it as featured; merchant dashboard no longer shows it as an active boost). A merchant cannot perform this admin refund/disable action.
6. **Given** a successful payment, **when** an admin inspects the ledger for that payment, **then** they see **platform_fee** and **gateway_fee** recorded for that charge: gateway cost is the India-first gateway’s cut (~2% + GST, as actually charged); **remainder is platform_fee** (the platform take). Customers never see this ledger as a public browsing UI.
7. **Given** a customer is browsing search (signed in or not), **when** featured listings are present, **then** those listings appear first per AC 2, and the **customer is not charged** and is not asked for payment.
8. **Given** checkout and webhooks run in local / demo **test or mock mode**, **when** a merchant completes the happy path without a live production gateway account, **then** AC 2–4 still work (success features; failure does not). **No card numbers are stored** in our database or logs in any mode. (Architect specifies how mock/test is wired; this slice does not require a live production key for local demo.)
9. **Given** this slice’s merchant and admin surfaces, **when** a merchant or admin looks for event grants, event sponsorships, or grant-funded boosts, **then** those are **not** offered — grants / event sponsorships are a **later slice**, not this SKU.

---

## UX notes

- **Screens / routes:** Merchant dashboard buy-boost control (same dashboard merchants already use); customer **search** result list (featured-first ordering + short paid-placement copy); admin surface to **disable / refund** a placement and to **view** platform_fee / gateway_fee on successful payments (admin-only, not a customer page).
- **Components to reuse:** `MerchantDashboard`, existing search list / business cards. Prefer adding a buy-boost control and “active until {expiry}” state on the dashboard rather than a new merchant product catalog. Admin disable/refund should feel like existing admin moderation tools, not a new billing product.
- **Empty states / errors:** No active boost: dashboard offers the 7-day ₹499 SKU for **approved** listings only, with a clear reason if the listing cannot be boosted (not owned, not approved). Checkout cancelled / failed: listing stays unfeatured; show a recoverable error, not a featured badge. Already active: do not imply a second overlapping SKU in this slice (one featured week at a time in the UX). Ledger empty: admin sees no fee rows until a successful payment exists.
- **Ranking copy (required):** Search must document the rule in beginner-friendly language: featured listings are **paid 7-day boosts**, not AI scores and not a judgment that the business is better. AI insights elsewhere stay **suggestions** (unchanged by this slice).
- **Fee model (product, not schema):** Merchant pays **₹499 per 7-day featured week**. Gateway (~2% + GST) is recorded as **gateway_fee**; remainder is **platform_fee**. One India-first gateway only — not two processors. This is a platform listing boost, not marketplace food GMV.
- **AI disclaimer required?** No new AI output. Ranking copy must **not** present featured order as an AI verdict. Existing AI suggestion language on cards/insights is unchanged.

---

## Out of scope

- A second payment gateway or **Stripe** (India-first only; Architect will name the provider and ports).
- A second SKU, subscriptions, auto-renew, or “boost forever.”
- Event **grants** / event sponsorships (later slice — AC 9).
- Transactional **email** (S-035) — no receipt/refund mail required here.
- An **AI billing dashboard** or charging for AI insights.
- Marketplace / food **GMV** take-rate (orders, delivery, cart).
- Storing card PANs or building a card vault (never).
- Customer-facing prices, checkout, or a public “who paid what” page.
- Mobile app checkout (web merchant/admin first; §12 parity tracker should mark mobile as unimplemented / future until a follow-up).

---

## Dependencies

- **S-033** merchant dashboard — **nice-to-have**, not a hard gate: the dashboard already exists; this slice adds a buy-boost control and active/expiry display on that surface.
- Existing **search** and approved-business listing (Phase 2) — featured-first rank applies to the current search list, not a new discovery product.
- **Payments** today sit on the README **hold list** (deferred commercial item: “Payments / PCI (Stripe etc.) — no product payments”). **This slice moves that item to planned** (one SKU, India-first, no cards stored). Do not treat Stripe-on-the-hold-list as the design.
- **S-035** email — **not** a dependency; explicitly out of scope.

---

## Definition of done (PM)

- [ ] All AC verified in test report
- [ ] UX matches notes above (dashboard buy-boost, search ranking + paid-placement copy, admin disable/refund + ledger)
- [ ] Documented in `README.md` §7 API reference / §8 Frontend guide if new patterns; §6 flow if the checkout/webhook path is user-visible
- [ ] `README.md` §12 Web ↔ mobile feature parity tracker has a row for this user-facing web capability (mobile typically `unimplemented` / `future` until a later slice)
- [ ] `README.md` §14 hold-list **Payments** row is updated from deferred to **planned / this slice** (not left as “no product payments”)
- [ ] PM Status set to **Accepted**

---

## Technical specification (Architect)

Filled 2026-08-15. Commercial lock: one SKU (₹499 / 7 days, INR inclusive listed price), Razorpay only, `PAYMENTS_PROVIDER=mock|razorpay`, never store PAN/card. ADR: [`docs/agents/adrs/ADR-008-razorpay-featured-fee.md`](../adrs/ADR-008-razorpay-featured-fee.md) (Proposed).

All new REST routes mount under `/api/v1`. Router: `backend/app/routers/payments.py` (thin). Logic: `backend/app/services/payments/` (Protocol + factory, same shape as `get_storage_provider()` / `get_ai_provider()`). **Do not** call Razorpay from routers. **Do not** add Stripe or grants.

Static paths before dynamic: `/featured/checkout`, `/webhooks/razorpay`, `/mock/complete`, `/admin/placements/{id}/disable`, `/admin/payments/{id}/refund` before `/businesses/{id}/placement`.

### API contract

| Method | Path | Auth | Request | Response | Errors |
|--------|------|------|---------|----------|--------|
| POST | `/payments/featured/checkout` | Merchant (own **approved** business). Admin **not** a buyer. | `{ "business_id": uuid }` | `{ "payment_id", "provider": "mock"\|"razorpay", "provider_order_id", "amount_paise": 49900, "currency": "INR", "sku": { "code": "featured_7d", "duration_days": 7, "listed_price_inr": 499 }, "checkout": { "key_id", "order_id", "amount", "currency", "name", "description", "prefill" } }` | 401; 403 non-merchant; 404 not owned (`get_owned_business`); 400 listing not `approved`; 409 active placement already exists (`disabled_at` null and `now < ends_at`) |
| POST | `/payments/webhooks/razorpay` | **Unauthenticated.** HMAC signature required. Exempt from cookie CSRF if/when CSRF middleware is added (Razorpay cannot send `X-CSRF-Token`). | Raw Razorpay JSON body (`payment.captured` is the success event). Header `X-Razorpay-Signature`. Mock mode: same path; verify `X-Razorpay-Signature` (or documented test header) against `RAZORPAY_WEBHOOK_SECRET` / mock secret — **not** a public unsigned POST. | `200 { "ok": true, "duplicate": bool }` always on valid signature (including replay). | 400 missing/invalid signature; 422 unknown payload that cannot be mapped after signature OK (log + 200 preferred if Razorpay retries on 5xx — Builder: 200 after signature verify, no-op if event is not `payment.captured`) |
| POST | `/payments/mock/complete` | **DEBUG-only** (`settings.debug` true). Admin. | `{ "provider_order_id": str, "outcome": "paid"\|"failed" }` | Same side effects as webhook (`paid` → fees + placement; `failed` → `status=failed`, no placement). | **404** if `DEBUG=false` (do not advertise in prod OpenAPI if easy). 401/403 otherwise; 404 unknown order |
| GET | `/payments/businesses/{id}/placement` | Merchant (own business) or admin | — | `{ "business_id", "active": bool, "placement": null \| { "id", "starts_at", "ends_at", "disabled_at", "payment_id" }, "sku": { ... } }`. **Admin only extra:** `payment`: `{ "id", "status", "amount_paise", "currency", "platform_fee_paise", "gateway_fee_paise", "provider", "provider_order_id", "created_at" }` (latest paid/refunded row for this business, or the placement’s payment). Merchant response **must not** include fee split. | 401; 404 not found / not owned (merchant); 403 customer |
| POST | `/payments/admin/placements/{id}/disable` | Admin | empty | `{ "id", "disabled_at" }` — sets `disabled_at=now` if null (idempotent if already disabled). Invalidates `search:*`. Does **not** refund. | 401/403; 404 |
| POST | `/payments/admin/payments/{id}/refund` | Admin | empty | `{ "id", "status": "refunded" }` — provider refund (mock: in-process mark); payment `status=refunded`; linked placement `disabled_at=now` if still active; invalidate `search:*`. Idempotent if already refunded. | 401/403; 404; 409 not `paid` (e.g. `created`/`failed`) |

**SKU (server-enforced, not client-priced):** amount always `49900` paise, currency `INR`, duration 7 days from webhook success time (`starts_at=now`, `ends_at=now+7d`). Ignore any client amount.

**Checkout fields:** enough for Razorpay Checkout.js (`key`, `order_id`, `amount`, `currency`). Mock returns a fake `key_id` / `order_id`; frontend still calls mock complete in DEBUG rather than loading live Checkout.

**Webhook idempotency:** unique `payments.provider_order_id`. If a `paid` row already exists for that order, return 200, do **not** insert a second `featured_placements` row, do **not** re-credit time. Key the processed event on `provider_order_id` (not a second events table in this slice).

**Fee split (on `payment.captured` only):** `amount_paise` = `amount_captured`. `gateway_fee_paise` = Razorpay payload `fee` (GST is typically already inside `fee`; `tax` is informational — **do not double-count**). `platform_fee_paise` = `amount_captured - gateway_fee_paise`. If `fee` is absent (mock), persist an estimated deduction (~2% + GST on listed price) so the ledger is non-zero; never leave both fees null on `paid`. Invariant: `platform_fee_paise + gateway_fee_paise == amount_paise` on `paid`.

**Search (existing):** `GET /search/businesses` stays public. Rank **active** featured first (`now < ends_at` AND `disabled_at IS NULL`), then existing `sort` (`rating` / `name` / `reviews`) and existing geo distance sort. Tie-break among featured: `ends_at` ascending (sooner expiry first) then current secondary sort. Extend `BusinessResponse` with `is_featured: bool` (false default) so the search UI can badge without a second request. Home `FeaturedGrid` is **editorial city explore** — do not retitle it as paid boost; cards may show the same badge if `is_featured`.

**Not in this slice:** Stripe; subscriptions; stacking/extending an active week; grants; receipt email (S-035); customer checkout; mobile Checkout; `GET` list-all-payments (admin uses drilldown `GET .../placement`).

### RBAC matrix

| Action | customer | merchant | admin |
|--------|----------|----------|-------|
| Browse search (featured-first, no charge) | public | public | public |
| Start featured checkout (own approved listing) | — | ✅ own + approved | — (not a buyer) |
| View placement active/expiry | — | ✅ own | ✅ |
| View `platform_fee` / `gateway_fee` ledger | — | — | ✅ |
| Razorpay webhook | n/a (unsigned callers rejected) | n/a | n/a |
| `POST /payments/mock/complete` | — | — | ✅ and `DEBUG=true` |
| Disable placement | — | — | ✅ |
| Refund payment | — | — | ✅ |

Ownership: `get_merchant_for_user` + `get_owned_business` (404, not 403) for merchant-scoped routes. `require_roles(UserRole.MERCHANT)` on checkout; `require_roles(UserRole.MERCHANT, UserRole.ADMIN)` on GET placement; `require_roles(UserRole.ADMIN)` on disable/refund/mock-complete.

### Data model impact

- [ ] None  [ ] Extend existing  [x] New table(s)

**Enums:** `PaymentStatus`: `created` | `paid` | `failed` | `refunded`. `PaymentProvider` stored as string `mock` | `razorpay` (not a third provider).

**`payments`**

| Column | Type | Notes |
|--------|------|--------|
| `id` | UUID PK | |
| `business_id` | UUID FK `businesses` | |
| `merchant_user_id` | UUID FK `users` | Buyer user, not `merchants.id` |
| `provider` | str | `mock` \| `razorpay` |
| `provider_order_id` | str **UNIQUE** | Razorpay `order_id` / mock id — webhook idempotency key |
| `status` | enum | `created` \| `paid` \| `failed` \| `refunded` |
| `amount_paise` | int | Always 49900 for this SKU |
| `currency` | str | `INR` |
| `platform_fee_paise` | int nullable | Set on `paid`; remainder after gateway |
| `gateway_fee_paise` | int nullable | Actual webhook deduction (or mock estimate) |
| `created_at` | timestamptz | |

No PAN, card last4, CVV, or network token columns. Optional later: `provider_payment_id` — **out of locked table list**; Builder may add a nullable string if needed for Razorpay refunds **without** storing card data (document in README §5 if added). Prefer resolving refunds via `provider_order_id`.

**`featured_placements`**

| Column | Type | Notes |
|--------|------|--------|
| `id` | UUID PK | |
| `business_id` | UUID FK `businesses` | |
| `payment_id` | UUID FK `payments` | One placement per successful payment |
| `starts_at` | timestamptz | Webhook success time |
| `ends_at` | timestamptz | `starts_at + 7 days` |
| `disabled_at` | timestamptz nullable | Admin disable or refund |

**Active** = `disabled_at IS NULL AND now() < ends_at`. Application-enforced: at most one active placement per `business_id` (checkout 409; webhook no-op second placement). Index `(business_id)` on both tables; unique `provider_order_id`; unique `payment_id` on placements.

Alembic migration required (`create_all` is not the schema owner). ERD update in README §5 **when built**. Seed: optional demo paid placement only if `PAYMENTS_PROVIDER=mock` and clearly labelled — not required for DoD.

### Cache / side effects

- Invalidate `search:*` via `cache_delete_pattern("search:*")` when a placement **activates** (first transition to `paid` + row insert) or **deactivates** (`disabled_at` set, including refund).
- Do not invalidate on `created` or `failed`.
- No AI calls. No storage provider. No S-035 email.
- Razorpay Checkout.js is loaded only when `provider=razorpay`; mock path never posts card data to our API.

### Payments port (`app/services/payments/`)

Mirror AI/storage:

- `PaymentProvider` Protocol: `create_order(amount_paise, currency, receipt, notes) -> ProviderOrder`; `verify_webhook(body, signature) -> WebhookEvent | None`; `refund(provider_order_id) -> None`; helper to read `amount_captured` / `fee` from captured payload.
- `MockPaymentProvider` — in-memory/DB-backed orders, HMAC with webhook secret or fixed test secret; local demo with **no** Razorpay keys.
- `RazorpayPaymentProvider` — Orders API + signature verify + refunds. Keys only in env.
- `get_payment_provider()` from `PAYMENTS_PROVIDER`. Startup: if `razorpay`, require `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET` (fail boot like missing AI key). Default **`mock`**.

### Frontend

- **Route:** `/merchant/dashboard` — boost CTA + “active until {ends_at}” (CSR, existing `MerchantDashboard`). `/search` — featured-first list + **Featured** badge + beginner copy: paid 7-day boost, **not** AI quality, **not** “better business” (SSR search page; badge on `BusinessCard`). `/admin/businesses/[id]` — admin disable / refund + fee ledger (CSR drilldown). No new public pricing or customer checkout route.
- **Rendering:** Dashboard/admin CSR (`"use client"`). Search stays SSR; pass `is_featured` through existing search fetch.
- **Components (reuse first):** `MerchantDashboard`, `BusinessCard`, admin business drilldown. New: small boost control + Razorpay Checkout wrapper used only when checkout `provider=razorpay`. Mock DEBUG: merchant/admin test complete via `POST /payments/mock/complete` (admin) — for merchant demo without admin, Builder may document Compose using mock webhook with signed test header from a script; **do not** expose mock-complete to merchants.
- **Copy:** Badge label **Featured**. Search helper text must state paid placement for a fixed period. Do not reuse AI “suggestion” as the badge. Home `FeaturedGrid` title unchanged (not this SKU).
- **Empty / errors:** Not approved / not owned: CTA disabled with reason. Checkout cancel/fail: no badge, recoverable error. Already active: hide second purchase (409).
- **API client:** extend `frontend/src/lib/api.ts` only.
- **Mobile:** unimplemented / `future` in §12; no Flutter Checkout in this slice.

### Flow

```mermaid
sequenceDiagram
    participant Merchant
    participant Web as Next.js
    participant API as FastAPI
    participant Pay as PaymentProvider
    participant RZ as Razorpay or mock
    participant DB as PostgreSQL
    participant Redis
    participant Search as GET /search/businesses

    Merchant->>Web: Boost CTA (approved listing)
    Web->>API: POST /payments/featured/checkout
    API->>API: require_roles merchant + owned + approved + no active placement
    API->>Pay: create_order 49900 INR
    Pay->>RZ: Orders API (no-op mock)
    API->>DB: payments status=created
    API-->>Web: order_id + checkout fields
    alt provider=razorpay
        Web->>RZ: Checkout.js (PAN never hits our API)
        RZ->>API: POST /payments/webhooks/razorpay (signed)
    else provider=mock DEBUG
        Note over Web,API: Admin POST /payments/mock/complete or signed mock webhook
    end
    API->>Pay: verify_webhook
    alt signature fail
        API-->>RZ: 400
    else duplicate provider_order_id already paid
        API-->>RZ: 200 duplicate
    else payment.captured
        API->>DB: status=paid, gateway_fee, platform_fee, featured_placements 7d
        API->>Redis: cache_delete_pattern search:*
        API-->>RZ: 200
    else failed
        API->>DB: status=failed (no placement)
    end
    Search->>DB: approved businesses, featured-active first
    Note over Search: is_featured badge; copy is paid boost not AI
```

Admin disable/refund: admin drilldown → `POST .../disable` or `.../refund` → `disabled_at` → invalidate `search:*`. Merchant cannot call these.

### README when built (Builder — do not invent extra .md)

`README.md` is the only prose doc:

| Section | Update |
|---------|--------|
| §5 Domain model / ERD | `payments`, `featured_placements`, enums |
| §6 Feature flows | checkout → webhook → featured-first search |
| §7 API reference | `/payments/*` table + search note (`is_featured`, rank) |
| §9 Security | PCI: hosted Checkout; we store order/payment ids and paise only; **never PAN**; webhook HMAC; mock-complete DEBUG-only |
| §12 parity tracker | new row: merchant boost + search Featured badge; mobile `unimplemented` / `future` |
| §14 | Move **Payments / PCI** off hold as **shipped (this slice)** — one SKU, Razorpay, no cards stored; Stripe stays out of scope |
| §15 | `PAYMENTS_PROVIDER`, `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET` |
| §16 | New short **fee numbers** subsection: listed ₹499 / 49900 paise / 7 days; `gateway_fee` ≈ 2%+GST actual from webhook; `platform_fee` = remainder |

### Architect checklist

- [x] API contract defined and matches README §7 style (`/api/v1`, method, auth, notes)
- [x] RBAC matrix for all roles
- [x] Data model impact documented; ERD update noted for Builder
- [x] Cache invalidation considered (`search:*` on activate/disable)
- [x] Payments use Protocol port (not routers); AI/storage unused; no secrets in design
- [x] ERD/API/FLOWS/§9/§12/§14/§15/§16 updates noted for implementation landing
- [x] ADR-008 Proposed (Razorpay + mock port + fee split)

### Risks / tradeoffs

- **Webhook vs Checkout success callback:** rank and placement change **only** after verified webhook (or DEBUG mock-complete). Client “payment success” is not enough — avoids spoofed frontend confirms.
- **Razorpay `fee` vs `tax`:** using `fee` as `gateway_fee` avoids double-counting GST. If a payload variant stores tax outside `fee`, Tester should assert `platform + gateway == captured`.
- **DEBUG mock-complete is an admin foot-gun** if `DEBUG=true` in a deployed env. Production must set `DEBUG=false`; route 404s. Default `PAYMENTS_PROVIDER=mock` so Compose works without keys.
- **No stacking:** second paid webhook while active records payment but does not extend — ops may need admin refund of the duplicate. Checkout 409 reduces this.
- **Geo search** currently re-sorts in Python by distance and **drops** SQL `order_by`. Builder must apply featured-first **after** the distance filter (featured, then distance).
- **Home “Featured businesses”** is a pre-existing editorial label; paid SKU copy lives on **search** + badge to avoid implying the homepage grid is the paid product.
- **CSRF vs webhook:** unauthenticated POST must stay CSRF-exempt. Document in §9 when CSRF (ADR-004) lands in code.
- **PCI SAQ:** hosted fields / Checkout keeps PAN off our DB; still not a pentest/SOC 2 claim.

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-036-*.md`
- Test report: `docs/agents/test-reports/TR-S-036-*.md`
- ADR: [`docs/agents/adrs/ADR-008-razorpay-featured-fee.md`](../adrs/ADR-008-razorpay-featured-fee.md)

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-15 | PM | Created slice. Monetization is deferred on the README hold list today; VC story needs a **transaction fee** without inventing marketplace GMV. One SKU only: **₹499 / 7-day featured listing (search boost)**. India-first gateway; **never store cards**; local **test/mock** must demo without live production keys (Architect specifies port). Event grants are **not** this slice. Fee split is product-level: gateway (~2% + GST) → `gateway_fee`, remainder → `platform_fee`. 9 numbered AC, UX (MerchantDashboard + search list + admin refund/disable), out of scope (Stripe, two SKUs, subscriptions, grants, S-035 email, AI billing). Dependencies: S-033 nice-to-have; payments move from hold → planned. Architect section left as template for Razorpay/gateway details. Status: **Draft**. |
| 2026-08-15 | Architect | Technical spec: Razorpay + `PAYMENTS_PROVIDER` mock port; tables `payments` / `featured_placements`; locked `/api/v1` payment endpoints including DEBUG-only `POST /payments/mock/complete`; webhook HMAC + `provider_order_id` idempotency; fee split from captured webhook; search featured-first + `search:*` invalidation; README §5–7, §9, §12, §14–16 when built. ADR-008 Proposed. Status: **Specified**. Handoff: Builder. |
