# Testing (backend)

> Mirrors the backend half of `.cursor/rules/testing.mdc` (Cursor
> `globs: backend/tests/**/*,frontend/**/__tests__/**/*`). The frontend half lives in
> [`frontend/CLAUDE.md`](../../frontend/CLAUDE.md). Keep both in sync with the Cursor
> rule — see the parity table in the root [`CLAUDE.md`](../../CLAUDE.md).

Full evaluation model (pyramid, mocks, staging, Playwright plan): `README.md` §11 and
`docs/agents/adrs/ADR-009-web-functional-e2e.md`.

## Feature → test index (keep current)

Master lookup: `README.md` §11 **Feature → test index**. Slice TRs remain the AC-level map.

- **Default:** run only the backend / web / mobile files on that row. Do not run the whole suite on every fix.
- **Full cheap pack** (`pytest`, `npm test`, `flutter test`): pre-merge, shared helper (`auth_helpers`, `security.py`, `api.ts`, app shell), or when asked.
- **Playwright / emulator:** only when the index e2e column applies (auth, payments, review create, SSR) or when asked.
- Same PR as new or moved tests: add or adjust the index row.

## Backend (pytest)
- `httpx.AsyncClient` + `ASGITransport` against `app.main:app`
- Test auth, RBAC, happy path per router
- `AI_PROVIDER=mock` — no network in tests
- Email/payments/storage stay on mock/local defaults in CI

## Web browser e2e (S-010 harness)
- Do not add Cypress/Selenium
- Playwright (Python) in `backend/tests/e2e/` per ADR-009 / TP-S-010
- Opt-in: `E2E=1` with Compose (mock vendors). Default `pytest` skips e2e.
- GitHub: `.github/workflows/web-e2e.yml` is **`workflow_dispatch` only** — not on push/PR, not a deploy step. Download `playwright-traces`.
- Run against Compose or staging, never live LLM/payment keys

## Before merge (full cheap pack — not the day-to-day default)
- `cd backend && pytest`
- `cd frontend && npm test`
- `cd mobile && flutter analyze && flutter test` (also enforced by `.githooks/pre-commit` when `mobile/` is staged)

## Local git hooks (every commit, IDE included)
- One-time: `git config core.hooksPath .githooks`
- Hook refuses commits on `main`/`master` — use a feature branch + PR
- If `mobile/` staged: `flutter analyze && flutter test`; emulator stays CI-only
- Full CI table: `ANDROID_APP_STRATEGY.md` § "Testing & CI flow"
- **Known gap:** backend/frontend app-test workflows are currently dispatch-only.
  Playwright (`web-e2e.yml`) is dispatch-only **by design**. Branch protection on
  `main` still must be set in GitHub Settings. See `README.md` §11.
