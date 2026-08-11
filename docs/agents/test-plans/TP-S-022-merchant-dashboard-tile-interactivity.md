# TP-S-022: Merchant dashboard tile interactivity — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-022 |
| **Author** | Tester |
| **Date** | 2026-08-11 |

---

## Scope

`MerchantDashboardPage` (`frontend/src/components/MerchantDashboard.tsx`) — the three
stat tiles in the `grid gap-4 sm:grid-cols-3` block ("Total reviews", "Average rating",
"Status") becoming interactive (`<button>` scroll-to-section / `<a>` navigation) instead
of static, inert `<div>`s. Pure frontend, no new API, no backend surface — see slice
technical spec (§ API contract: "No new or modified endpoint").

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Frontend | Jest + RTL | Tile markup (button/link roles), click → scroll target, click → href, selector-driven href updates, zero-reviews empty state |
| Backend | n/a | No backend change in this slice (existing `GET /dashboard/merchant/{business_id}` unchanged) |
| Manual | n/a | No new network calls, sections, or routes — nothing new to smoke-test beyond what RTL already covers; role-gating (AC7) is an explicit no-code-change regression check |

No isolated local Postgres/Docker is available in this environment, but that constraint
is irrelevant here: this slice has zero backend surface, so no pytest run (live or
otherwise) is needed or attempted.

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1. "Total reviews" tile is an interactive element (`<button>`), not a static `<div>` | Automated | `MerchantDashboard.test.tsx::"renders 'Total reviews' as a button that scrolls to #recent-reviews on click"` (asserts `tagName === "BUTTON"`); same button-role check reused for "Average rating" |
| 2. Clicking "Total reviews" scrolls to the existing "Recent reviews" section | Automated | `MerchantDashboard.test.tsx::"renders 'Total reviews' as a button that scrolls to #recent-reviews on click"` |
| 3. Clicking "Average rating" scrolls to the "Sentiment breakdown" chart section | Automated | `MerchantDashboard.test.tsx::"renders 'Average rating' as a button that scrolls to #sentiment-breakdown on click"` |
| 4. Clicking "Status" navigates to edit page (pending/rejected/suspended) or public profile (approved) | Automated | `MerchantDashboard.test.tsx::"links the 'Status' tile to the public profile when the business is approved"`, `"...to the edit page when the business is pending"`, `"...to the edit page when the business is suspended"` |
| 5. Switching the business selector updates all three tiles' click targets to the newly selected business | Automated | `MerchantDashboard.test.tsx::"updates the Status tile's href when the business selector changes"` (Status href asserted directly; the two scroll tiles' targets are static section ids `#recent-reviews`/`#sentiment-breakdown` that don't vary by business, so no separate assertion needed for those two — see Edge cases) |
| 6. Zero-reviews / single-business case: clicking "Total reviews" still lands on the existing "No reviews yet." empty state, no crash | Automated | `MerchantDashboard.test.tsx::"shows the existing empty state under #recent-reviews and does not crash when clicked, for a business with zero reviews"` |
| 7. Role-gating for `/merchant/dashboard` is unchanged (no regression) | No new test (code-review) | `RequireAuth` wraps `MerchantDashboardPage` at the page level (`frontend/src/app/merchant/dashboard/page.tsx`), untouched by this slice; existing `RequireAuth.test.tsx` coverage already applies unchanged |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| n/a — this slice makes no RBAC change | — | `RequireAuth role="merchant"` in `frontend/src/app/merchant/dashboard/page.tsx` is untouched; `MerchantDashboard.tsx` itself has never done its own role check. Existing `RequireAuth.test.tsx` (unauthenticated → `/login`, wrong role → `/`) already covers this and was re-run as part of the full suite with no regressions. |

---

## Edge cases

- Zero reviews (AC6) — covered.
- Only one owned business (no selector rendered) — covered implicitly by every
  single-business test in this plan (`mineMock.mockResolvedValue([business])`); the
  component only renders the `<Select>` when `owned.length > 1`.
- Multiple owned businesses, selector switch (AC5) — covered for the "Status" tile's
  href. The two scroll-tiles' targets (`scrollToSection("recent-reviews")` /
  `scrollToSection("sentiment-breakdown")`) are hardcoded section ids, not
  business-derived — they cannot go stale on business switch by construction (same
  section renders lower on the page regardless of which business is selected; only the
  *content* inside those sections re-renders, which is out of scope for this
  interactivity-only slice). No separate scroll-target-after-switch test is needed for
  those two tiles.
- `status` values: "approved" vs. "pending" vs. "suspended" both exercised for AC4's
  ternary (the fourth possible value, "rejected", takes the same code branch as
  "pending"/"suspended" — not separately tested, same ternary condition).

---

## Manual checklist (if applicable)

None required for this pass — no new network calls, no new backend routes, no new
pages/sections. The only screen touched (`/merchant/dashboard`) is fully covered by
RTL component tests above. (Contrast with S-018/S-019/S-020, which needed manual
Docker checklists for full-stack round trips — this slice has no full-stack surface.)

---

## Environment

- `AI_PROVIDER=mock` — n/a, no AI-provider code touched by this slice.
- `docker compose up --build` — not needed; no backend/API change, no live-browser
  E2E possible or required in this environment (no isolated DB, no CORS-approved
  local origin) — see slice/session environment notes. Fully covered by Jest + RTL.
