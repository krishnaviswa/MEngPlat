# Slice: S-047 — Home page social proof rail + problem section

| Field | Value |
|-------|-------|
| **Slice ID** | S-047 |
| **Phase** | 5 Polish |
| **Status** | Accepted |
| **Role(s)** | customer \| merchant (public, pre-auth — visible to any home-page visitor) |
| **Owner** | PM / 2026-08-16 |

---

## User story

**As a** visitor to the MerchantHub home page (prospective customer or prospective merchant, not yet signed in)
**I want** to see, right after the hero, evidence that other businesses already use MerchantHub and a clear, honest statement of the specific problems the platform solves for business reviews
**So that** I have a legitimacy signal and a reason to care *before* I reach the live platform stats and listings — rather than being dropped straight from the hero pitch into raw numbers with no framing

---

## Acceptance criteria

1. **Given** any visitor loads the home page (`/`), **when** the page renders, **then** the section order is: hero → `SocialProofRail` → `ProblemSection` → `TrustMetrics` → (existing `CityIndex`/`CategoryIndex`/`FeaturedGrid`/`ReviewVoices`/"How it works"/merchant CTA, unchanged) — both new sections sit between the hero and the existing stats block, never after it.

2. **Given** the `SocialProofRail` component, **when** its source is inspected, **then** its business name/logo entries come from a single hardcoded, exported `const` array declared at the top of the component file (one entry per line, `{name, logo or initial}` shape) — **not** from `businesses.list()` or any other API/data call. No network request is made to populate this section.

3. **Given** the `SocialProofRail` section renders, **when** a visitor views it, **then** it shows a small-caps label (e.g. "Businesses using MerchantHub") above a row of visually muted/grayscale name-or-logo entries, and it does **not** display any numeric stat, count, or percentage (real stats stay exclusively in `TrustMetrics`, directly below it).

4. **Given** the `ProblemSection` component, **when** a visitor views it, **then** it presents exactly three numbered points using the same numbered/icon-led visual treatment as the existing "How it works" section on the same page (`01`/`02`/`03` styling, `frontend/src/app/page.tsx` lines ~194–228) — not a new, unrelated visual pattern.

5. **Given** the `ProblemSection` copy, **when** read, **then** the three points are, in order: (1) "Your reviews are scattered" — reviews split across Google, word of mouth, and in-person feedback with no single view; (2) "You don't know what's actually working" — a star average alone doesn't say which service, staff member, or product is driving satisfaction; (3) "Vague reviews don't help anyone" — a review like "good place" gives the business owner and future customers nothing actionable.

6. **Given** the `ProblemSection` copy, **when** checked against real product capability, **then** no point names a specific business or a specific city, and no point overstates what is shipped today: point 1 does not claim multi-platform review aggregation is live (it is planned, sibling slice S-048); point 2 does not claim AI topic breakdown is live (it is planned, sibling slice S-049); point 3 may reference the guided review-collection flow (`/collect/[businessId]`) since that is already shipped (S-040, Accepted).

7. **Given** either new section, **when** rendered, **then** neither section conditionally returns `null` based on live data volume — unlike `TrustMetrics`/`ReviewVoices` (which hide under thin data), `SocialProofRail` and `ProblemSection` have no live-data dependency and always render their static/placeholder content.

8. **Given** either new section rendered in light or dark mode, **when** viewed, **then** all text/background/border colors use the existing semantic tokens and `dark:` pairs already established by S-045 (e.g. `text-ink`, `text-muted`, `border-border`, `brand-*`) — no new hardcoded light-only classes (e.g. bare `text-gray-900`, `bg-white`) are introduced.

9. **Given** neither new section presents any AI-generated or AI-derived content, **when** reviewed, **then** neither section includes an AI "suggestion" disclaimer (not applicable here) and neither section's copy implies an AI judgment — this is static marketing copy only.

---

## UX notes

- **Screens / routes:** home page only (`frontend/src/app/page.tsx`, `/`). No new route.
- **Components to reuse / match:**
  - Follow the established home-section conventions in `frontend/src/components/home/TrustMetrics.tsx` and `frontend/src/components/home/ReviewVoices.tsx` — Tailwind utility classes, `brand-*` color tokens, `font-display` for headings, `mh-section-reveal` section-level animation class, `mx-auto max-w-6xl px-4` content width.
  - `ProblemSection`'s numbered layout must visually match the existing "How it works" `<ol>` / `01`/`02`/`03` pattern at `frontend/src/app/page.tsx` lines ~194–228 (same `border-t border-brand-200 pt-6`, `font-display text-sm font-semibold tracking-widest text-brand-700` numeral treatment) — do not invent a new numbered-list visual style.
  - No new shared UI primitives required; both are self-contained presentational components under `frontend/src/components/home/`.
