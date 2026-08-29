# TR-S-122: Navbar shell — touch targets, current-page state, mobile menu — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-122 |
| **Author** | Tester |
| **Date** | 2026-08-29 |
| **Recommendation** | **Ship** — ready for PM acceptance, pending the PM visual / Playwright checklist (M-122-1 … M-122-10). No defects, no rework. |

---

## Summary

**Pass.** All 14 ACs are mapped. The DOM-, ARIA- and interaction-testable behaviour is fully
covered by Jest and green. Per Architect **Risk #3** (jsdom has no CSS engine), the
rendered-pixel / breakpoint / colour-contrast / hydration-flash aspects of ACs 1, 2, 3, 4, 8,
9, 12, 14 are recorded as **PASS-pending-PM-visual** — they cannot be asserted in jsdom and
must be confirmed by PM on desktop + a < 768 px viewport in light and dark. The Builder's
browser smoke-check on `localhost:3140` (recorded in the slice Changelog) is supporting
evidence for those rows but is not a substitute for PM sign-off.

- Full `npx jest`: **65 suites / 387 tests passed** (baseline was 63 / 347 → **+2 suites,
  +40 tests**).
- `npx next build`: compiles successfully, type-check + lint clean (Builder's "clean" result
  reproduced; the only build-log noise is the pre-existing `/` route "Dynamic server usage"
  info lines from `SocialProofRail` fetching the production backend at build time — unrelated
  to this slice, present on `main`).
- No implementation file was modified by the Tester. `NavLink.tsx`, `NavbarMobileMenu.tsx`,
  `Navbar.tsx`, `Footer.tsx` are exactly as the Builder left them.

---

## AC coverage matrix

