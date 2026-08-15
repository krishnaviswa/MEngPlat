# Slice: S-038 — Competitor rating benchmarking

| Field | Value |
|-------|-------|
| **Slice ID** | S-038 |
| **Phase** | 4 Dashboards |
| **Status** | Accepted |
| **Role(s)** | merchant |
| **Owner** | PM / 2026-08-15 |

---

## User story

**As a** merchant  
**I want** my average rating next to category and city medians from our own `Business` table  
**So that** I can see where I sit locally without an external API

---

## Acceptance criteria

1. **Given** I own an approved business with at least one category, **when** I load `GET /dashboard/merchant/{id}/benchmark`, **then** I receive my `average_rating`, category median (businesses sharing a category, approved only), and city median (same `city`, approved only).
2. **Given** a city or category has fewer than 3 other businesses, **when** median would be noisy, **then** that median is `null` and the UI says there is not enough local data — not a fake competitor score.
3. **Given** copy on the card, **when** shown, **then** it does **not** claim AI judged the business better/worse; numbers are directory medians (suggestions for where to look, not a verdict).
4. **Given** a customer or another merchant, **when** they request another shop’s benchmark, **then** 403/404 as today’s dashboard ownership rules.

---

## UX notes

- New `BenchmarkCard` on `/merchant/dashboard` under analytics.
- Empty: “Not enough nearby listings yet.”

---

## Out of scope

- External Google/Zomato ranks. S-037 chart variants (depends on dashboard layout after S-037).

---

## Dependencies

- **S-033** Accepted.
- **S-037** Specified/built first (same dashboard column).
- No S-036 payment dependency.

---

## Definition of done (PM)

- [x] Combined TR-S-037-040
- [x] README §7 + §12 M-69
- [x] PM Accepted (shot 2)

---

## Technical specification (Architect)

### API contract

| Method | Path | Auth | Response |
|--------|------|------|----------|
| GET | `/dashboard/merchant/{business_id}/benchmark` | Merchant (own) or admin | `{ "business_id", "own_rating", "category_median": float\|null, "city_median": float\|null, "category_sample_size": int, "city_sample_size": int, "disclaimer": str }` |

Static path `benchmark` after `{business_id}` like `reviews.csv`. Median of `Business.average_rating` for approved rows; exclude self from sample sizes used for the “≥3 others” rule (sample_size is others count). Disclaimer string fixed: “Directory medians from MerchantHub listings — not an AI judgment.”

### RBAC

Same `_load_owned_business` as merchant dashboard.

### Data model

- [x] None

### Cache

None.

### Frontend

CSR `BenchmarkCard`. `dashboard.benchmark(id)` in `api.ts`.

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-15 | PM + Architect | Specified; waits on S-037 file overlap. |
| 2026-08-15 | Tester | Combined TR-S-037-040 shot 2: all 4 AC mapped and passing, including directory-median (not AI) disclaimer. Recommendation Ship. Status left for PM. |
| 2026-08-15 | PM | **Accepted** on combined `TR-S-037-040-intel-wave.md` (shot 2, Ship, 4/4). Own + category/city medians; fewer than 3 peers → null + “not enough local data”; copy is directory medians not an AI judgment; ownership 403/404. Non-blocking: no live Postgres join this session. |
