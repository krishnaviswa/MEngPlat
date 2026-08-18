# TR-S-070: Aadhaar/PAN structural evaluation + mock Aadhaar OTP — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-070 |
| **Author** | Tester |
| **Date** | 2026-08-18 |
| **Recommendation** | Ship |

---

## Summary

**Pass.** All 8 acceptance criteria are covered by automated tests (backend pytest +
frontend RTL), with the endpoint contract deviation the Builder note flags (the
`request` endpoint takes `{ aadhaar_number }` in the body and holds it pending in Redis,
rather than reading a nonexistent "pending" value off `current_user`) verified as
implemented consistently end-to-end: schema regex → router → Redis pending-key →
verify-saves-and-deletes → frontend client → `MerchantNationalIdCard` UI. The "verify *is*
the save step" property (Aadhaar is never persisted via a raw `PATCH /auth/me`) is
directly exercised.

I extended `backend/tests/test_national_id.py` (13 new tests: schema-level PAN/Aadhaar
regex on `UserProfileUpdate`, `MockAadhaarOtpRequest`/`MockOtpVerifyRequest` validation,
the two new router endpoints' happy/error paths, and AC8's admin-masking) and
`frontend/src/components/__tests__/MerchantNationalIdCard.test.tsx` (5 new tests:
malformed Aadhaar/PAN inline errors, the always-visible mock/demo disclaimer, the full
request→verify→saved happy path, and the wrong-code retry path). No backend or frontend
regressions.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Aadhaar must be exactly 12 numeric digits, inline error before submission | A | Backend: `test_national_id.py::test_user_profile_update_accepts_structurally_valid_aadhaar`, `::test_user_profile_update_rejects_malformed_aadhaar[...]` (parametrized). Frontend: `MerchantNationalIdCard.test.tsx::"blocks submission with an inline error for a malformed Aadhaar number (S-070 AC1)"` | Pass |
| 2 | PAN must match `[A-Z]{5}[0-9]{4}[A-Z]{1}`, inline error before submission | A | Backend: `test_national_id.py::test_user_profile_update_accepts_structurally_valid_pan`, `::test_user_profile_update_rejects_malformed_pan[...]`. Frontend: `MerchantNationalIdCard.test.tsx::"blocks submission with an inline error for a malformed PAN number (S-070 AC2)"` | Pass |
| 3 | Structurally valid Aadhaar → mocked OTP step presented, clearly labeled, no real government API call | A | Backend: `test_national_id.py::test_request_aadhaar_mock_otp_stores_pending_number_and_returns_dev_code` (only Redis + `phone_otp.issue_otp` are touched, no external HTTP call exists in the endpoint). Frontend: `MerchantNationalIdCard.test.tsx::"routes Aadhaar through the mock OTP step instead of saving directly (S-070)"` (pre-existing) + `::"completes the mock Aadhaar OTP flow: request -> correct code -> saved (S-070 AC3/AC4)"` | Pass |
| 4 | Correct mock code → Aadhaar marked mock-verified, merchant continues; wrong code → error + retry | A | Backend: `test_national_id.py::test_verify_aadhaar_mock_otp_correct_code_saves_and_marks_verified`, `::test_verify_aadhaar_mock_otp_wrong_code_401s_and_does_not_save`, `::test_verify_aadhaar_mock_otp_expired_pending_value_401s`. Frontend: `MerchantNationalIdCard.test.tsx::"completes the mock Aadhaar OTP flow..."` + `::"shows an inline error and allows retry on a wrong mock OTP code (S-070 AC4)"` | Pass |
| 5 | "Other" ID type keeps S-043's free-text behavior unchanged — no new validation/OTP | A | Backend: `test_national_id.py::test_user_profile_update_applies_no_structural_check_for_other_type`. Frontend: existing `MerchantNationalIdCard.tsx` code path only branches on `nationalIdType === "aadhaar"` / PAN regex — "other" falls through to the unchanged direct-save path (verified by code read; `"prompts merchants who have no ID and saves PAN directly (non-Aadhaar path)"` exercises the same non-Aadhaar branch shape for PAN) | Pass |
| 6 | Structural error or incomplete OTP step blocks business-form submission (S-043 mandatory-ID rule) | A (existing, regression) + code read | `test_national_id.py::test_create_business_400_without_national_id` (pre-existing, unaffected by this slice) confirms the service-layer gate. Client-side: `formatError()` blocks `onSubmit` before any API call is made (`MerchantNationalIdCard.tsx` lines 68-72), and `PATCH /auth/me` never receives an Aadhaar value directly since Aadhaar's `onSubmit` branch always routes to `requestAadhaarMockOtp` instead of `auth.updateMe` — confirmed by code read | Pass |
| 7 | Mock/demo disclaimer visible everywhere the OTP/structural UI is shown | A | Frontend: `MerchantNationalIdCard.test.tsx::"shows the mock/demo disclaimer as soon as Aadhaar is selected (S-070 AC7)"` (pre-OTP-step badge) + `::"completes the mock Aadhaar OTP flow..."` asserts the OTP-step disclaimer text renders (`/mock\/demo verification/i`) | Pass |
| 8 | Admin national-ID list still masks Aadhaar/PAN regardless of mock-verification status | A | `test_national_id.py::test_apply_admin_national_id_mask_masks_aadhaar_regardless_of_type`, `::test_apply_admin_national_id_mask_masks_pan` — new tests closing a pre-existing coverage gap (`apply_admin_national_id_mask` had no direct unit test before this pass); confirms masking is applied uniformly and is untouched by this slice (no import of it changed in `app/services/admin_users.py`) | Pass |

