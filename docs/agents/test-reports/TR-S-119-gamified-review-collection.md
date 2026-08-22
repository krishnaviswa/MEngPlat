# TR-S-119: Gamified (tap-through) review collection experience — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-119 |
| **Author** | Tester |
| **Date** | 2026-08-22 |
| **Recommendation** | Ship (with 2 noted gaps, non-blocking) |

---

## Summary

Re-ran all automated tests myself. Web: 8/8 pass (2 suites: flag-off regression + new
gamified). Mobile flag-off: 9/9 pass (`collect_review_screen_test.dart`, includes S-118
cases). Mobile gamified (flag-on): 2/2 pass, and confirmed the suite self-skips (1 no-op
test) when `--dart-define=GAMIFIED_REVIEW=true` is omitted. `flutter analyze
lib/features/reviews lib/core/config`: no issues. `tsc --noEmit` on the collect
directories: only pre-existing project-wide jest-dom typing errors (not introduced by
this slice, confirmed present in the untouched flag-off test file too). Git diff confirms
`frontend/src/components/CollectQrCard.tsx` has zero changes on this branch (AC7).

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Flag off = byte-identical plain form (web + mobile) | A | `page.test.tsx` (6 tests, unmodified, still pass); `collect_review_screen_test.dart` (unmodified, still pass) | Pass |
| 2 | Flag on web: full-screen, one-at-a-time, tap-only, CSS pop-in/bounce | A + M | `page.gamified.test.tsx::walks stars -> chips -> text one screen at a time via tap only` | Pass (A); animation visual timing not asserted, code-inspected (`tailwind.config.ts` keyframes, `StepCard.tsx` key-remount) — M |
| 3 | Flag on mobile: stars → text → celebration, tap-only, `AnimatedSwitcher`/`AnimatedScale` | A + M | `collect_review_screen_gamified_test.dart::walks stars -> text one screen at a time, low ratings not gated` | Pass (A); animation widget choice code-inspected — M |
| 4 | Payload byte-identical to flag-off flow | A | `page.gamified.test.tsx::submits through the existing API...` asserts `reviews.create` called with `{business_id, rating, body}`; `collect_review_screen_gamified_test.dart::submits through the existing API...` asserts `createReview` called with matching rating/body via shared repo | Pass |
| 5 | All 5 star ratings reach identical next step, no gating | A (partial) | Web test exercises rating=1; mobile tests exercise rating=1 and rating=5 (boundary values). **Gap:** neither suite iterates all 5 values explicitly | Partial — see gaps |
| 6 | Celebration then existing unmodified "done" screen | A | `page.gamified.test.tsx` asserts `/review submitted!/i` then `/your review is live/i`; `collect_review_screen_gamified_test.dart` asserts `collectReviewCelebration` then `collectReviewSuccess` (existing `_SuccessState` key) | Pass |
| 7 | `CollectQrCard.tsx`, route, QR target unchanged | M | `git diff --stat` confirms zero changes to `CollectQrCard.tsx`; page/screen route paths unmodified | Pass |
| 8 | Submission failure shows inline error, retry, no data loss | M (code inspection only) | No automated test exercises the failure path on either platform. `TextStep.tsx`/`text_step.dart` render an `error` prop when present; `GamifiedCollectFlow`/`gamified_collect_flow.dart` thread the parent's existing error state through unchanged. **Gap: not automated** | Not automated — flagged |
| 9 | Web chip step selection optional | A | `page.gamified.test.tsx::walks stars -> chips -> text...` advances via "Continue" without requiring a chip click before the click on "Service" (chip tap happens but Continue is what advances; chip is not asserted as required) | Pass |
| 10 | No chip step on mobile (documented gap) | M | Confirmed by inspection: `mobile/lib/features/reviews/gamified/` has no chip widget; README §12 documents the gap | Pass |

**Coverage:** 8/10 fully automated-pass, 2/10 flagged (AC5 partial — boundary-only, not exhaustive 5-value sweep; AC8 not automated at all, only code-inspected).

---

## Backend tests
None — no API/backend changes in this slice (confirmed against Architect spec).

## Frontend tests
- `frontend/src/app/collect/[businessId]/__tests__/page.test.tsx` (6 tests, unmodified, flag-off regression) — pass
- `frontend/src/app/collect/[businessId]/__tests__/page.gamified.test.tsx` (2 tests, new) — pass

Run: `cd frontend && npx jest src/app/collect` → `Tests: 8 passed, 8 total`

## Mobile tests
- `mobile/test/collect_review_screen_test.dart` (9 tests incl. S-118 cases, unmodified) — pass
- `mobile/test/collect_review_screen_gamified_test.dart` (2 real tests, self-skips without the dart-define) — pass when run with `--dart-define=GAMIFIED_REVIEW=true`

Run:
```
cd mobile && flutter test test/collect_review_screen_test.dart
→ All tests passed! (9)

cd mobile && flutter test test/collect_review_screen_gamified_test.dart --dart-define=GAMIFIED_REVIEW=true
→ All tests passed! (2)

cd mobile && flutter analyze lib/features/reviews lib/core/config
→ No issues found!
```

## Manual checklist
- [x] M-119-1: `CollectQrCard.tsx` diff is empty on this branch
- [x] M-119-2: README §12 documents the mobile no-chip-step gap
- [ ] M-119-3: Visual pop-in/bounce/celebrate-pulse animation timing (not verifiable headlessly — browser/device manual spot check recommended before wide rollout)
- [ ] M-119-4: Submission-failure inline error + retry-without-data-loss on both platforms (AC8) — recommend adding an automated failure-path test before Accepted, or explicit manual sign-off if deferred

## Regressions / gaps
1. **AC5** — automated coverage samples only rating boundaries (1 and 5), not the full 1–5 sweep the AC literally requests. Low risk (shared code path, no per-rating branching exists in the components), but not exhaustively proven.
2. **AC8** — no automated test simulates a `reviews.create`/`createReview` rejection in the gamified flow on either platform. The error-prop wiring is present and code looks correct on inspection, but this is inference, not proof. Recommend either a quick added test (mock a rejected promise, assert error text + retry preserves entered values) before marking Accepted, or an explicit PM/Builder manual sign-off noted here.

## Recommendation
**Ship**, but PM should decide whether to require AC8's automated failure-path test (or a documented manual verification) before setting Status: Accepted — this is the one AC with zero automated proof, not just partial. AC5's boundary-only sampling is a lower-severity note, acceptable given shared non-branching code.
