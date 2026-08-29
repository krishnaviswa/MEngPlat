# TP-S-122: Navbar shell — touch targets, current-page state, mobile menu — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-122 |
| **Author** | Tester |
| **Date** | 2026-08-29 |

---

## Scope

Web chrome only. `Navbar.tsx`, `Footer.tsx`, new `ui/NavLink.tsx`, new `NavbarMobileMenu.tsx`.
No backend, no data model, no new route, no RBAC change (per Architect spec — API contract
table is `n/a`). Verification is split two ways, per Architect **Risk #3** (jsdom has no CSS
engine):

- **Jest / RTL** — DOM structure, ARIA attributes and their uniqueness, class presence
  (tokens, not computed style), and interaction (toggle click, Escape, outside `mousedown`,
  focus return, single-instance of links, `onLogout` wiring, role-gated visibility,
  hydration-safe `open=false` default, `next/navigation` mock behaviour, `NavLink`
  null-pathname guard, `match` exact-vs-prefix logic, Footer `linkClass` + palette classes).
- **PM visual / Playwright** — anything that needs a real layout/viewport/theme: rendered
  ≥ 44 × 44 px box size, "no hamburger at ≥ md", "collapsed on desktop / expanded on
  mobile", underline-bar colour contrast ≥ 3:1, dark-mode perceivability, navbar container
  height "essentially unchanged".

The Builder already ran a browser smoke-check on a dev server (`localhost:3140`) covering the
desktop/mobile reflow, active-state in light + dark, 44 px targets at desktop width, and the
toggle open/close/Escape/outside-click interactions (recorded in the slice Changelog). That
is **supporting evidence**; the PM-visual rows below still need PM sign-off on desktop + a
< 768 px viewport in both themes.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend API | — | None — no API surface in this slice |
| Frontend | Jest + RTL | `NavLink` active-state logic, `NavbarMobileMenu` disclosure a11y + interaction, `Navbar` wiring / role-gating / single-instance, `Footer` hit-area class + palette preservation |
| Visual / responsive | PM visual check + optional Playwright / `web-e2e` | 44 px rendered size, breakpoint reflow, contrast, dark mode, bar height |

No snapshot tests (repo convention). No `@testing-library/user-event` in the repo — use
`fireEvent` / `.click()` like the existing suites. `NotificationBell` and `ThemeToggle` are
mocked exactly as the existing `Navbar` / `ClientLayout` suites do (no poll timers pulled in).
`next/navigation` is mocked per-file (`usePathname: jest.fn(() => "/")`).

---

## AC → planned tests

