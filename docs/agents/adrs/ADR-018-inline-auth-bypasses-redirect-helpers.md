# ADR-018: Inline auth-on-submit stores tokens directly, bypassing `redirectAfterAuth`/`postLoginPath` navigation

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-29 |
| **Slice** | S-121 |

---

## Context

The QR review-collection flow (S-040 / S-118 / S-119) is the platform's highest-traffic
unauthenticated entry point. Today, its Submit handler calls `router.push('/login?next=...')`
(web, `frontend/src/app/collect/[businessId]/page.tsx`) or `context.push('/login?next=...')`
(mobile, `mobile/lib/features/reviews/collect_review_screen.dart`) whenever the customer is
unauthenticated at submit time — a full route change that discards the composed
rating/chips/body held only in that page/screen's in-memory state, and whose `next` param is
never actually honored on return (a confirmed, pre-existing bug). S-121 replaces this with an
inline login step rendered in place, followed by an automatic re-submit of the already-composed
review once auth succeeds.

Every existing sign-in completion path on both platforms funnels through a shared post-login
navigation helper:

- **Web:** `redirectAfterAuth()` (`frontend/src/lib/api.ts`) — called by `LoginForm.tsx` for the
  password/TOTP and Google paths, and called **internally, unconditionally** by
  `PhoneOtpPanel.tsx`'s own `verify()` for the phone-OTP path. `redirectAfterAuth` stores tokens,
  re-resolves the account's role via `auth.me()`, and hard-navigates
  (`window.location.href = destination`) to `roleLandingPath(role)`.
- **Mobile:** no auth widget navigates itself. `GoogleSignInButton`/`PhoneOtpPanel`/
  `AuthController`'s TOTP methods only flip `authControllerProvider`'s Riverpod state to a
  resolved user. Navigation is centralized in `mobile/lib/router.dart`'s `GoRouter.redirect`
  callback, which re-runs whenever that state changes (via `_AuthRefreshNotifier`) and computes a
  destination through `postLoginPath(role)`.

Using either mechanism unmodified from inside an inline login step would navigate the customer
away from `/collect/[businessId]` / `/collect/:slug` the instant auth succeeds — precisely the
state-losing behavior this slice exists to eliminate, and incompatible with the auto-submit
requirement (AC6).

---

## Decision

The inline auth step, on both platforms, completes authentication by calling the **same**
underlying functions every existing login surface already calls — `auth.login`, `auth.google`,
`auth.phoneVerify`, `auth.totpSetup`, `auth.totpConfirm`, `auth.totpVerify` (web); the same
`AuthController` methods (`submitCredentials`, `startTotpEnrollment`, `confirmTotpEnrollment`,
`verifyTotp`, `signInWithGoogle`, `signInWithPhone`) LoginScreen/PhoneOtpPanel already call
(mobile). On success, it does **not** call `redirectAfterAuth()` (web) and does **not** rely on
or trigger a `postLoginPath()`-driven route change (mobile):

- **Web:** a new `InlineAuthStep.tsx` stores tokens directly via the existing, unmodified
  `storeTokens()` export, then invokes an `onAuthenticated()` callback back into the collect page,
  which immediately re-invokes the existing `submit()` → `reviews.create()` path using the
  rating/chips/body already held in page state. `PhoneOtpPanel.tsx` gets one small, additive,
  backward-compatible change: an optional `onTokens?: (tokens: TokenResponse) => void` prop that,
  when supplied, is called **instead of** `redirectAfterAuth()`. Every existing caller that omits
  it (`LoginForm.tsx`, and any other current caller) keeps today's `redirectAfterAuth` behavior —
  including its `expectedRole`/`onRoleMismatch` note — byte-for-byte.