| AC# | Description | Type | Test (file :: name) / method | Result |
|-----|-------------|------|------------------------------|--------|
| 1 | Every interactive navbar item ≥ 44 × 44 CSS px via hit area; label stays `text-sm` | A (class token) + PM-visual (rendered px) | `Navbar.test.tsx :: applies the min-h-[44px] hit-area class to every interactive item (signed in)` / `... (signed out)`; `NavLink.test.tsx :: keeps the >=44px hit-area class whether active or not` — **plus** M-122-1 | **PASS-pending-PM-visual** |
| 2 | Every footer column link (incl. `mailto:`) ≥ 44 px tall via padding, no overlap; palette/type/dark bg unchanged | A + PM-visual (overlap, look) | `Footer.test.tsx :: gives every column link the >=44px hit-area class` (11 links), `... :: gives the mailto: link the >=44px hit-area class`, `... :: keeps the S-087 palette, typography and dark styling` — **plus** M-122-2 | **PASS-pending-PM-visual** |
| 3 | Sign Up pill + Logout button do not regress below 44 px; behaviour intact | A + PM-visual | `Navbar.test.tsx :: applies the min-h-[44px] hit-area class to Login and Sign Up (signed out)`, `... :: calls onLogout when the Logout button is clicked` — **plus** M-122-1 | **PASS-pending-PM-visual** |
| 4 | Active item: non-colour cue (weight + underline bar) **and** `aria-current="page"` | A (attr + class) + PM-visual (bar renders) | `NavLink.test.tsx :: marks aria-current=page and adds the weight cue when the path matches exactly`, `... :: renders an anchor with href and children, inactive on a non-matching path` — **plus** M-122-3 | **PASS-pending-PM-visual** |
| 5 | ≤ 1 item with `aria-current="page"`; non-active items carry neither styling nor attr | **A (full)** | `Navbar.test.tsx :: marks Dashboard active for a merchant on a nested dashboard route (only one aria-current)`, `... :: marks Admin active for an admin on /admin/users`; `NavLink.test.tsx :: does not light an exact-match link on a nested route`, `... :: renders an anchor ... inactive on a non-matching path` | **PASS** |
| 6 | `/search` (± query) → Search; merchant `/merchant/dashboard[/…]` → Dashboard; admin `/admin[/…]` → Admin | **A (full)** | `NavLink.test.tsx :: stays active when only a query string differed (usePathname drops it)`, `... :: lights a prefix link on a nested route (/admin/users -> /admin)`, `... :: lights a prefix link on the exact parent path (/admin)`; `Navbar.test.tsx :: marks Search active on /search`, `... :: marks Dashboard active for a merchant on a nested dashboard route`, `... :: marks Admin active for an admin on /admin/users` | **PASS** |
| 7 | Business detail / `/` / `/profile` / any non-nav route → no item active, no `aria-current`; brand never active; Search not sticky on a business page | **A (full)** | `Navbar.test.tsx :: marks no item active on a business detail page`, `... :: marks no item active on the home page`, `... :: marks no item active on /profile`; `NavLink.test.tsx :: does not light an exact link on an unrelated nested route`, `... :: prefix match respects the '/' segment boundary`, `... :: does not light an exact-match link on a nested route` | **PASS** |
| 8 | Active treatment perceivable on `bg-surface-raised` in **both** themes (contrast + non-colour cue) | A (DOM: weight + light + dark underline token) + PM-visual (≥ 3:1 contrast, dark perceivability — jsdom cannot compute colour) | `NavLink.test.tsx :: active treatment includes a non-colour cue and a dark-mode underline token` — **plus** M-122-3, M-122-4 | **PASS-pending-PM-visual** |
| 9 | Below `md` secondary items collapse behind one toggle; brand + bell + theme toggle stay outside it | A (single wrapper, single toggle wired to `#navbar-mobile-menu`, bell/ThemeToggle siblings) + PM-visual (actual hide/show at breakpoint) | `NavbarMobileMenu.test.tsx :: renders a button toggle wired to the panel with aria-controls / aria-expanded`; `Navbar.test.tsx :: renders exactly one mobile-menu toggle wired to #navbar-mobile-menu`, `... :: shows the NotificationBell only when signed in` — **plus** M-122-5, M-122-6 | **PASS-pending-PM-visual** |
| 10 | Toggle is a real `<button>` w/ accessible name + `aria-expanded` + `aria-controls`; activate opens/closes; Escape closes + returns focus; outside click closes; panel links Tab-reachable only while open | **A (full)** | `NavbarMobileMenu.test.tsx ::` `renders a button toggle wired to the panel …`, `opens on click …`, `toggles closed on a second click`, `closes on Escape and returns focus to the toggle`, `closes on an outside mousedown`, `keeps the menu open on an inside mousedown`, `ignores Escape while the menu is closed` (Tab-only-while-open is CSS `hidden`-driven — M-122-6) | **PASS** |
| 11 | ≤ 1 "Login", ≤ 1 "Sign Up", ≤ 1 avatar in the DOM at any menu state; existing single-match queries still resolve | **A (full)** | `Navbar.test.tsx :: signed-out: exactly one Login and one Sign Up link` + the 4 unchanged S-085/S-087 cases (`renders the user's avatar image …`, `renders an initials fallback …`, `renders no avatar for a signed-out visitor`, `does not attach an AI suggestion badge …`) still green; `NavbarMobileMenu.test.tsx :: renders each child link exactly once while collapsed`, `... :: never duplicates child links across open/close cycles` | **PASS** |
| 12 | At ≥ md: same set/order/labels/destinations, **no** hamburger, only additive active-state + hit areas; approved deviation — bell next to ThemeToggle | A (links + hrefs present, single toggle element, role-gating intact) + PM-visual (no hamburger ≥ md, bar height, bell placement) | `Navbar.test.tsx :: keeps role-gated link visibility`, `... :: keeps the brand link pointing at /`, `... :: renders exactly one mobile-menu toggle …` — **plus** M-122-5, M-122-7, M-122-9 | **PASS-pending-PM-visual** |
| 13 | No behaviour regressions: brand → `/`; role-gated links; bell iff signed in; ThemeToggle always renders + hydration idiom; Logout → `onLogout`; signed-out reaches Login + Sign Up | **A (full)** + existing `ThemeToggle.test.tsx` unchanged & green | `Navbar.test.tsx ::` `keeps role-gated link visibility`, `shows the NotificationBell only when signed in`, `calls onLogout when the Logout button is clicked`, `signed-out: exactly one Login and one Sign Up link`, `keeps the brand link pointing at /`; `ClientLayout.test.tsx :: updates the Navbar avatar when mh:user-updated fires` (still green with the `next/navigation` mock) | **PASS** |
| 14 | No hydration flash: first-paint state "collapsed" (`open=false`); no active↔inactive flicker | A (DOM: panel `hidden` + `aria-expanded="false"` on first render; `NavLink` derives active purely from `usePathname()`, no state/effect) + PM-visual (no visible flash on real hydration) | `NavbarMobileMenu.test.tsx :: defaults to collapsed on first render (hydration-safe)` — **plus** M-122-8 | **PASS-pending-PM-visual** |

**Coverage:** 14 / 14 AC mapped. **6 fully Jest-verified PASS** (AC 5, 6, 7, 10, 11, 13);
**8 PASS-pending-PM-visual** (AC 1, 2, 3, 4, 8, 9, 12, 14 — Jest covers the DOM/ARIA portion,
the rendered-layout / colour portion is on the PM visual checklist). **0 FAIL, 0 blocked.**

