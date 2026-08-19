# Slice: S-095 — Mobile admin ops console + avatar upload (M-90, M-91)

| Field | Value |
|-------|-------|
| **Slice ID** | S-095 |
| **Phase** | 5 Polish |
| **Status** | Accepted |
| **Role(s)** | admin \| customer \| merchant |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As an** admin  
**I want** extra snapshot tiles and jump links for tickets, repeat shop reports, and processing listings  
**So that** Admin Home is an ops console, not only the old five counts

**As a** signed-in user  
**I want** to pick a photo for my avatar  
**So that** I match web click-to-upload instead of pasting a URL

---

## Acceptance criteria

1. **Given** Admin Home, **when** platform analytics load, **then** I see tiles for open support tickets, repeat shop reports, and processing businesses from `GET /dashboard/admin/platform` (additive fields).
2. **Given** those tiles, **when** I tap them, **then** I go to `/admin/support`, `/admin/business-reports`, and the pending/processing queue on Admin Home respectively.
3. **Given** Admin Home, **when** it loads, **then** a compact ops jump row links to Users, Merchants, Categories, Reviews, Support tickets, Shop reports, WhatsApp (native chips, not a cloned wide web shell).
4. **Given** Profile, **when** I tap Change photo, **then** `image_picker` runs and `POST /auth/me/avatar` (multipart) updates my own `avatar_url` only — no `user_id` param.
5. **Given** Profile, **when** I save other fields, **then** Avatar URL text field is gone (URL paste removed).
6. **Given** Account, **when** `avatar_url` is set, **then** the leading avatar shows the photo (resolved via `resolveMediaUrl`), else initials.
7. **Given** another user’s id, **when** this client uploads, **then** it cannot target them (endpoint is self-only).

---

## UX notes

- Ops row: `Wrap` of `ActionChip`s
- Avatar: gallery picker; show progress and errors; no AI analysis

---

## Out of scope

- Camera-only capture requirement (gallery is enough)
- Cropping UI
- FCM / Play Store

---

## Dependencies

- S-094 routes for ticket/report tiles
- S-085 web Accepted; OpenAPI regen includes `POST /auth/me/avatar` and platform extras

---

## Definition of done (PM)

- [ ] Tester report + README §12 M-90, M-91
- [ ] PM Accepted

---

## Technical specification (Architect)

### API contract

| Method | Path | Auth |
|--------|------|------|
| GET | `/api/v1/dashboard/admin/platform` | admin; fields `open_support_tickets`, `repeat_shop_reports`, `processing_businesses` |
| POST | `/api/v1/auth/me/avatar` | authenticated self; multipart file |

### RBAC matrix

| Action | customer | merchant | admin |
|--------|----------|----------|-------|
| Ops tiles/nav | no | no | yes |
| Upload own avatar | yes | yes | yes |

### Data model impact

- [x] None

### Cache / side effects

Avatar write uses existing storage provider. Refresh `AuthController` from response.

### Frontend

- `AdminHomeScreen` extra `_AdminStat` + ops chips
- `ProfileScreen` picker; `AuthRepository.uploadAvatar`; `AccountScreen` `CircleAvatar` background image

### Architect checklist

- [x] API contract defined
- [x] RBAC matrix complete
- [x] Data model impact documented
- [x] Cache invalidation considered
- [x] Uses AI/storage abstractions where applicable
- [x] ERD/API/FLOWS updates noted

### Risks / tradeoffs

- `image_picker` in widget tests: inject a callback/repository so tests do not open a device picker.

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-095-mobile-ops-console-and-avatar.md`
- Test report: `docs/agents/test-reports/TR-S-095-mobile-ops-console-and-avatar.md`

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-19 | PM | Created |
| 2026-08-19 | Architect | Specified |
| 2026-08-19 | Builder | Ops tiles/chips + avatar picker |
| 2026-08-19 | Tester | TR-S-095 Ship |
| 2026-08-19 | PM | Accepted |
