# Slice: S-013 — Search pagination, sort, live categories

| Field | Value |
|-------|-------|
| **Slice ID** | S-013 |
| **Phase** | 2 Core |
| **Status** | Accepted |
| **Role(s)** | customer \| merchant \| admin (public search) |
| **Owner** | Builder (no prior worktree; implemented on main) |

---

## User story

**As a** visitor searching for businesses  
**I want** pagination, sort options, and a live category list  
**So that** I can browse large result sets without hardcoded filters

---

## Acceptance criteria

1. **Given** search results, **when** I am on page 1 with a full page of results, **then** I see a Next control that advances `page` in the URL.
2. **Given** I am on page 2+, **when** the page renders, **then** I see a Previous control.
3. **Given** the categories API is available, **when** the filter panel renders, **then** the category `<select>` is populated from `GET /businesses/categories/all` (not a hardcoded list).
4. **Given** I choose a sort option, **when** I apply filters, **then** `sort=rating|name|reviews` is sent to `GET /search/businesses`.

---

## Technical specification (Architect)

### API contract

| Method | Path | Auth | Notes |
|--------|------|------|-------|
| GET | `/api/v1/search/businesses` | Public | Existing; added `sort` query (`rating` default, `name`, `reviews`) |
| GET | `/api/v1/businesses/categories/all` | Public | Existing, reused |

### Frontend

- Route: `/search`
- Rendering: SSR
- Components: `FilterPanel` (categories + sort), pagination links on `search/page.tsx`

### Data model impact

- [x] None

---

## Definition of done (PM)

- [x] Pagination / sort / live categories on `/search`
- [x] Documented in README §7 (`sort` query param)
- [x] Status: **Accepted**
