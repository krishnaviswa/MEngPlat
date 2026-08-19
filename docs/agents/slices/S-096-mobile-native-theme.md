# Slice: S-096 — Mobile native theme + UI kit

| Field | Value |
|-------|-------|
| **Slice ID** | S-096 |
| **Phase** | 5 Polish |
| **Status** | Accepted |
| **Role(s)** | customer \| merchant \| admin |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As a** mobile user  
**I want** MerchantHub to use the brand tokens and job-sized chrome, not stock indigo Material  
**So that** the app feels like the product, not a cloned web dump

---

## Acceptance criteria

1. **Given** the Flutter app, **when** it launches, **then** light/dark `ThemeData` comes from `MhTheme` (brand `#0ea5e9` ramp), not `colorSchemeSeed: Colors.indigo`.
2. **Given** Figma, **when** I open **MerchantHub AI — Mobile** (`rk4RnruVFTpKdIsgGJIt9w`), **then** I see Cover + Screens (390pt) and Color Light/Dark tokens aliased to the same brand primitives as web.
3. **Given** screens, **when** they compose UI, **then** they can use `MhCard` / `MhStatTile` / `MhJobTile` / `MhEmpty` / `MhError` / `MhSkeleton` from `mobile/lib/ui/`.
4. **Given** README design system, **when** a visual value disagrees, **then** Figma Mobile wins for Flutter (`MhTokens`) the same way the web file wins for Tailwind.

---

## UX notes

- Figma: https://www.figma.com/design/rk4RnruVFTpKdIsgGJIt9w
- Web DS unchanged: `X0XXhJiwW8SxFdMf39n2t3`
- States: skeleton loading, human errors, empty with CTA

---

## Out of scope

- New APIs; M-54/M-65/M-71/M-74/FCM; restyling Next.js

---

## Technical specification (Architect)

- No API/RBAC/schema change
- `mobile/lib/ui/theme.dart` + `tokens.dart` + `widgets.dart`
- Proof: `app.dart` swaps theme; Merchant hub uses `MhJobTile`

### Architect checklist

- [x] API contract defined (none)
- [x] RBAC matrix complete (unchanged)
- [x] Data model impact documented (none)
- [x] Cache invalidation considered (n/a)
- [x] Uses AI/storage abstractions where applicable (n/a)
- [x] ERD/API/FLOWS updates noted (README design system)

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-19 | PM / Architect / Builder / Tester | Native mobile DS + Flutter kit |
