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

## Cursor rules
| Rule | Scope |
|------|-------|
| `project.mdc` | Always apply |
| `backend-fastapi.mdc` | `backend/**/*` |
| `frontend-nextjs.mdc` | `frontend/**/*` |
| `ai-and-integrations.mdc` | `backend/app/services/**/*` |
| `database.mdc` | `backend/app/models/**/*` |
| `docs-and-api.mdc` | `docs/**/*` |
| `testing.mdc` | test files |
