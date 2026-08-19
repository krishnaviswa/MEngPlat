# TR-S-077: Merchant review-collection QR — reproduce reported regression, then fix — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-077 |
| **Author** | Tester |
| **Date** | 2026-08-19 |
| **Recommendation** | Ship, with an explicit process gap flagged for PM decision (see "Reproduction evidence gap" below) |

---

## Summary

**Pass, functionally** — the code change matches the AC3 branch (approval-status UI gate,
no code defect) exactly as the Architect's spec sketched, and is well covered by
regression tests. **However, AC1 and AC4 explicitly require a live reproduction in a
running dev environment before any fix code is written**, and that reproduction was not
actually performed — a Jest unit test with mocked API responses was substituted instead.
I am flagging this substitution explicitly per the parent agent's instruction, rather than
silently accepting it as equivalent evidence. See "Reproduction evidence gap" below.

Code read of `frontend/src/components/MerchantDashboard.tsx` (current, lines 330-340)
confirms the fix matches the Architect's exact snippet:

```tsx
{status === "approved" ? (
  <div className="grid gap-4 md:grid-cols-2">
    <CollectQrCard businessId={business.id} businessName={business.name} />
    <WhatsAppUpdateCard businessId={business.id} businessName={business.name} />
  </div>
) : (
  <div className="rounded-xl border bg-surface-raised p-4 text-sm text-muted">
    Your review QR code (and WhatsApp update link) will be available once your business is
    approved.
  </div>
)}
```

`CollectQrCard.tsx` itself is untouched (`git status` confirms no diff) — matches AC5's
no-regression requirement for the approved-business baseline. The message copy is
non-AI, static status text (AC6) and is placed adjacent to the existing pending/processing
banners at the top of the same component, consistent tone (neutral `bg-surface-raised`
box vs. the amber banners — an acceptable, Builder's-call variant per the Architect's own
note that "amber or neutral are both consistent").

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Reproduce (before any fix) that the QR card is absent, no code error, due to the `status === "approved"` gate | **M — reproduction requirement not met as specified; see gap below** | Jest test `"shows a 'not approved yet' message (not silent absence) for a pending business"` demonstrates the *current, fixed* behavior with mocked data, not a pre-fix reproduction in a running app with real network/console inspection | **Gap — see below. Functionally, the underlying claim (UI gate, no code defect) is correct by code read, but the AC's evidence bar (live env, before fix, console/network trace) was not met** |
| 2 | Approved business: QR card renders and functions as designed (QR encodes `/collect/{businessId}`, business name in heading, working "Print for shop") | A | `MerchantDashboard.test.tsx::"renders both cards (no messaging fallback) for an approved business"` (card presence); `CollectQrCard.test.tsx` (pre-existing, unmodified — QR value, heading, print button) | Pass |
| 3 | Non-approved business sees a clear, dedicated "not available until approved" message instead of silent absence | A | `MerchantDashboard.test.tsx::"shows a 'not approved yet' message (not silent absence) for a pending business"` — asserts message text present and both card headings absent | Pass |
| 4 | If reproduction reveals a different root cause, fix targets that instead, and report states which branch applied with evidence | M | See "Reproduction evidence gap" below — the report states the AC3 branch applies (consistent with the Architect's own independent code read), but supporting evidence is code-read + unit test, not the live console/network/business-record evidence AC4 calls for | **Gap — see below** |
| 5 | Approved-business QR card unchanged/no regression | A | `CollectQrCard.tsx` has no diff (`git status`); `CollectQrCard.test.tsx` (pre-existing, unmodified, still passing) plus the new `MerchantDashboard.test.tsx` test above | Pass |
| 6 | AC3 messaging copy is non-AI, matches tone/placement of the existing pending-business banner | M (code-read) | Code read of `MerchantDashboard.tsx`: message is plain static text, no AI-suggestion language, placed directly below the pending/processing banners in the same component, `text-muted`/`bg-surface-raised` box — consistent placement, non-AI tone | Pass |

**Coverage:** 6 / 6 AC mapped. 3 automated pass, 2 code-read pass, **2 flagged as
process/evidence gaps (AC1, AC4)** — not code defects, but the reproduction-first
requirement itself was not satisfied as written.

---

## Reproduction evidence gap (flagged per instruction, for PM decision)

AC1 and AC4 are explicit about *when* and *how* reproduction must happen: "**must be
completed and its result documented before any fix code is written**," using a "fresh dev
environment," logging in as a real merchant, inspecting the actual DOM/console/network
tab, and recording the *actual* `business.status` value from a real network response (per
the Architect's reproduction checklist, steps 1-5) — specifically to rule out AC4's
alternate branches (a business incorrectly stuck out of `approved`, or a genuine rendering
error) that a mocked unit test cannot surface by construction, since the mock always
returns exactly the `status` value the test author chooses.

What was actually done: the Builder implemented the fix directly and pointed to a Jest
test (`MerchantDashboard.test.tsx`, mocked `businesses.mine()` responses) as reproduction
evidence, substituting it for a live-environment pass — because, per the handoff notes,
Alembic/Postgres/Docker are not reachable in this sandbox (a real constraint I can
independently confirm: I have no way to run `docker compose up` or hit a live backend from
this environment either).

**My assessment:** the Jest test is good regression-protection evidence (it will fail if
a future change reintroduces silent absence) and its *result* is consistent with the
Architect's own independent code read (no commits touched `CollectQrCard.tsx` since
introduction, confirmed again by me via `git log`). But it is **not equivalent** to what
AC1/AC4 ask for, for two concrete reasons specific to this slice, not a generic "tests vs.
manual QA" tradeoff:
1. AC4's alternate branches (business incorrectly stuck at a non-approved status; a
   genuine rendering/runtime error) can only be ruled out by observing a *real* merchant's
   business record and a *real* browser console/network tab — a mock can't fail to catch
   a bug it was never wired to reproduce.
