# Slice: S-037 — Merchant dashboard chart upgrade

| Field | Value |
|-------|-------|
| **Slice ID** | S-037 |
| **Phase** | 4 Dashboards |
| **Status** | Accepted |
| **Role(s)** | merchant |
| **Owner** | PM / 2026-08-15 |

---

## User story

**As a** merchant on `/merchant/dashboard`  
**I want** area/line charts for monthly review volume and period-over-period delta badges on stat tiles  
**So that** I can see direction of change, not only a bar snapshot

---

## Acceptance criteria

1. **Given** volume-by-month data from S-033, **when** I view the dashboard, **then** volume is an area or line chart (Recharts already installed), not only bars.
2. **Given** a selected range of 30 or 90 days, **when** stats load, **then** reply-rate and in-range review count show a period-over-period delta vs the immediately previous window of the same length (suggestion-free; these are DB counts). All-time range hides delta.
3. **Given** no prior-window reviews, **when** delta would be undefined, **then** the UI shows an em dash or “n/a”, never a fake 0% improvement.
4. **Given** a customer, **when** they hit the merchant dashboard API, **then** they are still denied (unchanged RBAC).

---

## UX notes

- Same `/merchant/dashboard`. Reuse `Charts`, `StatCard`.
- AI disclaimer: not required for DB deltas. Existing AI suggestion copy stays.

---

## Out of scope

- S-038 benchmark card. S-036 payments. New routes besides extending the existing merchant GET.

---

## Dependencies

- **S-033** Accepted (hard for volume series).
- **S-036** dashboard hunk should be merged first (file overlap on `MerchantDashboard.tsx`).
- **S-038** waits on this slice’s dashboard column.

---

## Definition of done (PM)

- [x] All AC verified in combined TR-S-037-040
- [x] README §7/§8 if payload or chart variant changes
- [x] PM Status Accepted (shot 2)

---

## Technical specification (Architect)

### API contract

Extend `GET /api/v1/dashboard/merchant/{business_id}` (`range=30|90|all`). Add optional `reply_rate_previous: float | null`, `review_count_in_range: int`, `review_count_previous: int | null`. Previous window = `[cutoff - duration, cutoff)` for 30/90; both previous fields `null` when `range=all`. Service: `merchant_dashboard.py`. No new path.

### RBAC matrix

Unchanged: merchant own / admin any / customer 403.

### Data model impact

- [x] None

### Cache / side effects

None. Dashboard is uncached.

### Frontend

- `Charts` accepts `variant?: "bar" | "area" | "line"` (default bar for rating mix / sentiment).
- Volume chart uses `area`.
- `StatCard` trend shows delta percent when previous exists.

### Architect checklist

- [x] API contract defined
- [x] RBAC unchanged
- [x] No new tables
- [x] Cache n/a
- [x] No AI/payments ports

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-15 | PM + Architect | Specified in parallel wave; deps S-033/S-036 file overlap. |
| 2026-08-15 | Tester | Combined TR-S-037-040 shot 2: all 4 AC mapped and passing (Jest + DB-free pytest). Recommendation Ship. Status left for PM. |
| 2026-08-15 | PM | **Accepted** on combined `TR-S-037-040-intel-wave.md` (shot 2, Ship, 4/4). Area/line volume, 30/90 deltas vs prior window, n/a when no prior reviews (never fake 0%), customer still denied. Non-blocking: no ASGI/Postgres/Docker this session. |
