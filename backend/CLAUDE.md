# Backend rules

> Mirrors `.cursor/rules/backend-fastapi.mdc` (Cursor `globs: backend/**/*`). Keep both
> in sync — see the parity table in the root [`CLAUDE.md`](../CLAUDE.md).

## Layering
- `routers/` — HTTP only (validation, auth, responses)
- `services/` — business logic, AI, cache, storage
- `models/` — SQLAlchemy ORM
- `schemas/` — Pydantic DTOs
- `dependencies.py` — auth helpers

## Patterns
- Async SQLAlchemy: `AsyncSession`, `await db.execute(select(...))`
- Eager-load with `selectinload` for nested JSON
- Static routes before dynamic (e.g. `/categories/all` before `/{slug}`)
- Invalidate search cache after writes: `cache_delete_pattern("search:*")`

## New endpoint checklist
1. Pydantic schema in `schemas/`
2. Router with docstring (method, auth, request, response)
3. RBAC via `require_roles(UserRole....)`
4. Update `README.md` §7 API reference
5. Pytest in `backend/tests/`

## Errors
Use `HTTPException` (401/403/404/409). Never expose stack traces.

See also: [`backend/app/models/CLAUDE.md`](app/models/CLAUDE.md) for schema conventions,
[`backend/app/services/CLAUDE.md`](app/services/CLAUDE.md) for AI/storage integrations,
and [`backend/tests/CLAUDE.md`](tests/CLAUDE.md) for testing.
