# TR-S-078: Merchant WhatsApp update QR — reproduce reported regression, then fix — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-078 |
| **Author** | Tester |
| **Date** | 2026-08-19 |
| **Recommendation** | Ship, with an explicit process gap flagged for PM decision (see "Reproduction evidence gap" below) — same posture as TR-S-077, plus a second, distinct evidence gap for candidate 2 |

---

## Summary

**Pass, functionally**, for both candidate root causes identified by the PM/Architect:

1. **Candidate 1 (approval-status gate)** — fixed via the same shared conditional-block
   change as S-077 (both cards sit in the same `{status === "approved" ? (...) : (...)}`
   block in `MerchantDashboard.tsx`); confirmed by code read, one shared message string,
   no duplication.
2. **Candidate 2 (provider unavailable by design)** — `WhatsAppUpdateCard.tsx`'s existing
   `!link.available || !link.wa_url` branch (lines 80-91) now reads:

   > "WhatsApp updates aren't set up for this platform yet — this needs a one-time
   > configuration change from the MerchantHub team, not an action you or an admin can
   > take in-app."

   This replaces the old "WhatsApp updates are not configured yet. Ask an admin to set
   the platform WhatsApp number." copy, which the Architect flagged as a plausible
   confusion point (implying an in-app admin action exists, when it's actually an
   infra/env-config task). The new copy directly addresses that flagged confusion.

Both fixes are covered by passing Jest tests. As with S-077, **AC1's reproduction
requirement and AC2's environment-inspection requirement were not met via a live dev
environment** — the Builder substituted Jest unit tests for both candidates. This gap is
somewhat more significant for S-078 than S-077, because the Architect's own spec
explicitly flagged that **candidate 2 cannot be reproduced at all in local dev** (mock
provider is always available) — it requires a `meta_cloud`-configured staging/Railway
environment, which is even further out of reach than the Postgres/Docker gap already
affecting this sandbox. See "Reproduction evidence gap" below.

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Reproduce (default `WHATSAPP_PROVIDER`=mock), non-approved business: card absent, no code error, due to shared approval gate | **M — reproduction requirement not met as specified; see gap below** | Jest test `"shows a 'not approved yet' message (not silent absence) for a pending business"` (shared with S-077, since both cards are in the same conditional) asserts the *fixed* behavior with mocked data, not a live pre-fix reproduction | **Gap — see below. Functionally correct by code read (shared gate confirmed identical to S-077's), but live-environment evidence bar not met** |
| 2 | Approved business: check `WHATSAPP_PROVIDER` config (mock vs. `meta_cloud`, 5 required settings); record whether `is_available()` returns `False` and produces the existing "not configured" state | **M — cannot be reproduced in this sandbox at all (mock always available; no `meta_cloud`-configured env reachable); see gap below** | Not reproduced live. Simulated instead via `MerchantDashboard.test.tsx::"shows a clarified not-configured message when the WhatsApp provider is unavailable"`, which mocks `dashboard.createWhatsAppLink` to return `{available: false, wa_url: null, ...}` directly — this exercises the frontend's handling of that response shape correctly, but does not touch the actual `is_available()` / env-config path at all | **Gap — see below. Frontend response-handling verified; backend provider-config path unexercised (by design, per Architect's own noted sandbox limitation)** |
| 3 | Approved + available provider: card renders working QR, business-specific copy, working "Print for shop" | A | `WhatsAppUpdateCard.test.tsx::"shows QR and wa.me URL for an available mock link"` (pre-existing, unmodified) + `MerchantDashboard.test.tsx::"renders both cards (no messaging fallback) for an approved business"` | Pass |
| 4 | Fix matches the actual root cause found (gate → shared messaging; provider-unavailable → confirm/re-copy existing message); report states which branch applied | M | Report states: **both** candidate 1 (approval gate) and candidate 2 (provider-unavailable copy) were addressed — see Summary. This matches the PM/Architect's expectation that either or both could apply; the code changes cover both without assuming a single answer | Pass, with the same evidence-standard caveat as AC1/AC2 |
| 5 | AC4 fix copy is non-AI, static, follows S-077 AC6's tone convention (gate case) or stays consistent with the existing card's tone (provider case) | M (code-read) | Gate-case message: identical shared string, already assessed non-AI/consistent in TR-S-077. Provider-case message: plain static text, same section/heading structure as before, no AI-suggestion language | Pass |
| 6 | Approved + available-provider card unchanged from baseline — no regression | A | `WhatsAppUpdateCard.test.tsx::"shows QR and wa.me URL for an available mock link"` — QR, wa.me text, print button, and the "wait for your approval" copy all still assert correctly; this branch of the component (lines 93-111) has zero diff from before | Pass |

**Coverage:** 6 / 6 AC mapped. 4 pass cleanly (with one caveat on AC4's evidence
standard), **2 flagged as reproduction/evidence gaps (AC1, AC2)**.

---

## Reproduction evidence gap (flagged per instruction, for PM decision)

