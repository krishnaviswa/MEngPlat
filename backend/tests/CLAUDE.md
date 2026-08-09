# Testing (backend)

> Mirrors the backend half of `.cursor/rules/testing.mdc` (Cursor
> `globs: backend/tests/**/*,frontend/**/__tests__/**/*`). The frontend half lives in
> [`frontend/CLAUDE.md`](../../frontend/CLAUDE.md). Keep both in sync with the Cursor
> rule — see the parity table in the root [`CLAUDE.md`](../../CLAUDE.md).

## Backend (pytest)
- `httpx.AsyncClient` + `ASGITransport` against `app.main:app`
- Test auth, RBAC, happy path per router
- `AI_PROVIDER=mock` — no network in tests

## Before merge
- `cd backend && pytest`
- `cd frontend && npm test`
