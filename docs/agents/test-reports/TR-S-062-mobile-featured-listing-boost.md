# TR-S-062: Mobile featured listing boost, browse-only (M-66 parity)

## Summary

**Pass** — all 10 numbered AC are met. `flutter analyze`: **0 issues**. `flutter test`:
**222/222 passing** (210 pre-existing + 12 new, 0 regressions after fixes below).

**One real regression found and fixed (not a pre-existing test-infra gap):** the Builder wired
`FeaturedBoostPanel` into `merchant_dashboard_screen.dart` without also giving
`mobile/test/merchant_dashboard_screen_test.dart`'s `_pumpDashboard` helper a
`paymentsRepositoryProvider` override. Every existing test that renders an **approved** business
(e.g. the S-059 share-review-link test, which uses `pumpAndSettle`) therefore built a real,
un-overridden `PaymentsRepository(ApiClient())` that tries a live network call inside `initState`
and never resolves in the test sandbox — `pumpAndSettle` timed out and that test failed
deterministically. Fixed by adding a `_FakePaymentsRepository` (defaulting to a "never featured"
placement) and overriding `paymentsRepositoryProvider` in `_pumpDashboard`, same pattern already
used for `dashboardRepositoryProvider`. Re-ran the full suite after the fix: 0 failures.

**One bug in my own first test draft, caught and fixed before landing:** `find.descendant(of:
find.byKey('featuredPlacementStatus'), matching: find.text(...))` never matches, because the key
is on the leaf `Text` widget itself, not a container — a descendant search on a leaf finds
nothing. Fixed by asserting `tester.widget<Text>(status).data` directly.

