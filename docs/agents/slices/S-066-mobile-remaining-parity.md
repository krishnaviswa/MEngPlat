# Slice: S-066 — Mobile remaining web capability parity

| Field | Value |
|-------|-------|
| **Slice ID** | S-066 |
| **Phase** | 4 Dashboards |
| **Status** | Testing |
| **Role(s)** | merchant \| customer \| admin |
| **Owner** | PM / 2026-08-18 |

---

## User story

**As a** merchant, customer, or admin  
**I want** every website capability available in the Flutter app  
**So that** I do not need the website for daily work, while the mobile UI stays native (cards, sheets, short lists — not cloned web chrome)

---

## Acceptance criteria

1. **Given** I own a business, **when** I open Merchant Home, **then** I see my rating next to category and city directory medians (or “not enough listings”), plus the backend disclaimer that this is not an AI judgment (M-69).
2. **Given** I can reply to a review that has `ai_analysis.suggested_response`, **when** I tap Draft with AI, **then** the composer fills with that suggestion, labeled as a suggestion, and nothing is posted until I submit (M-70).
3. **Given** topic-cluster data, **when** I view AI Insights, **then** Common Themes shows label, count, and sentiment as suggestions; insufficient/unavailable copy matches web (M-78).
4. **Given** an approved listing, **when** I use Featured boost, **then** tapping a SKU calls `POST /payments/featured/checkout`; mock provider shows a pending order waiting for admin; Razorpay without native SDK explains that capture continues on web after the order is created (M-66).
5. **Given** I own a business, **when** I link/search/sync Google reviews, **then** I can search candidates, link a place, and Sync now; public business detail shows up to five Google samples when present and hides the section when empty (M-80).
6. **Given** WhatsApp is configured, **when** I open Merchant Home, **then** I get a wa.me QR/share link and a read-only suggestion list; **given** I am admin, **when** I open WhatsApp drafts, **then** I can approve (optional field edits) or reject (M-79).
7. **Given** AI copy, **when** shown, **then** it is labeled suggestion, never a verdict.
8. **Given** M-65 / M-71 / M-67, **when** this slice ships, **then** tracker stays honest: password-reset completion and cold QR still need app-links; transactional email is shared backend with no extra mobile screen.

---

## UX notes

- Native density: one compact card per capability on Merchant Home; Google candidates as a list (no web map picker); WhatsApp QR reuses `qr_flutter` + `share_plus`.
- Admin WhatsApp queue: `/admin/whatsapp`, same pattern as users/categories.
- Out of chrome clone: no web navbar/footer (M-10 stays `partial`).

---

## Out of scope

- FCM (M-47 `future`)
- Android App Links / iOS Universal Links
- Native Razorpay SDK
- New backend endpoints

---

## Dependencies

- Existing Accepted web slices S-038, S-039, S-042, S-048–S-053; generated OpenAPI client already has the methods.
- S-065 is a different slice (in-app notice uniqueness) — do not reuse that ID.

---

## Definition of done (PM)

- [x] All AC verified in one combined test report (testing run once)
- [x] `README.md` §12/§14/§16 updated
- [ ] PM Status set to **Accepted** after Tester pass

---

## Technical specification (Architect)

### API contract (existing; no new routes)

| Method | Path | Auth |
|--------|------|------|
| GET | `/api/v1/dashboard/merchant/{id}/benchmark` | merchant own |
| GET | `/api/v1/ai/businesses/{id}/topics` | merchant own |
| POST | `/api/v1/payments/featured/checkout` | merchant |
| GET/POST | `/api/v1/dashboard/merchant/{id}/google-reviews*` | merchant own |
| GET | `/api/v1/businesses/{id}/external-reviews` | public |
| POST | `/api/v1/dashboard/merchant/{id}/whatsapp/link` | merchant own |
| GET | `/api/v1/dashboard/merchant/{id}/whatsapp/drafts` | merchant own |
| GET/POST | `/api/v1/admin/whatsapp/drafts*` | admin |

Draft-with-AI uses `ReviewResponse.ai_analysis.suggested_response` (no extra call).

### RBAC matrix

| Action | customer | merchant | admin |
|--------|----------|----------|-------|
| Benchmark / topics / Google link / WhatsApp link | — | own | — |
| Public Google samples | yes | yes | yes |
| Featured checkout | — | own approved | — |
| WhatsApp approve/reject | — | — | yes |

### Data model impact

- [x] None

### Frontend

- Flutter only. Reuse `ReviewCard`, `AiInsightsPanel`, `FeaturedBoostPanel`, `ShareReviewLinkSheet` QR/share pattern, `AdminHomeScreen` sibling routes.

### Risks / tradeoffs

- Razorpay JS SDK is web-only; mobile creates the order then tells the merchant to finish on web if `provider=razorpay`. Mock checkout is fully in-app.
- One slice, one `flutter analyze && flutter test` after all UI lands.

### Architect checklist

- [x] API contract defined (existing)
- [x] RBAC matrix
- [x] Data model impact none
- [x] Cache N/A
- [x] AI/storage abstractions unchanged
- [x] No secrets
