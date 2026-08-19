# Slice: S-102 — Gmail on device via public Google config

| Field | Value |
|-------|-------|
| **Slice ID** | S-102 |
| **Phase** | 5 Polish |
| **Status** | Testing |
| **Role(s)** | customer, merchant, admin |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As a** mobile user  
**I want** Continue with Google on Login/Register when the backend has Google configured  
**So that** I can sign in with Gmail without rebuilding the APK just to bake a client ID

---

## Acceptance criteria

1. **Given** backend `GOOGLE_CLIENT_ID` is set, **when** the app has no `--dart-define=GOOGLE_CLIENT_ID`, **then** Login/Register can show Continue with Google after `GET /api/v1/auth/google-config`.
2. **Given** dart-define is set, **when** config is resolved, **then** the baked ID wins over the API.
3. **Given** both are empty, **when** Login is shown, **then** the Google button is hidden.
4. **Given** `GET /auth/google-config`, **when** called anonymously, **then** `{ "client_id": "..." }` with no auth.

---

## Out of scope

- Changing `POST /auth/google` token verification
- Creating Android OAuth clients / SHA-1 (ops)

---

## Technical specification (Architect)

### API contract

| Method | Path | Auth | Request | Response |
|--------|------|------|---------|----------|
| GET | `/api/v1/auth/google-config` | Public | — | `{ "client_id": string }` |

### RBAC matrix

| Action | anonymous | customer | merchant | admin |
|--------|-----------|----------|----------|-------|
| GET google-config | yes | yes | yes | yes |

### Data model impact

- [x] None

### Frontend

- Flutter: dart-define override else `AuthRepository.fetchGoogleClientId`; `googleSignInClientProvider` is a `FutureProvider`.

### Architect checklist

- [x] API contract defined
- [x] RBAC matrix complete
- [x] Data model impact documented
- [x] Cache invalidation considered
- [x] Uses AI/storage abstractions where applicable
- [x] ERD/API/FLOWS updates noted

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-102-gmail-on-device.md`
- Test report: `docs/agents/test-reports/TR-S-102-gmail-on-device.md`

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-19 | PM | Created |
| 2026-08-19 | Architect | Spec |
| 2026-08-19 | Builder | Implemented |