---

## Backend tests

### Added
None. No API / backend surface in this slice (Architect API-contract table is `n/a`).

### Run output
n/a — no backend change.

---

## Frontend tests

### Added

- `frontend/src/components/ui/__tests__/NavLink.test.tsx` — **new suite, 12 tests**
  - `renders an anchor with href and children, inactive on a non-matching path`
  - `marks aria-current=page and adds the weight cue when the path matches exactly`
  - `stays active when only a query string differed (usePathname drops it)`
  - `does not light an exact link on an unrelated nested route`
  - `lights a prefix link on a nested route (/admin/users -> /admin)`
  - `lights a prefix link on the exact parent path (/admin)`
  - `does not light an exact-match link on a nested route`
  - `prefix match respects the '/' segment boundary`
  - `renders inactive (no crash) when usePathname() returns null`
  - `active treatment includes a non-colour cue and a dark-mode underline token`
  - `merges a caller-supplied className`
  - `keeps the >=44px hit-area class whether active or not`

- `frontend/src/components/__tests__/NavbarMobileMenu.test.tsx` — **new suite, 11 tests**
  - `renders a button toggle wired to the panel with aria-controls / aria-expanded`
  - `defaults to collapsed on first render (hydration-safe)`
  - `renders each child link exactly once while collapsed`
  - `keeps the child links inside #navbar-mobile-menu`
  - `opens on click: aria-expanded=true, name -> 'Close menu', panel shown`
  - `toggles closed on a second click`
  - `closes on Escape and returns focus to the toggle`
  - `closes on an outside mousedown`
  - `keeps the menu open on an inside mousedown`
  - `ignores Escape while the menu is closed`
  - `never duplicates child links across open/close cycles`

- `frontend/src/components/__tests__/Navbar.test.tsx` — **+14 tests** in a new
  `Navbar — S-122 shell` describe block (see AC matrix). The existing `NotificationBell` mock
  was changed from `() => null` to `() => <div data-testid="notification-bell" />` so AC13's
  "bell iff signed in" is assertable — no poll timers are pulled in, the 5 pre-existing
  S-085/S-087 tests are unaffected and still green.

- `frontend/src/components/__tests__/Footer.test.tsx` — **+3 tests** (`Footer hit areas +
  palette (S-122)`): all 11 column links carry `inline-flex min-h-[44px] items-center`; the
  `mailto:` link too; palette (`bg-slate-950` / `border-slate-800` / `text-slate-300` /
  `hover:text-brand-300`) + `space-y-2` + `text-sm` all still present.

### Also verified (Builder-authored, unchanged by Tester)
- `frontend/src/components/__tests__/Navbar.test.tsx` + `frontend/src/app/__tests__/ClientLayout.test.tsx`
  now carry `jest.mock("next/navigation", () => ({ usePathname: jest.fn(() => "/") }))` —
  the 7 pre-existing assertions across both suites still pass (Architect Risk #1: `NavLink`
  null-guards `usePathname()`, confirmed by `NavLink.test.tsx :: renders inactive (no crash)
  when usePathname() returns null`).

### Run output

```
cd frontend

# Index row ("Theme / chrome / dark contrast") — new + touched web files
npx jest src/components/ui/__tests__/NavLink.test.tsx \
         src/components/__tests__/NavbarMobileMenu.test.tsx \
         src/components/__tests__/Navbar.test.tsx \
         src/components/__tests__/Footer.test.tsx \
         src/app/__tests__/ClientLayout.test.tsx
→ Test Suites: 5 passed, 5 total
→ Tests:       47 passed, 47 total

# Full pre-merge pack
npx jest
→ Test Suites: 65 passed, 65 total   (baseline 63 → +2)
→ Tests:       387 passed, 387 total  (baseline 347 → +40)
→ Snapshots:   0 total

npx next build
→ ✓ Compiled successfully in 11.0s
→ Linting and checking validity of types ... (pass)
→ ✓ Generating static pages (21/21)
→ (pre-existing "/" Dynamic server usage info lines only — not from this slice)
```

---

## Manual / integration