2. The AC explicitly gates fix-writing on reproduction happening *first*. That ordering
   was not followed (mirrors the Architect's own risk note under "Risks/tradeoffs": "if
   reproduction surfaces AC4's alternate branch, everything under 'Frontend'/'Flow'
   becomes moot" — this presumes reproduction runs before the fix is coded, which it did
   not here).

This is consistent with, but a step beyond, the sandbox-limitation gaps flagged in prior
slices (e.g. TR-S-073's unverified Alembic-against-live-Postgres gap) — those were
*supplementary* verification steps the AC didn't gate the fix itself on; here the AC
explicitly does. **Recommend PM either (a) accept the code-read + independent Architect
confirmation + Jest-test evidence as sufficient given the sandbox constraint and close the
gap, or (b) require an actual `docker compose up` + browser walkthrough (by a human, or a
future agent with DB access) before setting Status: Accepted.** I am not able to perform
that live walkthrough from this environment either, so I cannot close this gap myself.

---

## Frontend tests

### Re-run (independent verification)
```
cd frontend && npx jest src/components/__tests__/MerchantDashboard.test.tsx src/components/__tests__/WhatsAppUpdateCard.test.tsx
Test Suites: 2 passed, 2 total
Tests:       33 passed, 33 total
```

### Full suite
```
cd frontend && npx jest --silent
Test Suites: 47 passed, 47 total
Tests:       284 passed, 284 total
```

### New/relevant tests in `MerchantDashboard.test.tsx`, describe block `"MerchantDashboard review QR / WhatsApp not-yet-approved messaging (S-077 / S-078)"`
- `"shows a 'not approved yet' message (not silent absence) for a pending business"` (AC1's *fixed-state* behavior, AC3)
- `"renders both cards (no messaging fallback) for an approved business"` (AC2/AC5)
- `"shows the same not-approved message for a suspended business"` (extends AC3 beyond `pending` to `suspended`, not explicitly required by AC text but a reasonable extension)

`CollectQrCard.test.tsx` — pre-existing, unmodified — still covers AC2's QR content/print behavior.

---

## Regressions

None found in the automated suite. `CollectQrCard.tsx` has zero diff, so no functional
regression is possible there. `git log` confirms no commits touched `CollectQrCard.tsx`
or `WhatsAppUpdateCard.tsx` between introduction (2026-08-16) and this slice's changes,
consistent with the PM's background claim.

---

## Gaps / rework items

1. **Reproduction evidence gap (AC1/AC4)** — see dedicated section above. Not a code
   defect; a process/evidence-standard gap requiring explicit PM sign-off.
2. **README §6/§12 not updated** — per DoD, if this counts as a "user-facing web
   capability change" the §12 parity tracker should get a row/update; this is a bug-fix to
   existing UX (adding a message where there was silence) rather than a new capability, so
   arguably N/A, but flagging for PM's DoD checklist since it wasn't addressed in this
   diff.

---

## Sign-off

- [x] All AC mapped (6/6), 4 pass cleanly, 2 flagged as an unresolved evidence gap (not a
      code defect)
- [x] RBAC — N/A per Architect spec (confirmed UI presentation gate, not an auth boundary;
      no new endpoint)
- [x] AI disclaimer — N/A, no AI content in this slice (per its own UX notes)
- [ ] **Not fully ready for PM acceptance without a PM decision on the reproduction gap**
      above — code itself is correct and tested; the open item is procedural/evidence
      sufficiency, not a bug.