- **Mobile:** no auth-widget or router code changes are needed at all. `GoogleSignInButton`,
  `PhoneOtpPanel`, and `AuthController`'s TOTP methods already only mutate
  `authControllerProvider`'s state — they never navigate. `router.dart`'s `redirect` callback
  already exempts every `/collect/`-prefixed location from all of its logged-in redirect branches
  (`isPublicCollectRoute` is checked in the guest-gate branch; none of the `isLoggedIn` branches —
  the `/login`↔`/register` bounce, or the `/favorites`/`/merchant`/`/admin` role gates — match a
  `/collect/` location), so an auth-state flip while sitting on `/collect/:slug` is **already a
  no-navigation event today**, confirmed by inspection, not by adding new logic.
  `CollectReviewScreen` only needs to add `ref.listen(authControllerProvider, ...)` for the
  null→non-null transition and re-invoke its own `_submit()`.
- `redirectAfterAuth()`, `roleLandingPath()` (web) and `postLoginPath()`/`router.dart`'s redirect
  logic (mobile) are left **completely unmodified**. Every other caller — the standalone `/login`
  page, `/register`, forgot-password, etc. — keeps today's post-login hard-navigation behavior
  exactly as-is.

This directly satisfies S-121 AC12: the `next`-param-ignored bug in `redirectAfterAuth`/
`postLoginPath` is **obsoleted** for this one entry point (the collect flow never reaches
`/login` in the first place), not separately patched.

---

## Consequences

### Positive
- Zero regression risk to the standalone `/login` page or any other existing caller of
  `redirectAfterAuth`/`postLoginPath` — both are untouched.
- Mobile requires no changes to `router.dart`, `post_login_path.dart`, `login_screen.dart`,
  `phone_otp_panel.dart`, or `google_sign_in_button.dart` — the existing decoupled
  (provider-state vs. navigation) architecture already supports this use case.
- Clean separation of concerns: "how tokens get stored" (existing `auth.*`/`AuthController` calls
  + `storeTokens`) is fully decoupled from "where the app navigates afterward" — the inline case
  simply chooses "nowhere, then auto-submit" instead of "role landing page".

### Negative / tradeoffs
- Two slightly different auth-completion code paths now exist per platform conceptually
  (navigate-and-land vs. store-and-continue), though both call the identical underlying API/
  provider functions — only the last step (navigate vs. callback) differs.
- `PhoneOtpPanel.tsx` (web) picks up a second responsibility (optional non-navigating completion
  via `onTokens`) that must be kept in sync manually if its internal `auth.phoneVerify` call ever
  changes shape.
- Web's role-mismatch note (`onRoleMismatch`, today surfaced only through `redirectAfterAuth`'s
  `expectedRole` option) is not reproduced inline for the phone-OTP path. Accepted as a minor,
  scoped UX omission: it doesn't block auto-submit for any of the 3 roles (AC11), and the
  standalone `/login` phone-OTP path keeps the note unchanged.

### Follow-ups
- If a second inline-auth surface is ever needed elsewhere, consider promoting
  `InlineAuthStep.tsx`/`inline_auth_step.dart` beyond the collect page — explicitly out of scope
  for S-121 (see slice "Out of scope": no generic inline-auth pattern is being built here).

---

## Alternatives considered

1. **Reuse `redirectAfterAuth`/router redirect unmodified, accept the hard navigation away from
   `/collect/...` after auth succeeds.** Rejected — defeats the purpose of this slice: state loss
   and no auto-submit, directly contradicting AC2/AC3/AC6.
2. **Modify `redirectAfterAuth`/`postLoginPath` to finally honor a `next`/return param and
   redirect back to `/collect/...` post-login.** Rejected per the slice's explicit scope (AC12).
   This still round-trips through a full route change/page reload (losing in-memory composer
   state on web, since the collect page would fully remount) and is precisely the long-broken
   `next`-param code path this slice is designed to make moot, not resurrect and fix.
3. **Fork a `redirectAfterAuth`-equivalent helper with a `skipNavigation` flag.** Rejected as
   unnecessary complexity — `redirectAfterAuth` bundles an `auth.me()` role-resolution round trip
   and mismatch-note timing that the inline case doesn't need at all, since `POST /reviews`
   accepts all 3 roles identically (AC11) and no role-based landing decision is being made here.
   Calling the already-exported `storeTokens()` directly is simpler and has a smaller diff.
