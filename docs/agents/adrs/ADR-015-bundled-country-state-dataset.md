# ADR-015: Bundled country/state dataset via `country-state-city` (Country + State only)

| Field | Value |
|-------|-------|
| **Status** | Accepted |
| **Date** | 2026-08-19 |
| **Slice** | S-084 |

---

## Context

S-084 replaces free-text Country/State `<input>`s in `BusinessForm.tsx` with cascading
`<select>`s. Country must cover the full ISO-3166 country list; State must cover every
selected country's subdivisions, not just India's — the user explicitly rejected
hand-curating a handful of countries in favor of "a standard dataset." The data is a pure
frontend UI concern only: no AC implies backend validation of state values, and no other
part of the system (search filters, backend schema) needs to know the full state list —
`Business.state`/`Business.country` remain plain strings server-side (see Data model
impact in the slice's technical spec).

`frontend/package.json` has no existing country/state dependency. The only close
precedent in the codebase is `PhoneOtpPanel.tsx`'s two-entry hardcoded dial-code
`<select>` (`+91`/`+1`) — too small a pattern to extend to ~250 countries × their
subdivisions.

---

## Decision

1. Add **`country-state-city`** (npm, MIT-licensed, TypeScript types included, widely
   used and actively maintained) as a new `frontend/package.json` dependency. It ships
   `Country.getAllCountries()` and `State.getStatesOfCountry(countryIsoCode)`, each
   entry carrying at minimum `{ name, isoCode, countryCode }`. Its `isoCode` values are
   the familiar short subdivision codes (e.g. `"TN"` for Tamil Nadu, `"CA"` for
   California) — this already matches the two-letter country codes this codebase uses
   today (`"IN"`/`"US"` defaults in `BusinessForm.tsx` / `Business.country`) and the
   `state: "TN"` fixture already present in `BusinessForm.test.tsx`, so no data-shape
   surprise for existing conventions or test fixtures.

2. **Never import `City`** from the package — only `Country` and `State`. City-level
   data is unneeded (AC8: City stays free text) and is by far the largest part of the
   package's bundled JSON (city data is an order of magnitude larger than country+state
   combined).

3. Wrap the package behind a single local module, `frontend/src/lib/countryState.ts`,
   exposing only:
   - `getCountries(): { code: string; name: string }[]`
   - `getStatesForCountry(countryCode: string): { code: string; name: string }[]`

   `BusinessForm.tsx` imports only from this wrapper, never the package directly. This
   isolates the rest of the app from the package's API/data shape and gives a single
   swap point if the contingency in §4 is ever triggered.

4. **Bundle-size verification is a build step, not optional.** Because
   `BusinessForm.tsx` is a `"use client"` component reachable only from
   `/merchant/businesses/new` and the merchant business edit route, Next.js's
   per-route code splitting already keeps this dataset out of every *other* page's
   bundle regardless of outcome — so the blast radius is scoped to the two onboarding
   routes, not global. Still, the Builder must run `next build` and inspect the
   route-level First Load JS for those two routes before merging, because some
   npm data packages (unclear yet whether `country-state-city`'s current published
   build is one of them) ship all their JSON as one CommonJS module graph that gets
   pulled in regardless of which named export is actually used, in which case the
   unused `City` dataset would bloat those two routes' JS despite never being called.
   **Contingency:** if that's observed and the added weight is judged unacceptable,
   fall back to vendoring a trimmed static JSON file at
   `frontend/src/data/countries-states.json` (name + code pairs only, dropping every
   field this feature doesn't use — flags, phone codes, currencies, lat/lng,
   timezones), generated once via a short one-off script (not hand-typed) from the same
   `country-state-city` data (or its upstream source, the public
   "countries-states-cities-database" dataset), behind the identical
   `countryState.ts` function signatures above — so no `BusinessForm.tsx` change would
   be needed if this fallback is later triggered, now or in a future slice.

---

## Consequences

### Positive
- No backend changes — this is a frontend-only static reference dataset (confirmed: no
  AC implies server-side state validation).
- Comprehensive, standard coverage (all ISO-3166 countries + subdivisions), matching the
  user's explicit "bundle a standard dataset" direction over hand-curating a handful of
  countries.
- The wrapper module (`countryState.ts`) isolates the rest of the app from the specific
  package's API shape, keeping the documented fallback (§4) a same-signature swap, not a
  `BusinessForm.tsx` rewrite.
- `isoCode` subdivision codes already match this codebase's existing two-letter
  country-code convention and existing test fixtures (`state: "TN"`).

### Negative / tradeoffs
- New frontend runtime dependency to keep updated — low ongoing burden (reference data
  changes rarely: new countries/subdivisions are a rare real-world event).
- Bundle-size risk if the package doesn't cleanly separate `City` from `Country`/`State`
  in its published build — mitigated by the wrapper module, the Builder verification
  step, and the documented vendored-JSON fallback (§4); not fully eliminated until that
  verification actually runs.
- `state` becomes an ISO subdivision *code* (e.g. `"TN"`) rather than a free-text name
  going forward, once a business is resaved through the new dropdown. Legacy free-text
  `state` values that don't match any bundled code for their stored country degrade
  gracefully to an unselected/placeholder option (AC7) rather than erroring or silently
  discarding data — accepted, not a regression, since nothing auto-saves without the
  merchant's explicit re-submission.

### Follow-ups
- If a future slice needs server-side validation of Country/State combinations (e.g.
  rejecting invalid pairs at the API layer), revisit whether this reference data needs
  to be mirrored on the backend at that time — not needed now (out of scope per the
  slice).

---

## Alternatives considered

1. **Hand-authored JSON covering only a handful of countries** — rejected outright per
   explicit product direction: the user chose "bundle a standard dataset" specifically
   *over* hand-curating, and the slice's AC4 requires full-country coverage, not just
   India.
2. **A different, states-only npm package with no bundled city data at all** — plausible,
   but `country-state-city` is more widely used/maintained (larger download count, more
   GitHub activity, native TypeScript types) and its data format already lines up with
   this codebase's existing conventions (see Decision §1) — no compelling reason to
   prefer a less-established package for a strictly smaller feature surface.
3. **A new backend endpoint serving the country/state list** — rejected: this is
   explicitly a pure frontend UI concern per the task framing (no AC implies backend
   validation of state values); adding backend surface (a new `/api/v1/...` route) for
   static reference data with no server-side use would be unnecessary complexity and
   violate "routers thin, logic in services" for no behavioral gain.
