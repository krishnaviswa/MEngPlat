# Slice: S-100 — Merchant hub + Insights / Reviews / Grow

| Field | Value |
|-------|-------|
| **Slice ID** | S-100 |
| **Phase** | 4 Dashboards |
| **Status** | Accepted |
| **Role(s)** | merchant |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As a** merchant  
**I want** Home to be a hub with Insights, Reviews, and Grow as jobs  
**So that** I am not scrolling a cloned web dashboard

---

## Acceptance criteria

1. **Given** `/merchant`, **when** I have a shop, **then** I see stats plus job tiles Insights / Reviews / Grow (`merchantInsightsJob`, `merchantReviewsJob`, `merchantGrowJob`).
2. **Given** those tiles in the real app, **when** I tap them, **then** I go to `/merchant/insights`, `/merchant/reviews`, `/merchant/grow` (same capabilities, focused).
3. **Given** Insights, **when** range/charts/AI load, **then** dashboard requests run in `Future.wait` (stats + insights + benchmark + topics), not four sequential round trips.
4. **Given** widget tests, **when** they pump `MerchantSection.all`, **then** existing Keys still resolve.

---

## Technical specification (Architect)

- Routes added under `/merchant`; no backend change
- Hub default `MerchantSection.hub`; tests use `all`

### Architect checklist

- [x] API none
- [x] RBAC merchant-only unchanged

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-19 | Full cycle | Merchant IA split |
