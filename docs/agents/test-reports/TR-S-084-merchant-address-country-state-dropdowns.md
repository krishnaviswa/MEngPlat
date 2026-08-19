# TR-S-084: Remove address lookup; Country/State cascading dropdowns — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-084 |
| **Author** | Tester |
| **Date** | 2026-08-19 |
| **Recommendation** | Ship |

---

## Summary

**Pass.** All 14 acceptance criteria are mapped. Frontend `BusinessForm` coverage and
backend country-PATCH + OTP-gate tests were re-run independently this session and
passed. Nominatim lookup UI is gone from `BusinessForm.tsx`; Country/State are `<select>`s
fed by `countryState.ts`; `BusinessUpdate.country` persists; removed maps routes 404;
`GET /maps/config` is unchanged.

**Flutter analyze / flutter test:** not run (on hold per product instruction). Mobile
codegen hygiene for AC13 was checked by grep of `mobile/packages/merchanthub_api` —
no remaining `geocode` / `autocomplete` symbols in generated Dart. Hand-written mobile
editor remaining free-text is the documented §12 `partial` gap, out of scope.

---

## AC coverage matrix

| AC# | Description | Type | Test | Result |
|-----|-------------|------|------|--------|
| 1 | Typing Street address fires no lookup request; no suggestion dropdown | A + code-read | `BusinessForm.test.tsx::"treats street address as a plain field with no lookup UI or network calls (S-084 AC1/AC2)"` — no `listbox` after typing. `frontend/src/lib/api.ts` `maps` object has only `nearby`/`config` (no `autocomplete`). | Pass |
| 2 | No "Look up address" button, Nominatim helper, or suggestion UI | A | Same test — asserts no Look up button and no Nominatim copy. Code read: those nodes are deleted from `BusinessForm.tsx`. | Pass |
| 3 | Country is a `<select>` from bundled list, default `IN` | A | `BusinessForm.test.tsx::"renders Country as a select defaulting to India (S-084 AC3)"` | Pass |
| 4 | State `<select>` options belong only to the selected country | A | `BusinessForm.test.tsx::"populates State options from the selected country (S-084 AC4)"` | Pass |
| 5 | Changing Country clears State and repopulates options | A | `BusinessForm.test.tsx::"clears State and repopulates options when Country changes (S-084 AC5)"` | Pass |
| 6 | Matching stored state pre-selected on edit load | A | `BusinessForm.test.tsx::"pre-selects a stored State that matches the country's options (S-084 AC6)"` | Pass |
| 7 | Unmatched legacy state shows placeholder, does not block save | A | `BusinessForm.test.tsx::"shows an unselected State placeholder for unmatched legacy data (S-084 AC7)"` | Pass |
| 8 | City remains a required free-text input | A | `BusinessForm.test.tsx::"keeps City as free text and Latitude/Longitude as optional number inputs (S-084 AC8/AC9)"` | Pass |
| 9 | Lat/lng remain optional number inputs, no geocode feed | A | Same test (`type="number"` on both). Geocode button gone per AC2. | Pass |
| 10 | Country-only edit persists on PATCH | A | Backend: `test_business_address_reverify.py::test_country_only_first_edit_persists_without_otp`. Frontend: `BusinessForm.test.tsx::"includes the new Country in businesses.update on edit (S-084 AC10)"`. Schema: `BusinessUpdate.country` present. | Pass |
| 11 | 2nd+ address-area edit still requires OTP; country participates | A | `test_country_only_second_edit_requires_otp`; existing `test_second_address_edit_without_otp_code_400s_and_does_not_change_address`; frontend OTP-step tests retained from S-073. | Pass |
| 12 | First address-area edit / create requires no OTP | A | `test_country_only_first_edit_persists_without_otp`; `test_first_address_edit_requires_no_otp_and_increments_count`; frontend `"does not require address re-verification when creating a business"` / `"allows a first address edit..."`. | Pass |
| 13 | `GET /maps/autocomplete` and `GET /maps/geocode` are 404; no live callers of those routes / `search_addresses()` / `AddressSuggestion` | A + grep | `test_api.py::test_removed_maps_geocode_and_autocomplete_are_404`. Grep of `backend/app` (except a stale comment — see Gaps), `frontend/src`, and `mobile/packages/merchanthub_api`: no `search_addresses`, `AddressSuggestion`, or geocode/autocomplete client methods. Dead `test_maps_autocomplete.py` is gone from disk. | Pass |
| 14 | `POST /maps/nearby` and `GET /maps/config` unchanged | A + code-read | `test_api.py::test_maps_config_unchanged` (`provider: osm`, `tile_url` present). Code read: `maps.py` still exposes `/nearby` and `/config` only; `api.ts` `maps.nearby` / `maps.config` unchanged. A live `POST /nearby` against a shared Postgres was not used as a gate (see Manual). | Pass |

