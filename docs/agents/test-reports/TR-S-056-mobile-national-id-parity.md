# TR-S-056: Mobile National ID parity fix (M-73) — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-056 |
| **Author** | Tester |
| **Date** | 2026-08-17 |
| **Recommendation** | Ship |

---

## Summary

Pass. All 5 ACs mapped: 4/5 automated and passing (`profile_screen_test.dart`, 5 new
widget tests extending the existing file), 1/5 (AC 5, "unchanged" behavior) verified by
code review rather than a widget test, since AC 5 is itself a claim of non-change to a
file this slice doesn't touch. `flutter analyze` → "No issues found!" and `flutter test`
→ "All tests passed!" (**149 tests** total across the mobile suite), both re-run and
confirmed directly by this Tester pass. See Build notes below for a **spec correction**:
the Architect's technical specification stated no OpenAPI regeneration was needed for
this slice ("`NationalIdType.aadhaar` already exists in the generated `merchanthub_api`
package") — this was incorrect, and the regen the Builder performed anyway was in fact
necessary for this slice's AC 1/2 to be achievable at all.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|-----------------|--------|
| 1 | ID-type dropdown shows all 4 options incl. Aadhaar | A | `profile_screen_test.dart::AC1: ID type dropdown offers Select type / PAN / Aadhaar / Other national ID` | Pass |
| 2 | Aadhaar selection persists via `PATCH /auth/me` and re-hydrates on reload | A | `profile_screen_test.dart::AC2: selecting Aadhaar and saving persists nationalIdType as aadhaar`; `::AC2: Aadhaar is re-hydrated (shown selected) the next time the profile screen loads` | Pass |
| 3 | Merchant sees merchant-specific helper copy (verbatim) | A | `profile_screen_test.dart::AC3: merchant sees the merchant-specific helper copy (verbatim)` | Pass |
| 4 | Customer/admin see non-merchant helper copy (verbatim, unchanged) | A | `profile_screen_test.dart::AC4: customer and admin see the non-merchant helper copy (verbatim)` | Pass |
| 5 | `business_editor_screen.dart`'s existing 400-string handling unchanged | M | M-001 (code review) — `git log --oneline -- mobile/lib/features/businesses/business_editor_screen.dart` shows zero commits touching this file within this slice's branch history; the file's generic 400 handling is unchanged by construction | Pass (manual) |

**Coverage:** 5 / 5 AC mapped (4 automated, 1 manual/code-review).

---

## Backend tests

### Added
- None — no backend change in this slice; `PATCH /auth/me` and the `NationalIdType.AADHAAR` enum value unchanged since S-043.

### Run output
```
n/a — no backend changes in this slice
```

---

## Frontend tests

### Added
- n/a — web `ProfilePage.tsx` (S-043) unchanged; this slice's copy is asserted to match it verbatim.

### Mobile tests added
- `mobile/test/profile_screen_test.dart` extended with 5 new widget tests (AC 1–4; pre-existing tests in the same file for the base profile-edit form, AC 13–17 from S-029, are untouched and still pass).

### Run output
```
cd mobile && flutter analyze
Analyzing mobile...
No issues found! (ran in 11.4s)

cd mobile && flutter test
00:52 +149: All tests passed!
```
Both commands re-run directly by this Tester pass. 149 is the full-suite count across all mobile test files.

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | `git log`/`git diff` confirms `business_editor_screen.dart` has no changes in this slice (AC 5) | Pass — verified via `git log --oneline -- mobile/lib/features/businesses/business_editor_screen.dart` against the current branch's commit range, no matching commits |

---

## Regressions

- None observed. Pre-existing `profile_screen_test.dart` cases (base edit form, save success/error, read-only email/role) still pass unmodified alongside the 5 new National ID cases.
- Full 149-test suite passed.

---

## Build notes (not mapped to an S-056 AC — flagged for PM visibility)

1. **Architect spec correction — OpenAPI regen was in fact required.** The Technical
   specification's "Mobile (Frontend)" section states: *"No OpenAPI regeneration is
   needed — `NationalIdType.aadhaar` already exists in the generated `merchanthub_api`
   package (the backend enum and its generated Dart counterpart were never the bug;
   only `profile_screen.dart` fails to expose the option in its dropdown `items`
   list)."* This was **incorrect**. The checked-in `merchanthub_api` client was stale:
   it was missing 4 auth endpoints (the ones needed by S-054/S-055) **and** missing the
   `aadhaar` enum value entirely, even though the backend has had it since S-043. The
   Builder regenerated the client as part of this session's combined work; without that
   regen, this slice's AC 1 (Aadhaar option in the dropdown) and AC 2 (persisting/
   re-hydrating `NationalIdType.aadhaar`) would not have been achievable — the Dart
   enum literally would not have had an `aadhaar` value to reference. This is flagged
   here as feedback for the Architect role, not as a defect in the shipped code: the
   regen happened, the ACs pass, but the spec's stated rationale for skipping it was
   wrong and should not be repeated for future single-file "no codegen needed" slices
   without first confirming the generated client is actually up to date.
2. **Unplanned 4th fix — nullable `UserResponse.email`.** Regenerating the client (for
   reason 1 above, combined with S-054/S-055's own regen needs) surfaced a pre-existing
   latent bug: `UserResponse.email` is correctly nullable server-side (a phone-OTP
   account, per S-055/M-74, has `email=None`), but three screens —
   `account_screen.dart`, `profile_screen.dart` (this slice's own file), and
   `role_home_screen.dart` — assumed it was always non-null. Fixed with
   null-coalescing fallbacks. Not required by any of this slice's own ACs, but
   noted here since one of the three touched files (`profile_screen.dart`) is the same
   file this slice modifies, and a reviewer diffing that file for this slice will see
   an extra unrelated-looking hunk. See `TR-S-055`'s Build notes for the fuller
   rationale (it's most directly relevant to phone-OTP accounts).

---

## Gaps / rework items

None blocking. Recommend the Architect role note the codegen-currency lesson from
Build note 1 above for future "no regen needed" scope calls.

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested (client-side copy branching only, per Architect spec; no server authorization change to test)
- [x] AI disclaimer N/A (National ID explicitly non-AI, per PM's UX notes)
- [x] Ready for PM acceptance
