# Slice: S-121 — Inline auth-on-submit for QR review collection

| Field | Value |
|-------|-------|
| **Slice ID** | S-121 |
| **Phase** | 2 Core |
| **Status** | Accepted |
| **Role(s)** | customer |
| **Owner** | PM / 2026-08-29 |

**Priority:** High — the collect flow is the highest-traffic unauthenticated entry point
(reached from every printed/shared QR code) and its "< 30 seconds" promise is currently
broken by a silent, state-losing redirect to `/login` whose `next` param is never even
honored. This is a conversion-critical bug fix plus UX improvement, not a nice-to-have.

---

## User story

**As a** customer scanning a merchant's review QR code
**I want** to compose my full review (stars, highlights, text) without being interrupted, and
only be asked to sign in — using whichever method is fastest for me — at the moment I actually
submit
**So that** I never lose a review I already wrote to a dead-end redirect, and leaving a review
truly takes less than 30 seconds as the page promises

---

## Acceptance criteria

1. **Given** an unauthenticated customer opens `/collect/[businessId]` (web) or `/collect/:slug`
   (mobile), **when** they progress through the star rating, highlight-chip (web), and
   comment/text steps of the composer, **then** no login prompt, redirect, or authentication
   check appears at any point before they tap Submit — composing the review is completely open,
   identical to an authenticated customer's experience. (Reaffirms: zero gate on the composer.)
2. **Given** an unauthenticated customer on web has composed a rating/chips/body and taps
   "Post review" (Submit), **when** the submit handler runs, **then** it does **not** call
   `router.push('/login?next=...')` or navigate away from `/collect/[businessId]` — instead an
   inline login step renders within the same page, and the composed rating/chips/body remain
   held in the page's existing in-memory state (no route change occurs).
3. **Given** an unauthenticated customer on mobile has composed a rating/comment and taps
   "Post review" in the collect screen, **when** `_submit()` runs, **then** it does **not** call
   `context.push('/login?next=...')` — instead an inline login step renders within the same
   screen (no named-route push/pop occurs), and the composed rating/body remain held in the
   screen's existing widget state.
4. **Given** the inline login step is shown (web or mobile), **when** the customer views the
   available sign-in options, **then** all three existing methods are present and functional:
   email+password (including mandatory first-time TOTP enrollment where applicable), Google
   Sign-In, and phone OTP — the same method set as the standalone `/login` page, with none
   stripped down or removed.
5. **Given** the inline login step is shown for this collect-flow entry point specifically,
   **when** it first renders, **then** the pre-selected/default method is Google Sign-In or
   phone OTP — **not** email+password — while email+password remains reachable via the same
   toggle used on `/login`. Rationale: password+TOTP enrollment alone would blow past the
   "< 30 seconds" completion budget for a first-time visitor at this specific entry point.
6. **Given** the customer completes any one of the three inline login methods successfully
   (including finishing mandatory first-time TOTP enrollment, if that path is chosen), **when**
   authentication succeeds, **then** the review submits automatically using the rating/chips/body
   already composed — no form is re-shown and no review content is re-entered.
7. **Given** auto-submission after inline login succeeds, **when** `POST /reviews` returns 201,
   **then** the customer lands on the existing celebration/done experience — the gamified
   `CelebrationStep`/`GamifiedCelebrationStep` (S-119) when that flag is on, or the existing
   plain done screen when it is off — with no new or duplicate success screen introduced by this
   slice.
8. **Given** the customer is already authenticated when they tap Submit, **when** the submit
   handler runs, **then** no inline login step is shown at all and the review submits directly —
   identical to today's behavior for a logged-in user (regression case).
9. **Given** the inline login step is shown and the customer enters wrong credentials, cancels
   the Google prompt, or enters a wrong OTP, **when** the attempt fails, **then** the customer
   sees the existing inline auth error messaging within the login step, stays on the collect
   page/screen (no navigation away), and their previously composed rating/chips/body are still
   intact so they can retry authentication without recomposing the review.
10. **Given** any of the 5 possible star ratings (1 through 5), **when** an unauthenticated
    customer submits, **then** whether the inline login gate appears at all, and which
    methods/default it offers, is identical regardless of the rating chosen — reaffirms S-040's
    no-rating-gating rule; the auth-on-submit gate is not a rating-based funnel.
11. **Given** `POST /reviews` remains `require_roles(CUSTOMER, MERCHANT, ADMIN)` (unchanged),
    **when** a customer, merchant, or admin account authenticates via the inline step, **then**
    auto-submit proceeds identically for all three roles — this slice adds no new role
    restriction on who may author a review and removes none.
