# TR-S-121: Inline auth-on-submit for QR review collection — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-121 |
| **Author** | Tester |
| **Date** | 2026-08-29 |
| **Recommendation** | Ship (with 3 noted gaps, all non-blocking) |

---

## Summary

Backend confirmed untouched (`git diff --stat main...HEAD -- backend/` empty — matches the
Architect spec's "no backend/API changes"). Added the missing web-side coverage flagged at
hand-off: a new component-level `InlineAuthStep.test.tsx` (4 cases, mirroring mobile's
`inline_auth_step_test.dart`), a page-level AC6/AC7 auto-submit test in both `page.test.tsx`
(plain flow) and `page.gamified.test.tsx` (gamified flow), and a page-level AC9 retry-preserves-
composed-state test. Re-ran everything:

- `cd frontend && npx jest "src/app/collect/[businessId]/__tests__/page.test.tsx"
  "src/app/collect/[businessId]/__tests__/page.gamified.test.tsx"
  src/components/collect/__tests__/InlineAuthStep.test.tsx
  src/components/__tests__/PhoneOtpPanel.test.tsx` → **18/18 pass** (4 suites)
- `cd frontend && npx jest` (full suite, since `PhoneOtpPanel.tsx`/`page.tsx` are shared files)
  → **354/354 pass** (64/64 suites) — no regressions
- `cd mobile && flutter test test/inline_auth_step_test.dart
  test/collect_review_inline_auth_test.dart test/collect_review_screen_test.dart` →
  **15/15 pass**
- `cd mobile && flutter test` (full suite) → **321 pass, 7 fail** — all 7 failures are in
  `forgot_password_screen_test.dart`; confirmed pre-existing/unrelated via
  `git diff --stat main...HEAD -- mobile/lib/features/auth/forgot_password_screen.dart
  mobile/lib/features/auth/login_screen.dart mobile/test/forgot_password_screen_test.dart`
  (empty — zero diff on this branch for those files)
- `cd mobile && flutter analyze lib/features/reviews/inline_auth_step.dart
  lib/features/reviews/collect_review_screen.dart
  lib/features/reviews/gamified/gamified_collect_flow.dart` → **No issues found!**

All 14 AC mapped. 3 non-blocking gaps flagged below (web-only Google-button test-env
limitation affecting AC4/AC9; web AC6 proven end-to-end for OTP only, not Google/password;
web AC10 covered implicitly rather than by an explicit side-by-side test like mobile's) plus
one outstanding DoD item for PM (README §12/§14 not yet touched on this branch).

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Composer (stars/chips/text) fully open, no auth gate before Submit — both platforms | A | `page.test.tsx::"does not intercept low star ratings"` (pre-existing, unmodified); `collect_review_screen_test.dart::"AC2: a 1-star and a 5-star pick both continue through the identical next step"` (pre-existing, unmodified); reaffirmed by every new S-121 test composing fully before Submit | Pass |
| 2 | Web: submit while unauth → no `router.push('/login?next=...')`, inline step renders in place, composed state held | A | `page.test.tsx::"shows the inline sign-in step in place, without navigating, when the visitor is not signed in (S-121)"` (rewritten case, asserts `pushMock` not called); reinforced by the new auto-submit and AC9-retry tests below | Pass |
| 3 | Mobile: submit while unauth → no `context.push('/login?next=...')`, inline step renders in place | A | `collect_review_screen_test.dart::"S-121: submitting while signed out shows the inline sign-in step in place, no route push, no silent failure"` (rewritten case) | Pass |
| 4 | Inline step shows all 3 methods (email+password/TOTP, Google, phone OTP), none stripped | A (mobile full; web partial — see gaps) | `inline_auth_step_test.dart::"AC4/AC5: Mobile OTP is pre-selected by default (not password), and Google is shown regardless of the toggle"` (mobile, incl. Google via mocked `googleSignInClientProvider`); `InlineAuthStep.test.tsx::"shows the phone-OTP panel by default (not email+password), and reaches password via the toggle"` (web — OTP + password only; Google's presence is confirmed by code inspection, not an automated assertion — see gaps) | Pass (web Google presence: gap noted) |
| 5 | Default method is Google/phone-OTP, not password; password reachable via the same toggle as `/login` | A | Same two tests as AC4 above, both platforms | Pass |
| 6 | Any method's success auto-submits the already-composed review, no re-shown form, no re-entry | A (mobile: Google+OTP; web: OTP — see gaps) | `collect_review_inline_auth_test.dart::"AC6/AC7: Google sign-in..."` and `"...phone OTP..."` (mobile, both methods); `page.test.tsx::"auto-submits the composed review after inline phone-OTP sign-in succeeds, with no re-entry (S-121)"` and `page.gamified.test.tsx::"shows the inline auth step in place and auto-submits after phone-OTP sign-in, reaching the celebration (S-121)"` (web, OTP path; Google/password auto-submit proven only by code inspection of the shared `completeAuth()`/`onAuthenticated()` call site plus `InlineAuthStep.test.tsx`'s "never redirectAfterAuth" test — see gaps) | Pass (web: OTP proven end-to-end, Google/password by inspection — gap noted) |
| 7 | Lands on existing celebration/plain-done screen post-auto-submit, no new/duplicate success UI | A | Same tests as AC6; web asserts `"Your review is live"` (plain) / `"review submitted!"` (gamified, pre-existing `CelebrationStep`); mobile asserts `collectReviewSuccess` key | Pass |
| 8 | Already-authenticated submit → no inline step, direct submit (regression) | A | `page.test.tsx::"creates the review through the existing API when signed in"` (pre-existing, unmodified); `collect_review_screen_test.dart::"AC3: a signed-in customer submitting rating + 10+ char body creates the review"` (pre-existing, unmodified) | Pass |
| 9 | Failed attempt (wrong creds / cancelled Google / wrong OTP) → inline error, no navigation away, composed state intact, retry works | A | `InlineAuthStep.test.tsx` (web, component-level: wrong password, wrong OTP); `page.test.tsx::"keeps the composed rating/body intact in page state across a failed inline sign-in attempt, then submits it on retry (S-121 AC9)"` (new, web page-level — proves the *page's* rating/body survive, not just the widget); `inline_auth_step_test.dart::"AC9: wrong password+email credentials..."` and `collect_review_inline_auth_test.dart::"AC9: a failed inline sign-in..."` (mobile, component- and page-level, via Google's error path) | Pass |
| 10 | Gate/methods/default identical for all 5 star ratings — S-040 no-gating rule reaffirmed | A (mobile explicit; web implicit — see gaps) | `collect_review_inline_auth_test.dart::"AC10: ...1-star..."` / `"...5-star..."` (mobile, explicit side-by-side comparison); web: implicit — S-121 tests collectively exercise ratings 1, 2, 3, 4, 5 across `page.test.tsx`/`page.gamified.test.tsx`, all reaching the identical `authPending`/`InlineAuthStep` gate, plus the Architect-documented structural guarantee (`auth.me()` catch branch has zero reference to `rating`) — no single web test explicitly compares 1-star vs. 5-star side by side | Pass (web: implicit coverage — gap noted) |
| 11 | `POST /reviews` `require_roles(CUSTOMER, MERCHANT, ADMIN)` unchanged; auto-submit identical for all 3 roles | M | `git diff --stat main...HEAD -- backend/` (empty — RBAC/route untouched); per Architect spec, no role selector is exposed inline (`role="customer"` hard-coded on both platforms for this entry point), so merchant/admin auto-submit isn't separately exercised by a new test — consistent with backend being fully unchanged | Pass |
| 12 | `redirectAfterAuth`/`postLoginPath` NOT modified to honor `next`; standalone `/login` unaffected | A + M | `InlineAuthStep.test.tsx::"stores tokens directly and calls onAuthenticated on a successful OTP sign-in, never redirectAfterAuth"` (new, explicit negative assertion); `PhoneOtpPanel.test.tsx` (2/2 pass, unmodified — proves every existing caller keeps byte-identical `redirectAfterAuth` behavior incl. role-mismatch note); `LoginForm.test.tsx` (unmodified, part of full 354/354 suite run) proves standalone `/login` untouched; mobile: `router.dart`/`post_login_path.dart`/`login_screen.dart` all zero-diff per `git diff --stat` | Pass |
| 13 | Behavior-level parity web/mobile (same trigger, same 3 methods, same non-password default, same auto-submit) | A + M | Composed from the AC2/3, AC4/5, AC6/7 rows above on both platforms — no single "parity" test exists by design (AC13 explicitly says behavior-level, not pixel-level) | Pass |
| 14 | `CollectQrCard.tsx` / collect route / QR / App-Links contract unchanged | M | `git diff --stat main...HEAD -- frontend/src/components/CollectQrCard.tsx` — empty; no new route files in the branch diff | Pass |

**Coverage:** 14 / 14 AC mapped. 3 flagged as partial-automation gaps (AC4 Google presence on
web, AC6 Google/password auto-submit on web, AC10 explicit side-by-side test on web) — all
non-blocking, detailed below.

---

## Backend tests

None added. Confirmed no backend/API/RBAC/schema changes: `git diff --stat main...HEAD --
backend/` returns empty, matching the Architect spec's "no backend/API changes" declaration.

---

## Frontend tests

### Added
- `frontend/src/components/collect/__tests__/InlineAuthStep.test.tsx` (new, 4 cases: AC4/AC5
  default-method + toggle-reachability, AC9 wrong-password error, AC9 wrong-OTP error, AC6/
  ADR-018 "stores tokens directly, never `redirectAfterAuth`")
- `frontend/src/app/collect/[businessId]/__tests__/page.test.tsx` — 1 case rewritten by the
  prior Tester run (AC2/AC3 inline-step-in-place, replacing the old redirect-to-`/login`
  assertion) + 2 new cases added this session (AC6/AC7 OTP auto-submit; AC9 page-level
  retry-preserves-composed-state)
- `frontend/src/app/collect/[businessId]/__tests__/page.gamified.test.tsx` — 1 new case (AC2/
  AC6/AC7 for the gamified branch: inline step swaps in without resetting the frozen `screen`
  state, then auto-submits to the gamified celebration)

### Run output
```
cd frontend && npx jest "src/app/collect/[businessId]/__tests__/page.test.tsx" \
  "src/app/collect/[businessId]/__tests__/page.gamified.test.tsx" \
  src/components/collect/__tests__/InlineAuthStep.test.tsx \
  src/components/__tests__/PhoneOtpPanel.test.tsx
→ Test Suites: 4 passed, 4 total / Tests: 18 passed, 18 total

cd frontend && npx jest
→ Test Suites: 64 passed, 64 total / Tests: 354 passed, 354 total
```

---

## Mobile tests

Unchanged from the prior Tester run (re-verified this session, no new mobile files added):
- `mobile/test/inline_auth_step_test.dart` (new, 2 cases: AC4/AC5, AC9)
- `mobile/test/collect_review_inline_auth_test.dart` (new, 5 cases: AC6/AC7 Google, AC6/AC7
  OTP, AC9, AC10×2)
- `mobile/test/collect_review_screen_test.dart` — 1 case rewritten (AC2/AC3 inline-step-in-
  place, replacing the old `/login?next=...` push assertion)

### Run output
```
cd mobile && flutter test test/inline_auth_step_test.dart \
  test/collect_review_inline_auth_test.dart test/collect_review_screen_test.dart
→ All tests passed! (15/15)

cd mobile && flutter test
→ +321 -7: Some tests failed.
   Failing tests: forgot_password_screen_test.dart (7 cases) — pre-existing/unrelated,
   confirmed via git diff --stat main...HEAD showing zero changes to
   forgot_password_screen.dart, login_screen.dart, or forgot_password_screen_test.dart
   on this branch.

cd mobile && flutter analyze lib/features/reviews/inline_auth_step.dart \
  lib/features/reviews/collect_review_screen.dart \
  lib/features/reviews/gamified/gamified_collect_flow.dart
→ No issues found!
```

---

## Manual checklist

- [ ] M-121-1: Real Google Sign-In prompt cancellation on `/collect/[businessId]` (web) shows
  the inline error and leaves the composed review intact — cannot be automated in the current
  Jest/JSDOM environment (`NEXT_PUBLIC_GOOGLE_CLIENT_ID` unset in tests; the real
  `window.google.accounts.id` SDK is never loaded). Mobile's equivalent (`AC9` Google-error
  case in `collect_review_inline_auth_test.dart`) *is* automated via a mocked
  `googleSignInClientProvider`, so this is a web-only manual gap.
- [ ] M-121-2: Real Google Sign-In success on `/collect/[businessId]` (web) auto-submits the
  composed review — same automation limitation as M-121-1; only the phone-OTP path is proven
  end-to-end on web today.
- [ ] M-121-3: End-to-end device/browser check that the password+TOTP toggle branch (first-
  time enrollment QR + confirm, and returning-user verify) also auto-submits correctly on both
  platforms — covered by code inspection (identical `completeAuth()`/`onAuthenticated()` call
  site as the tested OTP path) but not by a dedicated automated auto-submit test for this
  specific branch on either platform.
- [ ] M-121-4: `docker compose up --build` smoke — confirm `/collect/[businessId]` renders and
  the inline step appears at submit time with no console errors in a real browser (not run this
  session; recommended before wide rollout per the usual browser-layer second view, S-010).

---

## Regressions / gaps

1. **AC4/AC9 (web)** — Google Sign-In's presence and its cancellation/error path aren't
   verifiable by an automated web test today because `NEXT_PUBLIC_GOOGLE_CLIENT_ID` is unset in
   the Jest environment, so `GoogleSignInButton` always renders `null` (confirmed: this affects
   *every* existing web auth test, including `LoginForm.test.tsx`, not something introduced by
   this slice). `InlineAuthStep.tsx` source code does render `GoogleSignInButton`
   unconditionally per the Architect spec, so this is a coverage gap, not a behavior gap.
   Recommend either a small test-infra addition (a `NEXT_PUBLIC_GOOGLE_CLIENT_ID` test value +
   a mocked `window.google.accounts.id`) as a future cross-cutting improvement, or manual
   sign-off (M-121-1/M-121-2) before wide rollout.
2. **AC6 (web)** — only the phone-OTP path is proven end-to-end (page-level auto-submit into
   `POST /reviews`) on web; Google and password+TOTP auto-submit are proven only by code
   inspection of the shared `completeAuth()` → `onAuthenticated()` call site (identical for all
   three methods) plus `InlineAuthStep.test.tsx`'s "never `redirectAfterAuth`" assertion, not by
   a dedicated end-to-end test per method. Mobile's `collect_review_inline_auth_test.dart`
   proves both Google *and* OTP end-to-end. Low risk given the shared call site, but flagging
   for parity with mobile's coverage depth (M-121-3 covers the password+TOTP branch
   specifically).
