# Slice: S-040 — Review collection QR / public wizard

| Field | Value |
|-------|-------|
| **Slice ID** | S-040 |
| **Phase** | 2 Core |
| **Status** | Accepted |
| **Role(s)** | merchant, customer |
| **Owner** | PM / 2026-08-15 |

---

## User story

**As a** merchant  
**I want** a public `/collect/[businessId]` link and QR on my dashboard  
**So that** counter customers can leave a star rating and text without hunting the pin, with **no rating gating** (all stars go to MerchantHub equally)

---

## Acceptance criteria

1. **Given** an approved business, **when** anyone opens `/collect/{businessId}`, **then** they see the business name and a 1–5 star control. Submitting 1–5 all continue to the same text step — no intercept of low stars.
2. **Given** they submit rating + body (≥10 chars) while signed in as a customer, **when** POST `/reviews` succeeds, **then** the review is created through the existing API (AI analysis unchanged).
3. **Given** they are not signed in, **when** they finish the form, **then** they are sent to `/login?next=/collect/{id}` (or equivalent) rather than a silent drop.
4. **Given** the merchant dashboard, **when** the listing is approved, **then** a QR encoding the public collect URL is shown (`qrcode.react`).
5. **Given** optional Maps deep link, **when** shown after submit, **then** it is a suggestion to also review on Google — not required, not gating.

---

## UX notes

- New CSR page `frontend/src/app/collect/[businessId]/page.tsx`.
- Reuse `RatingWidget`, existing `reviews.create`.
- Out of scope: intercepting 1–3 star reviews, new review API, payments.

---

## Dependencies

- Existing review create + S-033 dashboard.
- Parallel with S-039. QR card on dashboard: small hunk after S-036 boost panel.
- Not blocked on S-037/S-038.

---

## Definition of done (PM)

- [x] Combined TR
- [x] README §6/§8/§12 M-71
- [x] Accepted shot 2

---

## Technical specification (Architect)

### API contract

None new. `GET /businesses/{slug}` or merchant mine + public get by id: use existing `GET /businesses/{slug}` after resolving id via public list or add client fetch `GET /businesses` filtered. **Builder:** load via existing `businesses.list` / a public get-by-id if present; if only slug get exists, merchant dashboard already has id+slug — QR uses `/collect/{id}`; page calls `GET /businesses` and finds id, or `GET /api/v1/businesses/{slug}` after a lightweight public lookup.

Prefer: extend nothing if `GET /businesses?` can find by id is not available — add **no new auth**. Public page may call `GET /api/v1/businesses` (approved list) and match `id`. Fine for v1.

`POST /reviews` unchanged `{ business_id, rating, body }`.

### RBAC

Collect page public. Create review: customer (existing).

### Data model

- [x] None

### Frontend

- Route `/collect/[businessId]` CSR.
- `qrcode.react` on merchant dashboard for `origin + /collect/{id}`.
- After success, optional `https://www.google.com/maps/search/?api=1&query={encoded name city}` link labeled as optional.

### Architect checklist

- [x] No new tables
- [x] No rating intercept
- [x] AI on review create stays suggestion-grade via existing pipeline

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-15 | PM + Architect | Specified; public wizard + QR; no gating. |
| 2026-08-15 | Tester | Combined TR-S-037-040 shot 2: all 5 AC mapped and passing, including 1-star continue (no rating gating). Recommendation Ship. Status left for PM. |
| 2026-08-15 | PM | **Accepted** on combined `TR-S-037-040-intel-wave.md` (shot 2, Ship, 5/5). 1-star continues (no gating); signed-in create via existing POST; login `next=` when unsigned; QR on approved dashboard; Maps link is optional suggestion. |
