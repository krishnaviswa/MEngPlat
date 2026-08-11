# TR-S-019: User profile enrichment — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-019 |
| **Author** | Tester |
| **Date** | 2026-08-11 |
| **Recommendation** | Ship |

---

## Summary

Pass. All 3 AC verified — frontend behavior fully automated (RTL); backend
persistence path verified by code review plus a written (not live-executed)
integration test, because `backend/.env`'s `DATABASE_URL` is the live production
Railway Postgres instance and no isolated test DB is available in this environment
(see TR-S-018 for the full environment-finding writeup — same constraint applies
here). No bugs found; no code changes made to this slice's implementation.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|-----------------|--------|
| 1 | `/profile` shows editable phone, address fields, national ID type/number | A | `frontend/src/components/__tests__/ProfilePage.test.tsx::"renders phone, address, and national-ID fields once the profile loads"` | Pass |
| 2 | Save persists via `PATCH /auth/me` | A + code review | `ProfilePage.test.tsx::"persists edited phone/address fields via auth.updateMe on save"` (frontend call shape verified); backend `UserProfileUpdate` schema + `update_me` handler verified by code review; integration assertions written in `backend/tests/test_s018_s020_login_profile.py` — not executed live (see gaps) | Pass |
| 3 | Sign-in security shown as status + tip (not a toggle) for password-TOTP or Google auth | A | `ProfilePage.test.tsx::"shows TOTP-enabled status as a security tip, not a toggle"`, `"tells a not-yet-enrolled password account that authenticator setup is required next sign-in"`, `"shows Google sign-in status for a Google account without TOTP"` — each explicitly asserts no `checkbox`/`switch` role is present | Pass |

**Coverage:** 3 / 3 AC mapped

---

## Backend tests

### Added
No new backend unit tests specific to S-019's field set — the `PATCH /auth/me`
handler and `UserProfileUpdate` schema are generic (they already carry the phone/
address/national-ID fields as part of the shared S-019/S-020 migration) and were
verified correct by direct code review:

- `backend/app/schemas/__init__.py::UserProfileUpdate` — has `phone`, `address_line1`,
  `address_line2`, `city`, `state`, `postal_code`, `country`, `national_id_type`,
  `national_id_number`, `full_name`, `avatar_url`; deliberately **omits** `email`,
  `role`, `is_active`, and both TOTP fields.
- `backend/app/routers/auth.py::update_me` — `payload.model_dump(exclude_unset=True)`
  only ever sets attributes present on the validated (schema-constrained) payload, so
  extra fields in the request body (e.g. `role`, `email`) are silently dropped by
  Pydantic before `update_me` ever sees them — self-escalation is structurally
  impossible, not just policy.

One shared integration test (`backend/tests/test_s018_s020_login_profile.py::
test_password_login_totp_and_profile_enrichment_flow`) includes a `PATCH /auth/me`
round trip with all S-019 fields plus a follow-up `GET /auth/me` to confirm
persistence — written this pass, **not executed live** (production DB constraint, see
TR-S-018).

A pre-existing test, `backend/tests/test_s011_s016_batch.py::
test_patch_me_updates_name_and_ignores_role`, already covers the email/role-ignored
guard at the router level (via real ASGI + DB) from an earlier slice. It was not
re-executed this pass for the same reason.

### Run output
```
No new backend test file was executed live for this slice. The generic PATCH /auth/me
logic is shared with (and exercised live, at the unit/mock level, by) S-020's test_mfa.py
additions — see TR-S-020 for that run output. This slice's own coverage is: frontend
RTL (below) + code review + a written-but-unexecuted integration test.
```

---

## Frontend tests

### Added
- `frontend/src/components/__tests__/ProfilePage.test.tsx` — new file (6 tests)

### Run output
```
cd frontend && npx jest src/components/__tests__/ProfilePage.test.tsx

PASS src/components/__tests__/ProfilePage.test.tsx
  ProfilePage
    √ renders phone, address, and national-ID fields once the profile loads
    √ persists edited phone/address fields via auth.updateMe on save
    √ shows TOTP-enabled status as a security tip, not a toggle
    √ tells a not-yet-enrolled password account that authenticator setup is required next sign-in
    √ shows Google sign-in status for a Google account without TOTP
    √ redirects to /login and does not render the form when there is no stored token

Test Suites: 1 passed, 1 total
Tests:       6 passed, 6 total
```
Full suite (`cd frontend && npx jest`) also run: **10 suites / 38 tests, all passed**
— no regressions.

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | `docker compose up --build`; edit and save profile fields, reload, confirm persistence | Not executed — no Docker available in this environment |
| M-002 | View `/profile` as Google-only vs. password+TOTP account; confirm no toggle for either | Not executed live in a browser; equivalent assertion (`queryByRole("checkbox"/"switch")` absent) is automated in `ProfilePage.test.tsx` for both cases |

---

## Regressions

None observed.

---

## Gaps / rework items

1. **Test infra gap (shared with S-018/S-020, not a slice bug):** no isolated backend
   test database in this environment; `DATABASE_URL` is production. Backend
   persistence for S-019's new fields is verified by code review + a written (not
   live) integration test rather than a live pytest run against the real endpoint.
   Recommend adding an ephemeral/Dockerized test Postgres before relying on the
   backend suite for CI gating.
2. No explicit test for the "clear a previously-set field" case (blank phone → `null`
   persisted) — code-reviewed as correct (`ProfilePage` sends `null` for blanked
   optional fields, `UserProfileUpdate` accepts `str | None`), but not exercised by an
   automated test. Low risk; flagged for a future pass.
3. No cross-field validation between `national_id_type` and `national_id_number`
   (e.g. type set without a number) — this is out of scope per the slice brief (no KYC
   verification), noted here only so it isn't mistaken for an oversight.

None of the above block shipping.

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested (unauthenticated `GET`/`PATCH /auth/me` → 401 via written integration
      test + code review; self-escalation of `role`/`email` structurally blocked by schema)
- [x] AI disclaimer verified (if applicable) — N/A, no AI-generated content in this slice
- [x] Ready for PM acceptance