3. **AC10 (web)** — no single web test explicitly compares the 1-star vs. 5-star inline-auth
   gate side by side the way mobile's `expectIdenticalGateForRating` helper does. Coverage is
   implicit: ratings 1 (pre-existing), 2, 3, 4 (new S-121 tests), and 5 (pre-existing signed-in
   test) are all exercised across the S-121 web test set, all hitting the identical
   `authPending`/`InlineAuthStep` gate condition, and the Architect spec documents the
   structural guarantee (`auth.me()`'s catch branch has zero reference to `rating` anywhere).
   Low risk, but not a literal AC10-named test on web.
4. **Pre-existing, unrelated** — `forgot_password_screen_test.dart` (7 failures) in the full
   mobile suite run. Confirmed via `git diff --stat main...HEAD` to have zero changes to
   `forgot_password_screen.dart`, `login_screen.dart`, or the test file itself on this branch.
   Already tracked separately (background task `task_32819c04`), not part of this slice's diff.
5. **README §12/§14 not yet updated on this branch** — `git diff --stat main...HEAD --
   README.md` was empty before this test-report session (I updated only the §11 feature → test
   index row, within Tester scope). The slice's own PM Definition-of-done checklist calls for
   a §12 Web ↔ mobile parity tracker touch (both platforms ship this simultaneously with
   matching behavior) and a §14 known-gaps resolution for the "`next` param ignored" bug this
   slice is designed to obsolete. Note: I searched README.md for existing "next param
   ignored"/"silently ignored" gap text and found no matching entry to remove — so that half of
   the §14 item may already be moot (the gap was apparently never formally logged in §14 to
   begin with), but the §12 parity-tracker pass is still outstanding. This is a PM/Builder DoD
   item, not a test failure — flagging so it isn't missed before `Status: Accepted`.

---

## Recommendation

**Ship.** All 14 AC are mapped to passing automated tests or justified manual/code-inspection
checks; RBAC is unchanged and confirmed via an empty backend diff; the shared `PhoneOtpPanel.tsx`/
`page.tsx` changes pass the full 354/354 web regression suite; the 7 mobile failures are
confirmed pre-existing and unrelated to this slice's diff; `flutter analyze` is clean on all
touched mobile files. The 3 flagged gaps (AC4/AC9 Google-path web test-env limitation, AC6
Google/password-path web coverage depth, AC10 explicit side-by-side web test) are all
coverage-depth gaps backed by either mobile's stronger equivalent coverage or direct code
inspection — none indicate a broken behavior. Recommend PM close the README §12 parity-tracker
DoD item in the same PR before setting `Status: Accepted`, and treat the manual checklist
(M-121-1 through M-121-4) as pre-wide-rollout sign-off, not a blocker to Accepted.
