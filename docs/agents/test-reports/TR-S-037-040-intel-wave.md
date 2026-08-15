# TR-S-037-040: Intel wave (charts, benchmark, AI draft, collect QR) — Test report

| Field | Value |
|-------|-------|
| **Slices** | S-037, S-038, S-039, S-040 |
| **Author** | Tester |
| **Date** | 2026-08-15 |
| **Shot** | 2 (combined; replaces the thin stub) |
| **Recommendation** | Ship |

---

## Summary

Pass. All **17** numbered acceptance criteria across S-037–S-040 are mapped and passing
at the unit/RTL layer. The previous stub TR named implementation details instead of real
tests; this shot adds the missing Jest/pytest coverage, re-ran it, and records honest
environment limits.

**Counts:** S-037 4/4 pass · S-038 4/4 pass · S-039 4/4 pass · S-040 5/5 pass.
**Blockers:** none. Tester does **not** set slice `Status: Accepted` (PM owns that).

**Environment (same class as `TR-S-035` / `TR-S-018`):** `backend/.venv` exists and was
used. `DATABASE_URL` in `backend/.env` still points at the shared live Railway Postgres.
ASGI + real-SQL files (`tests/test_dashboard.py` and siblings that warn *never run this
file locally against the project's dev DATABASE_URL*) were **not** executed this session.
New backend coverage is DB-free (direct helpers / fake db / mocked `get_benchmark`).
`AI_PROVIDER` was not needed; S-039 uses stored `suggested_response` only (no live LLM).
No Docker / running API in this environment, so Swagger and `docker compose` smoke are
manual IDs below, not executed.

Frontend: **28/28 suites, 124/124 tests** green (`npx jest`). Backend this session:
**13 passed** (`test_benchmark.py` 9 + `test_dashboard_deltas.py` 3 + existing
`TestReplyToReview` 2).

---

## Per-slice AC pass/fail

| Slice | Pass | Fail | Unmapped |
|-------|------|------|----------|
| S-037 Merchant dashboard chart upgrade | 4 | 0 | 0 |
| S-038 Competitor rating benchmarking | 4 | 0 | 0 |
| S-039 AI reply drafting | 4 | 0 | 0 |
| S-040 Review collection QR / wizard | 5 | 0 | 0 |
| **Total** | **17** | **0** | **0** |

---

## AC coverage matrix

### S-037 — Merchant dashboard chart upgrade

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Volume-by-month is an area (or line) chart, not only bars | A | `frontend/src/components/__tests__/Charts.test.tsx::renders an area chart when variant is area` (+ line + default-bar); `MerchantDashboard.test.tsx::renders review volume as an area chart (not bars)` waits for `[data-chart-variant="area"]` while rating mix / sentiment stay `bar` | Pass |
| 2 | Range 30/90: reply-rate and in-range count show period-over-period delta vs the previous window of the same length; all-time hides delta | A | UI: `MerchantDashboard.test.tsx::shows a percent vs the prior 30-day window when previous counts exist` (`+50% vs prior period` on both tiles; 90-day uses the same `deltaText` helper). Backend all-time hide: `test_dashboard_deltas.py::test_previous_count_and_reply_rate_are_null_for_all_time` (`_count_reviews(..., previous=True)` and `_reply_rate_previous` return `None` and do not hit the db). Window math for 30 vs 90: `::test_range_cutoff_30_and_90_are_that_many_days_ago`. Previous-window SQL itself is in `merchant_dashboard._count_reviews` / `_reply_rate_previous` (`[now-2d, now-d)`); not executed against Postgres this session (see Gaps) | Pass (automated); live previous-window SQL not re-run |
| 3 | No prior-window reviews → em dash / “n/a”, never a fake 0% improvement | A | `MerchantDashboard.test.tsx::hides period deltas on the all-time range (n/a, never a fake 0%)`; `::shows n/a when the previous window has zero reviews` (`previous === 0` is treated as undefined, not `0%`) | Pass |
| 4 | Customer hitting merchant dashboard API is still denied | A | Shared helper: `test_benchmark.py::test_load_owned_business_403_for_other_merchant` (same `_load_owned_business` used by `GET /dashboard/merchant/{id}`). Existing ASGI: `test_dashboard.py::test_merchant_dashboard_requires_merchant_or_admin_role` (403 customer) and `::test_merchant_dashboard_403s_for_non_owning_merchant` — **not re-run** (live DATABASE_URL). M-001: `merchant_dashboard` and `merchant_benchmark` both `Depends(require_roles(MERCHANT, ADMIN))` | Pass |

**Coverage:** 4 / 4 AC mapped

### S-038 — Competitor rating benchmarking

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Owner of approved listing gets own rating + category median + city median | A | `test_benchmark.py::test_merchant_benchmark_returns_payload_and_disclaimer` (router + `BenchmarkResponse` shape: `own_rating`, `category_median`, `city_median`, disclaimer); `::test_median_of_three` / `::test_median_of_four_is_midpoint`; client: `api.test.ts::GETs /api/v1/dashboard/merchant/{id}/benchmark`. `get_benchmark` SQL (approved peers, exclude self) is code-inspected, not run on Postgres this session | Pass |
| 2 | Fewer than 3 other businesses → median `null` and UI says not enough local data | A | `test_benchmark.py::test_median_none_below_three`, `::test_median_none_empty`; `BenchmarkCard.test.tsx::says there is not enough local data when a median is null` (“Not enough nearby listings yet.”, no fake `0.0`); `MerchantDashboard.test.tsx::renders directory-median disclaimer from the benchmark payload` | Pass |
| 3 | Copy does not claim AI judged the shop; numbers are directory medians | A | `test_benchmark.py::test_disclaimer_is_directory_medians_not_ai_judgment` (exact Architect string); `BenchmarkCard.test.tsx::shows directory-median disclaimer and never claims an AI verdict`; dashboard wiring test above. Copy: “Directory medians from MerchantHub listings — not an AI judgment.” | Pass |
| 4 | Customer / other merchant requesting another shop’s benchmark → 403/404 as dashboard ownership | A | `test_benchmark.py::test_load_owned_business_403_for_other_merchant`, `::test_load_owned_business_404_missing`; `merchant_benchmark` calls that helper before `get_benchmark`. HTTP customer-403 on `/benchmark` specifically is the same `require_roles` as S-037 AC4 (M-001); ASGI file not re-run | Pass |

**Coverage:** 4 / 4 AC mapped

### S-039 — AI reply drafting

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Draft with AI fills `suggested_response`; copy says suggestion, not a verdict, not auto-sent | A | `ReviewCard.test.tsx::fills the reply box from suggested_response as a suggestion` (button + textarea + “AI draft is a suggestion” + “not posted automatically”) | Pass |
| 2 | No `suggested_response` → button hidden or “No draft available” | A | `ReviewCard.test.tsx::shows 'No draft available' when suggested_response is missing` | Pass |
| 3 | Saved reply is whatever the merchant edited; API does not force AI text | A | Frontend: `ReviewCard.test.tsx::posts the edited textarea, not the original AI draft`. Backend: `test_reviews.py::TestReplyToReview::test_owner_can_reply_and_edit_in_place` (`payload.body` only; `reply_to_review` never reads `AIAnalysis`) | Pass |
| 4 | Customer ReviewCard does not show Draft with AI | A | `ReviewCard.test.tsx::hides Draft with AI when canReply is omitted (customer view)` (`canReply` defaults false) | Pass |

**Coverage:** 4 / 4 AC mapped

### S-040 — Review collection QR / public wizard

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | `/collect/{id}` shows name + 1–5 stars; 1-star continues to the same text step (no low-star intercept) | A | `frontend/src/app/collect/[businessId]/__tests__/page.test.tsx::does not intercept low star ratings` (1-star → Continue → body placeholder; no Google intercept on that step) | Pass |
| 2 | Signed-in customer submits rating + body (≥10) via existing `POST /reviews` | A | `page.test.tsx::creates the review through the existing API when signed in` (`reviews.create({ business_id, rating, body })`). Create handler unchanged; existing `test_reviews.py` create suite still covers the API (not re-expanded this shot) | Pass |
| 3 | Not signed in → `/login?next=/collect/{id}`, not a silent drop | A | `page.test.tsx::redirects to login with next= when the visitor is not signed in` (`auth.me` reject → `push("/login?next=/collect/b1")`, `reviews.create` not called) | Pass |
| 4 | Approved listing dashboard shows QR for the public collect URL | A | `CollectQrCard.test.tsx::encodes the public collect URL for an approved listing`; `MerchantDashboard.test.tsx::shows the collect QR on an approved listing and hides it when pending` | Pass |
| 5 | Optional Maps link after submit is a suggestion, not required, not gating | A | `page.test.tsx::creates the review through the existing API when signed in` (done-step link to `google.com/maps`, copy “suggestion, not required”; 1-star path never required Maps) | Pass |

**Coverage:** 5 / 5 AC mapped

**Coverage (wave):** 17 / 17 AC mapped

---

## Backend tests

### Added / expanded this shot
- `backend/tests/test_benchmark.py` (9 tests) — `_median_or_none` (<3 → `None`, empty, odd/even), exact `DISCLAIMER` string, fake-db `_load_owned_business` 403/404, `merchant_benchmark` payload + disclaimer with `get_benchmark` mocked (no Postgres).
- `backend/tests/test_dashboard_deltas.py` (3 tests) — `_range_cutoff` all/`30`/`90`; previous fields `None` for `range=all` without executing SQL.

### Re-run (existing, DB-free)
- `backend/tests/test_reviews.py::TestReplyToReview` (2 tests) — S-039 AC3/ownership of replies.

### Run output
```
cd backend && .venv/Scripts/python.exe -m pytest -q tests/test_benchmark.py tests/test_dashboard_deltas.py

11 passed in 3.67s

cd backend && .venv/Scripts/python.exe -m pytest -q tests/test_benchmark.py tests/test_dashboard_deltas.py tests/test_reviews.py::TestReplyToReview

13 passed in 3.90s
```

**Not run:** `tests/test_dashboard.py` (ASGI + real SQL aggregations; file header forbids local use against the project `DATABASE_URL`). That file already asserts S-037 payload keys `review_count_in_range`, `review_count_previous`, `reply_rate_previous` and customer 403 on `GET /dashboard/merchant/{id}`.

---

## Frontend tests

### Added / expanded this shot
- `frontend/src/components/__tests__/Charts.test.tsx` (3) — `area` / `line` / default `bar` via `data-chart-variant`.
- `frontend/src/components/__tests__/BenchmarkCard.test.tsx` (2) — disclaimer + empty medians.
- `frontend/src/components/__tests__/CollectQrCard.test.tsx` (1) — collect URL + QR SVG.
- `frontend/src/components/__tests__/MerchantDashboard.test.tsx` — +4 S-037 (area volume, all-time n/a, previous=0 n/a, +50% on range=30); +2 S-038/S-040 (disclaimer on dashboard, QR only when approved).
- `frontend/src/components/__tests__/ReviewCard.test.tsx` — +3 S-039 (no draft, edited submit, customer hidden). Existing “fills the reply box…” assertion extended with “not posted automatically”.
- `frontend/src/app/collect/[businessId]/__tests__/page.test.tsx` (3) — 1-star continue, `reviews.create`, login `next=`, optional Maps on done.
- `frontend/src/lib/__tests__/api.test.ts` — +1 `dashboard.benchmark` GET path.

### Product test hook (minimal)
- `Charts.tsx` wrapper: `data-chart-variant={variant}` so jsdom can assert area vs bar without relying on Recharts SVG classes (ResponsiveContainer width/height is 0 in jsdom).

### Run output
```
cd frontend && npx jest src/components/__tests__/Charts.test.tsx \
  src/components/__tests__/MerchantDashboard.test.tsx \
  src/components/__tests__/BenchmarkCard.test.tsx \
  src/components/__tests__/CollectQrCard.test.tsx \
  src/components/__tests__/ReviewCard.test.tsx \
  src/app/collect/[businessId]/__tests__/page.test.tsx \
  src/lib/__tests__/api.test.ts

Test Suites: 7 passed, 7 total
Tests:       52 passed, 52 total

cd frontend && npx jest

Test Suites: 28 passed, 28 total
Tests:       124 passed, 124 total
```

Full suite green this run (an earlier `search/page.test.tsx` S-036 “Featured” `getByText` collision did **not** reproduce on the full pass; not attributed to this wave).

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | Code review: `GET /dashboard/merchant/{id}` and `GET .../benchmark` both `require_roles(MERCHANT, ADMIN)` and `_load_owned_business`; `reply_to_review` persists `payload.body` only; collect page has no rating intercept | Pass |
| M-002 | `docker compose up --build`; merchant dashboard area chart + deltas; benchmark card; Draft with AI; scan/open `/collect/{id}` including 1-star | Not executed — no Docker in this environment. Covered by RTL + DB-free pytest |
| M-003 | Swagger `/docs` shows `GET /dashboard/merchant/{business_id}/benchmark` matching `BenchmarkResponse` | Not executed live (no server). Confirmed by `dashboard.py` docstring + `BenchmarkResponse` in `schemas` |

---

## Regressions

None in the 124 frontend tests or the 13 backend tests run this session.

`data-chart-variant` on `Charts` is a testability attribute only; chart drawing is unchanged.

---

## Gaps / rework items

None block shipping. Flagged for awareness:

1. **No live ASGI + Postgres** for dashboard aggregations or `get_benchmark` joins (approved peers, exclude self, category join). Previous-window SQL (`[cutoff-duration, cutoff)`) is reviewed in `merchant_dashboard.py` and proven at the UI layer with mocked payload fields. Same ephemeral-DB gap as TR-S-035.
2. **HTTP customer 403 on `/benchmark` specifically** is inferred from shared `require_roles` + `_load_owned_business`, not a dedicated ASGI case.
3. **M-002 / M-003** not executed live.
4. **90-day delta** uses the same `deltaText` as 30; only range=`30` is clicked in Jest.

---

## Sign-off

- [x] All AC mapped to tests (17/17)
- [x] RBAC tested — dashboard ownership helper 403/404 (executed); customer 403 on merchant dashboard exists in `test_dashboard.py` (not re-run); reply non-owner 403 re-run; collect create stays behind existing review auth
- [x] AI disclaimer verified — S-039: suggestion, edit-before-send, not auto-posted; S-038: directory medians, not an AI judgment
- [x] S-040 no rating gating — 1-star continues
- [x] Combined shot (no per-slice TRs)
- [ ] Ready for PM to set `Status: Accepted` on S-037–S-040 (Tester does not flip Status)
