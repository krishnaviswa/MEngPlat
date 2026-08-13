# TP-S-028: Mobile P1 discovery + rich business detail — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-028 |
| **Author** | Tester |
| **Date** | 2026-08-13 |

---

## Scope

Flutter Explore search chrome (query, filters, location, OSM results map, infinite scroll, photo cards, guest access) and rich business detail (contact, categories, hours, gallery, map pin, AI overview labeled as a suggestion). No new backend. AppShell / tabs unchanged.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend API | — | None (no backend change) |
| Mobile unit | `flutter test` | `SearchController` query params + pagination; hours helper |
| Mobile widget | `flutter test` | Explore chrome, guest search, photo card, detail blocks, AI suggestion copy, map keys |
| Integration | Manual / emulator CI | GPS permission, OSM tiles, dial/website (existing `app_test.dart` still finds `Businesses`) |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `search_controller_test.dart` (q passed) + `business_list_screen_test.dart` (search field) |
| 2 | Automated | `search_controller_test.dart` (clear q) |
| 3 | Automated | `search_controller_test.dart` (city, category, minRating, sort) |
| 4 | Automated | `business_list_screen_test.dart` (filters sheet lists live cities/categories) |
| 5 | Automated | `business_list_screen_test.dart` (Use my location → lat/lng/radius) |
| 6 | Automated | `business_list_screen_test.dart` (location failure message, no geo params) |
| 7 | Automated | `search_controller_test.dart` (radiusKm) |
| 8 | Automated | `business_list_screen_test.dart` (map toggle → `resultsMap`) |
| 9 | Automated | `business_list_screen_test.dart` (pin → detail) |
| 10 | Automated | `search_controller_test.dart` (loadMore page 2; no extra fetch when short page) |
| 11 | Automated | `business_card_test.dart` (photo vs placeholder) |
| 12 | Automated | `business_list_screen_test.dart` (guest sees search chrome) |
| 13 | Automated | `business_detail_screen_test.dart` (description/address/phone/website; omit missing) |
| 14 | Automated | `business_detail_screen_test.dart` (all categories / omit empty) |
| 15 | Automated | `business_hours_test.dart` + detail widget (hours / not listed) |
| 16 | Automated | `business_detail_screen_test.dart` (gallery + lightbox; omit empty) |
| 17 | Automated | `business_detail_screen_test.dart` (detail map pin / omit without coords) |
| 18 | Automated | `business_detail_screen_test.dart` (AI overview suggestion label / omit null) |
| 19 | Automated | `business_list_screen_test.dart` (error + Retry) |
| 20 | Automated | `business_list_screen_test.dart` (empty state) |
| 21 | Automated | existing `app_shell_test.dart` (detail has no `primaryNav`) |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Guest Explore | anonymous | Search chrome + list/map; no Favorites tab (S-027) |
| Guest detail | anonymous | Rich profile + reviews; Add review → login (S-023) |
| Customer | customer | Same discovery; favorites on cards |
| Merchant / admin | merchant / admin | Explore search works; no new privileged search API |

Discovery endpoints are public — no 401/403 cases to add. Location is a device permission, not RBAC.

---

## Edge cases

- Debounced search does not fire on every keystroke before the timer.
- Full page (`page_size`) triggers loadMore; short page does not.
- Image.network failure uses errorBuilder placeholder.
- `ai_merchant_summary` never shown without “suggestion” labeling.

---

## Manual checklist (if applicable)

- [ ] M-001: On a device/emulator, Use my location prompts for permission and filters nearby results.
- [ ] M-002: OSM tiles render on Explore map and detail pin (not a blank box).
- [ ] M-003: Phone opens dialer; website opens an external browser.
- [ ] M-004: CI emulator smoke still finds app bar title `Businesses`.

---

## Environment

- `AI_PROVIDER=mock` (unchanged; no LLM calls)
- Widget tests fake `BusinessRepository` + `LocationService` (no plugins, no network)
- `cd mobile && flutter analyze && flutter test`
