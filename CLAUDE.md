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

See also [`AGENTS.md`](AGENTS.md) for the repo map and where each tool's config lives.

## Non-negotiables
1. AI output is **suggestions**, never definitive judgments.
2. Use abstraction layers for AI (`app/services/ai/`) and storage (`app/services/storage/`).
3. Business logic in `services/`, not routers.
4. REST routes mount under `/api/v1`.
5. Keep diffs minimal; match existing patterns.
6. Never commit secrets (`.env`, API keys).
7. Local dev: `docker compose up --build`.

## RBAC
Use `require_roles()` from `app/dependencies.py`.

## Cursor ↔ Claude Code parity

This project is built with both Cursor and Claude Code, so config is mirrored between
`.cursor/rules/` and Claude Code's native equivalents. Whichever tool a session starts
in, the other should be able to pick up where it left off.

| Cursor (`.cursor/rules/`)     | Claude Code equivalent                  | Scope (Cursor `globs`)                |
| ------------------------------ | ---------------------------------------- | -------------------------------------- |
| `project.mdc`                  | `CLAUDE.md` (this file)                  | always applied                         |
| `backend-fastapi.mdc`          | `backend/CLAUDE.md`                      | `backend/**/*`                         |
| `database.mdc`                 | `backend/app/models/CLAUDE.md`           | `backend/app/models/**/*`              |
| `ai-and-integrations.mdc`      | `backend/app/services/CLAUDE.md`         | `backend/app/services/**/*`            |
| `testing.mdc`                  | `backend/tests/CLAUDE.md` + `frontend/CLAUDE.md` | `backend/tests/**/*`, `frontend/**/__tests__/**/*` |
| `frontend-nextjs.mdc`          | `frontend/CLAUDE.md`                     | `frontend/**/*`                        |
| `docs-and-api.mdc`             | `docs/CLAUDE.md`                         | `README.md`, `docs/**/*`               |
| `agents/role-product-manager.mdc` | `.claude/agents/product-manager.md`   | invoked as subagent                    |
| `agents/role-architect.mdc`    | `.claude/agents/architect.md`            | invoked as subagent                    |
| `agents/role-tester.mdc`       | `.claude/agents/tester.md`               | invoked as subagent                    |
| `agents/workflow.mdc`          | "Multi-agent workflow" section below     | orchestration guidance                 |

Claude Code loads nested `CLAUDE.md` files automatically when it works in that directory,
the same way Cursor auto-attaches a rule when a file matches its `globs`.

**Sync rule:** if you change conventions in one tool's config, port the change to the
other's in the same commit. Don't let them drift. This is enforced, not just advisory —
see [`scripts/check_agent_config_sync.py`](scripts/check_agent_config_sync.py) and
`README.md` §12 for the pre-commit hook and CI check that fail when a pair falls out of
sync.

## Multi-agent workflow

Full detail lives in `README.md` §13 and `.cursor/rules/agents/workflow.mdc`. Summary:

```
PM (slice brief) → Architect (tech spec) → Builder (code) → Tester (report) → PM (accept)
```

Do not skip stages, and do not implement before the Architect fills the technical
specification section and sets the slice `Status: Specified`.

| Stage | Output | Path |
|---|---|---|
| PM | Slice brief | `docs/agents/slices/S-XXX-*.md` (copy `_TEMPLATE.md`) |
| Architect | Tech spec + optional ADR | Same slice file + `docs/agents/adrs/` |
| Builder | Code + doc updates | `backend/`, `frontend/`, `README.md` §7 |
| Tester | Test plan + report | `docs/agents/test-plans/`, `docs/agents/test-reports/` |
| PM | Accept / rework | Update slice `Status` field |

**Invoking a role:** use the Agent tool with `subagent_type: product-manager`,
`architect`, or `tester` (defined in `.claude/agents/`), or say *"Act as Product Manager
for slice S-00X"* in-conversation. Builder work uses this file plus the nested
`CLAUDE.md` guides above — there is no separate Builder subagent.

Conflict resolution and slice sizing rules match `README.md` §13 exactly — don't
duplicate them here; read that section when running the workflow.