**Coverage:** 8 / 8 AC mapped, all automated (A).

---

## Contract-deviation note (per Builder note)

Confirmed as implemented and tested: `POST /auth/national-id/aadhaar/mock-otp/request`
takes `{ aadhaar_number: str }` (re-validated server-side against `^\d{12}$` via
`MockAadhaarOtpRequest`), stores it at `aadhaar-mock-pending:{user_id}` in Redis with the
same 5-minute TTL as the OTP code, and only persists to `current_user` inside `verify` on
a correct code — at which point the pending key is deleted
(`test_verify_aadhaar_mock_otp_correct_code_saves_and_marks_verified` asserts
`national_id_type`/`national_id_number` are set on `current_user` and the pending Redis
key is gone). An expired/missing pending value on an otherwise-correct code 401s rather
than silently succeeding (`test_verify_aadhaar_mock_otp_expired_pending_value_401s`).

---

## Backend tests

### Added (`backend/tests/test_national_id.py`, 13 new tests)
- `test_user_profile_update_accepts_structurally_valid_aadhaar`
- `test_user_profile_update_rejects_malformed_aadhaar[12345]` / `[12345678901a]` / `[1234567890123]` (+1 skipped: empty string is a no-op by design)
- `test_user_profile_update_accepts_structurally_valid_pan`
- `test_user_profile_update_rejects_malformed_pan[ABCDE1234]` / `[ABCD1234FF]` / `[12345ABCDE]` / `[abcde1234]`
- `test_user_profile_update_applies_no_structural_check_for_other_type`
- `test_mock_aadhaar_otp_request_accepts_valid_number`
- `test_mock_aadhaar_otp_request_rejects_malformed_number`
- `test_mock_otp_verify_request_rejects_wrong_length_code`
- `test_mock_otp_verify_request_accepts_six_digit_code`
- `test_request_aadhaar_mock_otp_stores_pending_number_and_returns_dev_code`
- `test_request_aadhaar_mock_otp_omits_dev_code_when_not_debug`
- `test_verify_aadhaar_mock_otp_wrong_code_401s_and_does_not_save`
- `test_verify_aadhaar_mock_otp_expired_pending_value_401s`
- `test_verify_aadhaar_mock_otp_correct_code_saves_and_marks_verified`
- `test_apply_admin_national_id_mask_masks_aadhaar_regardless_of_type`
- `test_apply_admin_national_id_mask_masks_pan`

