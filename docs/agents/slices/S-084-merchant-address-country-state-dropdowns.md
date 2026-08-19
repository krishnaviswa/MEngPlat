# Slice: S-084 — Remove address lookup; Country/State become cascading dropdowns

| Field | Value |
|-------|-------|
| **Slice ID** | S-084 |
| **Phase** | 2 Core (onboarding) |
| **Status** | Accepted |
| **Role(s)** | merchant |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As a** merchant entering or editing my business address
**I want** a plain address text field (no lookup/autocomplete network calls) and proper
Country / State dropdowns instead of free-text boxes
**So that** I can fill in my profile the way I actually want to — by typing my own address
text and picking my country/state from a correct, consistent list — without an
unreliable, sometimes irrelevant suggestion dropdown getting in the way, and without a
misleading claim that Nominatim is only queried on button click

---

## Background

Confirmed by reading `frontend/src/components/BusinessForm.tsx` (as extended by S-073):
the "Street address" field fires a debounced (300ms) live Nominatim autocomplete query
once 3+ characters are typed, showing a suggestion dropdown; a separate "Look up address"
button geocodes the full assembled address via Nominatim to set latitude/longitude; and
the helper text under that button reads "Geocoding uses OpenStreetMap Nominatim on button
click only (not while typing)" — which is false today, since the live-as-you-type
autocomplete is a second, separate call path to the same provider. The user reviewing
this screen found both the misleading copy and the suggestion dropdown itself unwanted:
the autocomplete query never filtered by country, so short/ambiguous input returned
irrelevant matches in the wrong countries/scripts.

After discussion, the decision is more fundamental than a copy fix: **remove
address-lookup/geocoding from this form entirely.** Direct quote from the user: "not lat
and long pair matters here its user entry to update profile. i dont want to look up
street address." This is a deliberate, partial reversal of S-073's UX (the live
autocomplete + click-to-geocode interaction it introduced). **S-073's other feature —
OTP re-verification required on the 2nd and later edit to a business's address/city/
state/postal/country, gated by the `address_edit_count` column — is unrelated and must
not be touched, weakened, or removed.**

In place of address lookup, Country becomes a real `<select>` and State becomes a real
`<select>` that cascades off the selected Country, populated from a bundled
country→state/subdivision reference dataset (the user explicitly chose "bundle a
standard dataset" over hand-curating a handful of countries — this must cover all
countries, not just India). City stays free text, unchanged in behavior other than no
longer being auto-filled by a suggestion pick (never the point of that field; not a
loss anyone asked to keep).

