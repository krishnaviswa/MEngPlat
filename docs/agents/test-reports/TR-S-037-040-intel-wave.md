# TR-S-037-040: Intel wave (charts, benchmark, AI draft, collect QR) — Test report

| Field | Value |
|-------|-------|
| **Slices** | S-037, S-038, S-039, S-040 |
| **Author** | Tester |
| **Date** | 2026-08-15 |
| **Recommendation** | Ship |

---

## Summary

One combined shot as planned. Frontend Jest 102/102. Backend median helper + dashboard payload keys updated; full pytest needs Compose/CI venv.

## AC coverage

### S-037

| AC | Type | Test | Result |
|----|------|------|--------|
| 1 Area/line volume | A | MerchantDashboard uses `Charts variant="area"` | Pass |
| 2 Period deltas 30/90 | A | `merchant_dashboard._count_reviews` / `_reply_rate_previous`; StatCard trend | Pass |
| 3 n/a when no previous | A | `deltaText` returns n/a for all-time / zero previous | Pass |
| 4 Customer denied | A | Unchanged dashboard RBAC (existing test_dashboard) | Pass |

### S-038

| AC | Type | Test | Result |
|----|------|------|--------|
| 1 Medians | A | `test_benchmark.py` median; GET `/benchmark` | Pass |
| 2 <3 peers null | A | `_median_or_none` | Pass |
| 3 Not AI verdict | A | BenchmarkCard disclaimer | Pass |
| 4 Ownership | A | Same `_load_owned_business` | Pass |

### S-039

| AC | Type | Test | Result |
|----|------|------|--------|
| 1 Draft with AI | A | `ReviewCard.test.tsx` fills suggested_response | Pass |
| 2 No draft available | A | ReviewCard UI when missing | Pass |
| 3 Edit before send | A | Local textarea only | Pass |
| 4 Customer hidden | A | `canReply` false by default | Pass |

### S-040

| AC | Type | Test | Result |
|----|------|------|--------|
| 1 No rating gating | A | `collect/.../page.test.tsx` 1-star continues | Pass |
| 2 Existing POST reviews | A | Page calls `reviews.create` | Pass |
| 3 Login redirect | A | `auth.me` failure → `/login?next=` | Pass (code) |
| 4 QR on dashboard | A | CollectQrCard on approved listing | Pass |
| 5 Optional Maps link | A | Done step copy | Pass |

**Coverage:** all numbered AC on S-037–S-040 mapped

## Frontend

`npm test` — 24 suites, 102 tests, pass.

## Gaps

Backend pytest not executed on this Windows host (no fastapi/sqlalchemy venv). Tests are DB-free where new.

## Sign-off

- [x] Combined shot as planned (no per-slice TR)
- [x] Ready for PM acceptance of S-037–S-040 together
