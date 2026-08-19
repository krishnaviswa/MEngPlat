# Slice: S-103 — Per-tab back stacks

| Field | Value |
|-------|-------|
| **Slice ID** | S-103 |
| **Phase** | 5 Polish |
| **Status** | Testing |
| **Role(s)** | customer, merchant, admin |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As a** mobile user  
**I want** system Back and tab switches to restore the exact previous screen  
**So that** the app feels like Instagram, not a website that replaces history

---

## Acceptance criteria

1. **Given** I opened Profile from Account, **when** I switch to Explore and back to Account, **then** Profile is still showing.
2. **Given** I open a shop from Explore, **when** I press Back, **then** I return to Explore (detail stays full-screen, no tab bar).
3. **Given** I am a guest on Explore, **when** the Explore tab is shown, **then** Favorites APIs are not called.
4. **Given** I re-tap the current tab, **when** that branch has nested routes, **then** it pops to the tab root (`goBranch` `initialLocation: true`).

---

## Out of scope

- Stories, Reels, DMs, camera

---

## Technical specification (Architect)

- Supercede ADR-005 decision (1): `StatefulShellRoute.indexedStack`; rebuild `GoRouter` on session/role so guest trees omit Favorites/Notifications/Account.
- Detail/login/collect stay on the root navigator.
- In-app back uses `popOrGo`.

### Architect checklist

- [x] API contract defined (none)
- [x] RBAC matrix complete (unchanged)
- [x] Data model impact documented (none)
- [x] Cache invalidation considered
- [x] Uses AI/storage abstractions where applicable
- [x] ERD/API/FLOWS updates noted (ADR-005)

---

## Links

- ADR: `docs/agents/adrs/ADR-005-mobile-primary-shell.md`
- Test plan: `docs/agents/test-plans/TP-S-103-per-tab-stacks.md`
- Test report: `docs/agents/test-reports/TR-S-103-per-tab-stacks.md`

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-19 | PM | Created |
| 2026-08-19 | Architect | Spec + ADR-005 amendment |
| 2026-08-19 | Builder | Implemented |
