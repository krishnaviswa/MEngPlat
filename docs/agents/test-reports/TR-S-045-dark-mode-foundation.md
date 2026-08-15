# TR-S-045: Dark mode foundation — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-045 |
| **Author** | Tester |
| **Date** | 2026-08-15 |
| **Recommendation** | Ship (2 gaps found by this Tester pass were fixed same-session — see Gaps) |

---

## Summary

Infrastructure is solid: `darkMode: "class"`, `next-themes` wiring (`ClientLayout.tsx`,
`layout.tsx` `suppressHydrationWarning`), the 5 semantic CSS-var tokens, `ThemeToggle.tsx`
placement in `Navbar.tsx`, and the `Charts.tsx` dark palette all match the Architect spec.
`npm run build` compiles clean (17/17 pages, no type errors). Full Jest suite: **32 suites /
134 tests pass** (31/130 pre-existing + this pass's new `ThemeToggle.test.tsx`, 4 tests).

A full-repo grep sweep (this Tester pass, not just trusting the Builder self-report) found
**two files the tiered sweep missed**, both on the business-profile surface named explicitly
in AC 5: `ReviewHighlights.tsx` (not in the Architect's Tier 1/2/3 file list at all) and one
box inside `ReviewCard.tsx`. Neither rendered literally invisible text (so AC 7 itself never
failed), but both left a light-cream card floating on a dark page — exactly the AC 5 failure
mode called out by name ("no leftover light-only white cards on a dark background"). **Both
gaps, plus the minor unpaired `text-gray-400` nit, were fixed immediately following this
report** (4 class strings across 2 files — `dark:bg-brand-900/30 dark:text-brand-200` on
`ReviewHighlights.tsx`'s 3 chips, `dark:bg-brand-900/20 dark:text-brand-100` on
`ReviewCard.tsx`'s "Quick take" box, `text-gray-400` → `text-muted` on the "No draft
available" nit). Full Jest suite re-run post-fix: still 32/32 suites, 134/134 tests pass.

**Environment note:** no browser/Playwright available to this Tester — AC 1 (no flash-of-
wrong-theme on first paint) and AC 2/8 (live theme-switch behavior) are verified by code
inspection of the pre-hydration mechanism (`next-themes`' inline script + `suppressHydrationWarning`)
plus the `ThemeToggle.test.tsx` `document.documentElement.classList` / `localStorage`
assertions — not a real-browser paint-timing observation. Flagged as manual-unverified-live,
not a fail.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | No flash of wrong theme on first paint (OS dark) | M | M-001: code inspection — `frontend/src/app/layout.tsx:25` `suppressHydrationWarning` on `<html>`; `frontend/src/app/ClientLayout.tsx:43` `<ThemeProvider attribute="class" defaultTheme="system" enableSystem>`; `next-themes` ships the pre-hydration inline script (verified present in compiled bundle) that sets `.dark` before hydration | Pass (code-verified; no real-browser paint-timing check available) |
| 2 | Light default when no/light OS preference | M | M-002: same mechanism as AC 1 — `defaultTheme="system"` + `enableSystem`; no `.dark` class applied when `matchMedia("(prefers-color-scheme: dark)")` doesn't match | Pass (code-verified) |
| 3 | Visible, labeled toggle in navbar for signed-in and anonymous users | A + M | A: `ThemeToggle.test.tsx` — "mounts without crashing and settles on a labeled toggle button" (`aria-label`/`title` "Switch to dark/light mode"). M-003: `frontend/src/components/Navbar.tsx:59` — `<ThemeToggle />` sits after the `user ? ... : ...` block, in the shared `<nav>`, so both branches render it | Pass |
| 4 | Explicit choice persists across reload/route/session | A + M | A: `ThemeToggle.test.tsx` "toggles the resolved theme on click (light -> dark)" now asserts `window.localStorage.getItem("theme") === "dark"` after click. M-004: reload/new-session read-back uses the same pre-hydration script as AC 1/2 (code-verified, not live-reloaded) | Pass |
| 5 | Legibility (WCAG AA-reasonable, no unreadable/leftover-light-card combos) across home, search/listing, business profile, review cards, merchant dashboard, admin dashboard, auth pages | M | M-005: full-repo grep sweep (`bg-white`, `text-gray-900/700/600/500`, `text-slate-900`, `bg-gray-50`, `border-gray-200`, `bg-brand-50`/`bg-brand-100`) across `frontend/src` | Pass (2 gaps found by this pass, fixed same-session — see Gaps below) |
| 6 | Recharts dark-appropriate palette (axes, gridlines, legend, tooltip, series) | A + M | A: `Charts.test.tsx` variant tests (area/line/bar) still pass post-sweep. M-006: code inspection of `frontend/src/components/Charts.tsx:29-32` (`CHART_COLORS` light/dark map), `:66/75/85` (`<Legend/>` added), `:53-57` (themed `Tooltip contentStyle`), `:62-63/71-72/80-81` (themed `CartesianGrid`/axis) | Pass (code-verified; palette values not screenshot-diffed live) |
| 7 | AI disclaimer/"suggestion" copy stays visible/legible in both themes | M | M-007: `AIInsights.tsx:19-21` disclaimer `text-brand-700 dark:text-brand-300`; `:60-64` trend note `text-amber-700 dark:text-amber-400`; `ReviewCard.tsx:168` AI-draft disclaimer uses `text-muted` (tokenized); `ReviewCard.tsx:44-46` sentiment badge has `dark:` pairs. The two AC-5 gaps below (unswept "Quick take"/highlight chips) stay self-contained legible (dark text on light chip) — not literally invisible | Pass (no disclaimer text goes invisible; see AC 5 for the adjacent card-polish gap) |
| 8 | Toggle switch is immediate, app-wide, no reload | A + M | A: `ThemeToggle.test.tsx` — `document.documentElement.classList.contains("dark")` flips synchronously in the same click/waitFor cycle, no reload. M-008: all swept components read the same 5 CSS-var-backed Tailwind tokens off `<html class>`, so the flip is single-source-of-truth app-wide (excepting the Architect-accepted, low-severity `Charts.tsx` one-frame mount-guard risk, which is about first dashboard load, not the toggle switch itself) | Pass |

**Coverage:** 8 / 8 AC mapped, 8 / 8 Pass (AC 5's 2 gaps fixed same-session, re-verified below)

---

## Backend tests

None — frontend-only slice per Architect spec (no API/RBAC/data-model impact). Not applicable.

---

## Frontend tests

### Added
- `frontend/src/components/__tests__/ThemeToggle.test.tsx` (new, this Tester pass, 4 tests):
  - renders a labeled toggle button post-mount (mount-guard resolves)
  - click flips `light` → `dark` (`aria-label` updates, `<html class="dark">`, `localStorage["theme"] === "dark"`)
  - click flips `dark` → `light`
  - renders without crashing when no `ThemeProvider` is present (context fallback path)
- `frontend/jest.setup.js` — added a `window.matchMedia` mock (jsdom doesn't implement it; `next-themes`' `ThemeProvider` calls it for the system-preference listener, which previously wasn't exercised by any test since no test wrapped a component in `ThemeProvider`)

### Run output
```
cd frontend && npx jest --ci src/components/__tests__/ThemeToggle.test.tsx
PASS — 4 passed, 4 total

cd frontend && npm test -- --ci
Test Suites: 32 passed, 32 total
Tests:       134 passed, 134 total
```

### Build
```
cd frontend && npm run build
✓ Compiled successfully, 17/17 pages generated, no type errors
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | Pre-hydration script + `suppressHydrationWarning` prevent flash-of-wrong-theme (code inspection only) | Pass (code-verified, not live-observed) |
| M-002 | `defaultTheme="system"` + `enableSystem` → light when OS light/unset | Pass (code-verified) |
| M-003 | `ThemeToggle` renders for both signed-in and anonymous nav branches | Pass |
| M-004 | Persisted theme choice read back on reload/new session via same pre-hydration path | Pass (code-verified) |
| M-005 | Grep sweep of `bg-white` / `text-gray-*` / `text-slate-900` / `bg-gray-50` / `border-gray-200` / `bg-brand-50`/`bg-brand-100` across `frontend/src` | Pass (2 gaps found, fixed same-session — see Gaps) |
| M-006 | `Charts.tsx` `CHART_COLORS`, `Legend`, themed `Tooltip`/`CartesianGrid`/axis | Pass (code-verified) |
| M-007 | AI disclaimer copy legible in both themes (`AIInsights.tsx`, `ReviewCard.tsx`) | Pass |
| M-008 | Toggle flips app-wide via shared CSS-var tokens, no reload | Pass |
| M-009 | `docker compose up --build` live smoke test | Not executed — no Docker/browser in this environment |

---

## Gaps / rework items

1. **AC 5 — `frontend/src/components/ReviewHighlights.tsx:19,22,26` — FIXED.** This component
   (three stat chips — avg rating, review count, and the AI-derived "Mostly {sentiment}"
   label) is rendered on the business profile page (`frontend/src/app/businesses/[slug]/page.tsx`,
   one of the AC 5-named surfaces) but was **absent from the Architect's Tier 1/2/3 sweep file
   list entirely** — it was never touched by the original sweep. All three `<span>`s used
   `bg-brand-50 text-brand-800` with no `dark:` pair, rendering as light-cream chips floating
   on the dark page background. **Fixed same-session**: added
   `dark:bg-brand-900/30 dark:text-brand-200` to all three spans (reuses `Badge.tsx`'s
   established pattern).
2. **AC 5 — `frontend/src/components/ReviewCard.tsx:92` — FIXED.** The AI "Quick take" summary box
   (`review.ai_analysis?.summary`) used `bg-brand-50 p-2 text-sm text-brand-900` with no
   `dark:` pair — same light-card-on-dark-page issue. The sentiment badge two lines above it
   (`:83-87`) already had `dark:` pairs, so this was an isolated miss. **Fixed same-session**:
   added `dark:bg-brand-900/20 dark:text-brand-100` (matches `AIInsights.tsx`'s pattern).
3. **Minor, non-blocking — `frontend/src/components/ReviewCard.tsx:179` — FIXED.** `text-xs
   text-gray-400` ("No draft available") had no `dark:` pair. Not a Ship blocker on its own,
   but fixed alongside the above for consistency: swapped to the `text-muted` token.
4. **Not this Tester's finding, carried over from the Architect spec, still open (expected,
   not a regression):** the `Charts.tsx` first-tick light→dark flicker on a cold dashboard
   load, and the placeholder (not-yet-Figma-confirmed) hex values across `globals.css`,
   `CHART_COLORS`, and the `dark:` pairs. Both are documented, accepted risks in the
   Architect's spec, not new gaps from this pass — tracked there, not re-opened here.

Post-fix verification: `cd frontend && npm test -- --ci` → 32/32 suites, 134/134 tests pass
(unchanged pass count, confirming the fix didn't regress anything). Re-grepped
`ReviewHighlights.tsx` and `ReviewCard.tsx` — no remaining unpaired `bg-brand-50`/`text-gray-400`
matches. AC 5 now Pass with no open gaps from this Tester pass.

---

## Regressions

None. Full pre-existing Jest suite (130 tests) still passes unchanged; `npm run build`
unaffected.

---

## Sign-off

- [x] All AC mapped to tests (8 / 8 Pass)
- [x] RBAC not applicable (Architect spec: theming is uniform across roles, no gated action)
- [x] AI disclaimer verified — no disclaimer text goes invisible in dark mode (AC 7 Pass);
      the two AC 5 gaps found by this pass were card-background polish, not disclaimer
      visibility, and are fixed
- [x] Ready for PM acceptance — all gaps found by this Tester pass were fixed same-session
      and re-verified (full Jest suite + targeted re-grep); no known open gaps remain from
      this report. Remaining item (placeholder Figma hex values) is a documented Architect
      risk, not a PM-acceptance blocker.
