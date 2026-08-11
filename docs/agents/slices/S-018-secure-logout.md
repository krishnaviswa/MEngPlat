# Slice: S-018 — Secure logout / session UX

| Field | Value |
|-------|-------|
| **Slice ID** | S-018 |
| **Phase** | 1 Foundation |
| **Status** | Testing |
| **Role(s)** | customer \| merchant \| admin |
| **Owner** | Builder / 2026-08-11 |

---

## User story

**As a** logged-in user  
**I want** logout to fully end my session in the UI  
**So that** Back / bfcache cannot show me as still signed in

---

## Acceptance criteria

1. **Given** I am logged in, **when** I log out from Navbar or Settings, **then** tokens are cleared and I am hard-navigated so the Navbar shows signed-out.
2. **Given** I logged out, **when** I use the browser Back button to a protected page, **then** I am sent to login (or see no authenticated shell).
3. **Given** tokens were revoked, **when** `auth.me()` fails on a guarded page, **then** local tokens are cleared.

---

## UX notes

- Central `performLogout` in `frontend/src/lib/api.ts`
- `pageshow` bfcache re-check on `RequireAuth`, Settings, Profile, ClientLayout

---

## Out of scope

- httpOnly cookie migration (README §9 item 1)

---

## Dependencies

- Existing logout blocklist (S-001)

---

## Definition of done (PM)

- [ ] All AC verified
- [ ] Documented in README §6 / §9
- [ ] PM Status set to **Accepted**

---

## Technical specification (Architect)

### API contract

No new endpoints — uses existing `POST /auth/logout`.

### RBAC matrix

| Action | customer | merchant | admin |
|--------|----------|----------|-------|
| Logout | ✅ | ✅ | ✅ |

### Data model impact

- [x] None

### Frontend

- **Route:** all authenticated shells
- **Rendering:** CSR
- **Components:** `ClientLayout`, `RequireAuth`, `SettingsPage`, `AlreadySignedIn`, `ProfilePage`

### Architect checklist

- [x] API contract defined
- [x] RBAC matrix complete
- [x] Data model impact documented
- [x] Cache invalidation considered
- [x] Uses AI/storage abstractions where applicable
- [x] ERD/API/FLOWS updates noted

### Risks / tradeoffs

Client-only guards cannot prevent a flash of cached HTML; hard navigation + pageshow minimize it.

---

## Links

- ADR: none

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-11 | PM+Architect+Builder | Implemented with S-019/S-020 |
