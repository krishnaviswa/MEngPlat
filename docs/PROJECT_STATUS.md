# Project Status — MerchantHub AI (MEngPlat)

_Snapshot taken 2026-08-08 by reading the actual code/config, not the docs' claims._

## 1. Where the project stands

**Backend (FastAPI) — mostly built out**
- 10 routers wired into `app/main.py`: `auth`, `businesses`, `reviews`, `photos`, `ai`, `dashboard`, `search`, `maps`, `analytics`, `notifications` ([main.py](../backend/app/main.py)).
- 19 SQLAlchemy models in one file: `User`, `Merchant`, `Business`, `Category`, `Review`, `Photo`, `AIAnalysis`, `Reply`, `Favorite`, `ReviewLike`, `ReviewReport`, `Notification`, `AuditLog`, etc. ([models/__init__.py](../backend/app/models/__init__.py)).
- Auth: JWT access/refresh via `python-jose`, bcrypt password hashing, role-based `require_roles()` dependency ([dependencies.py](../backend/app/dependencies.py)).
- AI: pluggable provider — `mock` (canned sentiment/summary, no network) or `openai`-compatible (works for OpenAI or DeepSeek via `AI_BASE_URL`). Selected by `AI_PROVIDER` env var ([services/ai](../backend/app/services/ai/__init__.py)).
- Storage: `local` disk provider is implemented; `s3` and `azure` providers exist only as stubs that raise `NotImplementedError` ([services/storage/__init__.py](../backend/app/services/storage/__init__.py)).
- No Alembic migrations despite being a dependency — schema is created via `Base.metadata.create_all()` on startup ([main.py:17-18](../backend/app/main.py)). Fine for a demo, not for real schema evolution.
- `backend/scripts/seed.py` creates 3 demo users (admin/merchant/customer) + 1 sample business, idempotently.

**Frontend (Next.js 15 / React 19) — core pages built**
- Pages: home, search, business detail, login, register, profile, settings, merchant dashboard, admin ([frontend/src/app](../frontend/src/app)).
- Talks to the API directly via `NEXT_PUBLIC_API_URL` / `API_URL_INTERNAL` — no BFF/rewrite layer ([lib/api.ts](../frontend/src/lib/api.ts)).

**Known gap: `Favorite` model exists but isn't wired up**
- The `Favorite` table is defined in the DB models, but there is no favorites router/endpoint on the backend and no Favorite button/UI on the frontend.
- This matches [docs/agents/slices/S-011-customer-favorites.md](agents/slices/S-011-customer-favorites.md), which is a **Draft** example slice for practicing the multi-agent workflow — it was never carried through to implementation.

**Multi-agent docs workflow — scaffold only, not really used yet**
- `docs/agents/adrs/`, `test-plans/`, `test-reports/` each contain only their `_TEMPLATE.md` — no real ADRs, test plans, or test reports have been written.
- `docs/agents/slices/` has exactly one slice (S-011, Draft/example).

**Tests — thin**
- Backend: 3 tests total (`health`, register+login, list businesses) in [test_api.py](../backend/tests/test_api.py). No conftest/fixtures, no DB isolation between test runs.
- Frontend: 1 test (`RatingWidget`) in `__tests__/`.

**Important local-dev catch:** models use Postgres-specific dialect types (`sqlalchemy.dialects.postgresql.UUID`, `JSONB` — see [models/__init__.py:17](../backend/app/models/__init__.py)) directly, not database-agnostic types. So even though `aiosqlite` is in `requirements.txt`, **you cannot just point `DATABASE_URL` at SQLite** — it will fail. A real PostgreSQL instance is required (Docker, native install, or a hosted DB like Neon).

## 2. How to run it locally

**This machine currently has:** Python 3.12.10, Node 24.19.0, npm 11.17.0 — **but no Docker installed** (checked via both Git Bash and PowerShell). Postgres/Redis are also not installed natively.

### Option A — Docker Compose (recommended, matches the README exactly)

1. Install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/) (not currently installed here).
2. From the repo root:
   ```bash
   docker compose up --build
   ```
3. This starts Postgres, Redis, backend (auto-seeds demo users, then `uvicorn --reload`), and frontend together.
4. Open:
   - App: http://localhost:3000
   - API: http://localhost:8000
   - Swagger: http://localhost:8000/docs
5. Login with `admin@merchanthub.ai` / `admin12345` (or merchant/customer — see [README.md](../README.md)).

This is the only path the project is actually documented and tested against — do this unless you have a specific reason not to.

### Option B — Native, without Docker

Requires installing PostgreSQL yourself (Redis is technically optional — cache failures are silently swallowed in [`cache.py`](../backend/app/services/cache.py), so the app runs without it, just with caching disabled).

1. **Install & start PostgreSQL 16**, then create the DB/user the code expects:
   ```sql
   CREATE USER merchanthub WITH PASSWORD 'merchanthub';
   CREATE DATABASE merchanthub OWNER merchanthub;
   ```
