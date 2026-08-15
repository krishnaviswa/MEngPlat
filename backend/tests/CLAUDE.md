# Testing (backend)

> Mirrors the backend half of `.cursor/rules/testing.mdc` (Cursor
> `globs: backend/tests/**/*,frontend/**/__tests__/**/*`). The frontend half lives in
> [`frontend/CLAUDE.md`](../../frontend/CLAUDE.md). Keep both in sync with the Cursor
> rule — see the parity table in the root [`CLAUDE.md`](../../CLAUDE.md).

Full evaluation model (pyramid, mocks, staging, Playwright plan): `README.md` §11 and
`docs/agents/adrs/ADR-009-web-functional-e2e.md`.

## Backend (pytest)
- `httpx.AsyncClient` + `ASGITransport` against `app.main:app`
- Test auth, RBAC, happy path per router
- `AI_PROVIDER=mock` — no network in tests
- Email/payments/storage stay on mock/local defaults in CI

## Web browser e2e (not implemented — S-010)
- Do not add Cypress/Selenium
- Playwright (Python) per ADR-009 / TP-S-010 when that slice is built
- Run against Compose or staging with mock vendors, never live LLM/payment keys

## Before merge
- `cd backend && pytest`
- `cd frontend && npm test`
- `cd mobile && flutter analyze && flutter test` (also enforced by `.githooks/pre-commit` when `mobile/` is staged)

## Local git hooks (every commit, IDE included)
- One-time: `git config core.hooksPath .githooks`
- Hook refuses commits on `main`/`master` — use a feature branch + PR
- If `mobile/` staged: `flutter analyze && flutter test`; emulator stays CI-only
- Full CI table: `ANDROID_APP_STRATEGY.md` § "Testing & CI flow"
- **Known gap:** backend/frontend app-test workflows are currently dispatch-only.
  Branch protection on `main` still must be set in GitHub Settings. See `README.md` §11.
