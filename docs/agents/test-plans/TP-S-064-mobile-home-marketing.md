# TP-S-064: Mobile home marketing surfaces — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-064 |
| **Author** | Tester |
| **Date** | 2026-08-18 |

---

## Scope

Flutter widget tests for the new public `/home` marketing screen (Tier 5 rows M-13–M-18, M-76, M-77), guest shell tab changes, Explore query-param wiring for `city`/`q`, and login "Continue without signing in" destination. No backend pytest; no new API.

---

## Test strategy

| Layer | Tool | Focus |
|-------|------|-------|
| Backend API | — | Unchanged public GETs; no new tests |
| Mobile | `flutter_test` | Section order, copy, empty hides, navigation, guest chrome |
| Integration | Manual | Optional on-device scroll/contrast |

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `home_screen_test.dart` — `/home` shows `homeScreen`, not the Explore search list |
| 2 | Automated | section keys in order (dy comparison) |
| 3 | Automated | hero copy + suggestion language + explore/register actions |
| 4 | Automated | social proof label, no invented stats on the rail |
| 5 | Automated | fallback roster when slug list empty; always visible |
| 6 | Automated | three problem titles + 01/02/03 |
| 7 | Automated | four trust labels when stats present; omitted when stats null |
| 8 | Automated | city row tap → `/businesses?city=`; omitted when no cities |
| 9 | Automated | category row tap → `/businesses?category=`; omitted when none |
| 10 | Automated | featured cards + suggestion blurb; empty state |
| 11 | Automated | voices shown with suggestion label; omitted when no items |
| 12 | Automated | how-it-works + merchant CTA routes |
| 13 | Automated | `app_shell_test.dart` guest tabs include `homeTab` |
| 14 | Automated | unauthenticated `/home` not bounced to login |
| 15 | Automated | problem/social-proof have no "AI suggestion" chrome; hero/voices do where applicable |
| 16 | Automated | home uses theme `ColorScheme` (no light-only hex in new section widgets) — code inspection + render under `ThemeMode.dark` |

---

## RBAC test cases

| Case | Role | Expected |
|------|------|----------|
| Unauthenticated `/home` | none | 200 UI, no login redirect |
| Guest Sign in tab | none | `/login`, no `primaryNav` |
| Customer tabs | customer | no `homeTab` (Explore still first) |

---

## Edge cases

- Stats fetch failure → hide trust metrics
- Empty cities/categories/voices → hide those sections
- Empty featured list → empty copy, not crash
- Social proof API empty → fallback names

---

## Manual checklist (if applicable)

- [ ] M-001: Guest path login → Continue without signing in → Home scroll in light and dark
- [ ] M-002: City and category chips land on a filtered Explore list

---

## Environment

- `flutter analyze` + `flutter test` from `mobile/`
- `AI_PROVIDER=mock` (N/A for this slice)