12. **Given** this slice is implemented, **when** a developer inspects `redirectAfterAuth` (web,
    `frontend/src/lib/api.ts`) and `postLoginPath`/mobile's login submit path, **then** neither is
    changed to finally honor the `next` query param passed to `/login`. Because inline
    auth-on-submit means the collect flow never navigates to `/login` in the first place, the
    previously-confirmed "`next` is silently ignored" bug is **obsoleted by this design**, not
    separately patched. The standalone `/login` page (e.g. reached via the header's "Log in"
    link) keeps today's `redirectAfterAuth`/`postLoginPath`/`roleLandingPath` behavior unchanged
    for every entry point other than this one.
13. **Given** both platforms implement this slice, **when** comparing web and mobile collect
    flows, **then** both exhibit the same trigger condition (login only on submit-while-
    unauthenticated), the same three-method availability, the same non-password-TOTP default,
    and the same auto-submit-after-login behavior — parity is at the behavior level, not
    necessarily identical pixel layout.
14. **Given** `frontend/src/components/CollectQrCard.tsx`, the collect route URLs, and the
    QR/App-Links targets established by S-118, **when** this slice is implemented, **then** none
    of them change — only the in-page/in-screen behavior at submit time changes.

---

## UX notes

- Screens / routes: Web `/collect/[businessId]` (existing route, no new route). Mobile
  `/collect/:slug` (existing route, no new route). The inline login step is a new internal state
  within each existing page/screen's step flow, not a new page.
- Figma (mobile file `rk4RnruVFTpKdIsgGJIt9w`) frame + states (default / empty / loading /
  error): TBD — Architect/UX to confirm the frame name for the new "inline login" step within
  the existing collect flow (states: method-selection default with Google/phone-OTP pre-selected,
  password+TOTP toggled-in, loading/submitting, auth-error, and the auto-submit transition into
  the existing celebration/done frame) before Builder starts mobile work.
- Mobile placement (named hub slot or new route — never append to a dump-screen): Renders as a
  conditional step inside the existing `/collect/:slug` route's own step sequence only — not
  added to any hub, dashboard, or as a pushed route.
- Components to reuse: Web — the existing `LoginForm.tsx` building blocks (`AuthMethodToggle`,
  `GoogleSignInButton`, `PhoneOtpPanel`) re-hosted inline inside the collect page rather than the
  full standalone `/login` route; the existing gamified `CelebrationStep` (S-119) and the
  existing plain done state, both reused unmodified. Mobile — the equivalent existing login
  widgets (Google sign-in button, phone OTP panel) re-hosted inline inside the collect screen
  rather than pushing `login_screen.dart`; the existing `_SuccessState`/celebration step, reused
  unmodified.
- Empty states / errors: Inline auth error surfaces within the login step without losing
  composed review state (AC9). Post-auto-submit review errors (e.g. network failure) reuse the
  existing inline-error-with-retry pattern already established for submission failures (S-119
  AC8) — no new error-handling pattern introduced.
- AI disclaimer required? no — this slice touches only authentication UI and submit-time
  sequencing; it introduces no AI-generated content.

---

## Out of scope

- Any change to `Review.author_id` (non-nullable FK to `users.id`), its
  `UniqueConstraint(author_id, business_id)`, or `POST /reviews`'s
  `require_roles(CUSTOMER, MERCHANT, ADMIN)` — reviews remain account-owned by design; this
  slice does **not** introduce anonymous or guest reviews.
- Any change to the standalone `/login` page's own default method, behavior, or its
  `redirectAfterAuth`/`postLoginPath`/`roleLandingPath` post-login destination for any entry
  point other than this collect flow (e.g. the header "Log in" link, merchant/admin dashboards
  keep landing where they land today).
- Any change to S-118's frozen collect route/QR/App-Links contract or
  `frontend/src/components/CollectQrCard.tsx`.
- Any change to what phone OTP or Google Sign-In do on a brand-new number/account (e.g. phone
  OTP already creates a customer/merchant account for an unrecognized number per existing
  behavior) — unchanged here, only *where* that existing flow is hosted (inline vs. a separate
  route) changes.
- Visual/UI redesign of the login form's own fields, copy, or styling
  (`AuthMethodToggle`/`GoogleSignInButton`/`PhoneOtpPanel`) — reused as-is, only re-hosted inline
  and re-defaulted (Google/OTP over password) for this one entry point.
- Building a generic "inline auth" pattern for other write actions (e.g. liking a review,
  following a business) — this slice is scoped strictly to the Submit action of the QR review
  collection flow on both platforms.
