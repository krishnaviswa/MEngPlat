# TR-S-031: Mobile P4 merchant + admin — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-031 |
| **Author** | Tester |
| **Date** | 2026-08-14 |
| **Recommendation** | Hold — tests authored, not executed |

---

## Summary

Widget tests cover dashboard empty/stats/insights, editor validation, admin stats, and reply composer. **`flutter analyze` and `flutter test` were not run.**

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Merchant dashboard not stub | A | `merchant_dashboard_screen_test.dart` | Not run |
| 2 | Multi-business selector | A | same | Not run |
| 3 | Empty + create CTA | A | same | Not run |
| 4 | Stats tiles | A | same | Not run |
| 5 | Total reviews scrolls | M | M-001 | Not run |
| 6 | Average rating scrolls | M | M-001 | Not run |
| 7 | Status navigates | M | M-001 | Not run |
| 8 | Sentiment bars | A | dashboard pump finds breakdown | Not run |
| 9 | AI suggestions only | A | `aiInsightsDisclaimer` | Not run |
| 10 | Refresh AI | M | M-001 | Not run |
| 11 | Reply composer | A | `review_card_test.dart` S-031 | Not run |
| 12 | Existing reply hides composer | A | `review_card_test.dart` AC7 | Not run |
| 13 | Create validation | A | `business_editor_screen_test.dart` | Not run |
| 14 | Edit save | M | M-002 | Not run |
| 15 | Role gate nested paths | A | router `startsWith` + app_shell | Not run |
| 16 | Admin platform stats | A | `admin_home_screen_test.dart` | Not run |
| 17 | Approve/suspend | M | M-003 | Not run |
| 18 | Moderate reported | M | M-003 | Not run |
| 19 | All businesses | M | M-003 | Not run |
| 20 | All reviews | M | M-003 | Not run |
| 21 | Non-admin blocked | A | existing redirect | Not run |
| 22 | Tabs unchanged; full-screen login/detail | A | `app_shell_test.dart` | Not run |

**Coverage:** 22 / 22 AC mapped. **0 / 22 executed.**

---

## Mobile tests

### Added

- `mobile/test/merchant_dashboard_screen_test.dart`
- `mobile/test/admin_home_screen_test.dart`
- `mobile/test/business_editor_screen_test.dart`

### Run output

```
Not run this session.
```

---

## Sign-off

- [x] All AC mapped
- [x] AI disclaimer on insights panel
- [ ] Executed
- [ ] Ready for PM acceptance after combined flutter pass
