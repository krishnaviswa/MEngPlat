# MerchantHub AI — Agent Guide

This repo is **MerchantHub AI** (MEngPlat): a full-stack merchant engagement platform with AI-powered review analysis. FastAPI backend, Next.js 15 frontend, PostgreSQL, Redis.

## Start here

**[`README.md`](README.md) is the single source of truth** — architecture, API reference, domain model, security, deployment, and the multi-agent workflow all live there.

| You need | Read |
|---|---|
| Product context and design rationale | README §2–§4 |
| API contracts | README §7, plus live Swagger at `/docs` |
| Data model | README §5 |
| Security model and known weaknesses | README §9 |
| The PM → Architect → Builder → Tester cycle | README §13 |
| What is *not* built yet | README §14 |

## Layout

- `backend/` — FastAPI, SQLAlchemy, `/api/v1` REST API
- `frontend/` — Next.js 15 App Router, Tailwind
- `docs/agents/` — live artifacts for the multi-agent workflow (templates + slices)
- `.cursor/rules/` — Cursor rules; loaded automatically by `alwaysApply` and `globs`

## Local development

```bash
docker compose up --build
```

Frontend http://localhost:3000 · Backend http://localhost:8000 · Swagger http://localhost:8000/docs

## Artifact templates

| Template | Path |
|---|---|
| Slice | [`docs/agents/slices/_TEMPLATE.md`](docs/agents/slices/_TEMPLATE.md) |
| ADR | [`docs/agents/adrs/_TEMPLATE.md`](docs/agents/adrs/_TEMPLATE.md) |
| Test plan | [`docs/agents/test-plans/_TEMPLATE.md`](docs/agents/test-plans/_TEMPLATE.md) |
| Test report | [`docs/agents/test-reports/_TEMPLATE.md`](docs/agents/test-reports/_TEMPLATE.md) |
| Worked example slice | [`docs/agents/slices/S-011-customer-favorites.md`](docs/agents/slices/S-011-customer-favorites.md) |

**Documentation rule:** this project keeps exactly one prose document. When something changes, update the relevant `README.md` section — do not add a new `.md` file.
