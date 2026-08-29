# Slice: S-122 — Navbar shell: touch targets, current-page state, mobile menu

| Field | Value |
|-------|-------|
| **Slice ID** | S-122 |
| **Phase** | 5 Polish |
| **Status** | Accepted |
| **Role(s)** | customer \| merchant \| admin |
| **Owner** | PM / 2026-08-29 |

---

## Priority

**Medium** (high for portfolio-quality / accessibility). The navbar and footer are global
chrome that render on every page for every role, so a defect here is a defect everywhere. A
visual/UX audit found three concrete, low-risk gaps in `Navbar.tsx` (and a spacing gap in
`Footer.tsx`): sub-minimum tap targets, no current-page indication, and no responsive
fallback for the authenticated navbar on phones. None require backend, data-model, or IA
changes — this is a contained polish + accessibility pass with disproportionate impact on
perceived quality and on our a11y story. It is not urgent (nothing is broken functionally),
which is why it is Medium rather than High.

---

## User story

**As a** customer, merchant, or admin using MerchantHub on a phone or desktop
**I want** to see which section I'm currently in and to reach every navbar action with a
comfortable tap — even when I'm signed in and the bar is busy
**So that** I always know where I am and never have to pinch, mis-tap, or fight a cramped
bar to navigate

---

## Acceptance criteria

1. **Given** any viewport and auth state, **when** the navbar renders, **then** every
   interactive navbar item — the "Search" link, the role links ("Dashboard" / "Admin"), the
   avatar/name link, and the "Login" link — presents a tap/click target of **at least
   44 × 44 CSS px**, achieved by increasing the hit area (padding / `min-height` / `min-width`,
   negative margin allowed to preserve visual rhythm), **not** by enlarging font size (visible
   label text stays at the current `text-sm` scale).
2. **Given** any viewport, **when** the footer renders, **then** every footer column link
   (Discover / For merchants / Account / Support lists and the `mailto:` link) presents a
   tap target of **at least 44 px tall** via padding on the link element, and adjacent link
   hit areas do not visually overlap. The footer's colour palette, typography, dark-only
   `bg-slate-950`, `border-slate-800`, and hover colours are **unchanged** — spacing / hit
   area only.
3. **Given** the "Sign Up" pill and the "Logout" button (already compliant), **when** this
   slice ships, **then** their size, style, and behaviour do not regress — they remain at or
   above the 44 px target.
4. **Given** a user is on a route that maps to a top-level navbar item, **when** the navbar
   renders, **then** that one item is shown in a **visually distinct active state** that uses
   **at least one non-colour cue** (e.g. an underline / indicator bar / heavier weight) in
   addition to colour, **and** that item's anchor carries `aria-current="page"`.
5. **Given** the navbar renders on any route, **when** the accessibility tree is inspected,
   **then** **at most one** navbar item has `aria-current="page"`; every non-active item has
   neither the active styling nor any `aria-current` attribute.
6. **Given** the current path is `/search` (including with query string, e.g.
   `/search?q=cafe&city=Pune`), **then** "Search" is the active item; **given** the path is
   `/merchant/dashboard`, **then** a signed-in merchant sees "Dashboard" active; **given** the
   path is `/admin` or any nested admin route (e.g. `/admin/users`), **then** a signed-in
   admin sees "Admin" active.
7. **Given** the current path is a business detail page (`/businesses/[slug]`), the home page
   (`/`), the profile page (`/profile`), or any other route that does not map to a navbar
   item, **when** the navbar renders, **then** **no** navbar item is shown active and none
   carries `aria-current` (the brand/logo link is explicitly not part of the active-state
   treatment). "Search" does **not** stay active on a business detail page.
8. **Given** either light or dark theme, **when** an item is active, **then** the active
   treatment is clearly perceivable against the `bg-surface-raised` navbar background in that
   theme (contrast and the non-colour cue both hold).
9. **Given** a viewport narrower than the `md` breakpoint (< 768 px), **when** the navbar
   renders, **then** the secondary items (Search, role link, account/profile link, Logout, or
   Login + Sign Up when signed out) are **collapsed behind a single toggle control**
   (hamburger/menu button); the inline row of those secondary items is not shown at this
   width. The brand/logo, the notification bell (when signed in), and the theme toggle remain
   directly reachable outside the collapsed menu.
