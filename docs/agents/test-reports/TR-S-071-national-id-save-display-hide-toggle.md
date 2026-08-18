# TR-S-071: Fix National ID save/display + hide-by-default toggle — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-071 |
| **Author** | Tester |
| **Date** | 2026-08-18 |
| **Recommendation** | Ship |

---

## Summary

**Pass.** `MerchantNationalIdCard.tsx` implements exactly the fix the Architect
specified: local `nationalIdType`/`nationalIdNumber`/`revealed` state is resynced via a
`useCallback`-wrapped `applyUser(u)` invoked from a `useEffect([user, applyUser])`, not a
one-time `useState` initializer — matching `ProfilePage.tsx`'s established pattern. A
client-side `maskNationalId()` helper (last-4-visible, `••••1234`-style) masks the number
by default; a "Show"/"Hide" toggle button (`revealed` state, local-only, never persisted)
flips visibility. `applyUser` explicitly resets `revealed` to `false` on every resync,
which covers both AC1/AC2 (fresh value after save/refetch) and AC5 (reveal state doesn't
survive a prop update or remount) in one code path.

Note: this component has since been extended by S-070 (Aadhaar mock-OTP verification
sub-step, landed concurrently on this branch) — the masking/reveal/resync logic this
slice (S-071) owns is unchanged by that addition and composes cleanly with it, as the
Architect's own risk note anticipated.

Full frontend suite: **238/238 passing**, 46/46 suites.

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Card resyncs from the updated `user` prop after a successful save (not a one-time `useState` initializer) | A | `frontend/src/components/__tests__/MerchantNationalIdCard.test.tsx::"resyncs the displayed value and re-hides when the user prop changes after mount"` (asserts a `rerender` with a new `user` prop updates the displayed masked value) | Pass |
| 2 | Reload/navigate-away-and-back shows the latest saved value, not stale/empty | A | Same test as AC1 (a prop-driven rerender models the parent handing down a freshly-refetched `user` after remount); `frontend/src/components/__tests__/MerchantDashboard.test.tsx` (existing suite) exercises the parent's `setUser`/refetch flow that feeds this prop | Pass |
| 3 | National ID hidden/masked by default when the card first shows a saved value | A | `MerchantNationalIdCard.test.tsx::"masks a saved national ID by default"` — asserts the input value is not the raw plaintext, contains only the last 4 chars, and is `readOnly` | Pass |
| 4 | Reveal toggle shows plaintext; clicking again re-hides | A | `MerchantNationalIdCard.test.tsx::"reveals the full value on toggle click, and re-hides on a second click"` | Pass |
| 5 | Reveal state does not persist across navigation/remount — resets to hidden | A | `MerchantNationalIdCard.test.tsx::"starts hidden again on a fresh mount, regardless of prior reveal state"` (remount case) and `"...resyncs the displayed value and re-hides..."` (prop-update case) — both paths covered since `applyUser` resets `revealed` in either | Pass |
| 6 | Never-saved national ID → existing S-043 empty state, no reveal toggle | A | `MerchantNationalIdCard.test.tsx::"shows no reveal/hide toggle when there is nothing to reveal"` plus the pre-existing `"prompts merchants who have no ID..."` test asserting the empty-state copy is still shown | Pass |
| 7 | No regression to other fields'/nearby cards' resync behavior | A (existing, regression) | Full suite run (238/238) including `MerchantDashboard.test.tsx`'s full existing coverage of sibling dashboard cards (analytics, benchmark, collect-QR, Google reviews) — all green after this fix, and the `useEffect([user])` fix is scoped to this one component's own props (code read confirms `MerchantDashboard.tsx`'s own state is untouched) | Pass |

**Coverage:** 7 / 7 AC mapped, all automated.

---

## Backend tests added
None — this slice is frontend-only per its own "Out of scope" (no `PATCH /auth/me`
change); confirmed via code read that `auth.updateMe()`'s call site is unchanged.

## Frontend tests added
- `frontend/src/components/__tests__/MerchantNationalIdCard.test.tsx` (extended existing
  file — pre-existing S-070 tests preserved, 5 new tests added):
  - `"shows no reveal/hide toggle when there is nothing to reveal"`
  - `"masks a saved national ID by default"`
  - `"reveals the full value on toggle click, and re-hides on a second click"`
  - `"resyncs the displayed value and re-hides when the user prop changes after mount"`
  - `"starts hidden again on a fresh mount, regardless of prior reveal state"`

### Fix made during this pass
One test-authoring bug was found and fixed (not a product bug): an initial
`screen.getByLabelText(/national id number/i)` regex over-matched both the number
`<input aria-label="National ID number">` **and** the toggle
`<button aria-label="Reveal/Hide national ID number">` (the regex isn't anchored, so it
matched the button's aria-label too), causing a false "multiple elements found" test
failure. Changed to the exact string `screen.getByLabelText("National ID number")`,
which resolves to the input only. No production code was changed for this.

## Manual checklist

| ID | Check | Result |
|----|-------|--------|
| M-071-01 | Live click-through: merchant saves a national ID, immediately sees masked value reflected (no refresh needed) | Not run — no live backend reachable in this sandbox; covered by automated resync test above via prop-driven rerender, which models the same `onSaved → setUser → new prop` chain. |
| M-071-02 | Live click-through: merchant reloads the dashboard page after saving, sees the same masked value (not stale/empty) | Not run — same environment limitation; covered by code read of `MerchantDashboard.tsx`'s `auth.me()` refetch-on-mount feeding the same prop path. |

---

## Regressions / gaps

None found. Full suite green (238/238), no test removed or weakened.

## Recommendation

**Ship.** All 7 AC automated and passing; the exact root cause described in the slice
(one-time `useState` initializer) is confirmed fixed via `useEffect`/`applyUser`, matching
the `ProfilePage.tsx` reference pattern.