- **Empty states / errors:** none applicable — both sections are static/hardcoded, not data-dependent, so there is no loading, error, or "hide if thin" state to design (this is the one respect in which these two sections deliberately diverge from the `TrustMetrics`/`ReviewVoices` convention — see AC 7).
- **AI disclaimer required?** No — neither section presents AI-derived content (see AC 9).

---

## Out of scope

- **Live business-logo query.** `SocialProofRail` ships with a hardcoded placeholder array only; wiring it to `businesses.list()` or any "top/verified businesses" query is explicitly not part of this slice. The user will swap in real client names/logos directly in code once available.
- **A/B testing** of section placement, copy, or presence — ships as a single fixed treatment.
- **Analytics/tracking** on either section (no click/impression instrumentation added in this pass).
- **Implementing the review aggregator or AI topic clustering themselves.** `ProblemSection` copy *references* those as roadmap capabilities (sibling slices S-048, S-049) but this slice does not build either — it is copy-only, honestly worded per AC 6.
- **Vertical-specific landing pages** — explicitly decided against in the parent plan; not reconsidered here.
- Any change to the existing "How it works" section itself, `TrustMetrics`, `ReviewVoices`, or any other existing home-page section — this slice only inserts two new sections between the hero and `TrustMetrics`.

---

## Dependencies

- None — self-contained. (`ProblemSection` copy references sibling slices S-048 and S-049 as forward-looking roadmap items, but this slice has no functional/build dependency on either — it ships and reads correctly regardless of their status.)

---

## Definition of done (PM)

- [x] All 9 AC verified in test report (`docs/agents/test-reports/TR-S-047-home-marketing-sections.md`, 9/9 pass)
- [x] UX matches notes above
- [x] `README.md` §8 Frontend guide — no new pattern convention introduced (straightforward reuse of existing `TrustMetrics`/"How it works" conventions), so no §8 edit needed
- [x] `README.md` §12 Web ↔ mobile feature parity tracker — `M-76` social proof rail, `M-77` problem section added, both `unimplemented` on mobile
- [x] `README.md` §14 (known gaps) and §16 ("built vs next") updated in the same PR
- [x] PM Status set to **Accepted**

---

## Technical specification (Architect)

> Filled by Architect before implementation.

### API contract

**N/A** — this slice adds no backend endpoint. Both components render static/hardcoded
content only; there is no fetch, no `businesses.*`/`reviews.*` call, and no addition to
`frontend/src/lib/api.ts`. (See AC 2 — `SocialProofRail`'s data must literally be a local
`const` array, never a network call.)

| Method | Path | Auth | Request | Response |
|--------|------|------|---------|----------|
| — | — | — | — | — |

### RBAC matrix

**N/A** — `/` is a public, pre-auth route. No role gating, no `require_roles()` usage, no
conditional rendering by role. Both sections render identically for anonymous visitors,
customers, merchants, and admins.

| Action | customer | merchant | admin |
|--------|----------|----------|-------|
| View section | yes (and anonymous) | yes | yes |

### Data model impact

- [x] None  [ ] Extend existing  [ ] New table(s)

**Details:** No PostgreSQL schema change. No new Pydantic schema, no SQLAlchemy model, no
Alembic migration. `SocialProofEntry` (below) is a **TypeScript-only** shape local to the
frontend; it is not persisted and has no server-side equivalent.

### Cache / side effects

None. No Redis read/write, no `search:*` (or any) cache-key interaction — these sections
never call the backend, so there is nothing to invalidate. No other side effects (no
analytics/tracking calls — explicitly out of scope per PM).

### Frontend

- **Route:** `/` (existing home route, `frontend/src/app/page.tsx`) — no new route.
- **Rendering:** SSR. `page.tsx` is already an async Server Component; both new components
  are plain (non-`"use client"`) Server Components — no hooks, no browser APIs, no
  interactivity, so no client boundary is needed for either.