10. **Given** the collapsed menu on a narrow viewport, **when** a keyboard or screen-reader
    user interacts with it, **then**: the toggle is a real `<button>` with an accessible name
    and `aria-expanded` reflecting state (and `aria-controls` pointing at the menu); activating
    it opens/closes the menu; pressing **Escape** while the menu is open closes it and returns
    focus to the toggle; clicking/tapping outside the open menu closes it; the menu's links
    are reachable by Tab only while it is open.
11. **Given** any viewport and any menu state, **when** the rendered DOM is queried, **then**
    it contains **at most one** link with accessible name "Login", **at most one** "Sign Up"
    link, and **at most one** avatar element (image or initials) for the signed-in user — the
    existing single-match queries in `Navbar.test.tsx`
    (`getByRole("link", { name: /login/i })`, `getByAltText("Ann Customer")`, etc.) still
    resolve to exactly one node. A collapsed-then-CSS-hidden duplicate set of links is not an
    acceptable implementation if it leaves two same-named nodes in the tree at once.
12. **Given** a viewport at or above the `md` breakpoint (>= 768 px), **when** the navbar
    renders, **then** the layout is **essentially unchanged** from today: same set, order,
    labels, and destinations of visible items; **no** hamburger/menu toggle is shown; the only
    differences are the additive active-state styling + `aria-current` on the active item and
    the enlarged hit areas from AC1.
13. **Given** this slice ships, **when** existing navbar/footer behaviours are exercised,
    **then** none regress: the brand/logo links to `/`; a merchant sees "Dashboard"
    (→ `/merchant/dashboard`) and a non-merchant does not; an admin sees "Admin" (→ `/admin`)
    and a non-admin does not; the `NotificationBell` renders when and only when signed in;
    the `ThemeToggle` always renders and keeps its hydration-safe mounted-placeholder idiom;
    the "Logout" control still invokes `onLogout`; a signed-out visitor can still reach
    "Login" and "Sign Up".
14. **Given** a signed-in merchant or admin loads any page, **when** the navbar first paints
    through hydration, **then** there is no hydration flash: the menu's SSR/first-paint state
    is "collapsed" (never briefly expanded then snapping shut), and no navbar item flickers
    between active and inactive.

---

## UX notes

**UX intent:** The navbar should feel calm and obviously navigable. On desktop it barely
changes — you just now get a quiet "you are here" marker on the active section and links that
are comfortably clickable. On a phone, a signed-in merchant or admin should get a tidy menu
button instead of a bar that overflows or crowds the notification bell and theme toggle. The
current-page cue must read for colour-blind users (not colour alone) and in dark mode. The
footer keeps its exact look; its links just stop being a 20 px sliver stacked 8 px apart.

- **Screens / routes:** web only — `frontend/src/components/Navbar.tsx` (rendered by
  `app/ClientLayout.tsx` on every route) and `frontend/src/components/Footer.tsx`. No new
  routes, no new nav destinations.
- **Figma (mobile file `rk4RnruVFTpKdIsgGJIt9w`) frame + states:** n/a — this is a web-chrome
  slice. Mobile already solves these jobs with native chrome (bottom `NavigationBar` selected
  state + native touch targets); a dedicated mobile port is out of scope (see below) and
  tracked as `future` in README §12.
- **Mobile placement (named hub slot / route):** n/a (web slice).
- **Components to reuse:** keep the existing leaf-component pattern — `NotificationBell`,
  `ThemeToggle`, `ui/Avatar` stay as-is. `FilterPanel.tsx`'s selected-pill styling is the
  closest existing "selected" visual precedent (not pathname-driven) and may inform the active
  treatment. No new UI dependency.
- **Empty / edge states:** signed-out narrow viewport → menu holds Login + Sign Up; signed-in
  narrow viewport → menu holds Search + (role link) + account link + Logout. Menu closed is
  the default at every load.
- **AI disclaimer required?** no — no AI-generated content in this slice.

---

## Out of scope

- Any navigation **IA redesign** — no reordering, renaming, grouping, or re-homing of nav
  items; the item set is exactly today's.
- Any **new nav destination** or route.
- **Search-in-navbar** — no search input / typeahead in the header (the existing "Search"
  link is unchanged in destination).
- Any change to the **footer's colour palette, typography, or dark styling** — spacing / hit
  area only.
- The **brand/logo** link's behaviour or styling, and giving it an active state on `/`.
- `NotificationBell`, `ThemeToggle`, and `ui/Avatar` internal behaviour — reused unchanged.
- **Mobile app** — Flutter chrome is native (`AppShell` / `NavigationBar`) and is a separate
  parity concern (README §12 M-10); no Flutter work in this slice.
