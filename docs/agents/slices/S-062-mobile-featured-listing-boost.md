# Slice: S-062 — Mobile featured listing boost, browse-only (parity for M-66)

| Field | Value |
|-------|-------|
| **Slice ID** | S-062 |
| **Phase** | 4 Dashboards |
| **Status** | Specified |
| **Role(s)** | merchant \| customer |
| **Owner** | PM / 2026-08-18 |

---

## User story

**As a** merchant using the mobile app
**I want** to see the featured-listing SKU catalog (three fixed prices/durations) and my
business's current placement status (active + expiry, or not featured) on the mobile dashboard
**So that** I know what a featured boost costs and whether one is currently running on my
listing, even though I complete the actual purchase on the web dashboard for now

**As a** customer (or any member of the public) browsing businesses on mobile
**I want** to see a clear, honest "Featured" badge on listings that have paid for a boosted
search position, with copy that makes clear this is a paid placement, not a quality judgment
**So that** I'm not misled into thinking a featured business was rated higher by AI or by other
customers

---

## Acceptance criteria

Numbered to parity-match S-036's 9 web AC one-for-one as far as makes sense, adapted to
Flutter/mobile after reading S-036 and S-042 in full and directly inspecting
`mobile/lib/features/merchant/merchant_dashboard_screen.dart`,
`mobile/lib/features/merchant/dashboard_repository.dart`,
`mobile/lib/features/businesses/business_card.dart`, `mobile/lib/features/businesses/`, the
generated `mobile/packages/merchanthub_api/lib/src/api/payments_api.dart`, and the backend
payments router — see "Current state verified" in UX notes.

**Important scope clarification, read before implementing (do not re-litigate):** this slice
does **not** add checkout-initiation to mobile. Starting a real (or mock) payment — i.e. calling
`POST /payments/featured/checkout` from the mobile client — is explicitly **out of scope**, per
S-036's own Out-of-scope line ("Mobile app checkout (web merchant/admin first)") and the current
`README.md` §12 M-66 note ("web built — mobile checkout later"). That deferral was a deliberate
product sequencing call on web's own slice, not a symptom of web's payment flow being
incomplete or mocked — S-036/S-042's web checkout is fully built (mock/Razorpay provider
abstraction, admin capture-then-approve gate, no cards stored) and is `Accepted`. This slice's
job is to close the **read/display** half of the mobile gap (SKU catalog, placement status,
Featured badge) while leaving the **write/checkout** half explicitly deferred to a dedicated
future slice, because adding a mobile payment-SDK integration (e.g. `razorpay_flutter`,
platform-specific native setup) is a materially different, larger, PCI-adjacent surface than
displaying already-computed, already-public data — it deserves its own Architect review, not to
be silently bundled into a parity/display slice.

1. **(Parity for S-036 AC 1 — SKU visibility, not checkout)** Given I am signed in as a
   merchant and I own an **approved** business, when I open a "Featured boost" info panel on the
   mobile merchant dashboard for that business, then I see the same three fixed SKUs web offers
   (₹299/7 days, ₹499/15 days, ₹899/30 days — `GET /payments/featured/skus`, already generated
   as `featuredSkusApiV1PaymentsFeaturedSkusGet`), with a clear, honest note that purchase is
   completed on the web dashboard for now (not a dead end, not a fake "coming soon" placeholder
   with no path forward — see UX notes for the exact affordance). This panel is not shown for a
   pending/rejected/suspended business, matching S-036 AC 1's "approved" gate.
