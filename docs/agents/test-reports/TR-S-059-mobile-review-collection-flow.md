# TR-S-059: Mobile review collection flow (parity for M-71)

## Summary

**Pass** — all 6 numbered AC are met by the implementation, independently verified against the
actual diff (not just the Builder's changelog claim) and now covered by automated `flutter_test`
widget tests that did not exist at hand-off. `flutter analyze`: 0 issues. `flutter test`:
**178/178 passing** (167 pre-existing + 11 new, 0 regressions in code this slice touches).

**Important non-AC classification flag, per the slice's own Definition of Done wording:**
recommend the M-71 parity-tracker row ship as **`partial`, not `implemented`**. All 6 AC as
written pass in full — the deferral is of a capability none of the 6 AC actually requires (a cold
QR scan opening the native app directly). This is the Architect's own explicit, reasoned decision
(deep-link/QR scope section of the slice), reconfirmed correct by direct inspection of
`mobile/lib/router.dart` and `mobile/lib/features/merchant/share_review_link_sheet.dart`: the
QR/share payload always encodes the existing, Accepted **web** `/collect/{slug}` URL, never a
mobile scheme; the new `/collect/:slug` in-app route is reachable only via direct in-app
navigation ("Preview in app"), never via the QR/link itself. The PM's own Definition of Done ties
`partial` specifically to this deferral, so this is a pre-answered classification, not a
Tester-discovered gap — flagging here so it isn't missed at Accept time.

**One blocking-to-my-own-verification, but not S-059-caused, issue found and fixed:** before I
could run `flutter analyze`/`flutter test` at all, the working tree failed analysis on
`mobile/test/merchant_dashboard_screen_test.dart` — `_FakeDashboardRepository.merchantStats`
didn't match `DashboardRepository.merchantStats`'s real signature (which already carries an
optional `{String range = 'all'}` param, confirmed by reading
`mobile/lib/features/merchant/dashboard_repository.dart`). This is **not** part of S-059's diff —
the file list the Builder gave me for S-059 doesn't include `dashboard_repository.dart`, and the
working tree has untracked S-060 slice files
(`docs/agents/slices/S-060-mobile-dashboard-analytics.md`,
`S-060-mobile-admin-ops-parity.md`) plus an uncommitted `dashboard_repository.dart`/OpenAPI-client
diff (a `range` param + new `reviewsCsv` method) that is S-060 work, not S-059's. I applied a
1-line test-only fix (added the missing `{String range = 'all'}` param to the fake's override) so
I could actually run the suite — this is **not a functional code change**, it only unblocks
analysis, and I'm flagging it explicitly rather than silently absorbing it: whoever finalizes the
S-059 PR should confirm this test file's fix travels with whichever slice's PR actually owns
`dashboard_repository.dart`'s real diff (S-060), not silently attributed to S-059.

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Merchant sees a QR code + shareable link for an approved owned business via "Share review link"; not shown for pending/rejected/suspended | A | `mobile/test/merchant_dashboard_screen_test.dart::S-059 AC1/AC6: "Share review link" is shown for an approved business owned by this merchant`, `::S-059 AC1: "Share review link" is not shown for a pending (not-yet-approved) business`; `mobile/test/share_review_link_sheet_test.dart::AC1: shows a QR code encoding the business public web collection URL`, `::AC1: a "Share link" action is present to hand the link to the device share sheet` | Pass |
| 2 | Public landing shows business name + 1-5 star control; any rating 1-5 continues identically, no branch/intercept | A | `mobile/test/collect_review_screen_test.dart::AC2: shows business name and a 1-5 star control reachable without a session`, `::AC2: a 1-star and a 5-star pick both continue through the identical next step`, `::a suspended/pending business shows the not-available empty state, not a crash` | Pass |
| 3 | Signed-in user's submit (rating + 10+ char body) creates the review via the existing, unmodified `createReview` path; AI pipeline unchanged (no new AI UI introduced) | A | `mobile/test/collect_review_screen_test.dart::AC3: a signed-in customer submitting rating + 10+ char body creates the review` (asserts the exact rating/body payload reaches the repository and a success state renders); AI-pipeline-unchanged claim verified by code inspection — `ReviewsController.createReview`/`ReviewRepository.createReview` in `review_providers.dart`/`review_repository.dart` are untouched by this slice's diff | Pass |
| 4 | Unauthenticated submit attempt redirects to `/login?next=/collect/{slug}` with a working return path, not a silent failure or dead end | A | `mobile/test/collect_review_screen_test.dart::AC4: submitting while signed out redirects to /login?next=/collect/{slug}, no silent failure` (asserts zero `createReview` calls and the exact `next` query param reaching `/login`); the `next` allow-list restricted to `/collect/` prefix (not an open redirect) verified by reading `mobile/lib/router.dart`'s `redirect` callback directly | Pass |
| 5 | Optional, non-gating "Suggest a Google review" affordance shown after a successful submit | A | `mobile/test/collect_review_screen_test.dart::AC5: after a successful submit, an optional "leave a Google review" affordance is offered` (asserts the success state and button are both already reached/enabled — i.e. the flow has completed independent of the button being tapped, confirming "optional, not required") | Pass |
| 6 | "Share review link" inherits the existing merchant-only dashboard gate | A + code inspection | `mobile/test/merchant_dashboard_screen_test.dart`'s two AC1 tests both run under a merchant-role fixture (`_FakeAuthController` returns `UserRole.merchant`); the dashboard route itself (`/merchant`) is gated in `mobile/lib/router.dart`'s `redirect` (`if (loc.startsWith('/merchant') && user.role != UserRole.merchant) return postLoginPath(user.role)`), confirmed unchanged by this slice's diff — no new route or widget makes the button reachable outside that existing gate | Pass |

No AC required manual-only (M) verification — all 6 were scriptable in `flutter_test`.

## Backend tests added

None — confirmed no backend routes/contracts changed, per the Architect's own inspection of
`backend/app/routers/businesses.py` (`GET /businesses/{slug}`, unchanged, still public) and
`backend/app/routers/reviews.py` (`POST /reviews`, unchanged, still `require_roles(CUSTOMER,
MERCHANT, ADMIN)`), independently re-confirmed here by reading both files directly.

## Frontend/mobile tests added

- `mobile/test/collect_review_screen_test.dart` (new, 6 tests) — AC 2, 3, 4, 5
- `mobile/test/share_review_link_sheet_test.dart` (new, 3 tests) — AC 1
- `mobile/test/merchant_dashboard_screen_test.dart` (extended, +2 tests; also required a
  test-only fake-signature fix unrelated to S-059, see Summary) — AC 1, 6

11 new tests added, 0 removed, 0 pre-existing test bodies modified (only the one unrelated fake
signature fix noted above).

## Manual checklist

- [x] `flutter analyze` — 0 issues (after the unrelated fake-signature fix noted in Summary)
- [x] `flutter test` — 178/178 passing (167 pre-existing + 11 new, independently re-run, not
      trusting the Builder's pre-slice "167/167" claim at face value)
- [x] Read every new/changed S-059 file directly (`collect_review_screen.dart`,
      `share_review_link_sheet.dart`, `merchant_dashboard_screen.dart`, `router.dart`,
      `app_config.dart`, `pubspec.yaml`) and confirmed the implementation matches the Architect's
      technical specification line-by-line, including the deep-link scope decision — no
      discrepancies found
- [ ] `docker compose up --build` / on-device QR-scan-with-camera smoke test — **not performed
      this pass** (no device/emulator available in this environment); not required regardless,
      since the deliberately-deferred true native-app-open journey (see Summary) has no AC that
      would need it, and the QR/link payload itself is asserted directly (selectable link text
      next to the code) rather than by scanning a rendered code with a camera

## Regressions / gaps

- **No functional regressions.** All 167 pre-existing mobile tests still pass unmodified.
- **Pre-existing, S-060-owned analyzer break found in the same working tree, fixed minimally to
  unblock this report** (see Summary for full detail) — `mobile/test/merchant_dashboard_screen_test.dart`'s
  `_FakeDashboardRepository.merchantStats` didn't match the real `DashboardRepository.merchantStats`
  signature after an uncommitted `range`-param change that belongs to S-060, not S-059. Flagging
  for the parent session: confirm this 1-line test fix rides with whichever PR actually owns
  `dashboard_repository.dart`'s diff, so it isn't lost or duplicated.
- **Test-environment-only surface-size workaround needed in 3 new test files**
  (`collect_review_screen_test.dart`, `share_review_link_sheet_test.dart`, and the two new cases
  in `merchant_dashboard_screen_test.dart`) — the default 800×600 `flutter_test` surface is too
  short to fit the collection form or the QR/link/share-sheet bottom sheet without scrolling,
  which both trips spurious `RenderFlex` overflow assertions and can leave a button off-screen for
  `tap()`. Widened via `tester.binding.setSurfaceSize(...)` in each helper, same class of fix
  S-058's Tester documented in `TR-S-058-mobile-review-list-interactivity.md`. Not a production
  bug — flagging so a future Tester extending these files doesn't need to re-diagnose it.
- **Test-harness auth-warm-up note for `collect_review_screen_test.dart`:** `CollectReviewScreen`
  deliberately only *reads* (not *watches*) `authControllerProvider`, inside `_submit`, so AC2's
  landing view renders with zero dependency on auth having resolved. In production this is safe
  because the router's `_AuthRefreshNotifier` (`router.dart`) is a live, app-wide listener on that
  provider from startup, so it's always already resolved by the time a user reaches
  `/collect/:slug`. In an isolated widget test with no such app-wide listener, the provider is
  still cold (`AsyncLoading`) at the first synchronous `ref.read` unless something warms it first
  — the test helper now does `await container.read(authControllerProvider.future)` before pumping,
  matching real app timing. Documented in the test file itself; noting here too since it's a
  non-obvious trap for anyone adding further cases against this screen.
- **README.md §12/§14/§16 not yet updated** to reflect M-71 closing as `partial` — this is the
  slice's own PM Definition of Done and, per this report's classification flag above, must land
  in the same PR before `Status: Accepted`.

## Recommendation

**Ship** (AC-wise) — all 6 AC pass, no rework required for any of them. Before PM sets `Status:
Accepted`: (1) set the M-71 row in `README.md` §12 to **`partial`**, not `implemented`, per the
Architect's own explicit recommendation and the PM's Definition of Done wording (all AC pass; the
true native-app-open cold-QR-scan journey is deferred by design, not by AC failure); (2) complete
the outstanding §14/§16 doc updates in the same PR; (3) confirm the unrelated
`merchant_dashboard_screen_test.dart` fake-signature fix (see Regressions/gaps) is correctly
attributed to whichever PR owns `dashboard_repository.dart`'s S-060 diff, not silently folded into
S-059's PR.
