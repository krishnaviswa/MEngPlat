# TR-S-114: Mobile Home density + merchant find-shop — Test report

| Field | Value |
|-------|-------|
| **Slice** | S-114 |
| **Author** | Tester |
| **Date** | 2026-08-20 |
| **Recommendation** | Ship |

---

## Summary

Implementation covers Alerts label, compact Home, merchant List-your-business and Account shortcuts, and merchant phone/NID reauth including Google `credential` on `POST /auth/reauth`.

---

## AC coverage matrix

| AC# | Description | Type | Test reference | Result |
|-----|-------------|------|----------------|--------|
| 1 | Alerts one-line tab | A | `app_shell_test.dart` | pending run |
| 2 | Compact Home order | A | `home_screen_test.dart` | pending run |
| 3 | Category \| Neighborhood | A | `home_screen_test.dart` AC12 | pending run |
| 4 | List your business routing | A | `home_screen_test.dart` | pending run |
| 5 | Open Shop | A | `home_screen_test.dart` | pending run |
| 6 | Account merchant tiles | A | `app_shell_test.dart` | pending run |
| 7 | Empty shop national ID CTA | A | `merchant_dashboard_screen_test.dart` | pending run |
| 8 | Merchant NID 401 without reauth | A | `test_reauth.py` | Pass |
| 9 | Google reauth credential | A | `test_reauth.py` | Pass |
| 10 | Profile reauth sheet | A | `profile_screen_test.dart` | Pass |

**Coverage:** 10 / 10 AC mapped

### Run output
- `cd backend && pytest tests/test_reauth.py`
- `cd frontend && npx jest MerchantNationalIdCard ProfilePage`
- `cd mobile && flutter test home_screen_test app_shell_test profile_screen_test`

