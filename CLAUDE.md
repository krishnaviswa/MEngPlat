# MerchantHub AI (MEngPlat)

Monorepo: local-business review platform with AI insights.

> This file is the Claude Code equivalent of `.cursor/rules/project.mdc` (Cursor's
> `alwaysApply: true` rule). It is kept in sync with `.cursor/rules/` — see
> **Cursor ↔ Claude Code parity** below.

## Stack

- Frontend: Next.js 15 App Router, React, TypeScript, Tailwind (`frontend/`)
- Backend: FastAPI, async SQLAlchemy, Pydantic (`backend/`)
- Data: PostgreSQL, Redis, local uploads (S3/Azure placeholders)
- Auth: JWT; roles: `customer` | `merchant` | `admin`

## Source of truth

`README.md` is the single project document. Sections: §2 logical design, §3 architecture,
§4 stack rationale, §5 domain model, §6 flows, §7 API, §8 frontend, §9 security,
§13 multi-agent workflow, §14 known gaps.

See also `[AGENTS.md](AGENTS.md)` for the repo map and where each tool's config lives.

## Non-negotiables

1. AI output is **suggestions**, never definitive judgments.
2. Use abstraction layers for AI (`app/services/ai/`) and storage (`app/services/storage/`).
3. Business logic in `services/`, not routers.
4. REST routes mount under `/api/v1`.
5. Keep diffs minimal; match existing patterns.
6. Never commit secrets (`.env`, API keys).
7. Local dev: `docker compose up --build`.