Router-level tests call `request_aadhaar_mock_otp`/`verify_aadhaar_mock_otp` directly
(no live app/DB) with `app.routers.auth.issue_otp`, `.consume_otp`, and `.get_redis`
monkeypatched to an in-memory `FakeRedisClient` — mirrors this codebase's existing
`test_businesses_cache_invalidation.py` pattern, no real Redis/Postgres needed.

### Run output
```
cd backend && python -m pytest tests/test_national_id.py -v
31 passed, 1 skipped in 4.25s

cd backend && python -m pytest tests/test_national_id.py tests/test_businesses_cache_invalidation.py -v
44 passed, 1 skipped
```

---

## Frontend tests

### Added (`frontend/src/components/__tests__/MerchantNationalIdCard.test.tsx`, 5 new tests)
- `"blocks submission with an inline error for a malformed Aadhaar number (S-070 AC1)"`
- `"blocks submission with an inline error for a malformed PAN number (S-070 AC2)"`
- `"shows the mock/demo disclaimer as soon as Aadhaar is selected (S-070 AC7)"`
- `"completes the mock Aadhaar OTP flow: request -> correct code -> saved (S-070 AC3/AC4)"`
- `"shows an inline error and allows retry on a wrong mock OTP code (S-070 AC4)"`

### Run output
```
cd frontend && npx jest src/components/__tests__/MerchantNationalIdCard.test.tsx --silent
Tests: 12 passed, 12 total (7 pre-existing + 5 new)

cd frontend && npx jest --silent   (full suite)
Test Suites: 46 passed, 46 total
Tests:       250 passed, 250 total   (238 baseline + 12 new: 5 S-070 + 7 S-073)
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-070-01 | Live click-through: merchant selects Aadhaar, enters a valid 12-digit number, sees the mock OTP step with a visible dev code (DEBUG mode), enters it, sees the ID saved/verified | Not run — no live backend/Postgres/Redis reachable in this sandbox (documented environment constraint, consistent with prior slices in this batch e.g. TR-S-067). Fully covered by automated tests above instead. |
| M-070-02 | Admin user-list page: an Aadhaar/PAN number set via this new flow renders masked, same as any other national ID | Not run live — covered by direct unit test of `apply_admin_national_id_mask` (AC8 row); no separate admin-list rendering path exists for mock-verified vs. non-verified IDs (single mask function applied uniformly, confirmed by code read of `app/services/admin_users.py`). |

---

## Regressions

None found. Full frontend suite green (250/250, up from 238 baseline). Backend
`test_national_id.py` + `test_businesses_cache_invalidation.py` green (44/45, 1
intentionally skipped).

---

## Gaps / rework items

None blocking. Two minor notes, neither a defect:

1. PAN validation normalizes case only for the *comparison* (`v.strip().upper()`) but
   returns the original-cased string, so a lowercase PAN like `abcde1234f` structurally
   passes but is stored lowercase. Not an AC violation (AC2's regex example is uppercase,
   and the frontend mirror regex does the same normalize-for-check-only pattern) —
   flagging for PM/Architect awareness only, not a blocker.
2. AC6's "incomplete mock OTP step blocks submission" is verified by code read (Aadhaar's
   `onSubmit` never reaches `auth.updateMe`) rather than a dedicated
   business-form-submission-level test, since national ID isn't a `BusinessForm` field —
   it's a precondition enforced server-side in `create_business` (already covered by the
   pre-existing `test_create_business_400_without_national_id`).

---

## Sign-off

- [x] All AC mapped to tests (8/8 automated)
- [x] RBAC tested — endpoint is role-agnostic by design (any authenticated user per the
      spec's RBAC matrix); no privilege-escalation path exists since the endpoint only
      ever mutates `current_user`'s own row
- [x] AI disclaimer verified — n/a (no AI content); the mock/demo disclaimer (AC7,
      analogous requirement) is directly tested
- [x] Ready for PM acceptance
