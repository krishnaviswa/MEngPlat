# ADR-005: Mobile primary shell — StatefulShellRoute + bottom NavigationBar

| Field | Value |
|-------|-------|
| **Status** | Accepted (amended S-103) |
| **Date** | 2026-08-13 |
| **Slice** | S-027; amendment S-103 |

---

## Context

S-023–S-025 hung Favorites, Notifications, and Logout as **app-bar icons on `BusinessListScreen` only**. README §12 P0 (M-10/M-11) calls for a primary shell; M-06 notes Logout is easy to miss; M-09 notes every role lands on `/businesses`.

ADR-003 already carved `/businesses` and `/businesses/:slug` out as public and kept `initialLocation: '/login'`. This ADR does not reopen that.

## Decision

1. Wrap primary destinations in `go_router` **`StatefulShellRoute.indexedStack`** with a Material 3 `NavigationBar` (`AppShell`). Each tab has its own navigator so Android Back and tab switches restore the exact previous page (S-103). **Guest (and non-customer) route trees omit Favorites / Notifications / Account branches** by rebuilding `GoRouter` when session/role changes — guests never mount those screens, so they cannot 401 (the original reason S-027 used a single `ShellRoute`).
2. Shell routes: `/businesses`, `/favorites`, `/notifications`, `/account`, `/merchant`, `/admin`, `/home`, `/support`. Visible tabs are a **role-filtered subset**; `onDestinationSelected` calls `goBranch` (re-tap pops that branch to its root). Guest **Sign in** is not a branch — it `go`s to `/login`.
3. Keep `/login` and `/businesses/:slug` **outside** the visible shell (full-screen). Login and detail use the **root** `navigatorKey` / `parentNavigatorKey` so they cover the `NavigationBar`.
4. After login / session restore on `/login`, redirect to `postLoginPath(role)`: customer → `/businesses`, merchant → `/merchant`, admin → `/admin`.
5. Remove Favorites, Notifications, and Logout **icon actions** from `BusinessListScreen`. Guest **Sign in** moves to a bottom-nav destination that `go`s to `/login`.
6. Merchant/admin Home screens shipped in later P4 slices (no longer placeholders).
7. ADR-003 public carve-out and `initialLocation: '/login'` stay unchanged. `/account`, `/merchant`, `/admin`, `/favorites`, `/notifications` stay auth-gated (plus role guards for favorites / merchant / admin).

## Consequences

### Positive

- Logout, Favorites, and Notifications are reachable from every shell tab.
- Role-aware landing matches tracker M-09.
- Tab stacks survive switches; Explore scroll/profile stack is preserved (S-103).
- Guests still do not mount Favorites/Notifications.

### Negative / tradeoffs

- `GoRouter` is recreated on login/logout (acceptable; session boundary).
- Business detail has no bottom nav (intentional).
- Guest Sign in leaves the shell because login is not a branch.

### Follow-ups

- Defaulting `initialLocation` to guest Explore remains an ADR-003 follow-up, not implied here.

---

## Alternatives considered

1. **Keep app-bar icons, add a fourth icon for Account.** Rejected: does not satisfy M-11 (bottom nav / primary shell) and still hides chrome on every screen except the list.
2. **Put business detail inside the shell.** Rejected: review form + tabs is cramped; current push-to-detail is the established pattern.
3. **Ship full merchant/admin dashboards in P0.** Rejected: README forbids starting P1+ / P4 `future` rows in this wave.
