# TP-S-059: Mobile review collection flow (parity for M-71)

## Scope

Verify the 6 numbered AC on `docs/agents/slices/S-059-mobile-review-collection-flow.md`:
merchant-side QR/link generation and share sheet (AC1), the public ungated `/collect/:slug`
landing screen with no star-rating interception (AC2), authenticated submission through the
existing `createReview` path (AC3), unauthenticated-submit redirect to `/login?next=...` (AC4),
the optional non-gating Google-review suggestion after success (AC5), and the merchant-only gate
on the "Share review link" action (AC6).

**Explicitly not required by any AC and not tested here:** a cold QR scan opening the native app
directly (the Architect's deep-link scope decision defers this by design — see slice's Risks
section; the QR/link always resolves to the existing, Accepted web `/collect/[businessId]` page
in the device browser).

## Approach

- `flutter_test` widget tests only (no backend/API changes per the Architect's spec — nothing to
  test on `backend/`).
- Riverpod `ProviderContainer` + `overrides` for `authControllerProvider`,
  `businessRepositoryProvider`, `reviewRepositoryProvider`, following the existing pattern in
  `mobile/test/business_detail_screen_test.dart` and `mobile/test/review_form_sheet_test.dart`.
- `GoRouter`-wrapped `MaterialApp.router` pumps for screens reached via `context.push`/redirect
  (`CollectReviewScreen`, `ShareReviewLinkSheet`'s "Preview in app"), matching
  `business_detail_screen_test.dart`'s router pattern.
- AI_PROVIDER=mock is N/A — this slice introduces no new AI-facing surface (confirmed in the
  slice's UX notes); the existing AI sentiment pipeline is unmodified and untested by this plan.

## Planned cases

| AC# | Case | Type |
|-----|------|------|
| 1 | "Share review link" button visible for an approved owned business; opens a sheet with a QR code + selectable link text + a "Share link" action | A |
| 1 | "Share review link" button hidden for a pending (not-yet-approved) owned business | A |
| 2 | `/collect/:slug` renders business name + 1-5 star control without a session | A |
| 2 | Picking star 1 and picking star 5 both leave the identical next step (body field) reachable, no branch/redirect on rating value | A |
| 2 | A non-approved (e.g. suspended) business shows a distinct empty state, not a crash | A |
| 3 | A signed-in user submitting rating + 10+ char body calls `createReview` with the right payload and shows a success state | A |
| 4 | Submitting while signed out does not call `createReview` and instead routes to `/login?next=/collect/{slug}` | A |
| 5 | After a successful submit, an optional, non-blocking "leave a Google review" button is present and enabled | A |
| 6 | "Share review link" inherits the existing merchant-only dashboard gate | A (covered by the dashboard already being merchant-role-gated at the router level, re-confirmed by AC1's fixture always being a merchant session — no separate customer/admin dashboard render path exists to assert against) |

## Non-AC risk noted for the record

The Architect flagged (slice's Risks/Deep-link section) that the honest M-71 parity-tracker status
on ship should be `partial`, not `implemented`, because the true "cold QR scan opens the native
app" journey is deliberately deferred by design — not because any AC fails. All 6 AC above are
expected to pass in full. This is a PM/Tester acceptance-time classification call, not a test
failure, and is carried into the test report's recommendation section per the slice's own
Definition of Done wording.
