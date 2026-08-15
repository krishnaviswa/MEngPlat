# Slice: S-041 — Admin category chips open search

| Field | Value |
|-------|-------|
| **Slice ID** | S-041 |
| **Phase** | 5 Polish |
| **Status** | Accepted |
| **Role(s)** | admin, customer |
| **Owner** | PM / 2026-08-15 |

---

## User story

**As an** admin  
**I want** category chips on the admin panel to open the public search filtered by that category  
**So that** I can see which listings sit in a category instead of clicking labels that do nothing

---

## Acceptance criteria

1. **Given** the admin Categories panel has at least one category, **when** I click a category chip, **then** I go to `/search?category={slug}` (same contract as the home category index).
2. **Given** a business detail page shows category badges, **when** I click a badge, **then** I go to the same `/search?category={slug}` URL.
3. **Given** the admin home tiles Total businesses and Total reviews, **when** those links are rendered, **then** they still point at `/admin/businesses` and `/admin/reviews` (no regression).

---

## UX notes

- Screens: `/admin` Categories section; business detail `CategoryBadges`.
- Create-category form unchanged.
- AI disclaimer required? no

---

## Out of scope

- Category edit/delete
- Map provider changes

---

## Dependencies

- S-034 (admin category UI), existing search `category` slug filter

---

## Definition of done (PM)

- [x] All AC verified in test report
- [x] UX matches notes above
- [x] Documented in `README.md` §8 / §12
- [x] PM Status set to **Accepted**

---

## Technical specification (Architect)

### API contract

No new endpoints. Reuse `GET /search/businesses?category={slug}`.

### RBAC matrix

| Action | customer | merchant | admin |
|--------|----------|----------|-------|
| Follow category chip to public search | yes | yes | yes |

### Data model impact

- [x] None

### Cache / side effects

None. Search cache keys already include category.

### Frontend

- **Route:** `/admin`, `/search`, `/businesses/[slug]`
- **Rendering:** CSR admin panel; SSR search
- **Components:** `AdminCategoryPanel`, `CategoryBadges`

### Architect checklist

- [x] API contract defined
- [x] RBAC matrix complete
- [x] Data model impact documented
- [x] Cache invalidation considered
- [x] Uses AI/storage abstractions where applicable
- [x] ERD/API/FLOWS updates noted

### Risks / tradeoffs

Admin leaves `/admin` when clicking a chip (full navigation). Acceptable — same as home index.

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-041-admin-category-search-links.md`
- Test report: `docs/agents/test-reports/TR-S-041-admin-category-search-links.md`

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-15 | PM | Created slice. |
| 2026-08-15 | Architect | No API; chips reuse search slug. |
| 2026-08-15 | Builder | Linked admin chips and CategoryBadges. |
| 2026-08-15 | Tester / PM | Accepted. |
