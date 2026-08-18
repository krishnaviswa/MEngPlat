# TP-S-063: Mobile dashboard trend chart + period-over-period deltas (parity for M-68)

| Field | Value |
|-------|-------|
| **Slice** | S-063 |
| **Author** | Tester |
| **Date** | 2026-08-18 |

---

## Scope

Verify the 6 numbered AC on `docs/agents/slices/S-063-mobile-dashboard-trend-deltas.md` against
the Builder's mobile-UI-only implementation: `review_volume_chart.dart` (`BarChart` → `LineChart`
+ area fill, same series / keys) and `merchant_dashboard_screen.dart` (`_TrendDelta` on
`replyRateTile` plus a new `reviewCountInRangeTile`). No backend change in scope (Architect
confirmed no gap) — existing dashboard RBAC tests cover AC 5.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Mobile UI | `flutter_test` widget tests | Chart type, empty-state regression, delta badge branches |
| Backend API | existing pytest (no new tests) | Unchanged 403 ownership/role gate (AC 5) |
| Integration | Manual / code inspection | No new route; merchant `/merchant` gate unchanged |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `mobile/test/merchant_dashboard_screen_test.dart::S-063 AC1: review volume chart renders as a LineChart (area/line, not BarChart) when data is present` |
| 2 | Automated | `...::S-063 AC2: delta badge shows +50% up-arrow when current > previous, and -33% down-arrow when current < previous` |
| 3 | Automated | `...::S-063 AC3: "All time" range shows no delta badge at all on either tile (fully absent, not an em dash)` |
| 4 | Automated | `...::S-063 AC4: 30-day range with a null previous window shows an em dash badge (distinct from AC 3's "fully absent")` plus Architect-risk `...::S-063 (Architect Risks): previous == 0 ...` |
| 5 | Automated (existing backend) + code inspection | `backend/tests/test_dashboard.py::test_merchant_dashboard_requires_merchant_or_admin_role` (customer 403), `::test_merchant_dashboard_403s_for_non_owning_merchant` (other merchant 403). Confirm this slice does not add a client-side bypass (`dashboard_repository.dart` / router unchanged). |
| 6 | Automated | `...::S-060/S-063 AC6: review volume chart shows empty-state copy when there is no volume data` (asserts empty copy + neither `BarChart` nor `LineChart`) |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Wrong role | customer | 403 on `GET /api/v1/dashboard/merchant/{id}` |
| Other merchant | merchant (not owner) | 403 |
| Owner | merchant | 200 (existing stats shape, including previous-window fields from S-037) |
| Unauthenticated | none | 401 (existing router/auth, unchanged) |

---

## Edge cases

- AC 3 vs AC 4 must not be conflated: `range=all` hides the badge entirely; `range=30|90` with
  `previous == null` **shows** an em dash (`trendDeltaUndefined`).
- `previous == 0` (real zero, not null) is treated as undefined (em dash), never a fabricated
  percentage — Architect risk, explicit widget test.
- Empty volume series still shows `"No reviews in this range."` (`reviewVolumeChartEmpty`); the
  chart-type upgrade must not render a `LineChart` in that case.

---

## Manual checklist (if applicable)

- [ ] M-001: Code inspection — `LineChart` + `belowBarData: BarAreaData(show: true, ...)` in
      `review_volume_chart.dart`; `_TrendDelta` branches on `range == 'all'` before `previous`.
- [ ] M-002: Confirm `dashboard_repository.dart` and `/merchant` router gate are unmodified.
- [ ] M-003: `flutter analyze` + `flutter test`.
- [ ] M-004: Re-run existing dashboard RBAC pytest (no new backend tests).
- [ ] M-005: `docker compose` / on-device smoke — not required (no new native channel).

---

## Environment

- `AI_PROVIDER=mock` (no AI surface in this slice)
- Widget tests use existing `_RecordingDashboardRepository` fakes — no live API
- Backend RBAC: existing `backend/tests/test_dashboard.py` fixtures