Deferred to PM — jsdom cannot assert any of these (Architect Risk #3). Full list in
`TP-S-122-navbar-shell.md` §"Manual checklist"; Builder's `localhost:3140` smoke-check
(slice Changelog) is supporting evidence.

| ID | Check | Result |
|----|-------|--------|
| M-122-1 | Rendered ≥ 44 × 44 px on every navbar item; label still `text-sm` (AC1/AC3) | PM to confirm |
| M-122-2 | Footer links rendered ≥ 44 px, no overlap, look unchanged (AC2) | PM to confirm |
| M-122-3 | Active underline + weight visible, ≥ 3:1 contrast — light theme (AC4/AC8) | PM to confirm |
| M-122-4 | Same in dark theme (AC8) | PM to confirm |
| M-122-5 | ≥ 768 px: inline row, no hamburger, bell left of ThemeToggle (AC9/AC12) | PM to confirm |
| M-122-6 | < 768 px: only hamburger; open/Escape/outside/pick-link all close; Tab reaches panel only while open (AC9/AC10) | PM to confirm |
| M-122-7 | Navbar height within a few px of pre-S-122 (~53 px) (AC12) | PM to confirm |
| M-122-8 | Signed-in phone-viewport hard reload — no expanded-menu flash, no active flicker (AC14) | PM to confirm |
| M-122-9 | PM sign-off on the approved AC12 deviation (bell → trailing cluster at ≥ md) | PM to confirm |
| M-122-10 | `docker compose up --build` smoke: navbar + footer render on `/`; `/docs` unchanged (no route added) | PM to confirm |

---

## Regressions

None found.

- All 5 pre-existing `Navbar.test.tsx` cases (S-085 avatar, S-085 no-avatar-for-anon,
  S-085 no-AI-badge, S-087 no-support-in-header) pass unchanged.
- `ClientLayout.test.tsx` avatar-sync (S-085 AC5) passes with the added `next/navigation` mock.
- `Footer.test.tsx` S-087 Support-column test passes unchanged.
- `ThemeToggle.test.tsx`, `NotificationBell.test.tsx` untouched, green in the full run.
- Full suite: 63 → 65 suites, 347 → 387 tests, 0 failures.

---

## Gaps / rework items

None blocking.

- **AC 1/2/3/9/12 rendered-pixel + reflow, AC 4/8 colour contrast, AC 14 hydration flash** —
  not machine-verifiable in jsdom (no CSS/layout/viewport). Covered at the DOM/ARIA/class
  level in Jest; the visual half is on the PM checklist (M-122-1 … M-122-10). This is the
  Architect-sanctioned split (Risk #3), not a coverage hole.
- **AC10 "panel links reachable by Tab only while open"** — the links are always in the DOM
  in jsdom (the `hidden` class is inert without a stylesheet); the actual `display:none`
  gating is CSS, verified by M-122-6. The Jest layer proves the single-instance + open/close
  state; it cannot prove focus order under real CSS.

---

## README / doc verification (Builder's edits — confirmed by Tester)

- **§8 Hooks table** — `| usePathname | Current path for active-nav state (S-122) | ui/NavLink |`
  row present. ✔
- **§8 Component list** — `NavbarMobileMenu.tsx` and `ui/NavLink.tsx` rows added; `Navbar.tsx`
  row updated with the S-122 note. ✔
- **§11 Feature → test index**, row **"Theme / chrome / dark contrast"** — Web column now
  `… ui/Select, ui/NavLink, NavbarMobileMenu`; Slice TRs column now ends `…, 116, 122`. ✔
  (The Web column lists component names, per that table's house format — it never lists test
  file paths; the two new component names map to the two new test files enumerated above.)
- **§12 Web ↔ mobile parity tracker** — row **M-92** added (Chrome; web `S-122`; mobile
  `future`). Rollup updated to `future 2 (FCM, M-92 …) · total 92` and the count identity
  holds (79 + 4 + 0 + 7 + 2 = 92). ✔
- **§14 / §16** — per the slice DoD, deferred to the PM-accept step (the "Accepted" row is
  added on acceptance, matching S-085 etc.). Not a Tester or Builder gap.

---

## What remains for PM

1. Walk M-122-1 … M-122-10 on desktop **and** a < 768 px viewport, in **light and dark**
   (this is the only outstanding verification for ACs 1, 2, 3, 4, 8, 9, 12, 14).
2. Sign off the approved AC12 deviation (M-122-9 — `NotificationBell` moved to the trailing
   control cluster at ≥ md).
3. On green visual pass: add the §14 (and §16 if investor-visible) "Accepted" row and set
   the slice **`Status: Accepted`**.

---

## Sign-off

- [x] All AC mapped to tests (14 / 14)
- [x] README §11 feature → test index updated for the new tests (Builder; Tester verified)
- [x] RBAC — n/a per Architect spec; presentational role-gating covered
      (`Navbar.test.tsx :: keeps role-gated link visibility`)
- [x] AI disclaimer — n/a (no AI content in this slice; slice UX notes confirm)
- [ ] Ready for PM acceptance — **yes, pending the M-122 visual checklist** (no rework needed)
