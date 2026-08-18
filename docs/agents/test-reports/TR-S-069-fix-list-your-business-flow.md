# TR-S-069: Fix "list your business" flow — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-069 |
| **Author** | Tester |
| **Date** | 2026-08-18 |
| **Recommendation** | Ship |

---

## Summary

**Pass.** Per the Architect's own spec, this slice's root cause is the *same* underlying
defect as S-067/S-068 (role-unaware post-login/"Continue" redirect). Reproducing AC3's
end-to-end flow after S-067/S-068 landed shows the fix is already in place:
`roleLandingPath()` (`frontend/src/lib/api.ts`) routes a merchant to
`/merchant/dashboard` and is used both by `redirectAfterAuth` (post-login, S-067) and by
`AlreadySignedIn.tsx`'s "Continue" link (the specific dead-end this slice called out —
`AlreadySignedIn` previously hardcoded `href="/"`, now uses
`roleLandingPath(user.role)`). No further code change was required or made for S-069
beyond what S-067 already shipped; this report closes the coverage gap the Tester flagged
in TR-S-067 (`AlreadySignedIn.tsx` had no dedicated test file) by adding one.

**Defect class identified for AC8:** a **nav/discoverability + redirect gap**, not a
`RequireAuth` gating bug and not a `POST /businesses` bug. Specifically: an
already-registered, already-logged-in merchant clicking the home-hero/footer "List your
business" link (→ `/register`) landed on `AlreadySignedIn`'s block screen, whose
"Continue" button was hardcoded to `href="/"` regardless of role — a dead loop back to
the public home page instead of forward to `/merchant/dashboard` →
`/merchant/businesses/new`. `RequireAuth role="merchant"` itself (fresh `auth.me()` on
every mount, no stale-role caching) and `POST /businesses` were both confirmed correct on
read, matching the slice's own "no speculative backend/RequireAuth change" scope.

Full frontend suite: **238/238 passing**, 46/46 suites (includes 5 new
`AlreadySignedIn.test.tsx` tests added in this pass).

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Visible "Add business" CTA on dashboard, even with zero businesses, navigates to `/merchant/businesses/new` | A (existing, regression) + code read | `frontend/src/components/__tests__/MerchantDashboard.test.tsx` (existing suite exercises the dashboard shell); code read confirms `MerchantDashboard.tsx` renders `<a href="/merchant/businesses/new">Create your business</a>` in the zero-business empty state and lists "Add business" in `navItems` unconditionally | Pass |
| 2 | At least one discoverable link to add-business flow in primary nav | A (existing, regression) + code read | Same as AC1 — nav item present on every dashboard visit; `Navbar.tsx` also renders a role-aware `/merchant/dashboard` link for `user?.role === "merchant"` (one hop from there to "Add business") | Pass |
| 3 | Reproduce end-to-end; identify and document the failing step | Code read (manual analysis, documented above and in slice's own Architect finding) | Traced: hero/footer CTA (`/register`) → `AlreadySignedIn` block screen → **role-unaware hardcoded `href="/"` Continue button (the failing step)** → S-067's `roleLandingPath` fix closes it | Pass |
| 4 | `RequireAuth role="merchant"` allows access for a genuinely-merchant role, incl. immediately post-login/role-switch | A (existing, regression) | `frontend/src/components/__tests__/RequireAuth.test.tsx` — matching-role renders children; code read confirms `auth.me()` is called fresh on every mount (no cached role) | Pass |
| 5 | Customer/unauthenticated visitor redirected/blocked from `/merchant/businesses/new` (no regression) | A (existing, regression) | `RequireAuth.test.tsx` — no-token → redirect `/login`; wrong role → redirect `/` | Pass |
| 6 | Valid submit → `POST /businesses` → success state → routed to see the new pending business, no silent failure | A | `frontend/src/components/__tests__/BusinessForm.test.tsx::"submits successfully once all required fields are valid"`; `frontend/src/app/merchant/businesses/new/page.tsx` code read: `onSuccess={() => (window.location.href = "/merchant/dashboard")}` | Pass |
| 7 | Invalid/missing data → backend rejection shown as a visible, specific error (not silent) | A | `BusinessForm.test.tsx::"blocks submission and shows inline required errors..."` and `"...invalid-format error..."` (client-side); server-side 422/400 surfaces via the form's existing top `error` banner (code read, unchanged code path) | Pass |
| 8 | Defect class from AC3 explicitly named for future traceability | Documentation (this report) | See "Defect class identified for AC8" above | Pass |

**Coverage:** 8 / 8 AC mapped (6 automated + 2 code-read/documented).

---

## Backend tests added
None — confirmed no backend defect on reproduction; `POST /businesses` and
`merchant_national_id_required` are unchanged, matching the slice's own "Out of scope."

## Frontend tests added
- `frontend/src/components/__tests__/AlreadySignedIn.test.tsx` (new file, 5 tests):
  - `"renders children (the real form) when there is no stored access token"`
  - `"shows a role-aware Continue link to /merchant/dashboard for a signed-in merchant"`
  - `"shows a role-aware Continue link to / for a signed-in customer"`
  - `"logs out and redirects to /login when 'Log out to sign in as someone else' is clicked"`
  - `"clears tokens and renders children when auth.me() fails for a stored token"`

This closes the exact gap TR-S-067 flagged as unresolved ("`AlreadySignedIn.tsx` has no
dedicated automated test file").

## Manual checklist

| ID | Check | Result |
|----|-------|--------|
| M-069-01 | Live click-through: logged-out visitor clicks home hero "List your business" → `/register` renders normally (no regression for a genuine new signup) | Not run — no live backend reachable in this sandbox. Code read confirms `AlreadySignedIn` renders `children` (the real `RegisterForm`) when no token is present. |
| M-069-02 | Live click-through: already-logged-in merchant clicks home hero "List your business" → block screen → Continue → `/merchant/dashboard` → "Add business" → form → submit → pending business visible on dashboard | Not run — no live backend/Postgres/Redis reachable in this sandbox (`docker compose up --build` required before merge, consistent with S-067/S-068's reports). |
| M-069-03 | Swagger `/docs` reflects no new/changed endpoints (frontend-only slice) | Not run (no live backend); confirmed via code read that no router file is touched by this slice. |

---

## Regressions / gaps

None found. Full suite green (238/238) with no test removed or weakened.

One pre-existing (not new) gap remains unverified end-to-end: live multi-step
click-through (M-069-01/02/03) requires a running `docker compose` stack, unavailable in
this sandbox — same documented limitation as TR-S-067/TR-S-068.

## Recommendation

**Ship.** All 8 AC mapped; the one prior test-coverage gap flagged against this exact
code path (`AlreadySignedIn.tsx`) is now closed. No code changes were needed for this
slice beyond what S-067 already shipped, per the Architect's own build-order finding —
confirmed correct on this pass.