| AC# | What it asserts | Method | Test ID / file |
|-----|-----------------|--------|----------------|
| 1 | Every interactive navbar item is a ≥ 44 × 44 px target via hit area, label stays `text-sm` | **Jest** (class token `min-h-[44px]` on every item; label scale unchanged) **+ PM-visual** (rendered px box) | `Navbar.test.tsx::applies the min-h-[44px] hit-area class to every interactive item (signed in)` / `...(signed out)`; `NavLink.test.tsx::keeps the >=44px hit-area class whether active or not`; PM-visual §"Rendered size" |
| 2 | Every footer column link ≥ 44 px tall via padding; no overlap; palette/typography/dark bg untouched | **Jest** (`linkClass` = `inline-flex min-h-[44px] items-center` on all 11 column links + `mailto:`; palette classes `bg-slate-950` / `border-slate-800` / `hover:text-brand-300` / `text-sm` still present) **+ PM-visual** (no visual overlap, look unchanged) | `Footer.test.tsx::every column link carries the >=44px hit-area class`, `...::keeps the S-087 palette / dark styling`; PM-visual §"Footer" |
| 3 | Sign Up pill + Logout button do not regress below 44 px | **Jest** (both carry `min-h-[44px]`, Logout still fires `onLogout`, Sign Up still `href="/register"`) **+ PM-visual** (rendered px) | `Navbar.test.tsx::applies the min-h-[44px] hit-area class ... (signed out)`, `...::calls onLogout when the Logout button is clicked` |
| 4 | Active item gets a non-colour cue (weight + underline bar) **and** `aria-current="page"` | **Jest** (`aria-current="page"` + `font-semibold` + `after:bg-brand-600` on match; neither when not) **+ PM-visual** (underline visibly renders) | `NavLink.test.tsx::marks aria-current=page and adds the weight cue when the path matches exactly`, `...::renders an anchor with href and children, inactive on a non-matching path` |
| 5 | At most one navbar item has `aria-current="page"`; non-active items have neither styling nor the attribute | **Jest** (`document.querySelectorAll('[aria-current="page"]').length` is 1 on a matching route, 0 otherwise; inactive `NavLink` renders no active class) | `Navbar.test.tsx::marks Dashboard active for a merchant on a nested dashboard route (only one aria-current)`, `...::marks Admin active for an admin on /admin/users`; `NavLink.test.tsx::does not light an exact-match link on a nested route` |
| 6 | `/search` (± query) → Search active; merchant on `/merchant/dashboard` → Dashboard active; admin on `/admin` or `/admin/users` → Admin active | **Jest** (`usePathname` mock pinned per case; exact match for Search incl. query dropped by `usePathname`; prefix match for Dashboard/Admin incl. nested) | `NavLink.test.tsx::stays active when only a query string differed`, `...::lights a prefix link on a nested route`, `...::lights a prefix link on the exact parent path`; `Navbar.test.tsx::marks Search active on /search`, `...::marks Dashboard active ...`, `...::marks Admin active ...` |
| 7 | Business detail / home / profile / any non-nav route → **no** item active, no `aria-current`; brand/logo never active; Search not sticky on a business page | **Jest** (`querySelectorAll('[aria-current]').length === 0` on `/`, `/profile`, `/businesses/[slug]`; prefix respects `/` segment boundary) | `Navbar.test.tsx::marks no item active on a business detail page`, `...::marks no item active on the home page`, `...::marks no item active on /profile`; `NavLink.test.tsx::does not light an exact link on an unrelated nested route`, `...::prefix match respects the '/' segment boundary` |
| 8 | Active treatment perceivable on `bg-surface-raised` in **both** themes (contrast + non-colour cue) | **Jest** (active className carries `font-semibold` **and** `after:bg-brand-600` **and** `dark:after:bg-brand-300` — both a non-colour cue and a themed underline token) **+ PM-visual** (≥ 3:1 contrast, dark-mode perceivability — jsdom cannot compute colour) | `NavLink.test.tsx::active treatment includes a non-colour cue and a dark-mode underline token`; PM-visual §"Active-state contrast" |
| 9 | Below `md` the secondary items collapse behind one toggle; brand + bell + theme toggle stay outside it | **Jest** (secondary links are `children` of the single `NavbarMobileMenu`; exactly one toggle wired to `#navbar-mobile-menu`; bell + ThemeToggle rendered as siblings outside the wrapper) **+ PM-visual** (row actually hidden < md, inline ≥ md) | `NavbarMobileMenu.test.tsx::renders a button toggle wired to the panel ...`; `Navbar.test.tsx::renders exactly one mobile-menu toggle wired to #navbar-mobile-menu`; PM-visual §"Breakpoint reflow" |
| 10 | Toggle is a real `<button>` with accessible name + `aria-expanded` + `aria-controls`; activate opens/closes; Escape closes + returns focus; outside click closes | **Jest** (all of it, via `fireEvent`) | `NavbarMobileMenu.test.tsx::renders a button toggle wired to the panel ...`, `...::opens on click ...`, `...::toggles closed on a second click`, `...::closes on Escape and returns focus to the toggle`, `...::closes on an outside mousedown`, `...::keeps the menu open on an inside mousedown`, `...::ignores Escape while the menu is closed` |
| 11 | ≤ 1 "Login", ≤ 1 "Sign Up", ≤ 1 avatar in the DOM at any menu state; existing single-match queries still resolve | **Jest** (`getAllByRole` length 1; one reflowed subtree, no duplicated `md:hidden` copy; stable across open/close cycles; existing `getByAltText("Ann Customer")` etc. untouched and green) | `Navbar.test.tsx::signed-out: exactly one Login and one Sign Up link` + the 4 unchanged S-085/S-087 cases; `NavbarMobileMenu.test.tsx::renders each child link exactly once while collapsed`, `...::never duplicates child links across open/close cycles` |
| 12 | At ≥ md the layout is essentially unchanged: same set/order/labels/destinations, **no** hamburger, only additive active-state + hit areas; (approved deviation: bell moves next to ThemeToggle) | **Jest** (same links + hrefs present; single toggle element only; role-gating intact) **+ PM-visual** (no hamburger visible ≥ md; bar height ~unchanged; bell placement) | `Navbar.test.tsx::keeps role-gated link visibility`, `...::keeps the brand link pointing at /`, `...::renders exactly one mobile-menu toggle ...`; PM-visual §"No hamburger at ≥ md" + §"Bar height" |
| 13 | No behaviour regressions: brand → `/`; merchant sees Dashboard, non-merchant doesn't; admin sees Admin, non-admin doesn't; bell iff signed in; ThemeToggle always renders w/ hydration idiom; Logout → `onLogout`; signed-out can reach Login + Sign Up | **Jest** (each clause) **+ existing** `ThemeToggle.test.tsx` (hydration idiom unchanged, not re-tested here) | `Navbar.test.tsx::keeps role-gated link visibility`, `...::shows the NotificationBell only when signed in`, `...::calls onLogout when the Logout button is clicked`, `...::signed-out: exactly one Login and one Sign Up link`, `...::keeps the brand link pointing at /` |
| 14 | No hydration flash: SSR / first paint state is "collapsed" (`open=false`), no item flickers active↔inactive | **Jest** (`open` defaults `false` — panel has `hidden` class + `aria-expanded="false"` on first render; `NavLink` derives active purely from `usePathname()`, no effect/state) **+ PM-visual** (no visible flash on real hydration) | `NavbarMobileMenu.test.tsx::defaults to collapsed on first render (hydration-safe)`; PM-visual §"Hydration" |