- **Components (new, both under `frontend/src/components/home/`, reuse-first — no new
  shared UI primitives per PM UX notes):**

  **`frontend/src/components/home/SocialProofRail.tsx`**
  ```ts
  export interface SocialProofEntry {
    name: string;
    /** 1–2 char fallback badge rendered when no logo asset exists yet (placeholder era). */
    initial: string;
    /** Optional future logo asset path; undefined for all placeholder entries in this slice. */
    logoUrl?: string;
  }

  /** Placeholder roster — swap for real client names/logos post-launch (see Risks). */
  export const SOCIAL_PROOF_ENTRIES: SocialProofEntry[] = [
    { name: "…", initial: "…" },
    // … one entry per line, hardcoded, per AC 2
  ];

  /** SocialProofRail — static "businesses using MerchantHub" logo/name strip. No props, no fetch. */
  export function SocialProofRail() { /* renders SOCIAL_PROOF_ENTRIES, muted/grayscale, no stat numbers (AC 3) */ }
  ```
  - No props — fully self-contained per AC 2 (data must live in the file, not be passed in
    or fetched), which also keeps it decoupled from the `Promise.allSettled` SSR data block
    already in `page.tsx`.
  - Visual: small-caps/uppercase label above a muted/grayscale row (`text-muted`, low-opacity
    or `grayscale` utility on any future logo `<img>`) — must not introduce a numeric stat
    (AC 3; real numbers stay in `TrustMetrics`).
  - Match section chrome to `TrustMetrics`/`ReviewVoices`: `mh-section-reveal`,
    `mx-auto max-w-6xl px-4`, `font-display` for the label, semantic `dark:`-paired tokens
    only (AC 8) — no bare `text-gray-*`/`bg-white`.

  **`frontend/src/components/home/ProblemSection.tsx`**
  ```ts
  /** ProblemSection — three honestly-scoped problem points, "How it works" 01/02/03 treatment. No props. */
  export function ProblemSection() { /* renders 3 fixed points per AC 5/6 */ }
  ```
  - No props, no exported data array required (unlike `SocialProofRail`) — mirrors the
    existing "How it works" block in `page.tsx` (lines ~202–226), which defines its 3-step
    array **inline** inside the `.map()` call rather than as a hoisted constant. Match that
    exact structure: `<ol className="mt-12 grid gap-10 md:grid-cols-3">`, each `<li>` using
    `border-t border-brand-200 pt-6`, numeral `<p>` using
    `font-display text-sm font-semibold tracking-widest text-brand-700` (`01`/`02`/`03`,
    not `1`/`2`/`3`), title `<h3>` using `font-display text-xl font-semibold text-ink`, body
    `<p>` using `text-muted`.
  - Copy (fixed, per AC 5/6 — verbatim titles, bodies paraphrased/finalized by content
    review, not by Architect):
    1. `01` "Your reviews are scattered" — no claim of live multi-platform aggregation
       (that's S-048, planned).
    2. `02` "You don't know what's actually working" — no claim of live AI topic
       breakdown (that's S-049, planned).
    3. `03` "Vague reviews don't help anyone" — may reference the guided
       `/collect/[businessId]` flow since S-040 is Accepted/shipped.
  - Section-level wrapper matches the "How it works" section chrome (`mh-section-reveal`,
    `border-t border-border`, `mx-auto max-w-6xl`, centered `<h2>`/`<p>` intro) so it reads
    as a sibling pattern, not a new visual language.

- **`page.tsx` insertion point:** between the closing `</section>` of the hero block
  (currently line 175) and `{stats && <TrustMetrics stats={stats} />}` (currently line 177).
  New JSX, no change to any existing SSR data-fetching (`Promise.allSettled`, `grid`,
  `voiceItems`, etc.) — both components take no props derived from that data:
  ```tsx
      </section>
      {/* hero ends here */}

      <SocialProofRail />

      <ProblemSection />

      {stats && <TrustMetrics stats={stats} />}
  ```
  Add the two imports alongside the existing `@/components/home/*` imports at the top of
  `page.tsx`. Never conditionally return `null` in either component (AC 7) — unlike
  `TrustMetrics`, which is gated by `{stats && …}` in the parent, `SocialProofRail`/
  `ProblemSection` render unconditionally with no such guard.

### Flow

No sequence diagram — this is fully static server-rendered markup, not a client/API
interaction. The only "flow" is: visitor requests `/` → Next.js renders `page.tsx` on the
server → `SocialProofRail`/`ProblemSection` render their fixed local content inline →
existing SSR data-fetch (`businesses.*`) proceeds unrelated, for `TrustMetrics` and below.

### Architect checklist

- [x] API contract defined *(N/A — none needed, documented above)*
- [x] RBAC matrix complete *(N/A — public route, documented above)*
- [x] Data model impact documented *(None)*
- [x] Cache invalidation considered *(None needed — no backend call)*
- [x] Uses AI/storage abstractions where applicable *(N/A — no AI-derived content per AC 9,
      no storage/upload involved)*
- [x] ERD/API/FLOWS updates noted *(no ERD/API change; README §12 parity tracker rows
      `M-76`/`M-77` and §14/§16 updates are PM DoD items above, not Architect-owned, since
      no API/domain-model/flow section of README actually changes)*

### Risks / tradeoffs

- **Stale placeholder data risk.** `SOCIAL_PROOF_ENTRIES` is hardcoded fictional/placeholder
  content by design (PM out-of-scope decision). If it ships to production without a manual
  swap to real client names, it risks reading as fabricated social proof. Mitigate by
  tracking the swap as a fast-follow task before/at public launch; do not silently forget it.
- **No A/B testing / no analytics** (both explicitly out of scope) means there is no
  quantitative signal on whether these sections help or hurt conversion between the hero and
  `TrustMetrics` — a later slice would need to add instrumentation before this could be
  data-validated.
- **Copy/roadmap drift.** `ProblemSection` point 1 and point 2 reference sibling slices
  S-048 (review aggregation) and S-049 (AI topic breakdown) as *not yet shipped*. If either
  slice's final scope changes materially from what's described here, `ProblemSection` copy
  should be revisited for accuracy at that time — no functional dependency, but a content
  freshness risk.
- **No CMS / code-only copy.** Both sections' copy lives in TSX, so any future wording
  change requires a code change + deploy, consistent with the rest of the home page today
  (no CMS in this stack per README §4) — acceptable, not a regression.
- **Scroll-length tradeoff.** Inserting two more full-width sections between hero and
  `TrustMetrics` lengthens the pre-stats scroll distance; deliberate PM tradeoff (framing
  before numbers) rather than an oversight — flagged here for visibility, not a blocker.

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-047-*.md`
- Test report: `docs/agents/test-reports/TR-S-047-*.md`
- ADR: `docs/agents/adrs/ADR-XXX-*.md` (if any)

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-16 | PM | Builder implemented both components and wired them into `page.tsx`; verified live in browser (correct section order, no console/server errors). Tester added 11 RTL tests (35 suites/160 tests pass, no regressions) and a test report — 9/9 AC pass. README §12 (`M-76`/`M-77`), §14, §16 updated same PR. Status: Specified → **Accepted**. |
| 2026-08-16 | Architect | Filled Technical specification: no API/RBAC/data-model impact (all N/A, public static content); specified `SocialProofRail` (`SOCIAL_PROOF_ENTRIES: SocialProofEntry[]` exported const, no props) and `ProblemSection` (no props, mirrors "How it works" inline `01/02/03` `<ol>` structure) as Server Components under `frontend/src/components/home/`, inserted in `page.tsx` between hero and `{stats && <TrustMetrics .../>}`; noted risks (placeholder-logo swap, no A/B/analytics, copy drift vs S-048/S-049). Status: Draft → Specified. |
| 2026-08-16 | PM | Created slice. Two new static home-page sections between the hero and `TrustMetrics`: `SocialProofRail` (hardcoded placeholder name/logo array, no live query, no invented stat numbers — real numbers stay in `TrustMetrics`) and `ProblemSection` (three specific, honestly-scoped problem points — scattered reviews, unclear drivers of satisfaction, vague review text — each mapped to a real capability: sibling slices S-048/S-049 (planned) and the already-shipped S-040 collection flow, matching the existing "How it works" `01/02/03` numbered layout). 9 numbered AC. Explicitly out of scope: live logo query, A/B testing, analytics tracking, and building the aggregator/topic-clustering capabilities referenced in copy. No dependencies — self-contained. Status: Draft. Technical specification left as template for Architect. |