- Adding `aria-current` or active-state logic to **`Footer` links**, `DashboardNav`, or any
  in-page nav — navbar top-level items only.
- New animation/transition libraries for the menu open/close.

---

## Dependencies

- S-085 (Accepted) — navbar `Avatar` + `/profile` link; must not regress (AC11, AC13).
- S-045 (Accepted) — dark-mode foundation + `ThemeToggle` hydration idiom; active state must
  hold in dark (AC8) and the toggle must not regress (AC13, AC14).
- S-087 (Accepted) — footer Support column; spacing change must not break its links (AC2).
- S-104 / S-116 (chrome/dark-contrast polish) — no hard dependency; keep visual language
  consistent.

---

## PM decisions (2026-08-29, before Builder)

Two Architect flags resolved by PM:
1. **NotificationBell position (AC12 deviation).** Approved: the bell moves to the trailing
   control cluster (immediately left of `ThemeToggle`) at ≥ md, so it stays reachable
   outside the collapsed menu without duplicating a polling component. Not the fallback
   (second `md:hidden` instance).
2. **Signed-out mobile menu (AC9 vs UX-note).** Approved AC9 as written: "Search" also
   collapses into the disclosure menu when signed out — consistent one-toggle behaviour
   below md.

## PM acceptance (2026-08-29)

**Decision: Accepted.** 0 defects; `next build` clean; full Jest **65 suites / 387 tests**
green (baseline 63 / 347). All 14 ACs mapped in `TR-S-122` with **0 FAIL**. ACs 5, 6, 7, 10,
11, 13 are fully Jest-verified. ACs 1, 2, 3, 4, 8, 9, 12, 14 have their DOM / ARIA /
class-token portion Jest-verified; the rendered-pixel / breakpoint-reflow / colour-contrast /
dark-mode / hydration-flash portion is un-automatable in jsdom (Architect **Risk #3** — by
design, it was never a Jest gate). That residual is covered by the Builder's recorded
`localhost:3140` browser smoke (slice Changelog): active state + `aria-current` on `/search`
in light **and** dark; no active item on `/`, `/businesses/[slug]`, `/profile`; 44 px hit
areas at desktop (Login widened 32 → 48 px); mobile (375 px) toggle 44 × 44,
open/close/Escape + focus-return/outside-click; collapsed-by-default, no hydration flash; no
hamburger at ≥ md; navbar height 53 px vs ~52 px before; underline moved brand-500 →
brand-600 (light) / brand-300 (dark) after a measured 2.77:1 contrast miss at brand-500.
This is behaviour-preserving polish shipping live on merge (no feature flag); light mode is
additive-only (active underline + ~1 px taller bar) and the worst credible regression is
cosmetic and reversible. The **M-122-1 … M-122-10 visual checklist is a recommended
post-merge user spot-check** (desktop + a < 768 px viewport, light + dark), **not a merge
blocker**.

**AC12 deviation — signed off.** `NotificationBell` moving from between "Dashboard" and the
avatar to the trailing control cluster (immediately left of `ThemeToggle`) at ≥ md is
confirmed. This was the PM's pre-approved decision (see "PM decisions" above — it avoids
duplicating the stateful polling component while keeping the bell reachable outside the
collapsed menu per AC9). No nav item is added, removed, renamed, or re-pointed; one
icon-button moved within the trailing controls. The sign-off stands.

## Definition of done (PM)