Confirmed by repo-wide search: `GET /maps/autocomplete` and `GET /maps/geocode`
(`backend/app/routers/maps.py`) have no other callers anywhere in the repo once
`BusinessForm.tsx` stops calling them — not elsewhere in the web frontend, and not in the
mobile Flutter app (mobile's generated `MapsApi` client only ever calls `GET
/maps/config`). Removing the address-lookup UI therefore makes `search_addresses()`
(`backend/app/services/geo.py`), the `AddressSuggestion` schema, and both routes dead
code — this slice removes them rather than leaving them behind. `POST /maps/nearby` and
`GET /maps/config` are untouched and still in active use (distance search / map tile
config).

Separately, S-073's own builder note flagged a pre-existing gap: `BusinessUpdate`
(backend schema) has no `country` field at all, so even before this slice, an edited
country could never actually persist via `PATCH /businesses/{id}`. This slice closes that
gap — the new Country dropdown's selection needs to actually save on edit, or the
dropdown is cosmetic.

---

## Acceptance criteria

1. **Given** a merchant is on the business create or edit form, **when** they type into
   the "Street address" field, **then** no network request fires as a result of typing —
   no suggestion dropdown appears, and the field behaves as an ordinary free-text input.
2. **Given** the business create or edit form, **when** it renders, **then** there is no
   "Look up address" button, no associated helper text about Nominatim/geocoding, and no
   address-suggestion dropdown UI anywhere on the form — all three are removed, not just
   hidden.
3. **Given** the business create or edit form, **when** it renders, **then** "Country"
   is a `<select>` dropdown (not a text input) populated from a bundled country reference
   list, defaulting to India ("IN") when no value is set — matching today's existing
   default for a new business.
4. **Given** the business create or edit form with a Country selected, **when** it
   renders (or the merchant changes the Country selection), **then** "State" is a
   `<select>` dropdown populated with only the states/provinces/subdivisions belonging to
   the currently selected Country, sourced from the bundled dataset.
5. **Given** a State was already selected, **when** the merchant changes the Country
   selection to a different country, **then** the State dropdown re-populates with that
   new country's states and the previous State selection is cleared (not left showing a
   state that belongs to the old, now-unselected country).
6. **Given** an existing business being edited whose stored `state` value matches one of
   the current Country's bundled state options, **when** the edit form loads, **then**
   that State option is pre-selected (no silent loss of previously-saved data on load).
7. **Given** an existing business being edited whose stored `state` value does **not**
   match any bundled option for its stored Country (e.g. legacy free-text data from
   before this slice), **when** the edit form loads, **then** the form does not crash or
   silently discard the field — at minimum the State dropdown shows an unselected/
   placeholder state without blocking the merchant from picking a valid option and
   saving.
8. **Given** the business create or edit form, **when** it renders, **then** "City"
   remains a free-text input, unchanged in every other respect (still editable, still
   required per existing validation) — the only behavior it loses is the old
   suggestion-triggered auto-fill, which no longer exists per AC1/AC2.
9. **Given** the business create or edit form, **when** it renders, **then** the
   Latitude and Longitude manual number inputs are present and behave exactly as before
   this slice (optional, manually editable, no geocode button feeding them) — this slice
   does not add, remove, or alter them.
10. **Given** a merchant edits an existing business and changes only its Country (e.g.
    from "IN" to "US") via the new dropdown, **when** they submit and the save succeeds,
    **then** reloading the business (or its detail view) shows the newly selected
    country persisted — closing the pre-existing gap where `BusinessUpdate` silently
    dropped `country` from `PATCH` payloads.
11. **Given** a merchant business whose `address_edit_count` is already 1 (i.e., one
    prior address-area edit has occurred), **when** they change Country, State, City,
    Address text, and/or postal code and submit, **then** the same OTP/re-verification
    step introduced by S-073 is still required before the change saves — unchanged,
    unweakened, unbypassed by this slice's dropdown/removal changes.
12. **Given** a merchant business whose `address_edit_count` is 0 (first address-area
    edit, or a brand-new business being created), **when** they set/change Country,
    State, City, or Address text and submit, **then** no OTP step is required — matching
    S-073's existing first-edit-free behavior, unchanged by this slice.
13. **Given** the backend API surface after this slice ships, **when** a client requests
    `GET /api/v1/maps/autocomplete` or `GET /api/v1/maps/geocode`, **then** both return
    `404 Not Found` (routes removed) — and no remaining code in the repo (web frontend,
    mobile app, or backend) references either endpoint, `search_addresses()`, or the
    `AddressSuggestion` schema.
14. **Given** the backend API surface after this slice ships, **when** a client requests
    `POST /api/v1/maps/nearby` or `GET /api/v1/maps/config`, **then** both behave exactly
    as before this slice — unchanged, unaffected by the removal in AC13.

---

## UX notes

- **Screens / routes:** `/merchant/businesses/new` (create), merchant business edit
  screen (existing edit route for `BusinessForm.tsx`'s `mode === "edit"`) — same screens
  S-073 touched.
- **Components to reuse:** `BusinessForm.tsx` — remove the autocomplete-dropdown and
  "Look up address" button/helper-text UI added by S-073; convert the existing Country
  and State `<input>` fields to `<select>` elements sourced from a bundled dataset.
  Reuse the existing form field visual pattern (label + control) already used elsewhere
  on this form — no new component, no new screen.
- **Empty states / errors:** if a bundled Country has no state/subdivision entries in the
  dataset (some small countries genuinely have none), the State dropdown should degrade
  gracefully (e.g. a single disabled "N/A" / "Not applicable" option, or the dropdown
  simply empty and non-blocking) rather than erroring — exact handling is a Builder/
  Architect implementation call, not prescribed further here; the product requirement is
  only that it must not block form submission.
- **AI disclaimer required?** no — this slice has no AI-generated content.
- **Continuing mobile parity gap (not fixed by this slice):** confirmed by reading
  `mobile/lib/features/merchant/business_editor_screen.dart` — the mobile business editor
  already has plain free-text Address/City/State/Country fields with no dropdowns and no
  address lookup of any kind (so mobile never had the S-073 autocomplete/geocode UX this
  slice removes from web, and does not gain the new Country/State dropdowns this slice
  adds to web either). This is a pre-existing, continuing web↔mobile parity gap; record
  it in `README.md` §12 as `partial`/`unimplemented` per the existing tracker convention
  when this slice ships — closing it on mobile is explicitly out of scope here (see
  below) and would be its own future slice.

---

## Out of scope

- Any replacement way of setting latitude/longitude (e.g. a map picker, pin-drop UI, or
  reintroducing geocoding under a different trigger). The user explicitly accepted that,
  without geocoding, most newly-created or newly-edited listings will end up with no
  coordinates — which affects the existing `POST /maps/nearby` distance-search/map
  feature's coverage. That tradeoff is accepted, not something this slice needs to solve.
- Fixing or improving `POST /maps/nearby`'s behavior/coverage for businesses that lack
  coordinates — unchanged by this slice (AC14).
- City dropdowns or a city reference dataset — City stays free text (AC8); only Country
  and State become dropdowns.
- Mobile parity — `mobile/lib/features/merchant/business_editor_screen.dart` keeps its
  existing plain free-text address/city/state/country fields; this is recorded as a
  continuing, pre-existing parity gap in UX notes above, not fixed here.
- Any change to the S-073 OTP re-verification mechanism itself (its trigger condition,
  its delivery channel, its `address_edit_count` semantics) beyond confirming it still
  fires correctly for the fields this slice touches (AC11/AC12).
- Any change to which fields count as "address-bearing" for the purposes of S-073's
  re-verification trigger (address, city, state, postal_code, country) — this slice adds
  `country` to what can actually *persist* via `PATCH` (AC10) but does not change the
  existing set of fields S-073 already treats as re-verification-triggering.

---

## Dependencies

- **S-073 (address autocomplete + re-verification on edit)** — Accepted. This slice
  reverses S-073's autocomplete/geocode-button UX (per the user's explicit direction) but
  depends on, and must not disturb, S-073's OTP re-verification-on-2nd-edit mechanism and
  its `address_edit_count` column/logic.
- Existing maps/geo service (`backend/app/routers/maps.py`,
  `backend/app/services/geo.py`) — this slice removes the `autocomplete`/`geocode` parts
  of it (AC13) while leaving `nearby`/`config` untouched (AC14).

---

## Definition of done (PM)

- [x] All AC verified in test report
- [x] UX matches notes above
- [x] `README.md` §7 API reference updated to remove `GET /maps/autocomplete` and
      `GET /maps/geocode`, and §5 domain model / §8 frontend guide updated if the
      Country/State dropdown pattern is new enough to warrant a note
- [x] `README.md` §12 Web ↔ mobile feature parity tracker has a row reflecting the new
      Country/State dropdown behavior on web vs. mobile's continuing plain free-text gap
- [x] `README.md` §14 Known gaps updated (closing the `BusinessUpdate.country`
      persistence gap noted by S-073's builder note; the "no coordinates without
      geocoding" tradeoff may be added as a new known gap/limitation)
- [x] PM Status set to **Accepted**

---

## Technical specification (Architect)

See **ADR-015** (`docs/agents/adrs/ADR-015-bundled-country-state-dataset.md`) for the
bundled country/state dataset decision (`country-state-city` npm package, Country+State
only, wrapped behind `frontend/src/lib/countryState.ts`, with a documented vendored-JSON
fallback if the Builder's bundle-size check fails).

### API contract

| Method | Path | Auth | Request | Response |
|--------|------|------|---------|----------|
| `GET` | `/api/v1/maps/autocomplete` | — | — | **REMOVED (AC13).** Route deleted from `backend/app/routers/maps.py`; returns `404` after this slice. `search_addresses()` (`backend/app/services/geo.py`) and the `AddressSuggestion` schema (`backend/app/schemas/__init__.py`) are deleted alongside it — no other callers repo-wide (confirmed: web frontend's only caller was `BusinessForm.tsx`, mobile's generated `MapsApi` never called it). |
| `GET` | `/api/v1/maps/geocode` | — | — | **REMOVED (AC13).** Route deleted from `backend/app/routers/maps.py`; returns `404` after this slice. `GeocodeResponse` schema is deleted — its only referencer was this route. |
| `PATCH` | `/api/v1/businesses/{business_id}` (existing, extended) | merchant (owner) / admin — **unchanged auth, unchanged path** | `BusinessUpdate` **gains** `country: str \| None = None`, following the exact existing pattern of `address`/`city`/`state`/`postal_code` on that same schema (all optional, `None` = "not being changed") | Unchanged `BusinessResponse` (`country` already present there). Unchanged `400`/`401` OTP-gating contract from S-073 — now also reachable via a **country-only** change on a merchant's 2nd+ address edit (AC11), since `country` was already listed in `_ADDRESS_FIELDS` (a forward-compatibility placeholder per S-073's builder note) but could never actually appear in a payload until this field exists on the schema. Closes AC10. |
| `POST` | `/api/v1/businesses` (existing) | merchant — **unchanged** | Unchanged — `BusinessCreate` already declares `country: str = "US"`; no gap existed here (only `BusinessUpdate` was missing the field). | Unchanged |
| `POST` | `/api/v1/maps/nearby` | none (public) — **unchanged (AC14)** | Unchanged | Unchanged |
| `GET` | `/api/v1/maps/config` | none (public) — **unchanged (AC14)** | Unchanged | Unchanged |
| `POST` | `/api/v1/businesses/{business_id}/address-verify/request` (S-073, existing) | merchant (owner) — **unchanged, not touched by this slice** | Unchanged | Unchanged |

No new routes, no route-signature changes on anything kept — this slice is purely
subtractive on the maps router and additive-by-one-field on `BusinessUpdate`.

### RBAC matrix

| Action | customer | merchant | admin |
|--------|----------|----------|-------|
| `GET /maps/autocomplete`, `GET /maps/geocode` | 404 for everyone — routes removed | 404 for everyone | 404 for everyone |
| `POST /maps/nearby` | yes (public) — unchanged | yes — unchanged | yes — unchanged |
| `GET /maps/config` | yes (public) — unchanged | yes — unchanged | yes — unchanged |
| `PATCH /businesses/{id}` with a Country (and/or other address-field) change, 1st edit | 403 (not owner) | yes, owner only, no OTP required — unchanged from today | yes, no OTP required — unchanged from today |
| `PATCH /businesses/{id}` with a Country (and/or other address-field) change, 2nd+ edit | 403 (not owner) | yes, owner only, **OTP required** — unchanged mechanism, now also triggered by country-only changes (AC11) | yes, OTP **not** required — unchanged admin-bypass from S-073/ADR-014 |

No RBAC change versus today — every row above matches S-073's existing matrix; the only
difference is that `country` now actually participates in the change-detection that was
already wired to look for it.

### Data model impact

- [x] None  [ ] Extend existing  [ ] New table(s)

**Details:** Schema-only, no migration. `Business.country` (`backend/app/models/__init__.py`
line 167: `Mapped[str]`, `String(100)`, `default="US"`, `nullable=False`) and
`Business.state` (line 165: `Mapped[str | None]`, `String(100)`, nullable) already exist
on the table — confirmed by reading the model. The only backend change is Pydantic-level:
add `country: str | None = None` to `BusinessUpdate`
(`backend/app/schemas/__init__.py`, in the existing field block alongside `address`/
`city`/`state`/`postal_code`, matching `BusinessCreate`'s field order which places
`country` between `postal_code` and `latitude`). `BusinessResponse` already has `country`;
no change needed there. `_ADDRESS_FIELDS = ("address", "city", "state", "postal_code",
"country")` in `backend/app/routers/businesses.py` **already includes `"country"`** (added
forward-looking in S-073) — confirmed by reading `update_business`: its change-detection
(`payload_fields = payload.model_dump(exclude_unset=True, ...)` then `any(field in
payload_fields ... for field in _ADDRESS_FIELDS)`) and its persistence
(`for field, value in payload_fields.items(): setattr(business, field, value)`) both
iterate generically over whatever keys `BusinessUpdate` actually has set. **No router
logic changes are needed beyond the one-field schema addition** — adding `country` to
`BusinessUpdate` is sufficient by itself to (a) make country changes persist (AC10) and
(b) make country changes participate in the existing OTP-gating exactly like the other
address fields (AC11/AC12), because the detection/persistence loops were already written
generically enough to pick it up. This is the entire backend fix for the pre-existing gap.

Frontend `country` state remains a plain string on `Business`/`BusinessCreateInput`/
`BusinessUpdateInput` (`frontend/src/lib/api.ts`) — both TS input interfaces already
declare `country?: string`, confirmed by reading `api.ts`; no frontend type change is
needed there, only the new `<select>` UI and the bundled dataset (see Frontend below).

### Cache / side effects

No change. `await cache_delete_pattern("search:*")` already fires unconditionally on
every successful `update_business` call (existing code, line ~343), including
country-changing updates now that they persist — the invalidation only needs to know the
update *succeeded*, not why. `country` is not a search/filter parameter today (confirmed:
not referenced in `backend/app/routers/search.py`'s filter logic, only ever returned in
response payloads) so no new/narrower cache key is needed beyond the existing wildcard.

### Frontend

- **Route:** `/merchant/businesses/new` (create), merchant business edit route (existing
  route for `BusinessForm.tsx`'s `mode === "edit"`) — same screens S-073 touched, no new
  routes.
- **Rendering:** CSR (`BusinessForm.tsx`, existing `"use client"`).
- **Components / files:**
  - **`frontend/src/components/BusinessForm.tsx`** (major edit, reuse the existing
    form-field visual pattern, no new component/screen):
    - Remove: the live-suggestion `useEffect` (debounced Nominatim query on
      `form.address`), `selectSuggestion`, `handleGeocode`, the `geocodeLoading` /
      `geocodeMessage` / `suggestions` state, the `skipNextAutocomplete` ref, the "Look
      up address" button + its helper-text paragraph, and the suggestions `<ul
      role="listbox">` dropdown markup (AC1/AC2).
    - Street address `<input>` stays a plain required text field, unchanged apart from
      losing the autocomplete-specific `aria-autocomplete="list"` attribute and the now
      dead `relative`/dropdown wrapper markup around it.
    - Country: convert the existing `<input>` to a `<select>`, options from
      `getCountries()` (new `countryState.ts` wrapper, see below), `value={form.country}`,
      default stays `"IN"` (`emptyValues.country = "IN"`, unchanged) (AC3).
    - State: convert the existing `<input>` to a `<select>`, options from
      `getStatesForCountry(form.country)`. On Country `onChange`, set both the new
      country and clear `state: ""` in the same `setForm` update (AC5). If the current
      `form.state` value isn't among the options returned for the current
      `form.country` (covers AC7's legacy-data case — e.g. on initial load from
      `businessToFormValues` before the merchant touches anything), render an extra
      **unselected placeholder option** (e.g. `<option value="">Select a state…</option>`,
      already implied by an empty-string default) so the `<select>` shows nothing
      selected rather than silently snapping to the first real option — no crash, no
      data loss, matches AC7's "must not block submission" requirement. If
      `getStatesForCountry` returns `[]` for a country with no bundled subdivisions, the
      `<select>` renders with only the placeholder option (disabled/empty), still
      non-blocking (per UX notes).
    - City `<input>` is untouched (AC8) other than no longer being reachable from
      `selectSuggestion` (which is deleted).
    - Latitude/Longitude `<input>`s are untouched (AC9) — the "Look up address" button
      that used to feed them is deleted, but the manual number inputs themselves are not
      touched.
    - Imports: drop `maps`/`AddressSuggestion` from `@/lib/api`; add
      `import { getCountries, getStatesForCountry } from "@/lib/countryState"`.
  - **New file `frontend/src/lib/countryState.ts`** — thin wrapper around
    `country-state-city` (ADR-015): `getCountries(): { code: string; name: string }[]`,
    `getStatesForCountry(countryCode: string): { code: string; name: string }[]`. Only
    module in the codebase that imports the `country-state-city` package directly
    (isolates the rest of the app from its API shape, per ADR-015).
  - **`frontend/package.json`** — add `country-state-city` as a new dependency (Builder
    picks the current published version at implementation time).
  - **`frontend/src/lib/api.ts`** — remove `maps.autocomplete` and `maps.geocode` client
    methods (keep `maps.nearby`, `maps.config` — untouched, AC14); remove the
    `AddressSuggestion` and `GeocodeResponse` interfaces (both dead once the two methods
    that used them are gone). `BusinessCreateInput`/`BusinessUpdateInput` need **no**
    change — both already declare optional `country`.
  - **`frontend/src/components/__tests__/BusinessForm.test.tsx`** — out of Architect
    scope to author (Tester/Builder), but flagged here for visibility per the task
    framing: the `jest.mock("../../lib/api", ...)` block's `maps: { geocode, autocomplete
    }` mock must be removed/replaced, and every S-073-era test that exercises the
    autocomplete dropdown, `selectSuggestion`, or the "Look up address" fallback
    (currently the block of tests tagged "S-073 AC1/AC2/AC8") must be deleted since that
    UI no longer exists; new coverage is needed for the Country/State `<select>`
    rendering, cascading behavior on Country change (AC4/AC5), pre-selection of a
    matching legacy State (AC6), graceful non-blocking handling of a non-matching legacy
    State (AC7), and country persisting through `businesses.update` on edit (AC10).
  - **`backend/tests/test_maps_autocomplete.py`** — dead test file once the route is
    removed; deletion is Tester-owned but flagged here since AC13 requires no dangling
    references anywhere in the repo.
- **Mobile generated client (not a mobile code change, a byproduct of the backend route
  removal):** `mobile/packages/merchanthub_api/` is generated from the backend's live
  OpenAPI schema via `mobile/scripts/generate_api_client.py` (see `README.md` §12 /
  `ANDROID_APP_STRATEGY.md`), not hand-written. Removing the two backend routes leaves
  `mobile/packages/merchanthub_api/lib/src/api/maps_api.dart`'s
  `geocodeAddressApiV1MapsGeocodeGet`/`autocompleteAddress...` methods,
  `lib/src/model/geocode_response*.dart`, and the matching `doc/`/`test/` files stale.
  The Builder must re-run the OpenAPI → Dart codegen against the updated backend (or, if
  a live backend isn't reachable in the build sandbox, manually delete the corresponding
  generated files and update `mobile/openapi.json`'s snapshot) as part of this slice —
  otherwise AC13's "no remaining code in the repo (web frontend, mobile app, or backend)
  references either endpoint" is violated by stale generated code. Mobile's hand-written
  screens (`business_editor_screen.dart`) don't call these methods today (per the PM's
  background research), so this is codegen hygiene only, not a mobile behavior change.

### Flow

```mermaid
sequenceDiagram
    participant Merchant
    participant Form as BusinessForm (create/edit)
    participant Data as countryState.ts (bundled dataset, no network)
    participant API

    Merchant->>Form: loads form
    Form->>Data: getCountries()
    Data-->>Form: [{code:"IN",name:"India"}, ...] (default "IN")
    Form->>Data: getStatesForCountry(form.country)
    Data-->>Form: [{code:"TN",name:"Tamil Nadu"}, ...]
    Note over Form: existing business.state pre-selected if it<br/>matches a returned code (AC6); else placeholder (AC7)
    Merchant->>Form: types Street address (plain input, no network call -- AC1)
    Merchant->>Form: changes Country select
    Form->>Data: getStatesForCountry(newCountry)
    Data-->>Form: new state list
    Form->>Form: clear previously selected State (AC5)
    Merchant->>Form: picks State, fills City/Address, submits
    Form->>API: PATCH /businesses/{id} {country, state, address, city, postal_code, ...}
    alt address_edit_count == 0 (first edit, or brand-new business)
        API-->>Form: 200 Business (country persisted -- AC10, AC12: no OTP)
    else address_edit_count >= 1 and merchant role
        API-->>Form: 400 Verification code required
        Form->>API: POST /businesses/{id}/address-verify/request (S-073, unchanged)
        API-->>Form: 200 (SMS sent, unchanged mechanism)
        Merchant->>Form: enters OTP code
        Form->>API: PATCH ... {..., address_otp_code}
        API-->>Form: 200 Business (country persisted -- AC10, AC11: OTP enforced)
    end
```

### Architect checklist

- [x] API contract defined and matches `README.md` §7 API reference style
- [x] RBAC matrix complete for all roles
- [x] Data model impact documented — schema-only (`BusinessUpdate.country`), no
      migration; `Business.country`/`Business.state` columns already exist
- [x] Cache invalidation considered — unchanged existing `search:*` wildcard already
      covers this path, `country` isn't a search filter
- [x] Uses AI/storage/maps abstractions where applicable — n/a (no AI, no storage, no new
      maps provider call; this slice removes Nominatim calls, doesn't add any)
- [x] No secrets in design
- [x] ERD/API/FLOWS updates noted — `README.md` §7 (remove `GET /maps/autocomplete`,
      `GET /maps/geocode`; note `PATCH /businesses/{id}` now accepts `country`), §5
      (no schema change to note beyond the Pydantic-level gap closing — the DB column
      already existed and was already documented), §6 (Merchant business registration
      flow currently describes the geocode-button interaction — needs rewriting per the
      Flow above), §12 (parity tracker row per UX notes), §14 (close the
      `BusinessUpdate.country` gap; add the no-coordinates-without-geocoding tradeoff)

### Risks / tradeoffs

- **Coordinate-coverage tradeoff (already accepted by PM, restated for visibility):**
  removing geocoding entirely means most newly-created or newly-edited listings will end
  up with no `latitude`/`longitude` unless a merchant enters them manually, degrading
  `POST /maps/nearby`'s distance-search coverage over time. Not this slice's job to fix
  (see Out of scope); record as a new/updated `README.md` §14 known gap at Accepted
  stage.
- **Breaking API-surface change:** `GET /maps/autocomplete` and `GET /maps/geocode`
  returning `404` instead of a documented response is a breaking change for any external
  consumer of the Swagger-documented `/api/v1` contract. Repo-wide search (see AC13)
  confirms no consumer exists today beyond `BusinessForm.tsx` and mobile's generated (but
  functionally unused) client — and this project doesn't publish a versioning/deprecation
  guarantee for third-party API consumers (`README.md` §7 doesn't document one). A hard
  removal rather than a deprecation window is therefore judged acceptable, but flagging
  explicitly since it's the kind of externally-visible contract change that would
  normally warrant one in a product with real third-party API consumers.
- **Mobile generated-client drift:** see Frontend section above — the Builder must
  regenerate (or manually prune) `mobile/packages/merchanthub_api/`'s maps-related
  generated files, or AC13 will fail on a technicality (stale generated code still
  referencing the removed paths) even though no hand-written mobile code calls them.
- **Dataset bundle-size risk:** see ADR-015 — mitigated by a wrapper module, a
  Builder-side `next build` verification step, and a documented same-signature vendored-
  JSON fallback if the package doesn't tree-shake `City` out cleanly. Scoped to the two
  onboarding routes regardless of outcome (Next.js per-route code splitting), not global.
- **`state` becomes a code, not a free-text name, going forward:** once a business is
  resaved through the new dropdown, `Business.state` holds an ISO subdivision code (e.g.
  `"TN"`) rather than whatever free text was there before. AC6/AC7 already dictate
  graceful degrade-on-mismatch for legacy data (pre-selects if it matches, shows an
  unselected placeholder if it doesn't — never blocks saving), so this is an accepted,
  spec'd migration path, not a gap.

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-084-merchant-address-country-state-dropdowns.md`
- Test report: `docs/agents/test-reports/TR-S-084-merchant-address-country-state-dropdowns.md`
- ADR: `docs/agents/adrs/ADR-015-bundled-country-state-dataset.md` (bundled
  `country-state-city` dataset choice, Country+State only, wrapper module, bundle-size
  verification step + fallback).

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-19 | PM | Created slice. Confirmed via codebase read (`BusinessForm.tsx`, `backend/app/routers/maps.py`, `backend/app/services/geo.py`, `backend/app/schemas/__init__.py`, `mobile/lib/features/merchant/business_editor_screen.dart`) that: `BusinessUpdate` has no `country` field (pre-existing gap flagged by S-073's builder note); `GET /maps/autocomplete`/`GET /maps/geocode` have no callers outside `BusinessForm.tsx`; mobile's business editor already has plain free-text address/city/state/country with no lookup, a continuing parity gap. 14 numbered AC covering address-field-is-plain-text, removed lookup UI, cascading Country/State dropdowns with India/"IN" default preserved, City unchanged, lat/lng unaffected, `BusinessUpdate.country` persistence gap closed, S-073 OTP re-verification unchanged, and dead-route removal with no dangling references. Status: Draft — Architect to fill technical specification (bundled dataset source, schema/migration for the new persisted `country`, exact route/service/schema deletions). |
| 2026-08-19 | Architect | Filled technical specification; wrote ADR-015 (`country-state-city` npm package, Country+State exports only, wrapped behind new `frontend/src/lib/countryState.ts`, with a Builder-side bundle-size verification step and a documented same-signature vendored-JSON fallback). Confirmed the `BusinessUpdate.country` gap fix is a single-field schema addition — `_ADDRESS_FIELDS` and `update_business`'s change-detection/persistence loops in `backend/app/routers/businesses.py` already handle `country` generically (added forward-looking in S-073), no router logic changes needed. Confirmed data model impact is schema-only (`Business.country`/`Business.state` columns already exist, no migration). Specified the removal of `GET /maps/autocomplete`/`GET /maps/geocode`, `search_addresses()`, and `AddressSuggestion`/`GeocodeResponse` schemas, and flagged (as a risk, not an AC gap) that the mobile OpenAPI-generated client (`mobile/packages/merchanthub_api/`) must be regenerated or manually pruned so AC13's "no dangling references" holds for generated code too. Status → Specified. |
| 2026-08-19 | Builder | Implemented: Nominatim lookup UI removed from `BusinessForm`; Country/State `<select>`s via `countryState.ts` wrapping `country-state-city` Country+State subpath imports (never `City` / `city.json`); `BusinessUpdate.country` added; maps autocomplete/geocode routes, `search_addresses()`, and suggestion/geocode schemas deleted; README §5/§6/§7/§12/§14 updated. Status → In Progress. |
| 2026-08-19 | Tester | Independent re-run: frontend `BusinessForm` 19/19 + full Jest 50 suites / 307 tests; backend OTP/country PATCH + maps 404/config 16/16. Wrote `docs/agents/test-reports/TR-S-084-merchant-address-country-state-dropdowns.md`. Recommendation: **Ship**. Flutter still on hold. Status remains In Progress pending PM accept. |
| 2026-08-19 | PM | Reviewed TR-S-084 against AC 1–14. All ACs mapped and passing. README §5/§6/§7/§8/§12/§14 DoD present (M-54 `partial` for web dropdowns vs mobile free-text; `BusinessUpdate.country` gap closed; no-coordinates-without-geocoding recorded). Non-blocking nits (stale `google.py` comment, missing TP file, Flutter on hold) do not reopen. **Status → Accepted.** No functional rework. |
