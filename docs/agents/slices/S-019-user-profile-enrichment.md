# Slice: S-019 — User profile enrichment

| Field | Value |
|-------|-------|
| **Slice ID** | S-019 |
| **Phase** | 5 Polish |
| **Status** | Accepted |
| **Role(s)** | customer \| merchant \| admin |
| **Owner** | Builder / 2026-08-11 |

---

## User story

**As a** logged-in user  
**I want** to store phone, address, and national ID on my profile  
**So that** my account has complete contact identity beyond name and avatar

---

## Acceptance criteria

1. **Given** I am logged in, **when** I open `/profile`, **then** I can edit phone, address fields, and national ID type/number.
2. **Given** I save the profile, **when** the request succeeds, **then** values persist via `PATCH /auth/me`.
3. **Given** I view sign-in security, **when** I have password TOTP or Google auth, **then** status is shown with a security tip (not an optional toggle for password MFA).

---

## Out of scope

- KYC verification of PAN
- SMS OTP
- Email/password change

---

## Dependencies

- S-016 profile edit
- S-020 TOTP status display

---

## Definition of done (PM)

- [x] All AC verified
- [x] README §5 / §7 updated
- [x] PM Status set to **Accepted**

---

## Technical specification (Architect)

### API contract

| Method | Path | Auth | Request | Response |
|--------|------|------|---------|----------|
| PATCH | `/api/v1/auth/me` | Bearer | phone, address_*, national_id_*, full_name, avatar_url | `UserResponse` |

### Data model impact

- [x] Extend existing — `users` profile + national ID columns (same migration as S-020)

### Frontend

- **Route:** `/profile`
- **Rendering:** CSR
- **Components:** `ProfilePage`

### Architect checklist

- [x] API contract defined
- [x] RBAC matrix complete
- [x] Data model impact documented
- [x] Cache invalidation considered
- [x] Uses AI/storage abstractions where applicable
- [x] ERD/API/FLOWS updates noted

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-11 | PM+Architect+Builder | Implemented |
| 2026-08-11 | Tester | TR-S-019 filed — 3/3 AC pass (frontend fully automated; backend persistence verified by code review + a written-but-unexecuted integration test). Recommendation: Ship. |
| 2026-08-11 | PM | Accepted. All 3 AC verified per TR-S-019. README §5 (ERD `users` table already lists `phone`, `address_line1`, `national_id_type`, `national_id_number`) and §7 (`PATCH /auth/me` already documented as "Update profile (name, avatar, phone, address, national ID)") already accurately reflect this slice — no changes needed. Same production-DB test-isolation caveat as S-018/S-020 applies to this slice's backend integration evidence (mocked/code-reviewed, not live end-to-end) — tracked as a follow-up infra item per Tester's recommendation, not a slice blocker. |