**Coverage:** 14 / 14 AC mapped

---

## Backend tests

### Added (Builder; independently re-run)
- `backend/tests/test_api.py::test_removed_maps_geocode_and_autocomplete_are_404`
- `backend/tests/test_api.py::test_maps_config_unchanged`
- `backend/tests/test_business_address_reverify.py::test_country_only_first_edit_persists_without_otp`
- `backend/tests/test_business_address_reverify.py::test_country_only_second_edit_requires_otp`

### Existing S-073 OTP / RBAC still green (re-run)
- First-edit no OTP; second-edit 400 / 401 / success with code
- Non-address field does not increment `address_edit_count`
- Admin bypasses OTP on 2nd edit
- Non-owner merchant `403` on `update_business` and on `request_address_verify`

### Deleted
- `backend/tests/test_maps_autocomplete.py` (dead with the routes)

### Run output (this session)
```
cd backend && python -m pytest tests/test_business_address_reverify.py \
  tests/test_api.py::test_removed_maps_geocode_and_autocomplete_are_404 \
  tests/test_api.py::test_maps_config_unchanged \
  tests/test_api.py::test_health -q

16 passed in 2.81s
```

Isolated S-084 + OTP suite used FakeDB (reverify) or no-DB HTTP (404 / config / health).
The rest of `test_api.py` talks to whatever Postgres this machine has configured; those
pre-existing DB-backed cases (`test_register_and_login` 409 on an already-registered
email, list endpoints) are **not** S-084 regressions and were not used as the gate.

---

## Frontend tests

### Added (Builder; independently re-run) — `BusinessForm.test.tsx`
- `"renders Country as a select defaulting to India (S-084 AC3)"`
- `"populates State options from the selected country (S-084 AC4)"`
- `"clears State and repopulates options when Country changes (S-084 AC5)"`
- `"pre-selects a stored State that matches the country's options (S-084 AC6)"`
- `"shows an unselected State placeholder for unmatched legacy data (S-084 AC7)"`
- `"treats street address as a plain field with no lookup UI or network calls (S-084 AC1/AC2)"`
- `"keeps City as free text and Latitude/Longitude as optional number inputs (S-084 AC8/AC9)"`
- `"includes the new Country in businesses.update on edit (S-084 AC10)"`

Country/State dataset is mocked in this file (`IN`/`US`/`SG`); cascade behavior is
proven against that stub. `countryState.ts` is a thin wrapper over `country-state-city`
Country+State subpaths (no `city.json` import) — ADR-015.

S-073 OTP UI tests on the same form were retained and still pass.

### Run output (this session)
```
cd frontend && npx jest src/components/__tests__/BusinessForm.test.tsx --silent
1 suite, 19 tests, all passed

cd frontend && npx jest --silent
Test Suites: 50 passed, 50 total
Tests:       307 passed, 307 total
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-084-01 | Merchant create/edit in a browser: Country/State dropdowns, no lookup UI | Not run — no Compose UI in this session; covered by RTL. |
| M-084-02 | `POST /api/v1/maps/nearby` against Compose returns 200 list as before | Not run — route still present in `maps.py`; config endpoint verified automatically. |
| M-084-03 | Swagger `/docs` no longer lists geocode/autocomplete | Not run; OpenAPI would omit deleted routes. `mobile/openapi.json` snapshot has no geocode/autocomplete paths (grep). |

---

## Regressions

- S-073 OTP re-verification (including country as an address-bearing field) still
  enforces 400 without code, 401 on wrong code, admin bypass, and non-owner 403.
- Full frontend suite green (307/307). No leftover `maps.geocode` / `maps.autocomplete`
  in the web client.

---

## Gaps / rework items

None material. Non-blocking nits (do **not** block PM accept):

1. `backend/app/services/review_sources/providers/google.py` module docstring still
   mentions `app/routers/maps.py`'s `geocode_address` — stale comment only; no call.
2. Slice file links `docs/agents/test-plans/TP-S-084-...md`, which was never written.
   Coverage lives in this report + the tests named above.
3. `flutter analyze` / `flutter test` still on hold. Re-run before merging if `mobile/`
   is staged (pre-commit hook).

---

## Sign-off

- [x] All 14 AC mapped to tests
- [x] RBAC tested (non-owner 403; admin OTP bypass unchanged; removed maps routes 404 for everyone)
- [x] AI disclaimer — n/a (no AI output on this slice)
- [x] Ready for PM acceptance
