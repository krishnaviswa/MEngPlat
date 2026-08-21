# TR-S-117: Mobile performance cheap wins — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-117 |
| **Author** | Tester |
| **Date** | 2026-08-21 |
| **Recommendation** | Ship |

---

## Summary

Pass. Flutter cheap wins with no layout/API change. Index-row `flutter test` 86/86.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Home hero search still Explore/suggestions; typing isolated in hero | A | `home_screen_test.dart` AC3 (query `q=salon`) | Pass |
| 2 | Explore search debounce + suggestions + same keys | A | `business_list_screen_test.dart` AC1 / suggestions | Pass |
| 3 | Map absent until toggle | A | `business_list_screen_test.dart` `S-117: resultsMap is absent until Map is selected` | Pass |
| 4 | Charts/map `RepaintBoundary`; keys still find widgets | A | `merchant_dashboard_screen_test.dart`, `platform_series_chart_test.dart`, `admin_home_screen_test.dart` | Pass |
| 5 | Display-sized image decode | A | `business_card_test.dart` photo uses `ResizeImage` | Pass |

**Coverage:** 5 / 5 AC mapped

---

## Backend tests

### Added
- none

### Run output
```
n/a — no API change
```

---

## Frontend tests

### Added
- none (web)

### Run output
```
n/a
```

---

## Mobile tests

### Added
- `business_list_screen_test.dart` S-117 map mount
- `business_card_test.dart` `ResizeImage` on storefront photo

### Run output
```
cd mobile && flutter test test/home_screen_test.dart test/business_list_screen_test.dart test/business_card_test.dart test/merchant_dashboard_screen_test.dart test/platform_series_chart_test.dart test/admin_home_screen_test.dart
86/86 passed
```

---

## Manual checklist

- [ ] M-001: On device, Home search typing keeps section order; Explore Map toggle still works. (optional profile-mode)

---

## Regressions / gaps

Home first paint still waits on `homePayloadProvider` (`README.md` §14). Cursor plan was labeled S-116; that ID is Home rail — this work is S-117.

---

## Recommendation

Ship