**Every AC (1–14) is mapped.** ACs 4, 8 are additionally PM-visual for the colour/contrast
portion; ACs 1, 2, 3, 9, 12, 14 are additionally PM-visual for the rendered-layout portion —
per Architect Risk #3. ACs 5, 6, 7, 10, 11, 13 are fully Jest-covered.

After tests land: update `README.md` §11 **"Theme / chrome / dark contrast"** row
(components `ui/NavLink`, `NavbarMobileMenu` + `TR-S-122` — Builder already did this; Tester
verifies). Default verification: run only the §11 row's web files, not the whole suite.

---

## RBAC test cases

No API / auth surface in this slice. Client-side link *visibility* gating is presentational
only (real guard stays server-side / `RequireAuth` on destination routes — unchanged). Covered
at the presentational level:

| Case | Role | Expected |
|------|------|----------|
| Signed out | anon | Login + Sign Up (one each); no Dashboard / Admin / avatar / bell |
| Customer | customer | avatar + Logout + bell; no Dashboard / Admin |
| Merchant | merchant | "Dashboard" → `/merchant/dashboard`; no "Admin" |
| Admin | admin | "Admin" → `/admin`; no "Dashboard" |

`Navbar.test.tsx::keeps role-gated link visibility` + `...::shows the NotificationBell only
when signed in` cover the matrix.

---

## Edge cases

- `usePathname()` returns `null` (no `AppRouterContext`, Next 15.1 — does not throw) →
  `NavLink` renders inactive, no crash (Architect Risk #1). — `NavLink.test.tsx`
- Query string only differs (`/search?q=cafe&city=Pune`) → `usePathname()` yields `/search`
  → Search still active. — `NavLink.test.tsx`
- String-prefix that is not a path-segment boundary (`/administrator` vs `href="/admin"`,
  `match="prefix"`) → not active. — `NavLink.test.tsx`
- `match="prefix"` on the exact parent path (`/admin` itself) → active. — `NavLink.test.tsx`
- Rapid open/close cycles of the mobile menu → child links never duplicate. — `NavbarMobileMenu.test.tsx`
- `mousedown` inside the open panel (on a link) → menu stays open. — `NavbarMobileMenu.test.tsx`
- Escape while menu already closed → no-op, no throw. — `NavbarMobileMenu.test.tsx`
- Caller-supplied `className` on `NavLink` → merged, base classes retained. — `NavLink.test.tsx`

---

## Manual checklist (PM visual / Playwright — jsdom cannot assert)

- [ ] **M-122-1 (AC1/AC3):** On desktop, every navbar item (Search, Dashboard/Admin, avatar
      link, Logout, Sign Up, Login, mobile-menu toggle) has a rendered hit box ≥ 44 × 44 CSS
      px (DevTools box model), and the visible label text is still `text-sm`.
- [ ] **M-122-2 (AC2):** Footer — every column link and the `mailto:` link has a rendered
      height ≥ 44 px; adjacent links do not visually overlap; the column looks the same as
      pre-S-122 (colour, weight, spacing feel, dark `bg-slate-950`).
- [ ] **M-122-3 (AC4/AC8):** On a route that maps to a nav item, the active item shows a
      visible underline bar **and** heavier weight; the bar has ≥ 3:1 contrast against
      `bg-surface-raised` in **light** theme.
- [ ] **M-122-4 (AC8):** Same as M-122-3 in **dark** theme — active treatment still clearly
      perceivable, underline uses the `dark:` brand token.
- [ ] **M-122-5 (AC9/AC12):** At ≥ 768 px the secondary items render as an inline row with
      **no** hamburger visible; the notification bell sits immediately left of the theme
      toggle.
- [ ] **M-122-6 (AC9/AC10):** At < 768 px the secondary items are hidden and only the
      hamburger shows; tapping it opens a dropdown panel; Escape / tap-outside / pick-a-link
      all close it; keyboard Tab only reaches the panel links while open.
- [ ] **M-122-7 (AC12/Risk #5):** Navbar container height is within a few px of pre-S-122
      (Builder measured ~53 px) — "essentially unchanged".
- [ ] **M-122-8 (AC14):** Hard reload as a signed-in merchant/admin on a phone viewport — no
      flash of an expanded menu, no active/inactive flicker on any nav item.
- [ ] **M-122-9 (AC12):** PM sign-off on the approved deviation — `NotificationBell` moved
      from between Dashboard and the avatar to the trailing control cluster (left of
      `ThemeToggle`) at ≥ md.
- [ ] **M-122-10:** `/docs` (Swagger) — unchanged (no route added); `docker compose up
      --build` smoke: navbar + footer render on `/` for anon.

---

## Environment

- `AI_PROVIDER=mock` (no AI in this slice)
- Jest run from `frontend/`: `npx jest src/components/ui/__tests__/NavLink.test.tsx
  src/components/__tests__/NavbarMobileMenu.test.tsx src/components/__tests__/Navbar.test.tsx
  src/components/__tests__/Footer.test.tsx src/app/__tests__/ClientLayout.test.tsx`
- Full `npx jest` + `npx next build` before merge
- No mobile / Flutter suite (web-only slice; §12 M-92 mobile status `future`)
