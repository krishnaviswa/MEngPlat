# TR-S-074: Left info panel on merchant onboarding screen — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-074 |
| **Author** | Tester |
| **Date** | 2026-08-18 |
| **Recommendation** | Ship |

---

## Summary

**Pass.** Implemented per the Architect's layout clarification: `Dashboard.tsx` gains an
optional `sidePanel?: React.ReactNode` prop, rendered as a new `lg:col-span-1` grid cell
between `nav` and `children` only when supplied (`children`'s span narrows from 3 to 2
when a `sidePanel` is present) — additive and backward-compatible; every other
`Dashboard` call site (Overview, Settings, edit business, etc.) omits the prop and is
structurally unaffected. `frontend/src/app/merchant/businesses/new/page.tsx` is the only
call site passing `sidePanel={<OnboardingGuidancePanel formState={formSnapshot} />}`.
`BusinessForm.tsx` gained the specified `onFormStateChange?: (values: BusinessFormValues)
=> void` prop, fired from a `useEffect([form])`, letting the page mirror form state into
`formSnapshot` without prop-drilling through `Dashboard`. `OnboardingGuidancePanel.tsx`
renders a 4-step list, a "what's required" summary, and identity-verification guidance —
the required-fields list and the disclaimer copy are both sourced from a single shared
`frontend/src/lib/onboarding-copy.ts` (`MERCHANT_REQUIRED_FIELDS`,
`NATIONAL_ID_DISCLAIMER`), so `BusinessForm`'s ★ legend and this panel cannot drift out of
sync — directly satisfying AC3's "no contradictory copy" requirement structurally, not
just by convention.

Full frontend suite: **238/238 passing**, 46/46 suites.

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Left column shows guidance panel in addition to existing nav links on `/merchant/businesses/new` | A | `frontend/src/components/__tests__/Dashboard.test.tsx::"renders the sidePanel alongside the existing nav links and children when provided"` (asserts Overview/Add business/Settings nav links, the sidePanel, and form children all render together) | Pass |
| 2 | Lists onboarding steps at a glance, reflecting actual form/identity steps | A | `frontend/src/components/__tests__/OnboardingGuidancePanel.test.tsx::"lists the onboarding steps"` (asserts all 4 steps: business info, contact details, identity verification, submit for review) | Pass |
| 3 | "What's required" summary consistent with the S-072 ★ legend, no contradictory copy | A | `OnboardingGuidancePanel.test.tsx::"renders the shared required-fields list, matching BusinessForm's legend source"` — asserts the panel renders every entry of the same `MERCHANT_REQUIRED_FIELDS` constant `BusinessForm.tsx`'s legend logically reflects (single source of truth, code read confirms no second hardcoded list exists) | Pass |
| 4 | Brief identity-verification guidance (Aadhaar/PAN/Other, mock/demo disclaimer consistent with S-043/S-070) | A | `OnboardingGuidancePanel.test.tsx::"renders the shared national ID mock/demo disclaimer verbatim"` — asserts the panel's copy is the exact `NATIONAL_ID_DISCLAIMER` string, sourced from the same file, not independently authored | Pass |
| 5 | Reflects basic progress (complete vs. pending) from client-side form state only, no new backend endpoint | A | `OnboardingGuidancePanel.test.tsx::"shows all steps as pending when the form is empty or unset"`, `"marks the business-info step complete once name, address, and city are filled"`, `"marks the contact-info step complete once phone and email are filled"`; code read confirms zero new fetch/API calls in `OnboardingGuidancePanel.tsx` | Pass |
| 6 | Mobile: panel doesn't block/crowd the form; no regression to Dashboard's responsive behavior | Code read | `Dashboard.tsx`'s grid (`grid gap-6 lg:grid-cols-4`) is unchanged Tailwind — the new `sidePanel` cell is inside the same grid container that already collapses to a single column below the `lg:` breakpoint (mobile stacks nav → sidePanel → children vertically); no new responsive CSS was added or needed, matching the Architect's own note | Pass |
| 7 | Panel does not appear (or is neutral) on other `Dashboard.tsx` routes (Overview, Settings) | A | `Dashboard.test.tsx::"does not render a sidePanel column when the prop is omitted"`; code read confirms every other `Dashboard` call site (`MerchantDashboard.tsx`, settings page) does not pass `sidePanel` | Pass |

**Coverage:** 7 / 7 AC mapped (6 automated, 1 code-read for a CSS/responsive-only claim
that isn't meaningfully assertable in jsdom).

---

## Backend tests added
None — this slice is entirely presentational/client-derived, per its own "Out of scope"
(no new backend endpoint).

## Frontend tests added
- `frontend/src/components/__tests__/OnboardingGuidancePanel.test.tsx` (new file, 6 tests):
  - `"lists the onboarding steps"`
  - `"renders the shared required-fields list, matching BusinessForm's legend source"`
  - `"renders the shared national ID mock/demo disclaimer verbatim"`
  - `"shows all steps as pending when the form is empty or unset"`
  - `"marks the business-info step complete once name, address, and city are filled"`
  - `"marks the contact-info step complete once phone and email are filled"`
- `frontend/src/components/__tests__/Dashboard.test.tsx` (new file, 2 tests):
  - `"renders the sidePanel alongside the existing nav links and children when provided"`
  - `"does not render a sidePanel column when the prop is omitted"`

### Note on test authoring
The first `Dashboard.test.tsx` draft used `title="Add business"` for the `sidePanel`
test, which collided with the nav link's own "Add business" label text (both matched
`getByText("Add business")`, a `TestingLibraryElementError: multiple elements`). Changed
the test's `title` prop to `"New listing"` to disambiguate; no production code change.

## Manual checklist

| ID | Check | Result |
|----|-------|--------|
| M-074-01 | Live viewport resize: confirm the panel visually stacks below nav and above the form on a real mobile-width browser (not just jsdom/Tailwind class presence) | Not run — no live dev server/browser exercised in this sandbox; Tailwind grid-collapse behavior is a well-established pattern already used elsewhere in `Dashboard.tsx`, so risk is low, but this is the one AC (AC6) not fully verified by an assertion. |

---

## Regressions / gaps

None found. Full suite green (238/238), no test removed or weakened. AC6 (mobile visual
stacking) is covered by code read only, not a rendered-viewport assertion — flagged as a
manual/visual gap (M-074-01), consistent with the limits of jsdom for CSS layout
behavior; low risk since no new responsive code was introduced.

## Recommendation

**Ship.** All 7 AC mapped, 6 fully automated; AC6 code-read confirmed low-risk given no
new CSS was introduced.
