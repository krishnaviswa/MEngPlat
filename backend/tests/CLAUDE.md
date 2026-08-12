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
- `cd mobile && flutter analyze && flutter test` (also enforced by `.githooks/pre-commit` when `mobile/` is staged)

## Local git hooks (every commit, IDE included)
- One-time: `git config core.hooksPath .githooks`
- Hook refuses commits on `main`/`master` — use a feature branch + PR
- If `mobile/` staged: `flutter analyze && flutter test`; emulator stays CI-only
- Full CI table: `ANDROID_APP_STRATEGY.md` § "Testing & CI flow"
- **Known gap:** branch protection on `main` (required status checks) still must be set in GitHub Settings
