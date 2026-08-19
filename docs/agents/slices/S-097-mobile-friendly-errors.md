# Slice: S-097 — Shared empty / loading / error chrome

| Field | Value |
|-------|-------|
| **Slice ID** | S-097 |
| **Phase** | 5 Polish |
| **Status** | Accepted |
| **Role(s)** | customer \| merchant \| admin |
| **Owner** | PM / 2026-08-19 |

---

## User story

**As a** user on a slow network  
**I want** a short retryable message, not a Dio timeout dump  
**So that** I know what to do next

---

## Acceptance criteria

1. **Given** a receive/connect timeout, **when** `ApiException.fromDioException` runs, **then** the message is "That took too long. Check your connection and try again."
2. **Given** Merchant Home, **when** dashboard load fails, **then** `MhError` shows that copy with Retry — never `RequestOptions.receiveTimeout`.
3. **Given** Home, Explore, shop, Favorites, Notifications, Admin Home, **when** a provider errors, **then** they use `MhError` / `friendlyMessage`.
4. **Given** existing widget tests, **when** they find Keys, **then** those Keys still exist.

---

## Technical specification (Architect)

- `mobile/lib/ui/friendly_error.dart`, `ApiException` timeout mapping
- No API change

### Architect checklist

- [x] API contract defined (none)
- [x] RBAC unchanged
- [x] Data model none

---

## Changelog

| Date | Agent | Change |
|------|-------|--------|
| 2026-08-19 | Full cycle | Friendly errors + skeletons |
