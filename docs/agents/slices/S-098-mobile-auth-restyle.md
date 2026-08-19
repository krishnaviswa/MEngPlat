# Slice: S-098 — Auth screens restyle

| Field | Value |
|-------|-------|
| **Slice ID** | S-098 |
| **Phase** | 5 Polish |
| **Status** | Accepted |
| **Role(s)** | customer \| merchant \| admin |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As a** guest  
**I want** sign-in / register / forgot-password to feel branded and fast  
**So that** I trust the app before I type a password

---

## Acceptance criteria

1. **Given** `/login`, **when** I open it, **then** I see `MhAuthHeader` + brand gradient, and existing Keys (`emailField`, `submitButton`, OTP, Google) still work.
2. **Given** `/register` and `/forgot-password`, **when** I open them, **then** they use the same header pattern and `friendlyMessage` on errors.

---

## Technical specification (Architect)

- Visual only; no auth API change

### Architect checklist

- [x] None

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-19 | Full cycle | Auth chrome |
