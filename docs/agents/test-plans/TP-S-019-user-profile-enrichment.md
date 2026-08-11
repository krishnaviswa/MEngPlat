# TP-S-019: User profile enrichment — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-019 |
| **Author** | Tester |
| **Date** | 2026-08-11 |

> Tested together with S-018 and S-020 — see TP-S-018 for the shared environment note
> on why some backend integration tests are written but not executed live this pass
> (production `DATABASE_URL`, no isolated test DB).

---

## Scope

`ProfilePage` phone/address/national-ID fields, `PATCH /api/v1/auth/me` persistence,
and the sign-in security status text (TOTP / Google) shown as a status + tip, not a
toggle.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Frontend | Jest + RTL | `ProfilePage` field rendering, save flow, security status text |
| Backend | pytest | `UserProfileUpdate` schema / `update_me` router logic via code review + written (not live-executed) integration test; existing `test_s011_s016_batch.py::test_patch_me_updates_name_and_ignores_role` (pre-existing, not re-run live this pass) |
| Manual | Browser | Full round trip: edit, save, reload, confirm persistence |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1. `/profile` shows editable phone, address fields, national ID type/number | Automated | `frontend/src/components/__tests__/ProfilePage.test.tsx::"renders phone, address, and national-ID fields once the profile loads"` |
| 2. Save persists via `PATCH /auth/me` | Automated | `ProfilePage.test.tsx::"persists edited phone/address fields via auth.updateMe on save"` (frontend call shape); backend schema/handler verified via code review (`backend/app/schemas/__init__.py::UserProfileUpdate`, `backend/app/routers/auth.py::update_me`) plus written integration assertions in `backend/tests/test_s018_s020_login_profile.py` (not executed live — see environment note); Manual M-001 for full round trip |
| 3. Sign-in security shown as status + tip, not an optional toggle, for password-TOTP or Google auth | Automated | `ProfilePage.test.tsx::"shows TOTP-enabled status as a security tip, not a toggle"`, `"tells a not-yet-enrolled password account that authenticator setup is required next sign-in"`, `"shows Google sign-in status for a Google account without TOTP"` (each asserts no `checkbox`/`switch` role is rendered, i.e. not a toggle) |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Unauthenticated `GET /auth/me` | none | 401 — pre-existing `test_favorites_requires_auth`-style coverage pattern; also written (not live) `test_s018_s020_login_profile.py::test_auth_me_and_logout_require_authentication`; also asserted at the UI layer by `ProfilePage.test.tsx::"redirects to /login and does not render the form when there is no stored token"` |
| Unauthenticated `PATCH /auth/me` | none | 401 — same written integration test |
| Any authenticated role can edit **only their own** profile | customer / merchant / admin | `update_me` operates on `current_user` from `get_current_user` only — there is no `user_id` path/body parameter to spoof, so cross-account modification is structurally impossible (verified by code review of `backend/app/routers/auth.py::update_me`) |
| `role`/`email`/`is_active`/TOTP fields cannot be self-escalated via this endpoint | customer | `UserProfileUpdate` schema has no `role`/`email`/`is_active`/`totp_*` fields at all (Pydantic drops unknown fields, `update_me` only ever sets attributes present on the validated payload) — verified by code review; pre-existing `test_s011_s016_batch.py::test_patch_me_updates_name_and_ignores_role` covers this at the router level (not re-run live this pass) |

---

## Edge cases

- Clearing a previously-set field (e.g. removing a phone number) — `ProfilePage`
  sends `null` for blanked optional fields (`phone.trim() || null`), which
  `UserProfileUpdate` accepts (`str | None`).
- `national_id_type` without `national_id_number` (or vice versa) — schema allows
  either independently; no cross-field validation exists (noted as a gap, not a bug —
  out of scope per the slice brief, KYC verification is explicitly out of scope).

---

## Manual checklist (if applicable)

- [ ] M-001: `docker compose up --build`; log in, go to `/profile`, fill phone/address/
      national-ID fields, save, reload the page (or navigate away and back) — confirm
      the values persisted rather than reverting.
- [ ] M-002: View `/profile` as a Google-only account and as a password+TOTP account —
      confirm the security status text differs appropriately and no toggle/checkbox is
      shown for either.

---

## Environment

- `AI_PROVIDER=mock`
- `docker compose up --build` (for the manual checklist)
- Backend live-DB execution intentionally skipped this pass — see TP-S-018's
  environment note.