- Any change to which roles may author reviews or to review edit/delete/like/reply permissions —
  unchanged.

---

## Dependencies

- S-040 (must be Accepted) — original collect flow and the no-rating-gating rule this slice must
  keep holding.
- S-118 (must be Accepted) — frozen collect route/QR/App-Links contract this slice must not
  touch.
- S-119 (must be Accepted) — gamified tap-through composer (stars/chips/text) and celebration
  screens this slice's auto-submit lands on; this slice's login step is inserted into that same
  flow.

---

## Definition of done (PM)

- [x] All AC verified in test report — 14/14 AC mapped in `TR-S-121-inline-auth-on-submit.md`,
      all Pass. 3 flagged coverage-depth gaps (web Google-button JSDOM limitation, web AC6
      Google/password auto-submit proven by code inspection of the shared `completeAuth()` call
      site rather than a dedicated per-method e2e test, web AC10 implicit rather than an explicit
      1-vs-5-star side-by-side test) reviewed by PM and judged non-blocking — see Changelog.
- [x] UX matches notes above — confirmed by reading `InlineAuthStep.tsx` and
      `collect_review_screen.dart`: inline step renders in the existing step flow (no new route),
      `authMethod`/`_method` defaults to `"otp"`, `GoogleSignInButton` renders unconditionally,
      password+TOTP reachable via the existing toggle only.
- [x] Documented in `README.md` §7 API reference / §8 Frontend guide if new patterns — n/a. No
      new/changed endpoint (§7). No novel frontend pattern beyond composing already-documented
      primitives (`AuthMethodToggle`/`GoogleSignInButton`/`PhoneOtpPanel`) inline with standard
      `useState`; §8 is an illustrative guide, not an exhaustive component catalog, and S-119's
      comparable (larger) new gamified-flow component set set the same precedent of not touching
      §7/§8.
- [x] README §12 Web ↔ mobile feature parity tracker row updated if the inline-auth behavior
      lands on one platform before the other — done (main session, this branch): M-71 row gained
      a dated **S-121** (2026-08-29) note; verified it reads correctly and matches what shipped.
- [x] README §14 Known gaps updated to remove/resolve the "`next` param ignored" gap this slice
      obsoletes (once shipped) — verified via repo-wide search: no existing §14 entry ever
      documented this bug, so there is nothing to remove. Confirmed moot, not skipped.
- [x] PM Status set to **Accepted**

---

## Technical specification (Architect)

No backend/API changes. `POST /reviews`'s `require_roles(CUSTOMER, MERCHANT, ADMIN)`, the
`Review.author_id` FK, and `UniqueConstraint(author_id, business_id)` are all unchanged. Every
existing auth endpoint (`auth.login`, `auth.google`, phone OTP request/verify, TOTP setup/
confirm/verify) is reused as-is — no new backend auth flow, no new endpoint. This is a
frontend-only, both-platform, presentation + submit-time-sequencing change to the existing
`/collect/[businessId]` page (web) and `/collect/:slug` screen (mobile), both frozen by S-118 and
untouched at the route/QR/App-Links level. **See `docs/agents/adrs/ADR-018-inline-auth-bypasses-redirect-helpers.md`**
for the crux design decision (why the inline step stores tokens directly instead of reusing
`redirectAfterAuth`/`postLoginPath`) — read that first; this section builds on it.

### API contract

| Method | Path | Auth | Notes |
|--------|------|------|-------|
| POST | `/api/v1/auth/login` | Public | Unchanged. Called directly by web's new `InlineAuthStep.tsx` (same call `LoginForm.tsx` makes) and, on mobile, indirectly via the unchanged `AuthController.submitCredentials`. |
| POST | `/api/v1/auth/google` | Public | Unchanged. Called directly by `InlineAuthStep.tsx`/mobile's `AuthController.signInWithGoogle` (via the reused, unmodified `GoogleSignInButton` on both platforms). |
| POST | `/api/v1/auth/phone/request`, `/api/v1/auth/phone/verify` | Public | Unchanged. Called via the reused `PhoneOtpPanel` (web: small additive `onTokens` prop, see below; mobile: zero changes) / `AuthController.requestPhoneOtp`/`signInWithPhone`. |
| POST | `/api/v1/auth/mfa/totp/setup`, `/confirm`, `/verify` | Public (mfa_token-scoped) | Unchanged. Called directly for the password+TOTP toggle branch, mirroring `LoginForm.tsx`/`login_screen.dart`'s existing calls. |
| GET | `/api/v1/auth/me` | Bearer | Unchanged. Still the existing pre-submit auth check in web's `submit()` (was already there; only what happens on failure changes — see Flow). Mobile keeps using `authControllerProvider`'s resolved session, unchanged. |
| POST | `/api/v1/reviews` | Bearer, `require_roles(CUSTOMER, MERCHANT, ADMIN)` | **Unchanged contract and unchanged RBAC.** Same `ReviewCreate` payload shape as S-119 (`business_id`, `rating`, `title?`, `body`). Auto-submitted after inline auth succeeds, using the composer state already held in the page/screen — no new payload field, no new call site logic beyond re-invoking the existing `submit()`/`_submit()` function. |

