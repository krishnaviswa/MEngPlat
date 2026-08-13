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
§12 repo layout (incl. Web ↔ mobile feature parity tracker), §13 multi-agent workflow,
§14 known gaps.

See also `[AGENTS.md](AGENTS.md)` for the repo map and where each tool's config lives.

## Non-negotiables

1. AI output is **suggestions**, never definitive judgments.
2. Use abstraction layers for AI (`app/services/ai/`) and storage (`app/services/storage/`).
3. Business logic in `services/`, not routers.
4. REST routes mount under `/api/v1`.
5. Keep diffs minimal; match existing patterns.
6. Never commit secrets (`.env`, API keys).
7. Local dev: `docker compose up --build`.
8. Testing is tiered, never skipped for speed — cheap checks (lint/unit) run on every push;
   expensive checks (mobile emulator integration) only ever cancel *stale, superseded* runs,
   never the check itself. Local `.githooks/pre-commit` refuses commits on `main` and runs
   `flutter analyze && flutter test` when `mobile/` is staged (enable with
   `git config core.hooksPath .githooks`). See `.cursor/rules/testing.mdc` and, for mobile CI
   specifics, `ANDROID_APP_STRATEGY.md` § "Testing & CI flow" (includes a known gap: `main`
   isn't yet branch-protection-gated on CI passing, so Railway can still deploy a failing build).

## Multi-agent workflow

Mirrors `.cursor/rules/agents/workflow.mdc`. Sequence (mandatory):

```
PM (slice brief) → Architect (tech spec) → Builder (code) → Tester (report) → PM (accept)
```

Do not skip steps. Do not implement before Architect fills the technical section.

Roles are subagents in `.claude/agents/` (`product-manager.md`, `architect.md`, `tester.md`) —
invoke explicitly, e.g. *"Act as Product Manager for slice S-00X"*, or the Agent tool with
`subagent_type: architect`.

### Definition of done (full cycle)

- [ ] All acceptance criteria numbered and testable
- [ ] Architect checklist complete on slice file
- [ ] Code on a **feature branch** + PR (never commit directly on `main`; `.githooks/pre-commit` enforces this locally — see `testing.mdc` / `ANDROID_APP_STRATEGY.md`)
- [ ] Every AC mapped to a test in test report
- [ ] If the slice adds or changes a **user-facing web** capability, `README.md` §12 Web ↔ mobile feature parity tracker has a matching row (usually `unimplemented` / `partial` / `future` until mobile follows)
- [ ] If the slice closes a **mobile** gap, the same §12 tracker row is updated to `implemented` or `partial`
- [ ] PM set `Status: Accepted` on slice file

### Cursor parity

Keep this section and `.cursor/rules/agents/workflow.mdc` in sync (enforced by
`scripts/check_agent_config_sync.py`).

## Cursor ↔ Claude Code parity

This project is built with both Cursor and Claude Code. Every rule in `.cursor/rules/`
has a mirror in Claude Code's native config:

| This Cursor rule | Mirrors |
| ----- | ---- |
| `project.mdc` (this file's stack/source/non-negotiables) | `CLAUDE.md` (root) |
| `backend-fastapi.mdc` | `backend/CLAUDE.md` |
| `frontend-nextjs.mdc` | `frontend/CLAUDE.md` |
| `ai-and-integrations.mdc` | `backend/app/services/CLAUDE.md` |
| `database.mdc` | `backend/app/models/CLAUDE.md` |
| `docs-and-api.mdc` | `docs/CLAUDE.md` |
| `testing.mdc` | `backend/tests/CLAUDE.md`, `frontend/CLAUDE.md` |
| `agents/workflow.mdc` | "Multi-agent workflow" section of `CLAUDE.md` (this file) |
| `agents/role-product-manager.mdc` | `.claude/agents/product-manager.md` |
| `agents/role-architect.mdc` | `.claude/agents/architect.md` |
| `agents/role-tester.mdc` | `.claude/agents/tester.md` |

**Sync rule:** if you change a convention here, port it to the matching Claude Code file
in the same commit, and vice versa. Enforced by `scripts/check_agent_config_sync.py`.
