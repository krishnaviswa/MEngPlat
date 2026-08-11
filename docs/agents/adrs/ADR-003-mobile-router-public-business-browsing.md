# ADR-003: Mobile router — public business browsing carve-out

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-11 |
| **Slice** | S-023 (also depended on by S-024, S-025) |

---

## Context

`mobile/lib/router.dart`'s `redirect` callback today gates the *entire* app behind login:
`initialLocation: '/login'`, and any route other than `/login` force-redirects to `/login`
whenever `authControllerProvider` has no session. This matches the app's only two screens
today (`LoginScreen`, `BusinessListScreen`), both of which currently assume a session either
way.

S-023 (Mobile reviews) AC1 and AC13 require an **anonymous** user to reach the business list
and a business detail screen and read its reviews — mirroring the web frontend, where
`/businesses/[slug]` is a public SSR page and `GET /reviews/business/{id}` requires no auth
server-side. The backend contract already supports this; only the mobile router's blanket
auth guard stands in the way. S-024 (Favorites) and S-025 (Notifications) both build UI (a
toggle, an entry-point icon) that must behave differently for a logged-out vs. logged-in
viewer of the *same*, now-public business list/detail screens, so whichever slice lands first
has to make this call once, for all three to build on rather than re-deciding it per slice.

## Decision

1. Carve out `/businesses` and `/businesses/:slug` as **public routes** in the `redirect`
   callback: these two paths are never force-redirected to `/login` regardless of session
   state. Every other route (`/favorites`, `/notifications`, and anything future) keeps the
   existing "must be logged in" default.
2. Keep `initialLocation: '/login'` unchanged (minimal diff, preserves today's default
   experience for the common login/register path) and add a "Continue without signing in"
   text link on `LoginScreen` that pushes `/businesses` — so the now-public path is reachable
   through real navigation, not only a raw deep link a widget test could exercise but an
   actual user couldn't reach.
3. `BusinessListScreen`'s `AppBar` becomes auth-conditional: a logged-in session sees the
   existing logout icon plus any auth-gated entry points (S-024's favorites icon, S-025's
   notifications badge); a logged-out (guest-browsing) session sees a "Sign in" action
   instead, and those auth-gated icons are hidden outright (not shown-but-disabled) —
   consistent with how `/favorites` and `/notifications` already redirect a logged-out direct
   navigation attempt to `/login`.
4. Review submission (S-023 AC13), favoriting (S-024 AC9), and any other in-page
   authenticated action reachable from these now-public screens keep working the same way:
   tapping the action while logged out routes to `/login` instead of performing the action.

## Consequences

### Positive

- Business browsing/reviews reach mobile-web parity — an anonymous visitor can evaluate a
  business before creating an account, matching the product's existing web behavior instead
  of the mobile client being strictly more restrictive for no product reason.
- One router change serves three slices (S-023/S-024/S-025) instead of each inventing its own
  guard logic, or worse, silently disagreeing on where the public/private line is.
- Everything not explicitly carved out keeps the simple, already-working "must be logged in"
  default — the blast radius of this change is two route patterns, not a rewrite of
  `redirect`.

### Negative / tradeoffs

- `BusinessListScreen`'s `AppBar` now has two visibility states (guest vs. session) instead of
  one static bar — a small but real increase in that widget's branching, and every future
  entry point added to it needs to remember to gate itself the same way.
- A logged-out user can now fetch business/review data through the mobile client without a
  token — no new backend exposure (the same data is already public over HTTP via
  `/api/v1/businesses` and `/api/v1/reviews/business/{id}` regardless of which client calls
  it), but worth stating explicitly since it is a visible behavior change in the mobile app
  itself, which had no such surface before.

### Follow-ups

- If a future slice wants the app to *default* to guest browsing (i.e. change
  `initialLocation` to `/businesses`), that is a bigger nav-shell/first-run decision than this
  ADR covers and should get its own review — not implied by this decision.

---

## Alternatives considered

1. **Deep-link only** (carve out the redirect but add no "Continue without signing in" UI
   entry point). Rejected: AC13 would only be reachable via a route push no real user could
   trigger — technically satisfies the letter of the AC but not its intent.
2. **Change `initialLocation` to `/businesses`** so guest browsing is the default landing
   experience, with `/login` reached via an app-bar action. Rejected for now: a bigger UX
   change than any of the three PM briefs asked for, and would need PM sign-off on the
   product's first-run experience — deferred to Follow-ups rather than decided here.
3. **Duplicate a per-screen guard inside `BusinessListScreen`/`BusinessDetailScreen`** instead
   of changing the shared `redirect` callback. Not a real alternative: the top-level
   `redirect` callback runs before a screen ever mounts, so a per-screen guard can't undo it —
   the shared callback is the only place this decision can live.