No new or modified endpoints.

### RBAC matrix

| Action | customer | merchant | admin |
|--------|----------|----------|-------|
| View collect composer (stars/chips/text), unauthenticated | yes (public route, unchanged) | yes | yes |
| View inline login step (Google/Phone-OTP pre-selected; password+TOTP via toggle) | yes (public, no new gate) | yes | yes |
| Auto-submit review immediately after inline auth succeeds | yes | yes | yes |
| Submit review while already authenticated (regression case, AC8) | yes | yes | yes |

Unchanged from today — `require_roles(CUSTOMER, MERCHANT, ADMIN)` on `POST /reviews` is not
touched, so this slice adds no new role restriction and removes none (AC11). **No-gating
structural guarantee (S-040, AC10):** the only branch condition that decides whether the inline
login step appears is `try { await auth.me() } catch { … }` (web) / `authControllerProvider`'s
resolved session (mobile) — a pure "is there a valid session" check with zero reference to
`rating`/`selectedChips`/`body` anywhere in its condition, call site, or the component it renders.
There is structurally no code path by which a star value could change whether the gate appears or
which method is defaulted.

### Data model impact

- [x] None

No schema, migration, or enum changes. No new table, column, or index.

### Cache / side effects

None. No `search:*` or other Redis cache keys are touched — `POST /reviews`'s existing cache
behavior (unchanged since S-040/S-119) is the only write in this flow. Token storage is
client-side only: web's existing `localStorage` via the unmodified `storeTokens()`; mobile's
existing secure-storage-backed `AuthRepository`/`authControllerProvider`, both untouched.

### Frontend

- **Route:** Web `/collect/[businessId]` (existing, unchanged). Mobile `/collect/:slug`
  (existing, unchanged). No new routes on either platform — the inline login step is new internal
  render state, not a new route/screen (S-118 reaffirmed, AC14).
- **Rendering:** CSR (unchanged) on both — same client-rendered wizard as S-119; only what renders
  inside it changes.
