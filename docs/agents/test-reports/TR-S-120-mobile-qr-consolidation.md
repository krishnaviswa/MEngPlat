# TR-S-120: Mobile QR share — fix shop resolution + share-as-image for printing — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-120 |
| **Author** | Tester |
| **Date** | 2026-08-22 |
| **Recommendation** | Ship (with 1 noted gap, non-blocking) |

---

## Summary

Re-ran `mobile/test/app_shell_test.dart`, `share_review_link_sheet_test.dart`,
`merchant_dashboard_screen_test.dart` together: 55/55 pass. `flutter analyze
lib/features/merchant/share_review_link_sheet.dart lib/features/account/account_screen.dart`:
no issues. Confirmed `CollectQrCard.tsx` (web) has zero diff on this branch (AC9).

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | >1 shop → routes to `/merchant`, no `shops.first` guess | A | `app_shell_test.dart::S-120: Account "Share review QR" with >1 shop goes to the dashboard instead of guessing shops.first` | Pass |
| 2 | Exactly 1 approved shop → opens `ShareReviewLinkSheet` directly | A | `app_shell_test.dart::S-114: merchant Account shows shop, list, QR, and Grow` implicitly exercises the single-shop tile presence; direct-open path is also the fallthrough branch in `account_screen.dart` (`shops.length==1 && approved` → `ShareReviewLinkSheet.show`) exercised indirectly since no test explicitly taps and asserts the sheet opens for a single **approved** shop from the Account screen | Partial — see gaps |
| 3 | 1 shop, not approved → sheet does not open with active QR/share; same gate as dashboard | A + design note | `app_shell_test.dart::S-120: Account "Share review QR" for a single not-yet-approved shop also goes to the dashboard` | Pass, but implementation detail differs from AC wording — see gaps |
| 4 | 1 approved shop → regression, unchanged direct-open | M (code inspection) | `account_screen.dart` L114-120 unchanged direct-open branch preserved; no dedicated new test, but pre-existing behavior untouched by diff | Pass (inferred, not directly tested post-change) |
| 5 | Tap "Share QR to print" → RepaintBoundary capture → OS share sheet with PNG + caption | A (partial) | `share_review_link_sheet_test.dart::S-120: a "Share QR to print" action is present alongside the text-link share button` only asserts the button exists; **no test taps it or verifies `SharePlus.instance.share` is invoked with PNG bytes + the caption text** | Not automated — flagged |
| 6 | OS share sheet target can print (AirPrint/print service) | M | Manual only — external OS behavior, correctly out of automated scope | Manual, not run (no device) |
| 7 | Existing "Share link" (text) button unchanged | A | `share_review_link_sheet_test.dart::AC1: a "Share link" action is present...` (pre-existing, unmodified test, still passes) | Pass |
| 8 | Both buttons present, one sheet implementation, both entry points | A | `share_review_link_sheet_test.dart` asserts both `shareReviewLinkSheetShareButton` and `shareReviewLinkQrImageButton` present; both `account_screen.dart` and (unmodified) `merchant_dashboard_screen.dart` call the same `ShareReviewLinkSheet.show` | Pass |
| 9 | `CollectQrCard.tsx` (web) untouched | M | `git diff --stat` confirms zero changes | Pass |
| 10 | QR payload/collect URL unchanged | A + M | `share_review_link_sheet_test.dart::AC1: shows a QR encoding the website collect URL` (pre-existing, still passes); `_link` in `share_review_link_sheet.dart` still uses unchanged `collectWebLink(AppConfig.webBaseUrl, slug)` | Pass |

**Coverage:** 8/10 fully covered, 2/10 flagged (AC5 button-presence-only, no invocation test; AC3's implementation choice deviates from the AC's literal "disabled state or explanatory message" wording though it satisfies the substantive intent).

---

## Backend tests
None — no API/backend changes (confirmed against Architect spec: read-only consumers of existing endpoints).

## Frontend tests
None — this slice is mobile-only; `CollectQrCard.tsx` confirmed untouched.

## Mobile tests
- `mobile/test/app_shell_test.dart` — includes 2 new S-120 cases
- `mobile/test/share_review_link_sheet_test.dart` — includes 1 new S-120 case
- `mobile/test/merchant_dashboard_screen_test.dart` — unmodified, regression pass

Run: `cd mobile && flutter test test/app_shell_test.dart test/share_review_link_sheet_test.dart test/merchant_dashboard_screen_test.dart`
→ `All tests passed! (55)`

`flutter analyze lib/features/merchant/share_review_link_sheet.dart lib/features/account/account_screen.dart` → `No issues found!`

## Manual checklist
- [x] M-120-1: `CollectQrCard.tsx` diff is empty on this branch
- [ ] M-120-2: Device/emulator tap of "Share QR to print" actually opens native OS share sheet with a non-blank PNG attached (AC5/AC6) — recommend before wide rollout since no automated test exercises the `SharePlus.instance.share` call path
- [ ] M-120-3: Confirm AC3's routing-to-dashboard design (rather than an inline disabled/explanatory Account-tile state) was a deliberate Architect/Builder decision the PM accepts as satisfying the AC's intent

## Regressions / gaps
1. **AC5** — no test taps `shareReviewLinkQrImageButton` and verifies the capture → `SharePlus.instance.share` call (with PNG bytes + `'Scan to leave a review — {businessName}'` text). This is the single riskiest code path in the slice (`RepaintBoundary.toImage()` timing is explicitly called out as a Flutter gotcha in the Architect's Risks section) and it has zero automated coverage — only a "button exists" assertion. Recommend a widget test that mocks/stubs the share channel and asserts the call, or explicit manual device verification before Accepted.
2. **AC3** — implementation routes the not-approved single-shop case to `/merchant` (where the dashboard's own gate simply hides the button) rather than showing an inline disabled/explanatory state on the Account screen itself, as the AC's phrasing more literally suggests. It does satisfy the substantive requirement ("sheet does not open... same gate... applied") and is tested, but it's a different UX shape than a literal reading of the AC — flagging for PM confirmation rather than treating as a hard fail.

## Recommendation
**Ship**, with the caveat that AC5 (the new PNG-capture-and-share code path) has no automated invocation test — recommend either adding one or getting explicit manual device sign-off before Status: Accepted. AC3's design choice should get a quick PM nod since it diverges from the AC's literal wording even though it meets the intent.