Same core issue as TR-S-077 for candidate 1 (approval gate) — see that report's
"Reproduction evidence gap" section; it applies identically here since both cards share
the exact same conditional block, and I confirmed via code read that
`MerchantDashboard.tsx`'s fix is the single shared block, not duplicated logic.

**Additionally, and more significantly for this slice:** candidate 2 (provider
availability) was **never actually exercised against the real code path** —
`get_whatsapp_provider().is_available()`, `MockWhatsAppProvider`, or
`MetaCloudWhatsAppProvider` were not invoked at all in this verification. The new Jest
test mocks `dashboard.createWhatsAppLink` directly at the API-client boundary, which
proves `WhatsAppUpdateCard.tsx` renders the right copy *given* an `available: false`
response — a legitimate and useful test — but it does not confirm:
- that `MockWhatsAppProvider.is_available()` actually always returns `True` in this
  codebase today (I did **not** re-read `mock.py`/`meta_cloud.py` as part of this
  frontend-scoped verification pass — the Architect's spec already did, and nothing in
  this slice's diff touches those files per `git status`, so no regression there is
  possible, but I did not independently re-confirm their current behavior either),
- that the real `POST /whatsapp/link` endpoint's response shape in a genuinely
  `meta_cloud`-misconfigured environment actually matches what the test hand-constructs,
- or, per the Architect's own explicit risk note, anything about a **staging/Railway**
  environment where `WHATSAPP_PROVIDER=meta_cloud` might realistically be set without full
  credentials — this sandbox has no access to that environment's config at all, so AC2
  cannot be attempted here under any circumstance, not just as a time-saving shortcut.

**My assessment:** this is a **larger gap than S-077's**, because the Architect explicitly
warned "reproducing purely in local dev will only exercise the mock provider... and cannot
reproduce candidate 2 at all" — meaning even a full live local reproduction, if it had been
possible, would not have satisfied AC2 either; only a staging/Railway session with the real
`meta_cloud` env config would. **Recommend PM treat AC2 as an open item requiring either:
(a) a manual pass against the actual staging/Railway environment (outside any agent
sandbox's reach) before Accepted, or (b) an explicit acceptance that the frontend-side
handling of `available: false` is sufficient proof and the backend `is_available()` logic
is covered by existing/prior backend test suites (not verified as part of this report —
PM/Architect should confirm whether `backend/tests/` has coverage for
`MetaCloudWhatsAppProvider.is_available()`'s five-setting requirement).**

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

### New/relevant tests
- `MerchantDashboard.test.tsx`, shared describe block `"MerchantDashboard review QR /
  WhatsApp not-yet-approved messaging (S-077 / S-078)"`:
  - `"shows a 'not approved yet' message (not silent absence) for a pending business"` (candidate 1, AC1)
  - `"shows a clarified not-configured message when the WhatsApp provider is unavailable"` (candidate 2, AC2/AC4) — asserts new copy present, old "ask an admin" copy absent
- `WhatsAppUpdateCard.test.tsx::"shows an unavailable empty state when WhatsApp is not configured"` — updated in place to assert the new copy (`/needs a one-time configuration change/i`) instead of the old copy
- `WhatsAppUpdateCard.test.tsx::"shows QR and wa.me URL for an available mock link"` — pre-existing, unmodified, confirms AC3/AC6 baseline unchanged

---

## Regressions

None found in the automated suite. `git log` confirms no prior commits touched
`WhatsAppUpdateCard.tsx` between introduction (2026-08-16) and this slice, consistent with
the PM's background claim. The "available" render branch (lines 93-111) has zero diff.

---

## Gaps / rework items

1. **Reproduction evidence gap, candidate 1 (AC1)** — identical to TR-S-077's gap; see
   that report. Not a code defect.
2. **Reproduction evidence gap, candidate 2 (AC2)** — larger in scope: not reproducible in
   this sandbox (or in default local dev at all, per the Architect's own note) without a
   `meta_cloud`-configured staging/Railway environment. Only the frontend's handling of the
   `available: false` response shape was verified; the backend `is_available()` config
   check itself was not exercised end-to-end as part of this report.
3. **Backend test coverage for `MetaCloudWhatsAppProvider.is_available()` not verified in
   this pass** — this report is scoped to the frontend diff (`WhatsAppUpdateCard.tsx`,
   `MerchantDashboard.tsx`) per the assignment; PM/Architect should confirm separately
   whether `backend/tests/` already covers the five-setting requirement (out of scope for
   this slice's diff regardless, since no backend files changed).
4. **README §6/§12 not updated** — same note as TR-S-077; arguably N/A for a messaging-only
   bug fix, flagging for PM's DoD checklist.

---

## Sign-off

- [x] All AC mapped (6/6), 4 pass cleanly, 2 flagged as unresolved evidence gaps (not code
      defects)
- [x] RBAC — N/A per Architect spec (confirmed UI gate + provider-config check, neither an
      auth boundary; no new endpoint)
- [x] AI disclaimer — N/A, no AI content in this slice (per its own UX notes)
- [ ] **Not fully ready for PM acceptance without a PM decision on both reproduction
      gaps** above — code itself is correct and tested at the frontend layer; open items
      are evidence-standard/environment-access gaps, not bugs.
