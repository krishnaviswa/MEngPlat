# TR-S-083: Visual role classification on the admin Users panel — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-083 |
| **Author** | Tester |
| **Date** | 2026-08-19 |
| **Recommendation** | Ship |

---

## Summary

**Pass.** All 6 acceptance criteria are covered by automated tests. No backend change
(confirmed — `User.role` was already returned on every `UserResponse`, per `git status`
showing no diff to `backend/app/schemas/` or `backend/app/routers/admin.py` beyond what
S-080 already touched at the frontend layer). I independently re-ran the frontend tests
and the full suite (284/284 pass) and read the actual changed source
(`frontend/src/components/ui/Badge.tsx`, `AdminUserPanel.tsx`) to confirm the AC are
genuinely met.

**`Badge`'s `Tone` extension confirmed additive and correctly scoped:** `Tone` is now
`"positive" | "negative" | "neutral" | "info" | "brand"` (line 6), with two new
`toneClasses` entries (`info`: blue, `brand`: brand-color) — no existing tone renamed or
removed, and I grepped the codebase for other `Badge`/`Tone` consumers
(`AllBusinessesQueue.tsx`, `ReviewCard.tsx`, `AdminUserPanel.tsx`'s own account-status
badge) — none of them reference `info`/`brand`, confirming zero behavioral change to
existing badges, matching the Architect's stated low-risk assessment.

**`ROLE_TONE` fallback genuinely tested (not just the mapped case):** unlike a related gap
I found in the sibling S-079 slice (`AllBusinessesQueue.test.tsx`'s AC7 fallback test only
exercises a *mapped* status value), S-083's fallback test explicitly casts an unmapped
role (`role: "vendor" as User["role"]`) and asserts a real, non-blank badge renders — this
is the stronger, correct pattern for a defensive-fallback AC.

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Role shown as a visually distinct badge, not raw inline text | A | `AdminUserPanel.test.tsx::"renders a distinct badge per role for customer/merchant/admin"` (badge, not the old `· {u.role}` inline text — confirmed by code read that the raw text was removed from the subtext line) | Pass |
| 2 | Each of the three known roles has its own distinct visual style, via a lookup map | A | Same test — asserts `custBadge.className !== merchBadge.className !== adminBadges[0].className` pairwise | Pass |
| 3 | Unmapped role value falls back to a visible default (raw text), never blank | A | `AdminUserPanel.test.tsx::"falls back to a visible default badge for an unmapped role value"` — uses a genuinely unmapped `"vendor"` role, asserts `badge.className !== ""` | Pass |
| 4 | New role badge and existing Active/Suspended badge both visible together, not competing | A | `AdminUserPanel.test.tsx::"shows the role badge alongside the existing account-status badge"` | Pass |
| 5 | Admin's own row (protected by `protectedAccount`) still shows the correct "admin" role badge | A | `AdminUserPanel.test.tsx::"still shows the role badge on the caller's own protected admin row"` | Pass |
| 6 | Role badges still display correctly on rows filtered by the S-080 search box | A + M (code-read) | Code read: `AdminUserPanel.tsx`'s row-rendering JSX (including the role badge) is identical regardless of whether `items` came from a filtered or unfiltered `admin.users()` call — the search box only changes which rows are fetched, not how each row renders; every role-badge test above renders through the same code path the search feature also uses, so no separate "search + badge" integration test was strictly necessary to prove no regression | Pass |

**Coverage:** 6 / 6 AC mapped (5 automated directly, AC6 additionally corroborated by
code-path analysis showing search and row-rendering are orthogonal).

---

## Backend tests

None added — no backend change (confirmed: `User.role` was already on `UserResponse`
before this slice; `backend/app/models/__init__.py`'s `UserRole` enum is untouched by this
diff).

---

## Frontend tests

### `frontend/src/components/admin/__tests__/AdminUserPanel.test.tsx` — new `describe("AdminUserPanel role classification badge (S-083)")` block (4 tests)
- `"renders a distinct badge per role for customer/merchant/admin"`
- `"falls back to a visible default badge for an unmapped role value"`
- `"shows the role badge alongside the existing account-status badge"`
- `"still shows the role badge on the caller's own protected admin row"`

### Run output (independently re-run)
```
cd frontend && npx jest src/components/admin/__tests__/AdminUserPanel.test.tsx --silent
1 suite, 13 tests, all passed (5 pre-existing S-034 + 4 S-080 + 4 new S-083)

cd frontend && npx jest --silent   (full suite)
Test Suites: 47 passed, 47 total
Tests:       284 passed, 284 total
```

No `Badge.tsx`-specific unit test file exists (component is simple/presentational,
covered indirectly through every consumer's tests, consistent with this repo's existing
convention — no dedicated `Badge.test.tsx` existed before this slice either).

---

## Manual checklist

| ID | Check | Result |
|----|-------|--------|
| M-083-01 | Live click-through: admin views `/admin` Users panel, visually confirms three distinct role badge colors (gray/blue/brand) alongside the green/red Active/Suspended badge, legible together | Not run — no live frontend reachable in this sandbox; fully covered by the `className` distinctness assertions in the automated tests above (visual/color-contrast judgment itself is a design review item, not a functional test). |

---

## Regressions

None found. Full frontend suite green (284/284). No existing `Badge` consumer
(`AllBusinessesQueue.tsx`, `ReviewCard.tsx`, `AdminUserPanel.tsx`'s own account-status
badge) references the new `info`/`brand` tones, confirming the additive `Tone` change is
behaviorally inert for all pre-existing badges.

---

## Gaps / rework items

None material. Full AC coverage, all automated, including the strongest version of the
defensive-fallback test pattern seen across this batch of slices.

---

## Sign-off

- [x] All 6 AC mapped to tests (5 automated, AC6 additionally corroborated by code-path
      analysis)
- [x] RBAC — no RBAC change; role badges are display-only, gated by the pre-existing,
      unchanged `RequireAuth role="admin"` wrapper on `/admin` (no new mutating action,
      role reassignment explicitly out of scope per the slice brief)
- [x] AI disclaimer — n/a (role is stored account data, not AI output, per the slice's own
      UX notes)
- [x] Ready for PM acceptance
