# TR-S-064: Mobile home marketing surfaces — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-064 |
| **Author** | Tester |
| **Date** | 2026-08-18 |
| **Recommendation** | Ship |

---

## Summary

Pass. Public `/home` (`HomeScreen`) ships the web home-section order on Flutter. Guest chrome is Home / Explore / Sign in; "Continue without signing in" lands on `/home`; signed-in tabs unchanged. All 16 AC mapped and passing. `flutter analyze` clean; `flutter test` 240/240.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Dedicated `/home`, not Explore | A | `home_screen_test.dart` AC1/AC2 (`homeScreen`, no `searchField`) | Pass |
| 2 | Web section order | A | same test — key `dy` order | Pass |
| 3 | Hero copy + suggestion + CTAs | A | AC3 explore `?q=` + register | Pass |
| 4 | Social proof label, no stats | A | AC4/AC5 | Pass |
| 5 | Fallback roster always shown | A | AC4/AC5 `Copper Kettle Cafe` | Pass |
| 6 | Problem 01/02/03 copy | A | AC6/AC15 | Pass |
| 7 | Trust metrics show/hide | A | AC7 | Pass |
| 8 | City index → `?city=`; hide empty | A | AC8 + `business_list_screen_test.dart` S-064 city param | Pass |
| 9 | Category index → `?category=`; hide empty | A | AC9 + existing S-061 category param | Pass |
| 10 | Featured cards + suggestion + empty | A | AC10 | Pass |
| 11 | Voices + suggestion; hide empty | A | AC11 | Pass |
| 12 | How it works + merchant CTA | A | AC12 | Pass |
| 13 | Guest tabs Home/Explore/Sign in | A | `app_shell_test.dart` AC4/AC10 (+ customer has no `homeTab`) | Pass |
| 14 | `/home` public carve-out | A | AC14 + app_shell guest path to `homeScreen` | Pass |
| 15 | AI disclaimer placement | A | AC6 (none on problem) + AC3/AC11/AC12 (suggestion where AI) | Pass |
| 16 | Dark `ColorScheme` render | A | AC16 | Pass |

**Coverage:** 16 / 16 AC mapped

---

## Backend tests

### Added
- None (no backend change)

### Run output
```
n/a
```

---

## Frontend tests

### Added
- `mobile/test/home_screen_test.dart` (12 widget tests)
- `mobile/test/business_list_screen_test.dart` — `?city=` / `?q=` first-frame filters
- `mobile/test/app_shell_test.dart` — guest Home tab + continue-as-guest → `/home`

### Run output
```
cd mobile && flutter analyze — No issues found
cd mobile && flutter test — 240/240 passed
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | Guest login → Continue without signing in → Home scroll light/dark | Not run (no device in this session) |
| M-002 | City/category tap filtered Explore | Pass via automated tap + query-param tests |

---

## Regressions

None. Signed-in shell tests still pass (no `homeTab` on customer/merchant/admin).

---

## Gaps / rework items

None blocking. Cold start remains `/login` by Architect decision (surfaces exist; login chrome not replaced).

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC tested (public `/home`; guest tabs only)
- [x] AI disclaimer verified (hero / Compare / featured / voices)
- [x] Ready for PM acceptance
