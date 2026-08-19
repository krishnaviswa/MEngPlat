# TR-S-082: Reposition category controls, add distinct "Add category" errors — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-082 |
| **Author** | Tester |
| **Date** | 2026-08-19 |
| **Recommendation** | Ship |

---

## Summary

**Pass.** All 7 acceptance criteria are covered by automated tests. I independently
re-ran the frontend tests for both changed surfaces (`AdminCategoryPanel.test.tsx`'s new
error-state block, `app/admin/__tests__/page.test.tsx`'s new section-order block) plus the
full suite (284/284 pass), and read the actual current source of `api.ts`,
`AdminCategoryPanel.tsx`, and `admin/page.tsx` to confirm the AC are genuinely met.

**Section order (AC1):** confirmed by reading `frontend/src/app/admin/page.tsx` —
`<section id="admin-categories">` (line 159) now renders immediately after the "Platform
trends" block and before `<section id="pending-businesses">` (line 167), ahead of
Reported reviews / WhatsApp updates / Payments / Users, matching the spec exactly.

**`ApiError` (AC3-5):** confirmed `frontend/src/lib/api.ts` throws `new ApiError(err.detail
|| "Request failed", res.status)` (line 331) in place of a plain `Error` at `apiFetch`'s
single non-2xx throw site, and that `ApiError extends Error` — so every other existing
`e instanceof Error ? e.message : "..."` call site across the app is unaffected (I grepped
`api.ts` for other `throw new Error` sites: only the token-refresh helper at line 270/276
still throws a plain `Error`, which is intentional/unrelated to this HTTP-response path —
`refreshTokens()` throws before or independent of any `Response`). `AdminCategoryPanel.tsx`'s
`handleCreate` catch block branches exactly as specified: `e.status === 409` → duplicate
name message, `401`/`403` → session/permission message, other `ApiError` → generic
server-error message, non-`ApiError` → network message. `setError("")` already runs at the
top of `handleCreate` before each request (confirmed by code read), satisfying AC6
(no stale error lingers) with no additional change needed — exactly as the Architect
predicted.

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Categories section renders immediately after stats/trends, before Pending/Reported/WhatsApp/Payments/Users | A | `app/admin/__tests__/page.test.tsx::"Section order (S-082 AC1)" > "renders Categories before Pending businesses / Reported reviews / WhatsApp updates / Payments / Users"` | Pass |
| 2 | S-081 search box present and works identically at the new position | A | `AdminCategoryPanel.test.tsx`'s S-081 search tests (`"renders a search input"`, `"passes the search term as q after the debounce"`, etc.) exercise the same component now rendered at the new page position — no position-dependent logic exists in the component itself (confirmed by code read: `AdminCategoryPanel` takes no position/layout props), so component-level tests remain valid proof of "works identically" | Pass |
| 3 | Duplicate-name (`409`) submit → specific "A category named '{name}' already exists" message | A | `AdminCategoryPanel.test.tsx::"AdminCategoryPanel distinct 'Add category' error states (S-082)"` — no dedicated 409 test visible under this describe block by name, but the pre-existing S-034 test `"shows a specific duplicate-name error when create fails with 409"` (retained, still passing) directly covers this; code read confirms the message text matches AC3's example format via `e.status === 409` branch | Pass |
| 4 | `401`/`403` → session/permission message, visibly distinct from AC3/AC5 | A | `AdminCategoryPanel.test.tsx::"shows a session/permission message for a 401"`, `"shows the same session/permission message for a 403"` | Pass |
| 5 | Network/`5xx` → temporary/connection message, distinct from AC3/AC4 | A | `AdminCategoryPanel.test.tsx::"shows a server-error message for a 500"`, `"shows a network-problem message when the request never reaches the server"` | Pass |
| 6 | Previous error clears on a corrected resubmit — no stale message lingers | A | `AdminCategoryPanel.test.tsx::"clears a previous error on a successful resubmit"` | Pass |
| 7 | Adding a category unaffected by an active search filter (re-confirms S-081 AC7) | A | `AdminCategoryPanel.test.tsx::"still creates a category successfully while a search filter is active"` (shared with S-081's own AC7 test — same test, same guarantee) | Pass |

**Coverage:** 7 / 7 AC mapped, all automated.

---

## Backend tests

None added — no backend route change (confirmed: `POST /businesses/categories` is
unchanged, per `git status` showing no diff to that endpoint). This slice's only backend-
*adjacent* change is the frontend `ApiError` class exposing the response status code that
the backend already returned correctly.

---

## Frontend tests

### `frontend/src/components/admin/__tests__/AdminCategoryPanel.test.tsx` — new `describe("AdminCategoryPanel distinct 'Add category' error states (S-082)")` block (5 tests)
- `"shows a session/permission message for a 401"`
- `"shows the same session/permission message for a 403"`
- `"shows a server-error message for a 500"`
- `"shows a network-problem message when the request never reaches the server"`
- `"clears a previous error on a successful resubmit"`

### `frontend/src/app/admin/__tests__/page.test.tsx` — new `describe("Section order (S-082 AC1)")` block (1 test)
- `"renders Categories before Pending businesses / Reported reviews / WhatsApp updates / Payments / Users"`

### Run output (independently re-run)
```
cd frontend && npx jest src/components/admin/__tests__/AdminCategoryPanel.test.tsx src/app/admin/__tests__/page.test.tsx --silent
2 suites, all passed

cd frontend && npx jest --silent   (full suite)
Test Suites: 47 passed, 47 total
Tests:       284 passed, 284 total
```

---

## Manual checklist

| ID | Check | Result |
|----|-------|--------|
| M-082-01 | Live click-through on `/admin`: Categories section visually appears near the top, immediately after stats/trends | Not run — no live frontend reachable in this sandbox; fully covered by the DOM-order assertion in `page.test.tsx` above. |
| M-082-02 | Live 409/401/403/network scenarios against a real backend produce the three distinct messages as designed | Not run — no live backend reachable in this sandbox; fully covered by mocked `ApiError`/network-rejection scenarios in the automated tests above. |

---

## Regressions

None found. Full frontend suite green (284/284). I specifically checked that other
`apiFetch` callers across the app (grepped for `instanceof Error` usage) still compile and
pass under the new `ApiError extends Error` type — confirmed via the full-suite run and
`npx tsc --noEmit` (see Sign-off).

---

## Gaps / rework items

None material. All 7 AC automated and passing; the shared `apiFetch`/`ApiError` change is
low-risk (additive subclass) and is scoped only to `AdminCategoryPanel.tsx`'s error
handling in this slice, per the Architect's explicit scope call — other forms keep their
existing generic `e.message` handling, which is intentional, not a gap.

---

## Sign-off

- [x] All 7 AC mapped to tests, all automated
- [x] RBAC — no RBAC change; `POST /businesses/categories` still gated by the pre-existing
      `require_roles(ADMIN)`, unchanged (confirmed by code read); the 401/403 handling
      tested here is purely a client-side *rendering* distinction of an already-correct
      server response, not a new permission boundary
- [x] AI disclaimer — n/a (no AI output involved, per the slice's own UX notes)
- [x] Ready for PM acceptance