- **Components (reuse first):**

  **Web:**
  - New `frontend/src/components/collect/InlineAuthStep.tsx` — shared by both the plain and
    gamified render branches (not gamified-specific, so lives beside `collect/DraftEngine.ts`, not
    under `collect/gamified/`). Props: `{ onAuthenticated: () => void }`. Internal state mirrors
    `LoginForm.tsx`'s shape but is **not** a reuse of `LoginForm.tsx` itself (that component is
    page-shaped: it owns `useSearchParams`, a "Signing in as" role `<Select>`, a "registered"
    query-flag banner, a forgot-password link, and its own `<form>` card chrome — none of which
    apply inline). Composes the three existing primitives directly:
    - `AuthMethodToggle` (reused, zero changes) — local `authMethod` state defaults to `"otp"`
      (not `"authenticator"`), satisfying AC5's "not email+password by default".
    - `GoogleSignInButton` (reused, zero changes) — rendered **unconditionally**, independent of
      `authMethod`'s value (LoginForm today nests it only inside the `"authenticator"` branch;
      `InlineAuthStep` instead always shows it, so Google is immediately available alongside the
      OTP-default panel without an extra toggle tap — this ordering lives only in the new
      component, `LoginForm.tsx`'s own layout is untouched).
    - `PhoneOtpPanel` (reused, one small additive prop — see below) — rendered when
      `authMethod === "otp"` (the default), passed `role="customer"` (matching `LoginForm`'s own
      `loginRole` default; no role selector is exposed inline, per Out-of-scope).
    - A local password+TOTP mini state machine (`step: "credentials" | "enroll" | "verify"`)
      calling `auth.login`, `auth.totpSetup`, `auth.totpConfirm`, `auth.totpVerify` directly —
      the **same** functions `LoginForm.tsx` calls, mirroring its branching logic 1:1, but
      re-implemented locally rather than importing `LoginForm.tsx` (see ADR-018's "Alternatives
      considered" #3 and the Risks section below for why this small, intentional duplication is
      accepted rather than extracting a shared `PasswordTotpPanel`). Rendered when
      `authMethod === "authenticator"` (reachable via the toggle, never the default — AC5).
    - On any method's success: local `completeAuth(tokens)` → `storeTokens(tokens)` (existing,
      unmodified `lib/api.ts` export) → `props.onAuthenticated()`. **Never** calls
      `redirectAfterAuth` or `router.push` (ADR-018).
    - Own local `error`/`loading` state, displayed with the same inline red-text pattern
      `LoginForm.tsx` already uses (AC9) — independent of the page's review-submission `error`.
  - `frontend/src/components/PhoneOtpPanel.tsx` — **one additive, backward-compatible change**:
    a new optional `onTokens?: (tokens: TokenResponse) => void` prop. In `verify()`, when
    `onTokens` is supplied it's called instead of `redirectAfterAuth(tokens, {...})`; when omitted
    (every existing caller — `LoginForm.tsx` and any other current caller), behavior is
    byte-identical to today, including the `expectedRole`/`onRoleMismatch` note. `InlineAuthStep`
    is the only caller that passes `onTokens`.
  - `frontend/src/app/collect/[businessId]/page.tsx` — modify `submit()`: on `auth.me()` failure,
    replace `router.push('/login?next=/collect/${businessId}')` with `setAuthPending(true)` (new
    `useState<boolean>` alongside the existing `rating`/`selectedChips`/`body`/`error` state), then
    `return`. Extract the existing `reviews.create(...)`/`setSubmitted`/`setStep("done")`/catch
    block (today's second half of `submit()`) into a `createReview()` helper, called both by
    `submit()` (already-authenticated case, unchanged) and by a new `handleAuthenticated()`
    (`setAuthPending(false); void createReview();`) passed to `InlineAuthStep`/`GamifiedCollectFlow`
    as `onAuthenticated`. Rendering: when `!gamified && step === "text" && authPending`, render
    `<InlineAuthStep onAuthenticated={handleAuthenticated} />` in place of the existing text
    `<form>` (the surrounding `step === "text"` gate is untouched, so nothing about the plain
    flow's step machine changes shape — only its "text" step conditionally swaps its inner
    content). When `gamified`, pass `authPending`/`onAuthenticated={handleAuthenticated}` down
    into `GamifiedCollectFlow` as two new props instead of branching in the page.
  - `frontend/src/components/collect/gamified/GamifiedCollectFlow.tsx` — add
    `authPending: boolean` and `onAuthenticated: () => void` to `GamifiedCollectFlowProps`. Inside
    `StepCard`, when `authPending` is true, render `<InlineAuthStep onAuthenticated={onAuthenticated} />`
    instead of the `screen`-based `stars`/`chips`/`text` branch, with `screenKey={authPending ? "auth" : screen}`.
    Critically, the component's own `screen` state (`useState<GamifiedScreen>("stars")`) is **not**
    reset or touched by `authPending` — it stays frozen at `"text"` (the only screen `onSubmit` is
    wired from), so when `authPending` flips back to `false` after auth succeeds, `TextStep`
    reappears exactly as the user left it (satisfies AC6's "no form is re-shown"). No changes to
    `StarStep.tsx`, `ChipStep.tsx`, `TextStep.tsx`, `StepCard.tsx`, or `CelebrationStep.tsx`.
  - **Zero changes:** `AuthMethodToggle.tsx`, `GoogleSignInButton.tsx`, `LoginForm.tsx`,
    `frontend/src/lib/api.ts`'s `redirectAfterAuth`/`roleLandingPath`/`storeTokens` (all reused
    verbatim; `redirectAfterAuth`/`roleLandingPath` keep serving `/login` and every other caller
    unchanged — ADR-018), `frontend/src/components/CollectQrCard.tsx` (S-118, AC14).

  **Mobile:**
  - New `mobile/lib/features/reviews/inline_auth_step.dart` — a `ConsumerStatefulWidget`, sibling
    to `collect_review_screen.dart` (shared by plain and gamified branches, so not placed under
    `reviews/gamified/`). No `onAuthenticated` callback param is needed: unlike web, mobile's
    `GoogleSignInButton`/`PhoneOtpPanel`/`AuthController` TOTP methods only mutate
    `authControllerProvider`'s Riverpod state and never navigate (ADR-018) — the parent
    `CollectReviewScreen` detects success itself via `ref.listen`. Internally:
    - Local `_method` (`otp` default | `password`) and `_step` (`credentials | enroll | verify`)
      enums, deliberately mirroring `login_screen.dart`'s private `_LoginMethod`/`_Step` (which
      are not exported/shared types, so a small local re-declaration is unavoidable without
      touching `login_screen.dart`).
    - `GoogleSignInButton` (reused, zero changes) rendered whenever `_step == credentials`,
      independent of `_method` — this **already matches** `login_screen.dart`'s own existing
      layout (Google is shown regardless of the OTP/Password segmented control there too), so no
      new visual pattern is introduced.
    - `PhoneOtpPanel` (reused, **zero changes** — see ADR-018: mobile needs no `onTokens`-style
      escape hatch since this widget never navigated in the first place) rendered when
      `_method == otp` (default), passed `role: UserRole.customer`.
    - Local password+TOTP fields calling `authControllerProvider.notifier`'s existing
      `submitCredentials`/`startTotpEnrollment`/`confirmTotpEnrollment`/`verifyTotp` — the same
      calls `login_screen.dart` makes — reachable via a `SegmentedButton<_method>` mirroring
      `login_screen.dart`'s own (not extracted into a shared widget on mobile today, so this is
      the mobile equivalent of web's small, accepted `LoginForm`-vs-`InlineAuthStep` duplication).
    - Own local `_error`/`_busy` display, matching `login_screen.dart`'s existing inline-error
      pattern (AC9).
  - `mobile/lib/features/reviews/collect_review_screen.dart` — add `bool _authPending = false;`.
    In `_submit()`, replace `context.push('/login?next=...')` with `setState(() => _authPending = true); return;`
    when `!isLoggedIn`. Add, unconditionally near the top of `build()` (before
    `businessAsync.when(...)`, so it runs on every build per Riverpod's `ref.listen` contract):
    `ref.listen(authControllerProvider, (previous, next) { if (_authPending && previous?.valueOrNull == null && next.valueOrNull != null) { setState(() => _authPending = false); final business = ref.read(collectBusinessProvider(widget.slug)).valueOrNull; if (business != null) _submit(business); } });`
    (safe to read `business` this way since `_authPending` can only become `true` after `business`
    has already resolved once, per `_submit`'s existing signature). In the plain-flow branch,
    render `InlineAuthStep()` in place of the `Rating`/`TextField`/`Submit` column when
    `_authPending`; when `AppConfig.gamifiedReview`, pass `authPending: _authPending` and an
    `authStep: const InlineAuthStep()` widget down into `GamifiedCollectFlow`.
  - `mobile/lib/features/reviews/gamified/gamified_collect_flow.dart` — add required
    `authPending: bool` and `authStep: Widget` params. `AnimatedSwitcher`'s `child` becomes
    `widget.authStep` (keyed `ValueKey('gamifiedAuthStep')`) when `authPending`, else the existing
    `_screen`-based `stars`/`text` branch, unchanged. `_screen` itself is never touched by
    `authPending`, so it stays frozen at `_GamifiedScreen.text` (the only screen `onSubmit` is
    wired from) and reappears unchanged once `authPending` flips back — same "no form re-shown"
    guarantee as web. No changes to `star_step.dart`, `text_step.dart`, or `celebration_step.dart`.
  - **Zero changes:** `phone_otp_panel.dart`, `google_sign_in_button.dart`, `login_screen.dart`,
    `register_screen.dart`, `post_login_path.dart`, `router.dart` (its `redirect` callback already
    exempts `/collect/` from every logged-in branch — confirmed by inspection, see ADR-018 — no
    edit needed), `auth_provider.dart`, `auth_repository.dart`.

### Flow

**Web** — inline auth completion bypasses `redirectAfterAuth` entirely (ADR-018); auto-submit
reuses the existing `submit()`/`createReview()` path:

```mermaid
sequenceDiagram
    participant User
    participant CollectPage as /collect/[businessId]
    participant InlineAuth as InlineAuthStep
    participant AuthAPI as auth.* (login/google/phone/totp)
    participant ReviewsAPI as POST /reviews

    User->>CollectPage: compose rating/chips/body, tap "Post review"
    CollectPage->>CollectPage: submit() calls auth.me()
    alt unauthenticated (401)
        CollectPage->>CollectPage: setAuthPending(true) -- no router.push
        CollectPage->>InlineAuth: render (screen/step state frozen, composer data untouched)
        User->>InlineAuth: choose Google (default) or Phone OTP, or toggle to password+TOTP
        InlineAuth->>AuthAPI: auth.login / auth.google / auth.phoneVerify / auth.totp*
        alt auth fails (wrong code, cancelled Google, etc.)
            AuthAPI-->>InlineAuth: error
            InlineAuth->>InlineAuth: inline error shown, stays in InlineAuthStep (AC9)
        else auth succeeds
            AuthAPI-->>InlineAuth: tokens
            InlineAuth->>InlineAuth: storeTokens(tokens) -- NOT redirectAfterAuth
            InlineAuth->>CollectPage: onAuthenticated()
            CollectPage->>CollectPage: setAuthPending(false); createReview()
            CollectPage->>ReviewsAPI: POST /reviews (rating/chips/body already held)
            alt 201
                ReviewsAPI-->>CollectPage: created review
                CollectPage->>CollectPage: existing celebration/done handoff (S-119, unchanged)
            else error
                ReviewsAPI-->>CollectPage: error
                CollectPage->>CollectPage: existing inline-error-with-retry (S-119 AC8, unchanged)
            end
        end
    else already authenticated
        CollectPage->>ReviewsAPI: POST /reviews directly (AC8 regression case, unchanged)
    end
```

**Mobile** — auth completion never navigates (no `context.push` involved at all, per ADR-018);
`CollectReviewScreen` detects success via `ref.listen` on `authControllerProvider`:

```mermaid
sequenceDiagram
    participant User
    participant CollectScreen as /collect/:slug
    participant InlineAuth as InlineAuthStep (Dart)
    participant AuthController as authControllerProvider
    participant ReviewsAPI as POST /reviews

    User->>CollectScreen: compose rating/body, tap "Post review"
    CollectScreen->>CollectScreen: _submit() checks authControllerProvider session
    alt unauthenticated
        CollectScreen->>CollectScreen: setState(_authPending = true) -- no context.push
        CollectScreen->>InlineAuth: render (GamifiedCollectFlow's _screen frozen, controllers untouched)
        User->>InlineAuth: choose Google (default) or Phone OTP, or toggle to password+TOTP
        InlineAuth->>AuthController: signInWithGoogle / signInWithPhone / submitCredentials+totp*
        alt auth fails
            AuthController-->>InlineAuth: throws
            InlineAuth->>InlineAuth: inline error shown, stays in InlineAuthStep (AC9)
        else auth succeeds
            AuthController->>AuthController: state = AsyncValue.data(user)
            Note over CollectScreen,AuthController: router.dart's redirect already exempts /collect/ -- no navigation (ADR-018)
            AuthController-->>CollectScreen: ref.listen fires (null -> user)
            CollectScreen->>CollectScreen: setState(_authPending = false); _submit(business)
            CollectScreen->>ReviewsAPI: createReview (rating/body already held in controllers)
            alt success
                ReviewsAPI-->>CollectScreen: created review
                CollectScreen->>CollectScreen: existing celebration/_SuccessState handoff (S-119, unchanged)
            else error
                ReviewsAPI-->>CollectScreen: error
                CollectScreen->>CollectScreen: existing inline-error-with-retry (S-119 AC8, unchanged)
            end
        end
    else already authenticated
        CollectScreen->>ReviewsAPI: createReview directly (AC8 regression case, unchanged)
    end
```

### Architect checklist

- [x] API contract defined and matches `README.md` §7 API reference style (no new/modified
      endpoints, explicitly enumerated as unchanged call sites)
- [x] RBAC matrix complete (unchanged `require_roles(CUSTOMER, MERCHANT, ADMIN)` on
      `POST /reviews`; no-gating structural guarantee documented for S-040/AC10)
- [x] Data model impact documented (none)
- [x] Cache invalidation considered (n/a — no new writes, no cache keys touched)
- [x] Uses AI/storage abstractions where applicable (n/a — no AI content, no storage/upload use)
- [x] No secrets in design
- [x] ERD/API/FLOWS updates noted — none needed for §5/§7 (no schema/endpoint change); README §6
      may gain a short note on the inline-auth variant of the collect flow; §12 parity tracker and
      §14 known gaps updated per PM DoD once shipped (removing the "`next` param ignored" gap)

### Risks / tradeoffs

- **Small, intentional duplication of the password+TOTP step machine.** Neither platform has an
  extractable "password+TOTP panel" component today (`LoginForm.tsx`/`login_screen.dart` both
  inline it directly), unlike `PhoneOtpPanel`/`GoogleSignInButton`/`AuthMethodToggle`, which *are*
  extracted and fully reused. `InlineAuthStep` on both platforms therefore re-implements this one
  sub-flow locally, calling the identical underlying `auth.*`/`AuthController` functions (no
  duplicated network logic, only duplicated step-state scaffolding). Accepted per ADR-018
  Alternatives #3 rather than refactoring `LoginForm.tsx`/`login_screen.dart` to extract a shared
  component, which would add regression surface to the standalone `/login` page/screen this slice
  is explicitly barred from touching. Flagged as a candidate for a future extraction slice if
  this duplication needs a third caller.
- **`PhoneOtpPanel.tsx`'s new `onTokens` prop is an extra responsibility on a shared component.**
  Small and backward-compatible today, but future changes to `PhoneOtpPanel`'s internal
  `auth.phoneVerify` call must remember both completion paths (default `redirectAfterAuth` vs.
  `onTokens`). No equivalent risk on mobile (`PhoneOtpPanel`/mobile needs zero changes — see
  ADR-018).
- **Web/mobile asymmetry in how "auth completion" is wired** (explicit `onAuthenticated` callback
  on web vs. `ref.listen`-driven detection on mobile) is a direct consequence of each platform's
  pre-existing auth-completion architecture (web's auth widgets navigate themselves today; mobile's
  don't). Documented here so Builder doesn't try to force one pattern onto both platforms.
- **Role-mismatch note not reproduced inline** (web phone-OTP path) — see ADR-018 Consequences.
  Minor, scoped, doesn't block any AC.
- **Riverpod `ref.listen` placement (mobile).** Must be registered unconditionally in `build()`
  (not nested inside `businessAsync.when()`'s `data` branch) per Riverpod's per-build `ref.listen`
  contract — the spec above places it correctly; Builder should not move it into a conditional
  branch even though `business` is only available there (work around via
  `ref.read(collectBusinessProvider(widget.slug)).valueOrNull` inside the listener, as specified).

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-121-*.md`
- Test report: `docs/agents/test-reports/TR-S-121-*.md`
- ADR: `docs/agents/adrs/ADR-018-inline-auth-bypasses-redirect-helpers.md`

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-29 | PM | Created slice |
| 2026-08-29 | Architect | Technical spec filled in (no backend/API/data-model changes); read current source on both platforms and designed the `authPending`-gated internal state-machine shape (frozen `screen`/`_screen` so no form is re-shown post-auth), the shared `InlineAuthStep`/`inline_auth_step.dart` component plan (reusing `AuthMethodToggle`/`GoogleSignInButton`/`PhoneOtpPanel` on web and their mobile equivalents unmodified except one small additive `onTokens` prop on web's `PhoneOtpPanel.tsx`), and wrote ADR-018 on bypassing `redirectAfterAuth`/`postLoginPath` for this entry point only. Status → Specified. |
| 2026-08-29 | PM | **Accepted.** Reviewed `TR-S-121-inline-auth-on-submit.md` against all 14 AC — matrix complete, all Pass. Re-verified test evidence: frontend static test-declaration count (`it(`/`test(` across `frontend/src`) is an exact match to the Tester's reported **354 across 64 files**; mobile test files and the `forgot_password_screen_test.dart` pre-existing-failure claim were confirmed present and consistent (no `skip:`/`@Tags` exclusions found), though this session had no shell/Bash tool available to literally re-execute `npx jest` / `flutter test` — corroboration here is via exact-match static analysis (web) and file/content inspection (both platforms), not a live run. Spot-checked the actual diff against the Architect spec by reading `InlineAuthStep.tsx`, `PhoneOtpPanel.tsx`'s new optional `onTokens` prop, `collect_review_screen.dart`'s `_authPending`/`ref.listen` wiring, and confirmed zero `router.push('/login...)`/`context.push('/login...)` remain in either submit path, and `CollectQrCard.tsx` has no trace of the new machinery (AC14). Judged the 3 flagged gaps non-blocking: (1) web Google-button JSDOM limitation is a pre-existing, suite-wide test-infra gap (affects `LoginForm.test.tsx` too), not introduced by this slice, and source confirms `GoogleSignInButton` renders unconditionally per spec; (2) web AC6 Google/password auto-submit is proven only by code inspection of the shared `completeAuth()` → `onAuthenticated()` call site rather than a dedicated e2e test per method, but that call site is identical for all three methods and mobile proves Google+OTP end-to-end, so risk is low; (3) web AC10 has no single explicit 1-vs-5-star side-by-side test (mobile does), but ratings 1–5 are all implicitly exercised across the S-121 web test set and the Architect-documented structural guarantee (`auth.me()`'s catch branch has zero reference to `rating`) holds. README verified: §11 feature → test index row (`Collect review / merchant QR`) lists the S-121 test files and TR-S-121; §12 M-71 row carries the dated S-121 note describing inline auth-on-submit landing on both platforms simultaneously and retiring the undocumented `redirectAfterAuth`/`next`-param-ignored bug. Searched README §14/§16 for any prior entry describing this bug — none found, so no stale entry to remove or update; left §14/§16 untouched, matching S-119/S-120 precedent. Status: Specified → **Accepted**. |
