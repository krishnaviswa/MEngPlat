# TP-S-056: Mobile National ID parity fix (M-73) — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-056 |
| **Author** | Tester |
| **Date** | 2026-08-17 |

---

## Scope

Narrow single-file bug fix in `mobile/lib/features/account/profile_screen.dart`: add
the missing `aadhaar` option to the National-ID-type dropdown, and make the ID-number
field's helper text role-conditional (merchant vs. customer/admin), matching web's
`ProfilePage.tsx` exactly. No backend change, no new routes, no repository change, no
OpenAPI regen required per the slice's own spec (though see Build notes in the test
report — this claim needed a correction). `business_editor_screen.dart`'s existing
generic 400 handling is explicitly unchanged (AC 5).

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Mobile widget | `flutter test` | Dropdown option set, Aadhaar persist + re-hydrate round trip, verbatim role-conditional helper copy |
| Backend | n/a | `PATCH /auth/me` unchanged since S-043 |
| Integration | Manual / code review | Confirm `business_editor_screen.dart` has zero diff in this slice (AC 5 — "unchanged" is itself the acceptance bar) |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `profile_screen_test.dart::AC1: ID type dropdown offers Select type / PAN / Aadhaar / Other national ID` |
| 2 | Automated | `profile_screen_test.dart::AC2: selecting Aadhaar and saving persists nationalIdType as aadhaar`; `::AC2: Aadhaar is re-hydrated (shown selected) the next time the profile screen loads` |
| 3 | Automated | `profile_screen_test.dart::AC3: merchant sees the merchant-specific helper copy (verbatim)` |
| 4 | Automated | `profile_screen_test.dart::AC4: customer and admin see the non-merchant helper copy (verbatim)` |
| 5 | Manual (code review) | M-001 — `git log`/`git diff` confirms `business_editor_screen.dart` is untouched by this slice's commits, so its existing generic 400-string handling is unchanged by construction |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Select Aadhaar, save via `PATCH /auth/me` | customer, merchant, admin | Allowed for all three (own profile only, unchanged server-side authorization) |
| Merchant-specific helper copy visible | merchant | Yes |
| Merchant-specific helper copy visible | customer, admin | No — sees non-merchant copy |

No server-side RBAC change in this slice; the "RBAC" here is purely client-side copy
branching by `UserResponse.role`, as documented in the Architect spec.

---

## Edge cases

- Dropdown item order matches web exactly: Select type / PAN / Aadhaar / Other.
- Helper copy is verbatim (AC 3/4 call out that even a minor paraphrase fails the AC) — tests assert the literal string via `find.text(...)`, not `find.textContaining(...)`.
- Existing customer/admin copy is unchanged from pre-slice behavior (regression, not new — asserted via the same verbatim match).

---

## Manual checklist (if applicable)

- [ ] M-001: Confirm `business_editor_screen.dart` has no diff in this slice's commit range (AC 5).

---

## Environment

- Widget tests only; `authControllerProvider` overridden with a fake `AuthController`. No `AI_PROVIDER` relevance — National ID is explicitly non-AI, self-service data.