2. **(Parity for S-036 AC 2 — featured-first + non-AI-judgment badge)** Given the backend already
   ranks businesses with an active featured placement first in search results (existing,
   unmodified `GET /search/businesses` behavior, S-036), when I browse businesses on the mobile
   business list / search screen (`business_list_screen.dart`, rendered via `BusinessCard`),
   then any business whose `BusinessResponse.isFeatured` is `true` (field already present in the
   generated model, confirmed by grep, currently unused by `business_card.dart`) shows a
   **Featured** badge, and the screen carries copy stating this is a **paid, fixed-period
   placement — not an AI quality score and not a judgment that the business is better** (parity
   wording with web's `search/page.tsx` disclaimer). The mobile list must not re-sort results
   client-side in a way that would undo the backend's featured-first ordering.
3. **(Parity for S-036 AC 3 — dashboard shows active/expiry)** Given that same approved,
   currently-featured business, when I view the mobile merchant dashboard, then I see the
   placement is **active** and its **expiry** date/time (`GET
   /payments/businesses/{id}/placement`, already generated as
   `getPlacementApiV1PaymentsBusinessesBusinessIdPlacementGet`) — the mobile equivalent of web's
   "active until {expiry}" dashboard state.
4. **(Parity for S-036 AC 4, adapted — no purchase attempt exists on mobile to fail)** Given a
   business has no active featured placement (never purchased, purchase pending admin approval
   per S-042, expired, or disabled/refunded), when I view it on the mobile dashboard or in
   search/business-list, then it shows no Featured badge and no "active until" copy — a clean
   "not featured" / "awaiting approval" state, never a fabricated or stale badge. (There is no
   mobile-initiated checkout attempt in this slice to "fail" or "cancel," so this AC is about
   absence-of-badge correctness, not error-path UX.)
5. **(Parity for S-036 AC 5 — admin disable/refund reflected)** Given an admin disables or
   refunds an active placement (existing, unmodified admin web/backend action, S-036/S-042),
   when the mobile dashboard or business list is next fetched (no client-side caching of
   placement/`isFeatured` state across sessions), then that listing no longer shows as featured
   anywhere on mobile — same live-data guarantee S-060 held for dashboard stats (no stale
   client-side filter of an old payload).
6. **(Parity for S-036 AC 6 — fee ledger stays admin-only, and stays off mobile in this
   slice)** Given `platform_fee`/`gateway_fee` are admin-only fields on the placement response
   (backend-enforced: "Merchant response must not include fee split," S-036), when a merchant
   views the mobile dashboard's featured panel, then no fee-split data is requested, received, or
   rendered — this slice builds no admin payment desk or ledger UI on mobile at all (see Out of
   scope); admin's existing web ledger (`/admin/businesses/[id]`) is unchanged and remains the
   only place fee data is visible, on either platform.
7. **(Parity for S-036 AC 7 — customer never charged)** Given a customer (signed in or not)
   browses businesses on mobile, when featured listings are present (AC 2), then the customer is
   never shown a payment prompt, checkout control, or charge of any kind — trivially true in this
   slice since mobile initiates no checkout at all, but stated explicitly to match S-036's own
   AC 7 wording.
8. **(Mobile-specific — explicit deferral of checkout-initiation, replaces S-036 AC 8's
   mock/test-mode requirement)** Given this slice's mobile scope, when a merchant looks for a
   "Buy now" / "Start checkout" control that actually creates a payment order from the mobile
   app (mock or live Razorpay), then none exists — no `POST /payments/featured/checkout` call is
   ever made from mobile code in this slice, and no Razorpay mobile SDK (`razorpay_flutter` or
   equivalent) is added to `pubspec.yaml`. The only mobile-initiated payments-API calls in this
   slice are the two read-only `GET`s in AC 1 and AC 3.
9. **(Parity for S-036 AC 9 — no grants)** Given this slice's merchant-facing featured panel,
   when a merchant looks for event grants, event sponsorships, or grant-funded boosts, then those
   are **not** offered — only the same three paid SKUs S-042 already locked on web, matching
   S-036 AC 9's boundary exactly.
10. **(Mobile-specific — permission/role case)** Given the "Featured boost" info panel from AC 1,
    when a **customer or admin** (not the owning merchant), or a merchant viewing a
    pending/rejected/suspended business of their own, attempts to reach that panel, then it is
    not shown/reachable — inherits the existing merchant-dashboard role gate (router-level,
    unchanged) plus the existing approved-only business gate already used elsewhere on this
    screen (e.g. the existing `shareReviewLinkButton`'s `if (business.status ==
    BusinessStatus.approved)` pattern from S-059).

---

## UX notes

- **Screens / routes affected:**
  - `mobile/lib/features/merchant/merchant_dashboard_screen.dart` — gains a read-only "Featured
    boost" info panel (SKU catalog + placement status) for an approved, currently-selected
    business (AC 1, 3, 4, 6, 8, 10). No new route.
  - `mobile/lib/features/businesses/business_card.dart` (and, by extension, every screen that
    renders it — `business_list_screen.dart` / Explore, Favorites) — gains a **Featured** badge
    when `business.isFeatured == true` (AC 2, 4, 5).
  - `mobile/lib/features/businesses/business_list_screen.dart` (or wherever the search/list
    result count/header text lives) — gains the non-AI-judgment disclaimer copy parity-matched to
    web's `search/page.tsx` line 113 ("Listings marked **Featured** paid for a 7-day search
    boost — that is not an AI quality score and does not mean the business is better."), adapted
    to mention that duration varies by the SKU purchased (7/15/30 days per S-042, not always 7).
- **Current state verified (not assumed) before writing these AC:**
  - `BusinessResponse` (`mobile/packages/merchanthub_api/lib/src/model/business_response.dart`)
    **already has** a generated `isFeatured` (`bool?`, default `false`) field (confirmed by
    grep — lines 111, 120, 274-277, 475) — same field S-036 added to the backend schema. Mobile's
    generated client is not behind; `business_card.dart` (read in full, 112 lines) simply never
    reads or renders it today — no badge, no chip, nothing featured-related exists on that widget.
  - `mobile/packages/merchanthub_api/lib/src/api/payments_api.dart` (and its doc,
    `PaymentsApi.md`) **already has all nine** S-036/S-042 payments endpoints fully generated:
    `featuredSkusApiV1PaymentsFeaturedSkusGet` (catalog), `getPlacementApiV1
    PaymentsBusinessesBusinessIdPlacementGet` (active/expiry + catalog, fee-split admin-only per
    backend), `featuredCheckoutApiV1PaymentsFeaturedCheckoutPost` (checkout — **intentionally not
    called by this slice**, see the scope clarification above), plus the admin-only
    approve/reject/disable/refund/mock-complete/webhook endpoints. **No mobile code anywhere
    calls any of these today** (confirmed by grep for `isFeatured`/`Featured` across
    `mobile/lib/` — zero hits outside test/doc/generated-client files). `dashboard_repository.dart`
    (read in full) has no payments-related method.
  - **No `razorpay_flutter` or any Razorpay/payment-SDK package exists in `mobile/pubspec.yaml`**
    (grepped, zero hits) — confirms there is no existing mobile checkout capability to
    accidentally regress, and that adding checkout-initiation would be new SDK/native-config
    surface, not a small wiring change (this is *why* checkout stays out of scope here, not an
    oversight).
  - `mobile/lib/core/config/app_config.dart` **already has** `AppConfig.webBaseUrl`
    (`String.fromEnvironment('WEB_BASE_URL', ...)`, added in S-059) — directly reusable for AC 1's
    "complete purchase on web" affordance (e.g. an `url_launcher` open of
    `{webBaseUrl}/merchant/dashboard`, the same `launchUrl(..., mode:
    LaunchMode.externalApplication)` pattern already used for S-059's Maps suggestion) — no new
    config value or package needed for that half of AC 1.
  - `mobile/lib/features/businesses/search_controller.dart` (read in full) does **not**
    client-side re-sort results by any field (no `sort`/`distance`/`orderBy` logic found by grep)
    — results are rendered in the order the backend returns them, so AC 2's "must not undo
    backend featured-first ordering" requirement is **already satisfied by construction**; this
    is a display-only addition (the badge), not a new sorting mechanism to build or a
    regression risk to guard against beyond "don't add client-side sorting."
  - Web's exact badge/copy precedent (for parity of wording, not literal component reuse):
    `frontend/src/components/BusinessCard.tsx` renders a `"Featured"` badge; `frontend/src/app/
    search/page.tsx` line 113 carries the non-AI-judgment disclaimer sentence quoted above.
  - **Conclusion: no backend gap.** Every field and endpoint this slice's AC need already exists,
    unmodified, and is already generated into the mobile OpenAPI client — same standard S-057/
    S-058/S-059/S-060 held themselves to. The only work is mobile-client display code (a badge
    widget change, a new read-only dashboard panel, two new `DashboardRepository`-style
    read-only methods) — deliberately **not** the checkout call, which is explicitly deferred
    (see scope clarification).
- **Components to reuse:** `BusinessCard` (extend, not replace — add the badge in the same
  `Stack`/`Positioned` region the existing category `Chip` uses, top-left or top-right of the
  photo, per Architect's call), `merchant_dashboard_screen.dart` (extend with a new panel,
  following the same `_StatTile`/section pattern already used for reply-rate, CSV export, etc.
  from S-060), `AppConfig.webBaseUrl` + `url_launcher` (both already present, reused from S-059).
- **Empty states / errors:**
  - No SKU data reachable (network error) → the panel shows the existing `_error`/retry pattern
    already used elsewhere on the dashboard screen, not a silent blank panel.
  - Not approved / not owned → panel not shown, same as AC 10.
  - No active placement, or an existing payment awaiting admin approval (S-042's
    capture-then-approve gate) → clear "not featured yet" / "awaiting admin approval" copy,
    distinct from "active until {expiry}" — do not conflate a captured-but-unapproved payment
    with an active boost (matches S-042 AC 2's explicit "no featured placement until admin
    approve").
- **AI disclaimer required?** No new AI output is introduced by this slice. The Featured badge
  copy must explicitly **not** be phrased as, or confused with, an AI suggestion/quality score —
  same non-negotiable S-036 already established on web (badge = paid placement fact, not an AI
  judgment). Existing AI suggestion language elsewhere (`AiInsightsPanel`, `ReviewCard` sentiment)
  is unchanged.

---

## Out of scope

- **Any mobile-initiated checkout.** `POST /payments/featured/checkout` is never called from
  mobile code in this slice — this is the central, deliberate scope boundary of this slice (see
  the "Important scope clarification" under Acceptance criteria). A merchant who wants to buy a
  featured boost still opens the web dashboard to do so; this slice only points them there
  clearly (AC 1) rather than pretending mobile supports the purchase.
- **Any Razorpay / payment-gateway mobile SDK integration** (`razorpay_flutter` or equivalent),
  and any related native Android/iOS configuration — confirmed not present today, not added by
  this slice. A future, dedicated slice (the "mobile checkout later" work `README.md` §12
  already flags) should scope and Architect-review that separately, given its materially larger
  PCI-adjacent/native-SDK surface compared to this slice's read-only display work.
- **Any admin payment desk / ledger UI on mobile** — `platform_fee`/`gateway_fee`,
  `GET /payments/admin/payments`, approve/reject/disable/refund actions are **not** built on
  mobile in this slice, for any role, including admin. Admin's existing web surface
  (`/admin/businesses/[id]` fee ledger + `/admin` payments list, S-036/S-042) remains the only
  place any of that is visible, matching the current `README.md` §12 M-66 note.
- **`POST /payments/mock/complete`** (DEBUG-only admin mock capture) — not called from mobile;
  no reason to, since mobile never starts a checkout for it to complete.
- **Any change to web code.** `frontend/` is untouched — S-036 and S-042 already shipped there
  and are both `Accepted`.
- **Any new backend endpoint, schema, or migration** — confirmed not needed; every field and
  route this slice's AC depend on already exists, unmodified, and is already generated into the
  mobile OpenAPI client.
- **Event grants / event sponsorships** — same boundary S-036 drew (AC 9); not this SKU, not
  this slice.
- **A second SKU catalog, subscriptions, auto-renew, or stacking boosts** — this slice only
  *displays* the existing, locked three-SKU catalog (S-042); it invents no new commercial terms.
- **Changing search ranking logic itself** — the backend already ranks featured-first
  (unmodified); this slice only renders what the backend already returns.

---

## Dependencies

- **S-036 (web featured boost + transaction fee) — Accepted.** This slice parity-matches its 9
  AC as far as the browse/display scope allows; Architect should read
  `docs/agents/slices/S-036-featured-boost-transaction-fee.md` in full for the reference backend
  contract (`PaymentProvider` port, fee-split rules, `is_featured` search behavior, RBAC) — all
  of it already shipped and reused as-is, not reimplemented.
- **S-042 (featured SKU catalog + admin payment desk) — Accepted.** Supersedes S-036's single-SKU
  commercial terms with the three-SKU catalog (₹299/7d, ₹499/15d, ₹899/30d) and the
  capture-then-admin-approve gate this slice's AC 4/6 rely on (a captured payment is not yet a
  placement until an admin approves it — mobile must reflect that distinction, not S-036's
  original auto-feature-on-capture behavior).
- **S-059 (mobile review-collection flow)** — not a hard blocker, but this slice reuses
  `AppConfig.webBaseUrl` and the `url_launcher` external-open pattern that slice introduced.
- **S-060 (mobile dashboard analytics)** — not a hard blocker, but this slice extends the same
  `merchant_dashboard_screen.dart` file S-060 last touched; Architect/Builder should confirm no
  merge-conflict-shaped overlap.
- Not blocked on M-68/M-69/M-70/M-78/M-79/M-80 (other Tier 3 items) — this is the second Tier 3
  item picked up per the mobile parity roadmap (`README.md` §12), after M-61/S-060.

---

## Definition of done (PM)

- [ ] All AC verified in test report (`TR-S-062-mobile-featured-listing-boost.md`)
- [ ] UX matches notes above, including the Architect's explicit confirmation of where the badge
      renders on `BusinessCard` and the exact "complete purchase on web" affordance for AC 1
- [ ] Documented in `README.md` §8 Frontend guide if a new reusable badge/panel pattern is
      introduced beyond what's already documented
- [ ] `README.md` §12 Web ↔ mobile feature parity tracker — M-66 row updated to `partial` (browse/
      display parity shipped; checkout-initiation explicitly still deferred to a future slice,
      matching the existing "web built — mobile checkout later" note) — not `implemented`, since
      the note's own "mobile checkout later" clause is still true after this slice
- [ ] `README.md` §12 Mobile parity roadmap Tier 3 annotated with M-66 partially closed
- [ ] `README.md` §14 and §16 updated to reflect the partially-closed mobile gap
- [ ] PM Status set to **Accepted**

---

## Technical specification (Architect)

> Filled by Architect before implementation.

> Specified 2026-08-18. **No backend gap — confirmed by direct inspection** of
> `backend/app/routers/payments.py` and the generated
> `mobile/packages/merchanthub_api/lib/src/api/payments_api.dart`, same conclusion the PM
> already reached. This slice is mobile-client-only, display-only: a new
> `PaymentsRepository` (two read-only methods), a `Featured` badge on `BusinessCard`, a
> disclaimer line on the business-list screen, and a new read-only panel on
> `merchant_dashboard_screen.dart`. **No checkout call is added anywhere** — confirmed no
> mobile code calls `featuredCheckoutApiV1PaymentsFeaturedCheckoutPost` before or after this
> spec, and none should be added by Builder.

### API contract

**No new backend routes.** Both endpoints below already exist, unmodified, on the backend
(`backend/app/routers/payments.py`, S-036/S-042, both Accepted) and are already generated
into `payments_api.dart`. This slice only starts *calling* the two `GET`s from mobile.

| Method | Path | Auth | Request | Response | Notes |
|--------|------|------|---------|----------|-------|
| `GET` | `/api/v1/payments/featured/skus` | Bearer; `require_roles(MERCHANT, ADMIN)` (unchanged, `backend/app/routers/payments.py:107-112`) | — | `list[FeaturedSku]` — `{ code, duration_days, listed_price_inr, amount_paise? }` × 3 (`featured_7d`/₹299, `featured_15d`/₹499, `featured_30d`/₹899 — confirm exact codes/prices against `_catalog()` at implementation time, S-042 locked the prices, not necessarily these illustrative codes). | Generated client: `featuredSkusApiV1PaymentsFeaturedSkusGet()` — `payments_api.dart:561`. No path/query params. |
| `GET` | `/api/v1/payments/businesses/{business_id}/placement` | Bearer; `require_roles(MERCHANT, ADMIN)` (unchanged, `payments.py:241-245`); merchant path additionally requires ownership (`get_owned_business`, 404 not 403 if not owned) | Path: `business_id` (string UUID) | `PlacementResponse` — `{ business_id, active: bool, placement: PlacementWindow? { id, starts_at, ends_at, disabled_at?, payment_id }, sku: FeaturedSku, skus: FeaturedSku[], awaiting_approval: bool, payment: PaymentLedger? }`. **Fee-split fields (`platform_fee_paise`/`gateway_fee_paise`) are server-nulled for the merchant role** (`payments.py:295-296` — only populated for admin, or nulled-out even inside a merchant-visible `PaymentLedger` when awaiting approval) — confirmed by reading the router, not assumed. | Generated client: `getPlacementApiV1PaymentsBusinessesBusinessIdPlacementGet(businessId: ...)` — `payments_api.dart:641`. `awaiting_approval` (S-042's capture-then-approve gate) is the field AC 4/UX notes' "awaiting admin approval" state maps to — distinct from `active`. |
| `POST` | `/api/v1/payments/featured/checkout` | Merchant, own approved business (unchanged) | — | — | **Exists, fully generated as `featuredCheckoutApiV1PaymentsFeaturedCheckoutPost` — explicitly NOT called by this slice.** Listed here only so Builder/Tester can grep-confirm zero call sites are added; do not wire a button to it. |

No other payments endpoints (webhook, mock-complete, admin approve/reject/disable/refund,
`GET /admin/payments`) are touched — all admin-only or write-only and out of scope per the PM.

### RBAC matrix

| Action | customer | merchant (owner, approved) | merchant (owner, pending/rejected/suspended) | merchant (other business) | admin |
|--------|----------|------------------------------|-----------------------------------------------|----------------------------|-------|
| `GET /payments/featured/skus` (AC 1) | 403 (unchanged backend gate; also never called from a customer-reachable screen) | 200 | N/A — mobile panel not shown (AC 1, AC 10) | N/A | 200 (not rendered anywhere admin-facing in this slice) |
| `GET /payments/businesses/{id}/placement` (AC 3) | 403 (unchanged backend gate) | 200, fee-split nulled server-side | N/A — panel not shown | 404 (`get_owned_business`, unchanged) | 200, fee-split populated but **not requested/rendered by this slice's mobile code** (AC 6) |
| "Featured boost" info panel reachability (`merchant_dashboard_screen.dart`) | Not reachable (dashboard route is already merchant-gated, S-031) | Reachable for the selected, owned, **approved** business only | Not shown (`if (business.status == BusinessStatus.approved)`, same pattern as S-059's `shareReviewLinkButton`) | Not reachable (business selector only lists the signed-in merchant's own businesses) | Not this slice's screen; no admin analytics/payment UI added (unchanged) |
| Featured badge on `BusinessCard` (AC 2) | Visible (public, read-only fact from `BusinessResponse.isFeatured`) | Visible | Visible | Visible | Visible |
| `POST /payments/featured/checkout` | — | **Never called by mobile code in this slice** | — | — | — (not a buyer role anyway) |

Matches S-036/S-042's already-accepted backend RBAC exactly — this slice adds no new
client-side bypass and introduces no new server-side check; all `403`/`404` cases above are
the existing backend gate, exercised for the first time from the mobile client.

### Data model impact

- [x] None  [ ] Extend existing  [ ] New table(s)

**Details:** No new tables, columns, enums, or Alembic migration. `BusinessResponse.isFeatured`
(bool?, default `false`) and both payments endpoints' response schemas already exist,
unmodified, confirmed by grep against the generated `business_response.dart`,
`featured_sku.dart`, and `placement_response.dart`. ERD in README §5: no update.

### Cache / side effects

- **No Redis change.** This slice makes no write calls (`search:*` invalidation on
  featured-placement activate/disable is unchanged, existing S-036/S-042 behavior triggered
  only by checkout/webhook/admin actions this slice never calls).
- **Client-side: no persistent cache of `isFeatured` or placement status**, matching AC 5's
  explicit "no client-side caching of placement/`isFeatured` state across sessions"
  requirement — same standard S-060 held for dashboard stats. The featured-boost panel's
  `PlacementResponse` is a per-screen `State` field refetched on dashboard load (same pattern
  as `_stats` in `merchant_dashboard_screen.dart`), not cached across app sessions. Business-list
  `isFeatured` badges come straight from each search response (`search_controller.dart`'s
  existing fetch), so admin disable/refund is reflected on the next fetch, never a stale local
  filter.

### Frontend

- **Route:** No new route. `mobile/lib/features/merchant/merchant_dashboard_screen.dart` gains
  a panel (no new screen); `mobile/lib/features/businesses/business_card.dart` and
  `mobile/lib/features/businesses/business_list_screen.dart` are extended in place.
- **Rendering:** n/a (Flutter) — Dart/Riverpod widget state, no SSR/CSR distinction (mobile).
- **New files:**
  - `mobile/lib/features/merchant/payments_repository.dart` (**new**) — a small,
    `DashboardRepository`-shaped class, not folded into `DashboardRepository` itself (payments
    is a distinct backend router/domain; keeping a separate repository mirrors how
    `dashboard_repository.dart` already stays scoped to `/dashboard/*` and `/ai/*`, and avoids
    growing that file with an unrelated domain per repo convention of thin, single-concern
    repositories):
    ```dart
    class PaymentsRepository {
      PaymentsRepository(this._client);
      final ApiClient _client;

      Future<List<FeaturedSku>> featuredSkus() async {
        try {
          final response = await _client.api.getPaymentsApi().featuredSkusApiV1PaymentsFeaturedSkusGet();
          return response.data?.toList() ?? [];
        } on DioException catch (e) {
          throw ApiException.fromDioException(e);
        }
      }

      Future<PlacementResponse> placement(String businessId) async {
        try {
          final response = await _client.api
              .getPaymentsApi()
              .getPlacementApiV1PaymentsBusinessesBusinessIdPlacementGet(businessId: businessId);
          return response.data!;
        } on DioException catch (e) {
          throw ApiException.fromDioException(e);
        }
      }
    }
    ```
    Same `try { ... } on DioException catch (e) { throw ApiException.fromDioException(e); }`
    pattern used by every other repository (`dashboard_repository.dart`, confirmed).
  - `mobile/lib/features/merchant/featured_boost_panel.dart` (**new**) — the read-only "Featured
    boost" info panel (AC 1, 3, 4, 6, 8, 10):
    - Only rendered when `business.status == BusinessStatus.approved` (mirrors
      `shareReviewLinkButton`'s existing gate, S-059) — satisfies AC 1's approved-only gate and
      AC 10's role/status gate (the panel is only reachable at all from
      `merchant_dashboard_screen.dart`, which is already merchant-role-gated end to end).
    - On build, loads `PaymentsRepository.featuredSkus()` and `.placement(business.id)` (parallel
      `Future.wait`, or sequential — Builder's call), rendered via the screen's existing
      `_error`/retry pattern on failure (matches every other panel on this screen, AC "empty
      states/errors" note).
    - SKU catalog: three tiles (or a simple `Column` of three rows), one per `FeaturedSku` —
      price (`listed_price_inr`), duration (`duration_days`), matching the PM's wording
      "₹299/7 days, ₹499/15 days, ₹899/30 days" (actual values come from the live response, not
      hardcoded, so if S-042's catalog ever changes, mobile shows the true prices with zero
      Builder change).
    - Placement status, derived from `PlacementResponse`:
      - `placement.active == true` → "Active until {ends_at, formatted}" (AC 3).
      - `placement.active == false && placement.awaitingApproval == true` → "Payment received —
        awaiting admin approval" (distinct copy, per UX notes' explicit "do not conflate a
        captured-but-unapproved payment with an active boost", S-042 AC 2).
      - Otherwise → "Not currently featured" (AC 4).
    - "Complete purchase on web" affordance (AC 1's required, non-dead-end path): a
      `FilledButton`/`OutlinedButton` (key `openWebCheckoutButton`) that calls `launchUrl(Uri.parse(
      '${AppConfig.webBaseUrl}/merchant/dashboard'), mode: LaunchMode.externalApplication)` —
      **reusing the exact `url_launcher` + `AppConfig.webBaseUrl` pattern already used**
      (`business_detail_screen.dart:355`, `collect_review_screen.dart:81`) rather than adding a
      new package. Button copy must read as an honest hand-off, e.g. "Buy a featured boost on the
      web dashboard" — **never** "Buy now" / "Start checkout" / any phrasing implying the tap
      itself starts a mobile payment (see Risks — this is the slice's central scope-leak risk).
      The button is disabled/hidden, never silently a no-op, if `AppConfig.webBaseUrl` external
      launch fails (existing `launchUrl` calls elsewhere in the app do not currently check the
      returned `bool`/catch failures — Builder should add a basic failure snackbar here rather
      than propagate that pre-existing gap, since a dead external-open button would itself
      violate AC 1's "not a dead end" requirement).
  - `mobile/lib/features/businesses/business_card.dart` (**modified**) — add a `Featured`
    `Chip`/badge, `Positioned(right: 8, top: 8, ...)` in the same `Stack` the existing category
    `Chip` (`Positioned(left: 8, top: 8, ...)`) already uses — opposite corner, no collision,
    matching web's own `BusinessCard.tsx` positioning (`absolute right-3 top-3`). Rendered only
    when `business.isFeatured == true` (key `featuredBadge`). Label text: **"Featured"** exactly
    (parity with web, not "Boosted" or any other synonym).
  - `mobile/lib/features/businesses/business_list_screen.dart` (**modified**) — add a single
    `Text` line above `_ResultsList`/`_ResultsMap` (key `featuredDisclaimerText`), always shown
    (matches web's `search/page.tsx` unconditional placement, not gated on "any result is
    featured" — avoids a layout-shift-on-scroll surprise and matches the PM's UX note wording):
    > "Listings marked **Featured** paid for a fixed-period search boost (7, 15, or 30 days) —
    > that is not an AI quality score and does not mean the business is better."
    Adapted from web's `search/page.tsx:113-114` to mention variable duration (7/15/30 days,
    S-042) instead of web's stale "7-day" wording (web itself has not been updated to reflect
    S-042's three-tier catalog in that string — **not this slice's job to fix web's copy**, but
    mobile should not copy web's now-outdated single-duration wording verbatim; flag as a
    non-blocking doc note in the changelog, not a scope creep into `frontend/`).
  - `mobile/lib/features/merchant/merchant_dashboard_screen.dart` (**modified**) — insert
    `FeaturedBoostPanel(business: business)` into the existing `ListView` (after the
    `_StatTile` row / before or after the CSV export row — Builder's call on exact ordering,
    no AC depends on position), gated by the same `if (business.status ==
    BusinessStatus.approved)` condition used for `shareReviewLinkButton` today (AC 10).
  - `mobile/lib/features/merchant/merchant_providers.dart` (**modified**) — add
    `paymentsRepositoryProvider` (`Provider<PaymentsRepository>`, same shape as
    `dashboardRepositoryProvider`).
- **No new package.** `url_launcher` (already a dependency, used in
  `business_detail_screen.dart`/`collect_review_screen.dart`) and `AppConfig.webBaseUrl`
  (S-059) cover AC 1's web hand-off; no charting, no payment SDK, no new dependency of any kind.
  `mobile/pubspec.yaml` is **not modified** by this slice.

### Flow

```mermaid
sequenceDiagram
    participant Merchant
    participant DashScreen as merchant_dashboard_screen.dart
    participant Panel as FeaturedBoostPanel
    participant PayRepo as PaymentsRepository
    participant API as FastAPI /payments (S-036/S-042, unchanged)
    participant Browser as External browser

    Merchant->>DashScreen: Open dashboard, approved business selected
    DashScreen->>Panel: build (business.status == approved)
    Panel->>PayRepo: featuredSkus()
    PayRepo->>API: GET /payments/featured/skus
    API-->>PayRepo: 3 SKUs (₹299/7d, ₹499/15d, ₹899/30d)
    Panel->>PayRepo: placement(business.id)
    PayRepo->>API: GET /payments/businesses/{id}/placement
    API-->>PayRepo: PlacementResponse (active/awaiting_approval/neither; fee split nulled for merchant)
    Panel-->>Merchant: Render 3 SKU tiles + status copy + "Buy on web dashboard" button
    Merchant->>Panel: Taps "Buy on web dashboard"
    Panel->>Browser: launchUrl(webBaseUrl + /merchant/dashboard, externalApplication)
    Note over Panel,Browser: No POST /payments/featured/checkout call from mobile, ever

    par Public browse
        Merchant->>DashScreen: (separately) browses Explore/search
        DashScreen->>API: GET /search/businesses (unchanged, backend already ranks featured-first)
        API-->>DashScreen: results incl. is_featured
        DashScreen-->>Merchant: BusinessCard shows "Featured" badge + list disclaimer text
    end
```

### Architect checklist

- [x] API contract defined and matches `README.md` §7 style — no new endpoints; existing
      S-036/S-042 contract confirmed by file/line against `payments.py` and `payments_api.dart`
- [x] RBAC matrix complete — customer/merchant-owner-approved/merchant-owner-non-approved/
      merchant-other/admin, matches existing backend gate exactly, no new surface
- [x] Data model impact documented — none, confirmed by grep against generated schemas
- [x] Cache invalidation considered — no Redis change (no write path); client-side confirmed
      to hold no persistent `isFeatured`/placement cache, satisfying AC 5's live-data requirement
- [x] AI/storage/maps use existing abstraction layers — n/a, no AI/storage/maps surface touched;
      `url_launcher`/`AppConfig.webBaseUrl` reused exactly as S-059 established, no new package
- [x] No secrets in design — no keys, no payment credentials touched (checkout/webhook paths
      are read-only-adjacent to this slice, never called)
- [x] Checkout boundary named explicitly: `featuredCheckoutApiV1PaymentsFeaturedCheckoutPost`
      listed in the API contract table as **existing-but-not-called**, so Tester can grep-verify
      zero call sites rather than relying on prose alone

### Risks / tradeoffs

- **The "no checkout" boundary is a copy/UX risk, not a technical one — flagging per explicit
  task instruction.** The single highest-risk element of this whole slice is the "Buy on web
  dashboard" button in `FeaturedBoostPanel`: it is a real, tappable, correctly-functioning
  control (external browser open), sitting directly next to SKU price tiles that look exactly
  like a checkout screen. If its copy reads as "Buy now" / "Start checkout" / "Purchase" with no
  "on the web" qualifier, a merchant could reasonably believe tapping it starts and completes a
  mobile purchase — that would make the AC 8 boundary *feel* leaky even though no
  `POST /payments/featured/checkout` call is ever made. **Mitigation, mandatory for Builder:**
  button label must contain "web dashboard" (or equivalent unambiguous phrasing), and the panel
  must show static explanatory copy near the SKU tiles (not just on the button) stating purchase
  happens on web — not solely relying on the button label to carry that disclosure. Tester should
  explicitly assert this copy exists (a dedicated AC-1-adjacent test), not just that the button
  exists and launches a URL.
- **A silently-failing external launch would itself be a dead end, violating AC 1's "not a dead
  end" requirement.** Existing `launchUrl` call sites in the app (`business_detail_screen.dart`,
  `collect_review_screen.dart`) do not check the returned `bool` or catch failures. This slice's
  new call site should not blindly copy that gap — a snackbar/error on launch failure is a small,
  contained improvement scoped to the new call site only (not a retrofit of the two existing
  call sites, which is out of scope here).
- **`awaiting_approval` vs `active` conflation risk (S-042's capture-then-approve gate).** A
  merchant who has paid but not yet been admin-approved must see "awaiting approval" copy, never
  "active until {expiry}" — getting this wrong would misrepresent payment state, which is exactly
  the kind of "fake progress" this repo's non-negotiables (AI-suggestion honesty; by extension,
  UI honesty about payment/approval state) guard against. `PlacementResponse.awaitingApproval`
  is the correct discriminator (confirmed present in the generated model); `active` alone is not
  sufficient to distinguish "never purchased" from "awaiting approval" (both are `active: false`).
- **Web's own disclaimer copy (`search/page.tsx:113`) is stale relative to S-042's three-SKU,
  variable-duration catalog** (it still says "7-day search boost," a leftover from S-036 before
  S-042 superseded it with 7/15/30-day tiers). This slice deliberately does **not** fix
  `frontend/` (out of scope, per PM) but also should not copy that stale wording onto mobile —
  mobile's new disclaimer text says "fixed-period search boost (7, 15, or 30 days)" instead.
  Flagging this as a **non-blocking follow-up note for whoever next touches `search/page.tsx`**
  (not this slice's job, not a blocker to Specified status here).
- **New `PaymentsRepository` vs extending `DashboardRepository`:** chose a separate small
  repository (see Frontend section) to keep single-concern repositories consistent with the
  existing `dashboard_repository.dart` (`/dashboard/*`, `/ai/*` only) rather than absorbing an
  unrelated `/payments/*` domain into it. This is a naming/organization choice, not a behavior
  risk — flagged only so Builder doesn't second-guess mid-implementation.
- **No ADR needed:** this slice adds no new integration, no schema change, no auth change, and
  no AI provider behavior change — it calls two existing, already-Accepted `GET` endpoints from
  a new mobile client-side path. Same bar S-060 applied (no ADR for `fl_chart`, a pure rendering
  addition); this slice is an even smaller surface (zero new packages).

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-062-*.md`
- Test report: `docs/agents/test-reports/TR-S-062-*.md`
- ADR: `docs/agents/adrs/ADR-XXX-*.md` (if any)

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-18 | PM | Created slice. Mobile parity for M-66 (featured listing boost, paid), the second Tier 3 item in the mobile parity roadmap (`README.md` §12), picked up after M-61/S-060. Read S-036 (Accepted, ₹499/7-day single-SKU original) and S-042 (Accepted, supersedes S-036 with a three-SKU catalog ₹299/7d, ₹499/15d, ₹899/30d + admin capture-then-approve gate) in full first, plus ADR-008 and ADR-010. Confirmed via `README.md` §12's M-66 row and §14/§16 that web's own checkout is fully built (mock/Razorpay provider port, no cards stored, `Accepted`) — the "mobile checkout later" phrasing is a deliberate sequencing decision from S-036's own Out-of-scope line ("Mobile app checkout (web merchant/admin first)"), not evidence that web's payment flow is itself incomplete or mocked-as-a-hack. Verified against the actual mobile codebase before writing AC (not assumed): `BusinessResponse.isFeatured` is already generated into the mobile OpenAPI client and unused by `business_card.dart`; all nine S-036/S-042 payments endpoints (SKU catalog, placement GET, checkout POST, admin approve/reject/disable/refund/mock-complete, webhook) are already fully generated into `payments_api.dart` and called by zero mobile code today; no Razorpay/payment-SDK package exists anywhere in `mobile/pubspec.yaml`; `AppConfig.webBaseUrl` (S-059) and `url_launcher` are already available and reusable for a "complete purchase on web" affordance; `search_controller.dart` does no client-side re-sorting, so backend featured-first ordering is preserved by construction. **Conclusion: no backend gap** — same standard prior mobile-parity slices held themselves to. **Central scope decision (per explicit task instruction to be careful here):** this slice is deliberately **browse/display-only** — SKU catalog visibility, Featured badge + non-AI-judgment copy on business cards/search, and read-only placement/expiry status on the merchant dashboard. It does **not** add checkout-initiation (`POST /payments/featured/checkout`) or any Razorpay mobile SDK to mobile — that remains explicitly deferred to a future, dedicated slice, both because S-036 itself already drew that line on web's own roadmap and because a mobile payment-SDK integration is a materially larger, PCI-adjacent surface than rendering already-computed public data, warranting its own Architect review rather than being silently bundled here. 10 numbered AC: 9 parity-matched to S-036's 9 web AC (SKU visibility without checkout, featured-first badge + disclaimer, dashboard active/expiry, no-badge-when-not-featured, admin disable/refund reflected live, fee ledger stays admin-only/off-mobile, customer never charged, explicit no-checkout-of-any-kind deferral replacing S-036's mock-mode AC, no event grants) plus 1 new mobile-specific role/permission AC. Out of scope: mobile checkout of any kind, Razorpay SDK, admin payment desk on mobile, mock-complete, web changes, new backend work (verified not needed), event grants, new SKUs/subscriptions, and any change to backend ranking logic itself. Depends on S-036 and S-042 (both Accepted, reference contracts — S-042 supersedes S-036's auto-feature-on-capture with the capture-then-approve gate this slice's AC 4/6 must respect), non-blockingly on S-059 (`webBaseUrl`/`url_launcher` reuse) and S-060 (same dashboard file). DoD ties acceptance to a `partial` (not `implemented`) M-66 tracker status, since the "mobile checkout later" deferral is still true after this slice ships — only the display half of the gap closes. Status: **Draft**. Technical specification left as template for Architect. |
| 2026-08-18 | Architect | Technical specification: confirmed **no new backend endpoint/schema** by reading `backend/app/routers/payments.py` line-by-line (`GET /payments/featured/skus` at line 107, `GET /payments/businesses/{business_id}/placement` at line 241, both `require_roles(MERCHANT, ADMIN)`, both already generated as `featuredSkusApiV1PaymentsFeaturedSkusGet`/`getPlacementApiV1PaymentsBusinessesBusinessIdPlacementGet` in `payments_api.dart`) and confirming the fee-split fields (`platform_fee_paise`/`gateway_fee_paise`) are server-nulled for the merchant role at `payments.py:295-296`, satisfying AC 6 with zero client-side filtering needed. Read `BusinessResponse.isFeatured` (`business_response.dart`), `FeaturedSku`/`PlacementResponse`/`PlacementWindow` generated models, `business_card.dart` (112 lines, no featured concept today), `business_list_screen.dart`, `merchant_dashboard_screen.dart` (S-060-era, no payments concept today), `dashboard_repository.dart`, `merchant_providers.dart`, `app_config.dart` (`webBaseUrl`, S-059), and both `url_launcher` call sites (`business_detail_screen.dart:355`, `collect_review_screen.dart:81`) directly, plus web's `BusinessCard.tsx` (`absolute right-3 top-3` Featured badge) and `search/page.tsx:113-114` (disclaimer copy, found **stale** relative to S-042's three-SKU catalog — still says "7-day," a leftover from before S-042 superseded S-036; flagged as a non-blocking follow-up for web, mobile does not copy the stale wording). **API contract:** two existing `GET`s only, `POST /payments/featured/checkout` explicitly listed as existing-but-not-called so Tester can grep-verify zero call sites. **RBAC:** unchanged backend gate exercised for the first time from mobile; panel additionally gated client-side on `business.status == approved`, mirroring S-059's `shareReviewLinkButton` pattern exactly. **Data model:** None. **Cache:** no Redis change (no write path this slice touches); confirmed no persistent client-side `isFeatured`/placement cache, satisfying AC 5's live-data requirement. **Frontend:** new `payments_repository.dart` (kept separate from `dashboard_repository.dart` — single-concern repositories, matches existing convention) with two read-only methods; new `featured_boost_panel.dart` rendering the 3-SKU catalog (values from the live response, never hardcoded) + active/awaiting-approval/not-featured status (discriminated via `PlacementResponse.awaitingApproval`, not `active` alone — S-042's capture-then-approve gate) + a "Buy on web dashboard" `launchUrl`/`AppConfig.webBaseUrl` hand-off button (no new package); `business_card.dart` gets a `Featured` badge `Positioned(right: 8, top: 8, ...)`, opposite the existing category chip; `business_list_screen.dart` gets an always-shown disclaimer line naming the 7/15/30-day variable duration; `merchant_dashboard_screen.dart` and `merchant_providers.dart` wired to the new panel/repository. `pubspec.yaml` is **not modified** — no new dependency of any kind. Mermaid flow covers panel load, the web hand-off, and (in a `par` block) the existing, unchanged public-search badge path. **Risks:** flagged the "Buy on web dashboard" button copy as the slice's central leak risk (must read as an honest hand-off, never "Buy now"/"Start checkout," with static explanatory copy near the SKU tiles too, not just the button label — Tester should assert this explicitly) and required a launch-failure snackbar on the new call site specifically (not retrofitting the two pre-existing bare `launchUrl` sites, out of scope); flagged the `awaiting_approval`-vs-`active` conflation risk explicitly; flagged web's stale disclaimer wording as non-blocking. No ADR — no new integration, schema, auth, or AI-provider-behavior change (same bar S-060 applied to `fl_chart`, and this slice adds zero new packages, a smaller surface still). Architect checklist complete. **Status: Draft → Specified.** Builder may proceed. |