No production code in `featured_boost_panel.dart`, `payments_repository.dart`, `business_card.dart`,
or `business_list_screen.dart` needed changes — only the test fixture gap above.

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | SKU catalog visible with live prices/durations + honest "purchase on web" affordance (not a dead end) | A | `merchant_dashboard_screen_test.dart::S-062 AC1: featured boost panel renders live SKU prices/durations and a static web-handoff note`, `::S-062 AC1/AC8 (risk note): "Buy on web" button copy is an honest hand-off...` | Pass |
| 2 | Featured badge on browse/search + non-AI-judgment disclaimer; no client-side re-sort undoing backend order | A + M | `business_card_test.dart::S-062 AC2: Featured badge is shown when isFeatured is true`, `business_list_screen_test.dart::S-062 AC2: featured disclaimer is always shown...` (both empty and non-empty results). No-re-sort: code inspection of `search_controller.dart` — confirmed no `sort`/`orderBy` logic (Architect's own finding, independently re-confirmed by reading the file) | Pass |
| 3 | Dashboard shows active + expiry | A | `::S-062 AC3: placement status shows "Active until <expiry>" when a placement is active` | Pass |
| 4 | No badge / no "active until" when not featured (never purchased, awaiting approval, expired, disabled) | A | `business_card_test.dart::S-062 AC4: no Featured badge when isFeatured is false or unset`, `merchant_dashboard_screen_test.dart::S-062 AC4/S-042: a captured-but-unapproved payment shows "awaiting admin approval", never "Active until"`, `::S-062 AC4: no active or pending placement shows "Not currently featured"` | Pass |
| 5 | Admin disable/refund reflected live, no client-side cache | M | Code inspection: `PlacementResponse`/`isFeatured` are per-load `State`/per-search-response fields, no persistent storage (`shared_preferences`, `hive`, etc.) touches either — confirmed by reading `featured_boost_panel.dart` and `search_controller.dart` in full | Pass |
| 6 | Fee-split fields stay admin-only / off mobile | M | Code inspection: `PaymentsRepository.placement`/`FeaturedBoostPanel` never reference `platform_fee_paise`/`gateway_fee_paise`/`PaymentLedger` fields anywhere (grep, zero hits in the new files) | Pass |
| 7 | Customer never charged | M | Trivially true — no checkout control exists anywhere on mobile in this slice, confirmed by AC 8's grep | Pass |
| 8 | No mobile-initiated checkout call, no Razorpay SDK | M (code inspection) | `grep -r featuredCheckoutApiV1PaymentsFeaturedCheckoutPost mobile/lib` → **0 hits**. `grep -i razorpay mobile/pubspec.yaml` → **0 hits**. Both independently re-run by Tester, not taken on the Architect's word alone | Pass |
| 9 | No event grants / sponsorships offered | M | Code inspection: `FeaturedBoostPanel` renders only the `FeaturedSku` list from the live response — no grant/sponsorship affordance added | Pass |
| 10 | Panel not reachable for customer/admin or a merchant's own non-approved business | A | `::S-062 AC10: featured boost panel is not shown for a pending (not-yet-approved) business`. Customer/admin/other-merchant: unchanged existing gates — dashboard route is merchant-role-gated (S-031), business selector only lists the signed-in merchant's own businesses (`ownedBusinessesProvider`), both confirmed unchanged by reading the diff | Pass |

Two additional tests were added beyond the AC matrix to cover the panel's own error/retry path
(SKU-fetch and placement-fetch failures both surface through the existing `_error` UI, not a
silent blank panel) — not a numbered AC but directly required by the slice's "Empty states /
errors" UX note.

## Backend tests added

None — confirmed no backend routes/schemas changed (re-verified independently against
`backend/app/routers/payments.py:107-112` and `:241-296`, same conclusion the Architect reached).

## Frontend/mobile tests added

- `mobile/test/merchant_dashboard_screen_test.dart` (extended, +9 tests; also added
  `_FakePaymentsRepository`, `_defaultSkus`/`_activePlacement`/`_awaitingApprovalPlacement`/
  `_notFeaturedPlacement` fixtures, and wired `paymentsRepositoryProvider` into `_pumpDashboard`)
- `mobile/test/business_card_test.dart` (extended, +2 tests)
- `mobile/test/business_list_screen_test.dart` (extended, +2 tests)

## Manual checklist

- [x] `flutter analyze` — 0 issues
- [x] `flutter test` — 222/222 passing (210 pre-existing + 12 new, 0 regressions)
- [x] Read every new/changed S-062 file directly (`payments_repository.dart`,
      `featured_boost_panel.dart`, `business_card.dart`, `business_list_screen.dart`,
      `merchant_dashboard_screen.dart`, `merchant_providers.dart`) against the Architect's
      technical specification — matches exactly, no undocumented deviation
- [x] Grepped `mobile/lib/` for `featuredCheckoutApiV1PaymentsFeaturedCheckoutPost` — 0 hits
- [x] Grepped `mobile/pubspec.yaml` for `razorpay` (case-insensitive) — 0 hits, confirming no
      new dependency was added
- [x] Confirmed `pubspec.yaml` has no diff in this slice (no new package)
- [ ] `docker compose up --build` / on-device smoke test — not performed (no device/emulator
      available in this environment); not required for any of the 10 AC per the coverage
      matrix above (no new native platform-channel behavior — `url_launcher` reuses S-059's
      already-verified pattern)

## Regressions / gaps

- **No functional regressions** after the fix below. All 210 pre-existing tests pass unmodified
  in behavior (test fixtures extended, not altered).
- **Real bug found and fixed** (test-infra, not production code): `merchant_dashboard_screen_test.dart`'s
  `_pumpDashboard` had no `paymentsRepositoryProvider` override, causing `pumpAndSettle` to hang
  in the pre-existing S-059 share-review-link test once `FeaturedBoostPanel` started rendering
  for approved businesses. This would **not** affect the real app (a real `ApiClient` resolves
  normally), but it was a genuine, deterministic regression in the test suite itself introduced
  by this slice's wiring, not a pre-existing gap — fixed by adding `_FakePaymentsRepository` and
  overriding the provider by default.
- **README.md §8/§12/§14/§16 not yet updated** — per the slice's own PM Definition of Done, these
  must land before `Status: Accepted`: §12 M-66 row → `partial` (browse/display parity shipped;
  checkout-initiation still deferred, per the slice's own explicit scope boundary — not
  `implemented`), §14/§16 reflecting the partially-closed gap. No new reusable component pattern
  beyond what S-060/S-059 already documented in §8, so no §8 change strictly required (Tester
  flags for PM's own judgment call, not a blocker).

## Recommendation

**Ship** — all 10 AC pass, no rework required. Before PM sets `Status: Accepted`: complete the
outstanding README §12 (`partial`, not `implemented`) and §14/§16 updates per the slice's own DoD.
