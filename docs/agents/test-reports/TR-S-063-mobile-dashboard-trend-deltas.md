# TR-S-063: Mobile dashboard trend chart + period-over-period deltas (M-68 parity)

| Field | Value |
|-------|-------|
| **Slice** | S-063 |
| **Author** | Tester |
| **Date** | 2026-08-18 |
| **Recommendation** | Ship |

---

## Summary

**Pass** — all 6 numbered AC are met. No production-code rework. `flutter analyze`: **0 issues**.
`flutter test`: **226/226 passing** (222 from S-062 + 4 net new: the old S-060 “volume is a
`BarChart`” assertion was replaced by the S-063 `LineChart` test, plus four additional delta
tests). Independently re-read `review_volume_chart.dart` and `_TrendDelta` against the Architect
spec: `LineChart` + `belowBarData: BarAreaData(show: true, ...)`, `isCurved: false`, dots on;
`_TrendDelta` branches `range == 'all'` first (AC 3), then `previous == null` / `previous == 0`
(AC 4 + Architect risk), then signed percent (AC 2).

**AC 5 pytest re-run this session:**
`test_merchant_dashboard_requires_merchant_or_admin_role` (customer 403) **passed**.
`test_merchant_dashboard_403s_for_non_owning_merchant` **failed locally** with
`RuntimeError: Event loop is closed` during the *second* merchant register (asyncpg/SSL teardown
against the shared local Postgres) — not a 200/bypass, and **not caused by this slice** (no
`backend/` diff). AC 5 is still Pass via existing, already-Accepted tests plus code inspection:
`DashboardRepository` still only calls the generated merchant-dashboard GET; `/merchant` remains
role-gated in `router.dart`; no new client route.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Volume chart is area/line (`LineChart`), not bars, same series | A | `merchant_dashboard_screen_test.dart::S-063 AC1: review volume chart renders as a LineChart (area/line, not BarChart) when data is present` | Pass |
| 2 | 30/90-day range: reply-rate + reviews-in-range tiles show up/down % vs previous window | A | `...::S-063 AC2: delta badge shows +50% up-arrow when current > previous, and -33% down-arrow when current < previous` | Pass |
| 3 | All-time range: delta badge fully absent (not an em dash) | A | `...::S-063 AC3: "All time" range shows no delta badge at all on either tile (fully absent, not an em dash)` | Pass |
| 4 | Previous window undefined (`previous == null`): em dash, never a fake % | A | `...::S-063 AC4: 30-day range with a null previous window shows an em dash badge...`; extra `...::S-063 (Architect Risks): previous == 0 ...` | Pass |
| 5 | Customer / non-owner merchant denied (existing backend 403; no new client bypass) | A + M | `backend/tests/test_dashboard.py::test_merchant_dashboard_requires_merchant_or_admin_role` (re-run: Pass); `::test_merchant_dashboard_403s_for_non_owning_merchant` (existing; local re-run env-flake). Inspection: `dashboard_repository.dart` + `router.dart` `/merchant` gate unchanged | Pass |
| 6 | Empty volume series still shows `"No reviews in this range."`; no chart widget | A | `...::S-060/S-063 AC6: review volume chart shows empty-state copy when there is no volume data` | Pass |

**Coverage:** 6 / 6 AC mapped

---

## Backend tests

### Added

None — confirmed no backend routes/schemas changed (this slice is mobile-UI-only; S-037 already
ships `review_count_in_range` / `review_count_previous` / `reply_rate_previous`).

### Run output

```
python -m pytest tests/test_dashboard.py::test_merchant_dashboard_requires_merchant_or_admin_role tests/test_dashboard.py::test_merchant_dashboard_403s_for_non_owning_merchant -q
# 1 passed (customer 403), 1 failed (other-merchant register: Event loop is closed / local DB teardown — not a product 403 regression)
```

---

## Frontend tests

### Added

Builder-added widget tests in `mobile/test/merchant_dashboard_screen_test.dart` (AC 1–4, AC 6,
plus `previous == 0`). Tester did not add further cases; coverage already matches the Architect
risks.

### Run output

```
cd mobile && flutter analyze  — No issues found
cd mobile && flutter test     — 226/226 passing
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | `review_volume_chart.dart` uses `LineChart` + area fill; empty branch unchanged | Pass |
| M-002 | `_TrendDelta` range-first then previous; `reviewCountInRangeTile` on its own row | Pass |
| M-003 | `dashboard_repository.dart` / `/merchant` redirect unmodified | Pass |
| M-004 | No AI copy on delta badges (plain DB counts) | Pass (N/A disclaimer) |
| M-005 | `docker compose` / on-device smoke | Not performed (no new native channel) |

---

## Regressions

None. Rating-mix remains `BarChart`. Featured boost panel (S-062) and CSV export (S-060) tests
still pass. Empty volume copy is unchanged.

---

## Gaps / rework items

None. Local pytest flake on the other-merchant case is environment teardown, not a slice gap.

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested (customer 403 re-run + existing other-merchant test + inspection)
- [x] AI disclaimer verified (if applicable) — N/A; deltas are DB counts
- [x] Ready for PM acceptance

## Recommendation

**Ship**
