# Integration rules

> Mirrors `.cursor/rules/ai-and-integrations.mdc` (Cursor `globs: backend/app/services/**/*`).
> Keep both in sync — see the parity table in the root [`CLAUDE.md`](../../../CLAUDE.md).

## AI
- Implement `AIProvider` in `app/services/ai/base.py`
- Factory: `get_ai_provider()` — never call LLM APIs from routers
- Config: `AI_PROVIDER`, `AI_API_KEY`, `AI_BASE_URL`, `AI_MODEL`
- Default: `MockAIProvider` for local dev and tests

## AI copy
- Hedged language: "appears", "suggestion", "may indicate"
- Store raw response in `ai_analyses.raw_response`

## Storage
- Use `get_storage_provider()` — don't write files directly from routers
- Dev: `local`; prod: implement S3/Azure placeholder classes

## Maps
Placeholder only in `app/routers/maps.py` until Google Maps is wired.
