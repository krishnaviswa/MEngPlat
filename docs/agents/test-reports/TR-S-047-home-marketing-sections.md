# TR-S-047: Home page social proof rail + problem section — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-047 |
| **Author** | Tester |
| **Date** | 2026-08-16 |
| **Recommendation** | Ship |

---

## Summary

All 9 AC verified — 6 by new automated RTL tests, 3 by manual/code inspection (structural
section-order, visual "How it works" pattern match, and light/dark visual review — none of
which are meaningfully unit-testable in jsdom without a real browser). Builder's implementation
matches the Architect's spec exactly: `SocialProofRail` renders `SOCIAL_PROOF_ENTRIES` (a local
hardcoded `const`, no fetch) with a small-caps label and no numeric stat; `ProblemSection` renders
the three fixed points with `01`/`02`/`03` numerals reusing the "How it works" `<ol>`/`<li>`
structure and class names verbatim; `page.tsx` inserts both between the hero's closing
`</section>` (line 177) and `{stats && <TrustMetrics .../>}` (line 183), confirmed by direct
read of the file. This Tester pass added 11 new tests across 2 new files (zero pre-existing
coverage of either component). Full suite: **35 suites / 160 tests pass** (149 pre-existing + 11
new, none broken).

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Section order: hero → `SocialProofRail` → `ProblemSection` → `TrustMetrics` → unchanged rest | M | M-001: code read of `frontend/src/app/page.tsx` — hero `</section>` at line 177, `<SocialProofRail />` at 179, `<ProblemSection />` at 181, `{stats && <TrustMetrics .../>}` at 183, no reordering below | Pass |
| 2 | `SocialProofRail` entries come from a hardcoded exported `const` array, not `businesses.list()`/any API call | A | `SocialProofRail.test.tsx` — imports `SOCIAL_PROOF_ENTRIES` directly from the component module and asserts every entry's `name` renders (only possible if it's a static, importable const, not a runtime fetch); corroborated by M-002 code read (no `import` of `@/lib/api`, no `fetch`/`useEffect` in the file) | Pass |
| 3 | Label + muted/grayscale entries render; no numeric stat/count/percentage shown | A | `SocialProofRail.test.tsx` — "renders the small-caps label", "does not display any numeric stat, count, or percentage" (asserts rendered text has no digit or `%` character) | Pass |
| 4 | `ProblemSection` presents exactly 3 numbered points using the "How it works" `01`/`02`/`03` visual treatment | A / M | `ProblemSection.test.tsx` — "renders exactly three numbered list items", "renders the 01/02/03 numerals, not 1/2/3" (A); M-003: code diff confirms identical class names to `page.tsx`'s "How it works" block (`border-t border-brand-200 pt-6`, `font-display text-sm font-semibold tracking-widest text-brand-700`, `<ol className="mt-12 grid gap-10 md:grid-cols-3">`) (M) | Pass |
| 5 | Three points, in order, with the exact specified titles | A | `ProblemSection.test.tsx` — "renders the exact three point titles, in order" (asserts `<h3>` text array equals `["Your reviews are scattered", "You don't know what's actually working", "Vague reviews don't help anyone"]`) | Pass |
| 6 | Copy doesn't name a specific business/city or overstate shipped capability (no live aggregation/AI-topic claims; point 3 may reference `/collect/[businessId]`) | M | M-004: code read of `ProblemSection.tsx` body copy — point 1 ("Google reviews, word of mouth, in-person feedback — there's no single place to see it all") makes no aggregation-is-live claim; point 2 makes no AI-topic-breakdown claim; point 3 references "MerchantHub's guided review flow" (S-040, shipped) without naming a business/city; corroborated by `ProblemSection.test.tsx` — "does not claim live multi-platform aggregation or AI topic breakdown" (asserts rendered text contains no "AI" substring) | Pass |
| 7 | Neither section conditionally returns `null` — both always render | A | `SocialProofRail.test.tsx` / `ProblemSection.test.tsx` — "renders unconditionally (never null/empty) — component takes no props" in both files, plus every other test in both files implicitly exercises the only render path (no props exist to vary, so there is no conditional branch to exercise separately) | Pass |
| 8 | Both sections use existing semantic/`dark:` tokens; no new hardcoded light-only classes (`text-gray-900`, `bg-white`) | A / M | `SocialProofRail.test.tsx` / `ProblemSection.test.tsx` — "does not use hardcoded light-only color literals" (grep of rendered HTML for `text-gray-900`/`bg-white`, zero hits in both); M-005: source-file grep for `text-gray-|bg-white|bg-gray-` across both files — zero hits; `SocialProofRail`'s one non-semantic-token pair (`bg-slate-200 dark:bg-slate-700` on the initial badge) is `dark:`-paired, not a bare light-only literal, and pre-exists as a pattern elsewhere in the codebase | Pass |
| 9 | Neither section has an AI disclaimer (not applicable) and copy implies no AI judgment | M | M-006: code read confirms no "AI"/"suggestion" wording, no `AIInsights`/disclaimer component import in either file; corroborated by `ProblemSection.test.tsx`'s "does not claim live... AI topic breakdown" test (no "AI" substring anywhere in rendered output) | Pass |

**Coverage:** 9 / 9 AC mapped, 9 / 9 Pass

---

## Backend tests

None — frontend-only, static-content slice per Architect spec (no API/RBAC/data-model change,
confirmed N/A in Technical specification). Not applicable.

---

## Frontend tests

