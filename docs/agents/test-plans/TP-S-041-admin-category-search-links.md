# TP-S-041: Admin category search links — Test plan

| Field | Value |
|-------|-------|
| **Slice** | S-041 |
| **Author** | Tester |
| **Date** | 2026-08-15 |

---

## Scope

Admin category chips and public category badges link to `/search?category={slug}`. Admin business/review tiles stay valid.

---

## AC → planned tests

| AC# | Test approach | Test ID / file |
|-----|---------------|----------------|
| 1 | Automated | `AdminCategoryPanel.test.tsx` links each chip by slug |
| 2 | Automated | `CategoryBadges.test.tsx` hrefs |
| 3 | Automated | `admin/page.test.tsx` Total businesses / Total reviews hrefs |

---

## Environment

- `AI_PROVIDER=mock`
