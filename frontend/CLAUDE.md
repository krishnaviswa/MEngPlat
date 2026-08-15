# Frontend rules

> Mirrors `.cursor/rules/frontend-nextjs.mdc` (Cursor `globs: frontend/**/*`), plus the
> frontend half of `.cursor/rules/testing.mdc`. Keep both in sync — see the parity table
> in the root [`CLAUDE.md`](../CLAUDE.md).

## Rendering
- **Server Components** (default): home, search, business profile
- **`"use client"`** only for: forms, hooks, localStorage, charts, modals

## Structure
- Pages: `src/app/**/page.tsx`
- Components: `src/components/`
- API client: `src/lib/api.ts` — extend here, don't scatter fetch

## API URLs
- Browser: `NEXT_PUBLIC_API_URL`
- Server in Docker/Railway: `API_URL_INTERNAL` (see `src/lib/api.ts`) — required on Railway or SSR falls back to `localhost:8000` and Featured stays empty
- Home SSR uses `cache: "no-store"` for GETs and surfaces fetch failures via `FeaturedGrid` `loadError`

## UI
- Tailwind + `brand-*` colors
- AI UI must say "suggestion", not fact
- Reuse: BusinessCard, ReviewCard, RatingWidget, AIInsights, Dashboard
- JSDoc on components: purpose, props, state/hooks

## Auth
Tokens in localStorage (MVP); attach via `apiFetch` Authorization header.

## Local commits
Do not commit on `main` — use a feature branch + PR. `.githooks/pre-commit` enforces this
(and runs mobile analyze/test when `mobile/` is staged). See `.cursor/rules/testing.mdc`.

## Testing (Jest + RTL)
- Colocate under `__tests__/`
- Test behavior, not implementation
- Run: `cd frontend && npm test`
- Full evaluation model: `README.md` §11. Browser e2e is Playwright in `backend/tests/e2e/` (`E2E=1`), not Cypress. GitHub job `web-e2e.yml` is dispatch-only (artifact traces); not on push/PR.

## Local git hooks (every commit, IDE included)
- One-time: `git config core.hooksPath .githooks`
- Hook refuses commits on `main`/`master` — use a feature branch + PR
- If `mobile/` staged: `flutter analyze && flutter test`; emulator stays CI-only
- Full CI table: `ANDROID_APP_STRATEGY.md` § "Testing & CI flow"
- **Known gap:** frontend-tests.yml is currently `workflow_dispatch` only. Branch
  protection on `main` still must be set in GitHub Settings. See `README.md` §11.
