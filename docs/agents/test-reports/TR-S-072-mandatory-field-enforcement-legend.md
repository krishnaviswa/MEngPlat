# TR-S-072: Mandatory field enforcement + required-field legend — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-072 |
| **Author** | Tester |
| **Date** | 2026-08-18 |
| **Recommendation** | Ship |

---

## Summary

**Pass.** Both halves of this slice are implemented as specified:

- **Frontend** (`BusinessForm.tsx`): a `★ Required field` legend renders near the top of
  the form (`aria-label="Required field legend"`); Business name / Street address / City
  / Phone / Email labels all use the same `★` marker (Phone/Email conditionally, only in
  `mode === "create"`, matching AC7's "only marks fields actually required for that
  role/context" — edit mode doesn't re-require phone/email on every partial update, which
  is consistent with `BusinessUpdate`'s intentionally-optional backend schema). A
  proactive National ID legend line links to the dashboard profile. Client-side
  `validateRequiredFields()` distinguishes "is required" (blank) from "invalid format"
  (non-empty but malformed) errors for both email and phone, rendered inline per-field —
  distinct from the top-of-form server-error banner, per AC6.
- **Backend** (`BusinessCreate` in `backend/app/schemas/__init__.py`): `phone: str` and
  `email: EmailStr` are now non-optional (were `| None = None`), with a
  `@field_validator("phone")` enforcing a loose E.164-ish format
  (`\+?\d{7,15}`). `BusinessUpdate` is confirmed unchanged (still fully optional), matching
  the slice's explicit scope decision.

Full frontend suite: **238/238 passing**, 46/46 suites. Backend `test_national_id.py`
(now includes 5 new schema-level tests for this slice): **10/10 passing**.

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Legend visible near top of form explaining ★ | A | `frontend/src/components/__tests__/BusinessForm.test.tsx::"renders a required-field legend explaining the star marker"` | Pass |
| 2 | ★ consistently marks name/address/city/email/phone/national-ID (replacing bare `*`) | A | `BusinessForm.test.tsx::"marks name, address, city, phone, and email with the ★ required marker"`; national ID has no form field (by design, S-072 note) — its ★-consistent copy is verified via the shared `MERCHANT_REQUIRED_FIELDS` constant, see `frontend/src/components/__tests__/OnboardingGuidancePanel.test.tsx::"renders the shared required-fields list..."` | Pass |
| 3 | Blank email blocks submit with inline "Email is required"; backend also rejects missing email with 400-level | A | `BusinessForm.test.tsx::"blocks submission and shows inline required errors when email and phone are blank"`; `backend/tests/test_national_id.py::test_business_create_requires_email` (422 via Pydantic `ValidationError`) | Pass |
| 4 | Same enforcement for phone | A | Same tests as AC3 (blank-phone case) + `test_national_id.py::test_business_create_requires_phone` | Pass |
| 5 | Same enforcement for national ID (S-043's existing rule, UI now signals it proactively) | A (existing, regression) + code read | `backend/tests/test_national_id.py::test_create_business_400_without_national_id` (existing, unchanged — service-level 400 gate still fires); `BusinessForm.tsx` code read confirms the proactive dashboard-profile legend line renders in create mode | Pass |
| 6 | Invalid (non-empty) format produces a distinct error from "required" | A | `BusinessForm.test.tsx::"shows a distinct invalid-format error for a malformed (non-empty) email/phone"` (frontend); `test_national_id.py::test_business_create_rejects_malformed_phone` and `::test_business_create_rejects_malformed_email` (backend) | Pass |
| 7 | Legend pattern, if reused elsewhere (customer/admin forms), only marks fields required for that role/context — no over-marking | Code read (conditional — not yet reused) | Confirmed via code read: the legend is implemented inline within `BusinessForm.tsx` (not yet extracted into a separate shared component reused by another form); the underlying required-fields data (`MERCHANT_REQUIRED_FIELDS` in `frontend/src/lib/onboarding-copy.ts`) is merchant-specific and not imported by `ProfilePage.tsx` or any customer/admin form, so no over-marking currently exists. AC holds vacuously today; flagged for re-verification if/when the pattern is reused. | Pass |
| 8 | No conflicting behavior between mandatory-ness (this slice) and S-043/S-070/S-071 (national ID gate, structural validation, hide/reveal) | A (existing, regression) | Full suite green including `test_national_id.py`'s national-ID-gate test (AC5 row) and `MerchantNationalIdCard.test.tsx`'s structural-validation/reveal tests (S-070/S-071) — all pass together, no shared state or ordering conflict found | Pass |

**Coverage:** 8 / 8 AC mapped, all automated (AC7 additionally documented as a code-read/
conditional finding since no reuse exists yet).

---

## Backend tests added
- `backend/tests/test_national_id.py::test_business_create_requires_phone`
- `backend/tests/test_national_id.py::test_business_create_requires_email`
- `backend/tests/test_national_id.py::test_business_create_rejects_malformed_phone`
- `backend/tests/test_national_id.py::test_business_create_rejects_malformed_email`
- `backend/tests/test_national_id.py::test_business_create_succeeds_with_valid_phone_and_email`
  (sanity check — no over-tightening)

These close a real gap: prior to this pass, no test asserted that `BusinessCreate`
actually rejects a payload missing `phone`/`email`, even though several test fixtures
elsewhere in the suite had already been updated (by the Builder) to always pass valid
`phone`/`email` values — meaning the requirement was assumed but never directly exercised.

Run:
```
cd backend && python -m pytest tests/test_national_id.py -v
10 passed in 3.37s
```

## Frontend tests added
- `frontend/src/components/__tests__/BusinessForm.test.tsx` (new file, 7 tests — 5 map to
  this slice, 2 map to S-075's photo-manager wiring, see TR-S-075):
  - `"renders a required-field legend explaining the star marker"`
  - `"marks name, address, city, phone, and email with the ★ required marker"`
  - `"blocks submission and shows inline required errors when email and phone are blank"`
  - `"shows a distinct invalid-format error for a malformed (non-empty) email/phone"`
  - `"submits successfully once all required fields are valid"`

## Manual checklist

| ID | Check | Result |
|----|-------|--------|
| M-072-01 | Live submit with JS disabled: server-side 422 surfaces as a readable message in the top error banner, not a raw stack trace | Not run — no live backend reachable in this sandbox; code read confirms `apiFetch`'s existing error-throwing behavior surfaces `err.detail` verbatim via `BusinessForm`'s `error` state, unchanged code path. |

---

## Regressions / gaps

None found. Full frontend suite green (238/238); `test_national_id.py` fully green in
isolation (10/10). Note: a broader `pytest -k business`-style run in this sandbox hits a
known pre-existing `sqlalchemy.exc.InterfaceError: cannot perform operation: another
operation is in progress` DB-pooling flakiness (reproduced independently on
`test_businesses_mine.py`, unrelated to this slice's schema-only change) — not a
regression introduced here.

## Recommendation

**Ship.** All 8 AC mapped and passing (7 fully automated, 1 code-read/conditional).