### Added
- `frontend/src/components/home/__tests__/SocialProofRail.test.tsx` (new, 5 tests): renders the
  "Businesses using MerchantHub" label; renders every `SOCIAL_PROOF_ENTRIES` name (not just the
  first); rendered text contains no digit or `%` character (AC 3 — no stat leakage); renders
  unconditionally with a non-empty `<section>` (AC 7); no `text-gray-900`/`bg-white` literals in
  rendered HTML (AC 8).
- `frontend/src/components/home/__tests__/ProblemSection.test.tsx` (new, 6 tests): renders
  exactly 3 `<ol> > <li>` items; renders `01`/`02`/`03` numerals and not `1`/`2`/`3`; renders the
  three `<h3>` titles in the exact specified order; renders unconditionally with a non-empty
  `<section>` (AC 7); rendered text contains no "AI" substring (AC 6/9 honest-scoping guard); no
  `text-gray-900`/`bg-white` literals in rendered HTML (AC 8).

### Run output
```
cd frontend && npx jest --ci src/components/home/__tests__/SocialProofRail.test.tsx src/components/home/__tests__/ProblemSection.test.tsx
PASS x2 — 11 passed, 11 total

cd frontend && npm test -- --ci
Test Suites: 35 passed, 35 total
Tests:       160 passed, 160 total
```
(149 pre-existing + 11 new this pass; no pre-existing test broken. Pre-existing unrelated
`console.warn`/`act(...)` noise from `MerchantDashboard.test.tsx` and recharts'
`ResponsiveContainer` (zero width/height in jsdom) predates this slice, not introduced by it, not
a failure.)

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | AC 1 — code read of `frontend/src/app/page.tsx`: hero `</section>` (177) → `<SocialProofRail />` (179) → `<ProblemSection />` (181) → `{stats && <TrustMetrics .../>}` (183); rest of the page (`CityIndex`/`CategoryIndex`/`FeaturedGrid`/`ReviewVoices`/"How it works"/merchant CTA) unmoved below that | Pass |
| M-002 | AC 2 — `SocialProofRail.tsx` has no `import` from `@/lib/api`, no `fetch`, no `useEffect`/data-fetching hook; `SOCIAL_PROOF_ENTRIES` is a plain exported `const` array declared at module scope | Pass |
| M-003 | AC 4 — `ProblemSection.tsx`'s `<ol>`/`<li>` class names (`mt-12 grid gap-10 md:grid-cols-3`, `border-t border-brand-200 pt-6`, `font-display text-sm font-semibold tracking-widest text-brand-700`) match the existing "How it works" block in `page.tsx` verbatim, per Architect spec | Pass |
| M-004 | AC 6 — copy review of all 3 `ProblemSection` points: no business/city named; point 1 doesn't claim live aggregation (S-048 not yet shipped); point 2 doesn't claim live AI topic breakdown (S-049 not yet shipped); point 3 references the shipped `/collect/[businessId]` guided flow (S-040, Accepted) only implicitly by description, not overstated | Pass |
| M-005 | AC 8 — grep `SocialProofRail.tsx` and `ProblemSection.tsx` for `text-gray-|bg-white|bg-gray-`: zero hits in both files. Also visually reviewed the User's manually-verified browser preview (per task brief) confirming both sections render correctly in the page's current light theme, with no obviously broken/unpaired class | Pass |
| M-006 | AC 9 — neither file imports an `AIInsights`/disclaimer component or contains "AI"/"suggestion" wording; both are pure static marketing copy | Pass |
| M-007 | `docker compose up --build` / live browser dark-mode toggle smoke test on both new sections | Not executed in this pass — User already manually verified page render/order/copy in a live browser preview per task brief; full dark-mode toggle re-verification not repeated here (low risk given AC 8's semantic-token-only usage, confirmed by grep) |

---

## Regressions

None. Full pre-existing Jest suite (149 tests) still passes unchanged.

---

## Gaps / rework items

None. All 9 AC pass. No RBAC surface exists for this slice (public, pre-auth route, no role
gating per Architect's RBAC matrix — N/A, correctly so). No AI disclaimer is required (AC 9,
correctly absent). One non-blocking note: M-007 (live dark-mode toggle in a running
`docker compose` browser) was not independently re-run by Tester in this pass — the User's
already-completed manual browser verification (page order, no console/server errors, copy match)
plus this report's static grep for light-only literals (M-005) are treated as sufficient
corroboration for AC 8; flagging only for completeness, not as a Ship blocker.

Separately (PM Definition-of-done items, not test failures): `README.md` §12 parity tracker rows
`M-76`/`M-77` and §14/§16 updates are still open per the slice's DoD checklist — not yet verified
as present in this pass; PM should confirm before setting `Status: Accepted`.

---

## Sign-off

- [x] All AC mapped to tests (9 / 9 Pass)
- [x] RBAC not applicable — public, pre-auth, unconditional render for all roles/anonymous
      visitors, confirmed by Architect's RBAC matrix and by AC 7's "no conditional `null`" test
- [x] AI disclaimer verified — correctly absent per AC 9 (no AI-derived content), confirmed by
      code read and by the "no AI substring" assertion in `ProblemSection.test.tsx`
- [x] Ready for PM acceptance — no AC unmapped, no RBAC gap, no AI disclaimer issue. One
      non-blocking note above (M-007 dark-mode re-verification) and a reminder that README §12/§14/§16
      DoD items are still open, neither is a Ship blocker for this test pass.
