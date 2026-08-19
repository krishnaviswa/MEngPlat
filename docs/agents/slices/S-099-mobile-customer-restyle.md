# Slice: S-099 — Customer / guest surface restyle

| Field | Value |
|-------|-------|
| **Slice ID** | S-099 |
| **Phase** | 5 Polish |
| **Status** | Accepted |
| **Role(s)** | customer |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As a** customer  
**I want** Home, Explore, shop, favorites, notifications, account, support, and collect to use the mobile kit  
**So that** those jobs feel like one app

---

## Acceptance criteria

1. **Given** Home / Explore / shop / favorites / notifications, **when** loading or failing, **then** I see `MhSkeleton` or `MhError` with Retry.
2. **Given** Account, **when** I am signed in, **then** identity is a card and Profile/Support are `MhJobTile`s (Keys `accountIdentity`, `profileLink`, `supportLink` preserved).
3. **Given** Explore cards, **when** a photo loads, **then** `Image.network` uses `cacheWidth` so decode stays cheap.

---

## Technical specification (Architect)

- No API change; support/tickets already routed (S-094)

### Architect checklist

- [x] None

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-19 | Full cycle | Customer surfaces + S-102 support included |
