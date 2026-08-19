# Slice: S-101 — Admin Home restyle

| Field | Value |
|-------|-------|
| **Slice ID** | S-101 |
| **Phase** | 4 Dashboards |
| **Status** | Accepted |
| **Role(s)** | admin |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As an** admin  
**I want** Admin Home to load queues in parallel and show human errors  
**So that** ops on a phone feels fast

---

## Acceptance criteria

1. **Given** Admin Home, **when** it loads, **then** platform stats, series, pending, processing, and reported reviews fetch via `Future.wait`.
2. **Given** a failure, **when** it surfaces, **then** `MhError` + Retry; ops nav Keys unchanged (`adminOpsNav`, queue tiles).
3. **Given** drill-down queues, **when** they error, **then** messages go through `friendlyMessage`.

---

## Technical specification (Architect)

- No API change (S-093–S-095 queues stay)

### Architect checklist

- [x] None

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-19 | Full cycle | Admin parallel load + chrome |
