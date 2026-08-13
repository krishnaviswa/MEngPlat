# TR-S-028: Mobile P1 discovery + rich business detail — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-028 |
| **Author** | Tester |
| **Date** | 2026-08-13 |
| **Recommendation** | Hold — tests authored, not executed this session |

---

## Summary

Widget/unit tests were added for every AC. **`flutter analyze` and `flutter test` were not run** (combined P1+P2 pass requested later). Do not treat this as a Ship sign-off.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Search `q` after debounce | A | `search_controller_test.dart` applyQuery q; `business_list_screen_test.dart` search field | Not run |
| 2 | Clear query | A | `search_controller_test.dart` clearing omits q | Not run |
| 3 | City, category, min rating, sort | A | `search_controller_test.dart` filters; list screen apply city | Not run |
| 4 | Live cities + categories | A | `business_list_screen_test.dart` filters sheet | Not run |
| 5 | Use my location → lat/lng/radius | A | `business_list_screen_test.dart` location success | Not run |
| 6 | Location failure, no geo filter | A | `business_list_screen_test.dart` location error snackbar | Not run |
| 7 | Radius with location | A | `search_controller_test.dart` radiusKm | Not run |
| 8 | OSM results map | A | `business_list_screen_test.dart` map toggle / `resultsMap` | Not run |
| 9 | Pin → detail | A | `business_list_screen_test.dart` map pin | Not run |
| 10 | Infinite scroll page 2 | A | `search_controller_test.dart` loadMore | Not run |
| 11 | Photo cards / placeholder | A | `business_card_test.dart` | Not run |
| 12 | Guest search chrome | A | `business_list_screen_test.dart` guest chrome | Not run |
| 13 | Description, address, phone, website | A | `business_detail_screen_test.dart` S-028 AC13 | Not run |
| 14 | All categories / omit empty | A | `business_detail_screen_test.dart` S-028 AC14 | Not run |
| 15 | Hours / not listed | A | `business_hours_test.dart` + detail S-028 AC15 | Not run |
| 16 | Gallery + lightbox / omit empty | A | `business_detail_screen_test.dart` S-028 AC16 | Not run |
| 17 | Detail map pin / omit without coords | A | `business_detail_screen_test.dart` S-028 AC17 | Not run |
| 18 | AI overview suggestion label | A | `business_detail_screen_test.dart` S-028 AC18 | Not run |
| 19 | Search error + Retry | A | `business_list_screen_test.dart` AC19 | Not run |
| 20 | Empty results | A | `business_list_screen_test.dart` AC20 | Not run |
| 21 | No bottom nav on detail | A | existing `app_shell_test.dart` AC13 | Not run |

**Coverage:** 21 / 21 AC mapped. **0 / 21 executed.**

---

## Backend tests

None (no backend change).

---

## Mobile tests

### Added

- `mobile/test/search_controller_test.dart`
- `mobile/test/business_list_screen_test.dart` (extended)
- `mobile/test/business_card_test.dart`
- `mobile/test/business_hours_test.dart`
- `mobile/test/business_detail_screen_test.dart` (S-028 cases)
- `mobile/test/app_shell_test.dart` (fake repo signature only)

### Run output

```
Not run this session. Combined `cd mobile && flutter analyze && flutter test` after P1+P2.
```

---

## Manual / integration

| ID | Check | Result |
|----|-------|--------|
| M-001 | Device GPS permission + nearby results | Not run |
| M-002 | OSM tiles on Explore map and detail pin | Not run |
| M-003 | Phone dialer / website external | Not run |
| M-004 | Emulator smoke still finds `Businesses` | Not run |

---

## Regressions

Unknown until the combined analyze+test run.

---

## Gaps / rework items

1. Execute the combined mobile analyze+test pass before PM **Accepted**.
2. M-13–M-18 remain `unimplemented` by design.

---

## Sign-off

- [x] All AC mapped to tests
- [x] RBAC: discovery is public; guest chrome covered (AC12); no new privileged APIs
- [x] AI disclaimer mapped (AC18) — not executed
- [ ] Ready for PM acceptance
