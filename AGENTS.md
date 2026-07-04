# MerchantHub AI — Agent Guide

This repo is **MerchantHub AI** (MEngPlat): a full-stack merchant engagement platform with AI-powered review analysis.

## Start here
- **Product spec:** [`docs/MERCHANTHUB_AI_BUILD_PROMPT.md`](docs/MERCHANTHUB_AI_BUILD_PROMPT.md)
- **Architecture:** [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- **API:** [`docs/API_REFERENCE.md`](docs/API_REFERENCE.md) and live Swagger at `/docs`

## Project layout
- `backend/` — FastAPI, SQLAlchemy, `/api/v1` REST API
- `frontend/` — Next.js 15 App Router, Tailwind
- `docs/` — architecture, flows, ERD, deployment guides
- `.cursor/rules/` — Cursor AI rules for this project

## Local development
```bash
docker compose up --build
```
- Frontend: http://localhost:3000
- Backend: http://localhost:8000

---

## Multi-agent workflow

Three specialized agents collaborate via **shared artifacts** in `docs/agents/`:

| Agent | Rule file | Artifacts |
|-------|-----------|-----------|
| **Product Manager** | `.cursor/rules/agents/role-product-manager.mdc` | `docs/agents/slices/` |
| **Architect** | `.cursor/rules/agents/role-architect.mdc` | Tech spec on slice + `docs/agents/adrs/` |
| **Tester** | `.cursor/rules/agents/role-tester.mdc` | `test-plans/`, `test-reports/` |
| **Orchestration** | `.cursor/rules/agents/workflow.mdc` | [`docs/agents/WORKFLOW.md`](docs/agents/WORKFLOW.md) |

**Cycle:** PM (slice brief) → Architect (tech spec) → Builder (code) → Tester (report) → PM (accept)

**Example prompts:**
- *"Act as Product Manager. Create slice S-007 for admin moderation."*
- *"Act as Architect. Add technical spec to S-007."*
- *"Act as Tester. Verify S-007 and write test report."*
- *"Run full multi-agent cycle for S-007."*

**Builder** (implementation) uses the rules below.

---

## Cursor rules (builder layer)

| Rule | Scope |
|------|-------|
| `project.mdc` | Always apply |
| `backend-fastapi.mdc` | `backend/**/*` |
| `frontend-nextjs.mdc` | `frontend/**/*` |
| `ai-and-integrations.mdc` | `backend/app/services/**/*` |
| `database.mdc` | `backend/app/models/**/*` |
| `docs-and-api.mdc` | `docs/**/*` |
| `testing.mdc` | test files |

## Cursor rules (agent layer)

| Rule | Scope |
|------|-------|
| `agents/workflow.mdc` | Multi-agent orchestration |
| `agents/role-product-manager.mdc` | `docs/agents/slices/**/*` |
| `agents/role-architect.mdc` | slices, adrs, architecture docs |
| `agents/role-tester.mdc` | test plans, reports, test code |

---

## Agent artifact templates

| Template | Path |
|----------|------|
| Slice | `docs/agents/slices/_TEMPLATE.md` |
| ADR | `docs/agents/adrs/_TEMPLATE.md` |
| Test plan | `docs/agents/test-plans/_TEMPLATE.md` |
| Test report | `docs/agents/test-reports/_TEMPLATE.md` |
| **End-to-end example** | [`docs/agents/EXAMPLE-END-TO-END.md`](docs/agents/EXAMPLE-END-TO-END.md) |

See [`docs/agents/WORKFLOW.md`](docs/agents/WORKFLOW.md) for the full playbook and slice backlog.
