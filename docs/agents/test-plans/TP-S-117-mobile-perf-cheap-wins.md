# TP-S-117: Mobile performance cheap wins — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-117 |
| **Author** | Tester |
| **Date** | 2026-08-21 |

---

## Scope

Flutter-only: isolate Home/Explore search rebuilds, `RepaintBoundary` on charts/map, display-sized `Image.network` decode. No layout or API change.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend API | — | No API change |
| Frontend web | — | No web change |
| Mobile | flutter_test | Keys, map mount, image cache dims, existing Home/Explore/dashboard tests |
| Integration | Manual | Optional profile-mode scroll; not required for AC |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `home_screen_test.dart` (hero search / Explore query) |
| 2 | Automated | `business_list_screen_test.dart` (searchField / suggestions) |
| 3 | Automated | `business_list_screen_test.dart` S-117 resultsMap absent until Map |
| 4 | Automated | `merchant_dashboard_screen_test.dart`, `platform_series_chart_test.dart`, `admin_home_screen_test.dart` (existing chart keys) |
| 5 | Automated | `business_card_test.dart` cacheWidth/cacheHeight on photo |

After tests land, update `README.md` §11 **Feature → test index**. Default verification: index-row files only.

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Unauthenticated | none | Unchanged public Home/Explore |
| Wrong role | — | N/A (no new gated API) |

---

## Edge cases

- Explore map unmounted on list
- Masked/lightbox images stay full-res (no cacheWidth on lightbox)

---

## Manual checklist (if applicable)

- [ ] M-001: On a device/emulator, Home search typing does not change section order; Explore Map toggle still works.
