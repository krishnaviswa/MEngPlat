# Database rules

> Mirrors `.cursor/rules/database.mdc` (Cursor `globs: backend/app/models/**/*`). Keep
> both in sync — see the parity table in the root [`CLAUDE.md`](../../../CLAUDE.md).

- PostgreSQL, normalized — see `README.md` §5 Domain model
- UUID PKs, timezone-aware timestamps
- Enums: UserRole, BusinessStatus, ReviewStatus, Sentiment

## Model changes
1. Update SQLAlchemy model
2. Update Pydantic schemas
3. Update `README.md` §5 Domain model
4. Update `backend/scripts/seed.py` if needed

## Naming
- Tables: plural snake_case
- Avoid reserved names (use `extra_data`, not `metadata`)

## Moderation
Use `ReviewStatus` enum; prefer status changes over hard deletes.