2. **Backend:**
   ```bash
   cd backend
   python -m venv .venv
   .venv\Scripts\activate
   pip install -r requirements.txt
   copy .env.example .env
   ```
   Edit `backend/.env`: change `DATABASE_URL` host from `postgres` to `localhost` (and `redis` to `localhost` in `REDIS_URL` if you're running Redis too).
   ```bash
   python scripts/seed.py
   uvicorn app.main:app --reload --port 8000
   ```
3. **Frontend** (separate terminal):
   ```bash
   cd frontend
   npm install
   copy .env.example .env.local
   npm run dev
   ```
4. Open http://localhost:3000 (frontend) and http://localhost:8000/docs (API).

### Running the tests

```bash
# Backend — needs a reachable Postgres (see Option B step 1); no test DB isolation exists yet
cd backend && pytest

# Frontend
cd frontend && npm test
```

## 3. Hosted deployment (skip local setup entirely)

Instead of installing anything on this machine, the app can be deployed to free/cheap hosted platforms and run from a URL. Cost comparison for low-traffic MVP/portfolio use:

| | **Option C — Vercel + Render + Neon + Upstash** | **Option D — Railway (all-in-one)** |
|---|---|---|
| Frontend | Vercel Hobby — $0 | included |
| Backend | Render free tier — $0 (spins down after 15min idle, ~30-60s cold start) | included |
| Postgres | Neon free tier — $0 (permanent, scales to zero when idle) | included |
| Redis | Upstash free tier — $0, or skip entirely (app no-ops without it, see [`cache.py`](../backend/app/services/cache.py)) | included |
| Realistic monthly cost | **$0/mo** (accept cold starts), or ~$7/mo for always-on backend | **~$5-15/mo** if always-on (Hobby plan's $5 credit gets consumed by 24/7 usage) |
| Setup effort | 4 separate dashboards to wire together | 1 dashboard, deploys straight from the existing Dockerfiles |

### Option C — Vercel + Render + Neon + Upstash

Documented in [DEPLOYMENT.md](DEPLOYMENT.md) "Option A". Frontend → Vercel (root dir `frontend`), backend → Render web service (root dir `backend`, Docker or `pip install -r requirements.txt` + `uvicorn app.main:app --host 0.0.0.0 --port $PORT`), database → Neon (convert the connection string to `postgresql+asyncpg://...`), Redis → Upstash (optional). Not yet built out in this repo — no Render/Vercel config files exist.

### Option D — Railway (all-in-one) — chosen, partially wired up

[`backend/railway.json`](../backend/railway.json) and [`frontend/railway.json`](../frontend/railway.json) are already in the repo, configured with `builder: DOCKERFILE` (reuses the existing, verified `Dockerfile`s rather than Railway's auto-detecting Railpack builder) plus `sleepApplication: false`, single replica, `ams` region, restart-on-failure.

The backend's `railway.json` overrides the container start command to `sh -c "python scripts/seed.py && uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"` — this fixes two Railway-specific issues without touching the Dockerfile:
- The Dockerfile's own `CMD` hardcodes port 8000 in exec form, which can't expand Railway's injected `$PORT` — the override does.
- The Dockerfile's `CMD` never runs `scripts/seed.py` (only `docker-compose.yml`'s command override does that) — the override adds it back so the demo accounts get created.

The frontend needs no Dockerfile/start-command changes — `next dev` picks up a shell-level `$PORT` automatically.

**Remaining steps (require your Railway account — not something I can do for you):**

1. New Project → Deploy from GitHub repo (this repo).
2. `+ New → Database → PostgreSQL` and `+ New → Database → Redis` in the same project.
3. `+ New → GitHub Repo` (same repo) for the backend: Root Directory `backend`, config-as-code path `backend/railway.json`.
4. Same again for the frontend: Root Directory `frontend`, config-as-code path `frontend/railway.json`.
5. Settings → Networking → Generate Domain for both `backend` and `frontend`.
6. Backend service → Variables:
   ```
   DATABASE_URL=postgresql+asyncpg://${{Postgres.PGUSER}}:${{Postgres.PGPASSWORD}}@${{Postgres.PGHOST}}:${{Postgres.PGPORT}}/${{Postgres.PGDATABASE}}
   REDIS_URL=${{Redis.REDIS_URL}}
   SECRET_KEY=<generate, e.g. `openssl rand -hex 32`>
   AI_PROVIDER=mock
   STORAGE_PROVIDER=local
   STORAGE_LOCAL_PATH=/app/uploads
   CORS_ORIGINS=https://${{frontend.RAILWAY_PUBLIC_DOMAIN}}
   ```
   (Railway's Postgres plugin exposes `DATABASE_URL` as plain `postgresql://`, which doesn't match this codebase's `postgresql+asyncpg://` requirement in [config.py](../backend/app/config.py) — hence composing it from the individual `PG*` vars instead of referencing `DATABASE_URL` directly.)
7. Frontend service → Variables:
   ```
   NEXT_PUBLIC_API_URL=https://${{backend.RAILWAY_PUBLIC_DOMAIN}}
   NEXT_PUBLIC_GOOGLE_MAPS_KEY=placeholder
   ```
8. Redeploy both services.

**Known caveats:**
- `STORAGE_LOCAL_PATH=/app/uploads` is ephemeral container disk — uploaded review photos are lost on every redeploy. Fine for prototyping, not for a persistent demo.
- `sleepApplication: false` keeps everything running 24/7, which burns through the Hobby plan's included $5/mo credit fastest. Set it to `true` in both `railway.json` files if this is a prototype you check occasionally rather than a live link you're sharing.
- `${{Postgres.*}}` / `${{Redis.*}}` / `${{frontend.*}}` / `${{backend.*}}` reference syntax assumes those are the literal service names Railway assigns — adjust if yours differ.

## 4. Fastest path to "see it working" right now

Given nothing is installed on this machine yet, the shortest local route is: install Docker Desktop → `docker compose up --build` → open http://localhost:3000. If you'd rather not install anything at all, Railway (Option D above) gets you a live URL instead — most of the repo-side config is already done, what's left is the dashboard steps.
