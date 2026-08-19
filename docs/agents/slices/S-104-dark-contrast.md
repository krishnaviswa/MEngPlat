# Slice: S-104 — Dark contrast + list refresh

| Field | Value |
|-------|-------|
| **Slice ID** | S-104 |
| **Phase** | 5 Polish |
| **Status** | Testing |
| **Role(s)** | customer, merchant, admin |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As a** user in dark mode  
**I want** body text, nav labels, and buttons to stay readable  
**So that** I can use the app at night

---

## Acceptance criteria

1. **Given** dark theme, **when** a filled button is shown, **then** `onPrimary` is white, not light-mode ink.
2. **Given** dark theme, **when** NavigationBar labels render, **then** they use `mutedDark`, not light muted/ink.
3. **Given** Explore list, **when** I pull to refresh, **then** search reloads (existing API).
4. **Given** Favorites and Notifications, **when** I pull to refresh, **then** those lists reload (already present).

---

## Out of scope

- Replacing Figma hex placeholders for web

---

## Technical specification (Architect)

- Dark `ColorScheme.primary` = brand500, `onPrimary` = white.
- Featured badge and photo placeholder follow `washFor`/`inkFor`.
- Explore `RefreshIndicator` → `SearchController.reload()`.

### Architect checklist

- [x] API contract defined (none)
- [x] RBAC matrix complete
- [x] Data model impact documented (none)
- [x] Cache invalidation considered
- [x] Uses AI/storage abstractions where applicable
- [x] ERD/API/FLOWS updates noted

---

## Links

- Test plan: `docs/agents/test-plans/TP-S-104-dark-contrast.md`
- Test report: `docs/agents/test-reports/TR-S-104-dark-contrast.md`

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-19 | PM | Created |
| 2026-08-19 | Architect | Spec |
| 2026-08-19 | Builder | Implemented |