- [x] All AC numbered, testable, and verified in the Tester's report (`TR-S-122`) — 14/14
      mapped, 0 FAIL; ACs 5/6/7/10/11/13 fully Jest-verified, ACs 1/2/3/4/8/9/12/14 have Jest
      DOM/ARIA coverage + a rendered-pixel/contrast residual (Architect Risk #3) covered by
      the Builder's recorded `localhost:3140` smoke and the M-122 user spot-check
- [x] Code on a **feature branch** (`feat/s-122-navbar-shell`) + PR — never committed to `main`
- [x] Architect checklist below complete on this slice file; Status moved Draft → Specified by Architect
- [x] Every AC mapped to a test (Jest: `Navbar.test.tsx`, `Footer.test.tsx`,
      `app/__tests__/ClientLayout.test.tsx`, + new `ui/NavLink.test.tsx`,
      `NavbarMobileMenu.test.tsx`) with an ID in the test report — see `TR-S-122` AC matrix
- [x] `Navbar.test.tsx` + `ClientLayout.test.tsx` updated with the `next/navigation`
      (`usePathname`) mock — existing single-match assertions (AC11) still hold (7/7 green)
- [x] README §11 feature → test index row **"Theme / chrome / dark contrast"** updated
      (+ `ui/NavLink`, `NavbarMobileMenu`, TR-S-122)
- [x] README §12 Web ↔ mobile feature parity tracker: new row **M-92** added, mobile status
      **`future`**; §12 rollup updated (total 92, future 2)
- [x] README §8 Hooks table (+ `usePathname` → `ui/NavLink`) and component list
      (+ `NavbarMobileMenu`, `ui/NavLink`) updated. No new product `.md`/`.txt` checklist.
- [x] README §14 "Built and working" — S-122 "Accepted" row added (matching the S-085 style).
      README §13 slice backlog row added (`Accepted`). §16 "built vs next" deliberately **not**
      touched — navbar a11y / touch-target polish is not investor-visible capability
      (precedent: S-104 and S-116 chrome polish are also absent from §16).
- [ ] UX matches the notes above (PM visual check on desktop + a < 768 px viewport, light +
      dark) — Builder live-smoke evidence recorded (slice Changelog, `localhost:3140`); the
      full **M-122 checklist is recommended as a post-merge user spot-check**, not a merge
      blocker (behaviour-preserving polish; light mode additive-only)
- [x] PM sets `Status: Accepted` after the Tester's report shows all AC covered and passing

---

## Technical specification (Architect)

> Filled by the Architect (2026-08-29). Behaviour-preserving polish + a11y pass. No backend,
> no data model, no new route. Light mode is the regression baseline; desktop (>= md) is
> essentially unchanged.

### API contract

**n/a — web chrome only.** No REST endpoint is added, changed, or newly called. `Navbar` /
`Footer` render from props (`user`, `onLogout`) already supplied by `ClientLayout`;
`usePathname()` is a client-router read, not a network call; `NotificationBell`'s existing
poll is untouched. §7 API reference needs no change.

| Method | Path | Auth | Request | Response |
|--------|------|------|---------|----------|
| — | — (no server interaction) | — | — | — |

### RBAC matrix

No change to role gating. The active-state + `aria-current` treatment and the mobile menu
are available to every role and to anonymous visitors identically. Link visibility keeps the
same client-side `user?.role` conditional as today (presentational only — the real guard
stays server-side / `RequireAuth` on the destination routes).

| Action | anon | customer | merchant | admin |
|--------|------|----------|----------|-------|
| See brand, Search, ThemeToggle, mobile-menu toggle | yes | yes | yes | yes |
| See `NotificationBell` + profile/avatar link + Logout | no | yes | yes | yes |
| See Login + Sign Up | yes | no | no | no |
| See "Dashboard" link (→ `/merchant/dashboard`) | no | no | yes | no |
| See "Admin" link (→ `/admin`) | no | no | no | yes |
| Active-state / `aria-current` on the current section | yes | yes | yes | yes |

### Data model impact

- [x] None  [ ] Extend existing  [ ] New table(s)

**Details:** none. No table, column, enum, relationship, or migration. ERD unchanged.

### Cache / side effects

None. No DB write, no Redis, no `search:*` invalidation. No new `localStorage` / `window`
access (`ThemeToggle` keeps its existing theme persistence; `NotificationBell` keeps its
existing 30 s poll). No new effect that runs during SSR.

### Frontend

- **Route:** none added or changed. Global chrome rendered by `app/ClientLayout.tsx` on
  every route.
- **Rendering:** unchanged. `ClientLayout` stays `"use client"`; `Navbar` / `Footer`
  continue to be server-rendered to initial HTML and then hydrated inside it. The two new
  leaves are `"use client"`. No route switches SSR <-> CSR.

- **Client-boundary decision — Option B (leaf extraction).** `Navbar.tsx` stays **without** a
  `"use client"` directive — it remains a plain composition module, pulled into the client
  bundle by `ClientLayout` exactly as today. The two new client concerns move into small
  `"use client"` leaves, matching the established `NotificationBell` / `ThemeToggle` /
  `ui/Avatar` pattern and `frontend/CLAUDE.md` ("`"use client"` only for: forms, hooks,
  localStorage, charts, modals"):
  - `frontend/src/components/ui/NavLink.tsx` (NEW, `"use client"`) — the `usePathname`-aware active link.
  - `frontend/src/components/NavbarMobileMenu.tsx` (NEW, `"use client"`) — the `< md` disclosure.

  **Rationale:** almost all of `Navbar`'s JSX is static or `user`/`role` conditional, not
  interactive; only 3 links need `usePathname` and only one region needs `useState`. Keeping
  the shell non-client keeps the change additive, keeps `Navbar` reviewable as pure
  composition, lets the active-link rule be unit-tested in isolation
  (`ui/__tests__/NavLink.test.tsx`) without dragging in every auth branch, and avoids marking
  the whole shell client for no benefit (CLAUDE.md #5, minimal diff).

  **Consequence for tests:** any suite that renders `<Navbar>` now mounts `NavLink`, which
  calls `usePathname()`. In Next 15.1 `usePathname()` is `useContext(PathnameContext)` — it
  returns `null` (it does **not** throw) when no `AppRouterContext` is mounted; only
  `useRouter()` throws. `NavLink` **must** null-guard that value, so existing
  `Navbar.test.tsx` / `ClientLayout.test.tsx` assertions do not break. Both suites should
  still add an explicit `next/navigation` mock (see below) so active-state cases can pin a path.

- **Components (reuse first):**
  - **`Navbar.tsx` (edit)** — add hit-area classes (`inline-flex min-h-[44px] items-center`
    + horizontal padding with a compensating negative margin so the `gap-4` rhythm and the
    `text-sm` label scale are unchanged) to **every** interactive item, including the Logout
    `<button>` and the Sign Up pill (AC1, AC3); swap the 3 top-level `<a>` (Search, Dashboard,
    Admin) for `<NavLink>`; wrap the collapsible secondary group in `<NavbarMobileMenu>`.
    The container's `py-4` may drop to `py-2`/`py-3` so the taller targets don't grow the bar
    (AC12).
  - **`ui/NavLink.tsx` (new leaf)** — props `{ href: string; children: ReactNode;
    className?: string; match?: "exact" | "prefix" }` (`match` default `"exact"`).
    `const pathname = usePathname();`
    `const active = !!pathname && (pathname === href || (match === "prefix" && pathname.startsWith(href + "/")));`
    Active → `<a>` gets `aria-current="page"` **plus a two-cue treatment**: `font-semibold`
    `text-ink` (weight — non-colour) **and** an underline/indicator bar
    (`border-b-2 border-brand-500 dark:border-brand-300`, or an `after:` bar) that holds
    >= 3:1 against `bg-surface-raised` in **both** themes (AC4, AC8). Inactive → renders
    **neither** `aria-current` nor any active class (AC5). Search uses `match="exact"` (so
    `/businesses/[slug]`, `/`, `/profile` never light Search — AC7; `/search?q=...` still does
    because `usePathname()` drops the query — AC6). Dashboard / Admin use `match="prefix"` (so
    `/admin/users`, nested merchant routes light the parent — AC6). The three namespaces
    (`/search`, `/merchant/dashboard`, `/admin`) are disjoint, so at most one `NavLink` is
    ever active — no tie-break logic (AC5). The brand/logo link is a plain `<a>`, **not** a
    `NavLink` (AC7).
  - **`NavbarMobileMenu.tsx` (new leaf)** — props `{ children: ReactNode }`. Renders:
    (a) a real `<button type="button">` toggle, `md:hidden`, `min-h-[44px] min-w-[44px]`,
    accessible name "Menu" (swap to "Close menu" on open), `aria-expanded={open}`,
    `aria-controls="navbar-mobile-menu"`;
    (b) a wrapper `<div id="navbar-mobile-menu">` holding `{children}`, classed
    `clsx("md:flex md:items-center md:gap-4", open ? "<dropdown-panel classes>" : "hidden md:flex")`.
    So at **>= md** the wrapper is always an inline flex row (children in source order,
    hamburger hidden) — the current desktop layout (AC12); **below md** it is `display:none`
    until `open`, then a positioned dropdown panel. `open` defaults to **`false`** — SSR and
    first client paint agree, never expanded-then-collapsed (AC14). A `useEffect` (attached
    only while `open`) adds: **Escape** → close + return focus to the toggle; outside
    `mousedown` → close (mirror `NotificationBell`'s exact ref + listener idiom, lines 43–59).
    No animation library (out of scope); a Tailwind transition is optional and must not gate
    visibility. Relies on Tailwind emitting `md:flex` after `hidden` so it wins at >= md —
    Builder must not reorder or add `!hidden`. No `display:contents` (older-browser a11y quirk).
  - **`NotificationBell`, `ThemeToggle`, `ui/Avatar`** — reused unchanged (out of scope).
  - **`Footer.tsx` (edit)** — on every column `<a>` and the `mailto:` link:
    `inline-flex min-h-[44px] items-center` (hit area only). Keep `<ul class="space-y-2">`
    (8 px gap) → 44 px targets sit 8 px apart, **no overlap** (AC2). Palette, typography,
    `bg-slate-950`, `border-slate-800`, `hover:text-brand-300`, `text-sm` — **all untouched**.
    The bottom bar `<p>` elements (© / AI disclaimer) are not links → no change.
  - **`FilterPanel`'s** solid-fill selected pill is the nearest existing "selected" precedent
    but is deliberately **not** copied — a solid fill is too heavy for persistent chrome; the
    underline+weight cue is lighter and still colour-blind-safe.

- **Single-instance strategy (AC11).** The collapsible items are rendered **exactly once**,
  as `children` of the single `NavbarMobileMenu` wrapper. That one wrapper is *reflowed* by
  breakpoint (inline flex at >= md; `display:none` / dropdown below md) — never a second copy.
  So there is always exactly one "Login" link, one "Sign Up" link, one avatar node in the
  DOM, in every menu state; `getByRole("link", { name: /login/i })`,
  `getByAltText("Ann Customer")`, etc. keep resolving to one node. In jsdom no stylesheet
  loads, so the `hidden` class is inert and the children are always query-able regardless of
  `open` — fine **because there is only one set of them**. A test that needs "the panel
  specifically" scopes with `within(...)` on `#navbar-mobile-menu`, not CSS visibility
  (jsdom can't evaluate `@media`).
  - **Deliberate deviation from AC12 — needs PM sign-off at acceptance.** Because
    `NotificationBell` must stay reachable *outside* the collapsed menu (AC9) while Search /
    role / account / Logout all move *inside* it, and because we refuse to duplicate the
    stateful, polling `NotificationBell` into two subtrees, the bell shifts from its current
    slot (between "Dashboard" and the avatar) to the trailing control cluster, immediately
    left of `ThemeToggle`, at >= md. No nav item is added, removed, renamed, or re-pointed;
    one icon-button moves within the trailing controls. Fallback if PM rejects: a second
    `md:hidden` bell instance (order preserved, one extra mounted 30 s poll).

- **`next/navigation` test mock.** Per-file, matching the ~15 existing suites that already do
  this — **no** global mock in `jest.setup.js` (several suites need specific
  `useRouter`/`useSearchParams` shapes a global default would fight; `jest.setup.js` stays
  limited to the `matchMedia` shim). Add to `Navbar.test.tsx` and `ClientLayout.test.tsx`:

  ```ts
  jest.mock("next/navigation", () => ({ usePathname: jest.fn(() => "/") }));
  ```

  and let path-specific cases do `(usePathname as jest.Mock).mockReturnValue("/search")`.
  New `NavLink.test.tsx` / `NavbarMobileMenu.test.tsx` mock it the same way. No shared
  test-util helper is warranted for a two-line mock.

### Flow

```mermaid
sequenceDiagram
    participant U as User (viewport < md)
    participant B as Toggle button
    participant M as Menu panel (#navbar-mobile-menu)
    participant D as document

    Note over B,M: SSR + first paint: open=false, panel display:none, aria-expanded="false" (AC14)
    U->>B: click / Enter / Space
    B->>M: open=true -> panel shown, aria-expanded="true"
    B->>D: add keydown(Esc) + mousedown(outside) listeners
    alt Escape
        U->>D: keydown Escape
        D->>M: open=false
        M->>B: focus() returns to toggle
    else click outside
        U->>D: mousedown outside panel + toggle
        D->>M: open=false
    else pick a link
        U->>M: click NavLink / Login / Logout
        M-->>U: navigation (or onLogout); panel unmounts on route change
    end
    M->>D: remove listeners
```

### Architect checklist

- [x] API contract defined — **n/a (web chrome only)**, stated explicitly above; §7 unchanged.
- [x] RBAC impact stated — **none**; same items, same role gating; matrix above.
- [x] Data-model impact documented — **none**; ERD unchanged.
- [x] Cache invalidation considered — **n/a**; no writes, no `search:*`.
- [x] Component / client-boundary decision recorded — **Option B** (leaf extraction); `Navbar`
      stays non-`"use client"`; new `ui/NavLink` + `NavbarMobileMenu` leaves; menu `open`
      defaults `false` (hydration-safe).
- [x] ADR needed? — **No.** No new integration, schema-pattern, auth, or AI-provider change;
      `ClientLayout` is already a client boundary; `NavLink` is an additive leaf in the
      existing leaf pattern; fully reversible. Revisit only if the active-link rule later
      becomes a shared cross-surface hook (e.g. reused by `DashboardNav` / `AdminOpsNav` /
      breadcrumbs).
- [x] Test plan pointer — `docs/agents/test-plans/TP-S-122-navbar-shell.md`. Tester touches:
      `Navbar.test.tsx` (+ `next/navigation` mock; AC1/3/4/5/6/7/11/12/13/14),
      `Footer.test.tsx` (AC2 — `min-h-[44px]` per link, palette classes still present),
      `app/__tests__/ClientLayout.test.tsx` (+ `next/navigation` mock; existing avatar-sync
      still green), NEW `components/ui/__tests__/NavLink.test.tsx` (AC4/5/6/7/8 + null-pathname
      guard), NEW `components/__tests__/NavbarMobileMenu.test.tsx` (AC9/10/14). Queries stay
      `getByRole("link", { name })` / `getByAltText` / `getByRole("button", { name })`;
      scope panel assertions with `within(#navbar-mobile-menu)`.
- [x] ERD/API/FLOWS updates noted — none (§5/§6/§7 unchanged). Post-merge README:
      §11 index row **"Theme / chrome / dark contrast"** (+ `NavLink`, `NavbarMobileMenu`,
      the two new test files, `TR-S-122`); §12 new parity row (mobile status **`future`**);
      §8 component list (~line 1533) + Hooks table (~line 1465, add `usePathname`); §14
      (and §16 if surfaced).

### Risks / tradeoffs

1. **`Navbar.test.tsx` / `ClientLayout.test.tsx` do not mock `next/navigation` today.**
   `NavLink` pulls `usePathname()` into every `<Navbar>` render. It returns `null` (not a
   throw) with no router context in Next 15.1, so nothing breaks **iff** `NavLink`
   null-guards before `pathname.startsWith(...)`. Builder must land that guard. Both suites
   should still add the two-line mock so active-state cases can pin a path.
2. **Bell repositioning vs. AC12** (see Single-instance strategy). One intentional layout
   delta — bell moves next to `ThemeToggle` at >= md. Needs PM sign-off. Fallback: a second
   `md:hidden` bell (order preserved, extra poll).
3. **jsdom has no CSS**, so `hidden` / `md:*` classes are inert in Jest. "Collapsed on
   desktop / expanded on mobile", rendered 44 px size, no-hamburger-at->=md, active-underline
   contrast, and dark-mode perceivability are **CSS/viewport** properties Jest cannot assert —
   they are a PM visual check (desktop + a `< 768 px` viewport, light + dark) and/or an
   optional Playwright / `web-e2e` step. Jest covers DOM structure + ARIA + interaction
   (toggle, Esc, outside-click, focus return, single-instance, `aria-current` uniqueness).
   `TP-S-122` must state this split.
4. **Single-subtree relies on `md:flex` overriding `hidden`.** Correct with Tailwind's
   variant ordering, but Builder must not reorder the classes, add `!hidden`, or use
   `display:contents`.
5. **Touch targets grow the bar.** 44 px targets + container `py-4` makes the header taller
   than today; trim the container padding to keep total navbar height close so "essentially
   unchanged" (AC12) stays honest.
6. **`aria-current` uniqueness (AC5)** depends on `/search`, `/merchant/dashboard`, `/admin`
   staying disjoint namespaces. They are today; documented so it stays a conscious constraint
   if routes are ever nested.
7. **AC9 vs. UX-note wording for the signed-out menu.** AC9 collapses "Search ... or Login +
   Sign Up"; the UX note says the signed-out menu "holds Login + Sign Up". Spec follows
   **AC9**: Search also collapses into the menu when signed out (consistent one-toggle
   behaviour below md). Flag for PM — trivial to change if PM meant Search stays inline for
   anon.
8. **Footer `min-h-[44px]` on `inline-flex` anchors** slightly increases each row's box; with
   `space-y-2` retained the gap is 8 px and hit areas do not overlap (AC2). If PM finds the
   column too tall, reduce `space-y-2` -> `space-y-1` (still no overlap) — spacing only,
   palette untouched.

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-122-navbar-shell.md`
- Test report: `docs/agents/test-reports/TR-S-122-navbar-shell.md`
- ADR: none — Architect decided no ADR is warranted (additive leaf in the existing
  `"use client"` leaf pattern; no integration/schema/auth/AI change; reversible).

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-29 | PM | Created slice — navbar/footer touch targets, current-page `aria-current` + non-colour cue, responsive collapse of authed navbar into a keyboard-accessible menu below `md`. Status: Draft. |
| 2026-08-29 | Architect | Tech spec: no API / data-model / cache / RBAC change. Client-boundary = **leaf extraction** — new `ui/NavLink` + `NavbarMobileMenu` `"use client"` leaves; `Navbar.tsx` stays non-client. Single reflowed menu subtree (one `NavbarMobileMenu` wrapper, `md:flex` inline / `hidden` below md) for AC11 — no duplicated nodes. Per-file `next/navigation` mock in `Navbar` + `ClientLayout` suites (`usePathname` returns `null`, not a throw, in Next 15.1 — `NavLink` must null-guard). No ADR. Flagged for PM: `NotificationBell` shifts next to `ThemeToggle` at >= md (AC12 sign-off); AC9-vs-UX-note on the signed-out menu (spec follows AC9). Status: Draft -> Specified. |
| 2026-08-29 | PM | Resolved both Architect flags: bell → trailing cluster at ≥ md (approved); signed-out menu follows AC9 (Search collapses). |
| 2026-08-29 | Builder | Implemented: new `ui/NavLink.tsx` (null-guarded `usePathname`, `match` exact/prefix, `aria-current` + `font-semibold` + `after:` underline bar — brand-600 light / brand-300 dark), new `NavbarMobileMenu.tsx` (one reflowed subtree, `md:flex` / `hidden`, toggle `min-h/w-[44px]` + `aria-expanded`/`aria-controls`, Escape+focus-return, outside-click). `Navbar.tsx`: `py-1` container, `min-h-[44px]` hit areas on every interactive item (Login gets `px-2 -mx-2` for 44px width), 3 links → `<NavLink>`, secondary group wrapped in `<NavbarMobileMenu>`, bell moved next to `ThemeToggle`. `Footer.tsx`: `linkClass` = `inline-flex min-h-[44px] items-center hover:text-brand-300` on all 11 column links — palette/type untouched. `next/navigation` mock added to `Navbar.test.tsx` + `ClientLayout.test.tsx`. README §8/§11/§12 updated. Verified: `next build` clean, full `jest` 347/347 (63 suites), browser smoke on :3140 — active-state on `/search` (both themes), no active item on `/` `/businesses/[slug]`, 44px targets at desktop, mobile toggle open/close/Escape/outside-click, collapsed-by-default (no flash), navbar height 53px (~unchanged). New Jest files (`NavLink.test.tsx`, `NavbarMobileMenu.test.tsx`) + AC matrix → Tester. |
| 2026-08-29 | Tester | `TP-S-122` + `TR-S-122` written; AC matrix maps all 14 ACs. New `frontend/src/components/ui/__tests__/NavLink.test.tsx` (12 tests — AC4/5/6/7/8 DOM parts + null-pathname guard + `match` exact/prefix + segment-boundary + className passthrough) and `frontend/src/components/__tests__/NavbarMobileMenu.test.tsx` (11 tests — AC9/10/11/14 toggle/Escape/outside-click/focus-return/single-instance/hydration default). Added 14 cases to `Navbar.test.tsx` (AC1/3/5/6/7/11/12/13) — `NotificationBell` mock changed `() => null` → testid marker. Added 3 cases to `Footer.test.tsx` (AC2 hit area on all 11 links + palette preserved). Full `jest` **65 suites / 387 passed** (was 63/347; +2 suites, +40 tests); `next build` compiles + type/lint clean (pre-existing `/` dynamic-server-usage logs only). No defects; no impl files changed. AC5/6/7/10/11/13 fully Jest-covered; AC1/2/3/4/8/9/12/14 have Jest DOM/ARIA coverage + PM-visual rows deferred (rendered ≥44px px, no-hamburger-≥md, reflow, contrast, dark mode, bar height, hydration flash). Recommendation: ready for PM acceptance pending the visual checklist. |
| 2026-08-29 | PM | **Accepted.** 0 defects, 14/14 AC mapped (6 fully Jest-verified; 8 Jest DOM/ARIA + Builder `localhost:3140` live-smoke for the jsdom-blind visual half). AC12 bell-reposition deviation signed off. M-122-1 … M-122-10 visual checklist flagged as a post-merge user spot-check (desktop + < 768 px, light + dark), not a merge blocker. Slice `Status: Specified → Accepted`. README §14 "Built and working" + §13 backlog rows added; §16 deliberately skipped (a11y polish, not investor-visible — matches S-104 / S-116). |
