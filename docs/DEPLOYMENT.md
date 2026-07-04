# Deployment Guide

## Local Development (Docker Compose)

### Prerequisites

- Docker Desktop
- Git

### Start the stack

```bash
cd MEngPlat
docker compose up --build
```

| Service | URL |
|---------|-----|
| Frontend | http://localhost:3000 |
| Backend API | http://localhost:8000 |
| Swagger docs | http://localhost:8000/docs |
| PostgreSQL | localhost:5432 |
| Redis | localhost:6379 |

### Seed accounts (auto-created on first run)

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@merchanthub.ai | admin12345 |
| Merchant | merchant@example.com | merchant123 |
| Customer | customer@example.com | customer123 |

### Environment variables

Copy and customize as needed:

**Backend** (`backend/.env` or docker-compose):
```
DATABASE_URL=postgresql+asyncpg://merchanthub:merchanthub@postgres:5432/merchanthub
REDIS_URL=redis://redis:6379/0
SECRET_KEY=change-me-in-production
AI_PROVIDER=mock
CORS_ORIGINS=http://localhost:3000
```

**Frontend**:
```
NEXT_PUBLIC_API_URL=http://localhost:8000
```

---

## Option A — Simple Learning Deployment

Production-style split deployment for portfolio demos.

```mermaid
flowchart LR
    GH[GitHub Repo] --> V[Vercel Frontend]
    GH --> R[Render/Railway Backend]
    R --> N[Neon PostgreSQL]
    R --> U[Upstash Redis optional]
    V -->|API calls| R
```

### Step 1 — Database (Neon PostgreSQL)

1. Create account at [neon.tech](https://neon.tech)
2. Create project `merchanthub-ai`
3. Copy connection string (use **pooled** URL for serverless)
4. Convert to async format: `postgresql+asyncpg://user:pass@host/db?sslmode=require`

### Step 2 — Backend (Render or Railway)

**Render:**
1. New Web Service → connect GitHub repo
2. Root directory: `backend`
3. Build: `pip install -r requirements.txt`
4. Start: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
5. Set environment variables:

| Variable | Value |
|----------|-------|
| DATABASE_URL | Neon connection string (asyncpg) |
| REDIS_URL | Upstash Redis URL (optional) |
| SECRET_KEY | Random 64-char string |
| AI_PROVIDER | mock or openai |
| AI_API_KEY | Your LLM key |
| CORS_ORIGINS | https://your-app.vercel.app |
| STORAGE_PROVIDER | local (or s3 for production) |

**Railway:** Same env vars; deploy from `backend/` Dockerfile.

### Step 3 — Redis (optional, Upstash)

1. Create free Redis at [upstash.com](https://upstash.com)
2. Copy `REDIS_URL` to backend env

### Step 4 — Frontend (Vercel)

1. Import GitHub repo at [vercel.com](https://vercel.com)
2. Root directory: `frontend`
3. Framework preset: Next.js
4. Environment variable:

```
NEXT_PUBLIC_API_URL=https://your-backend.onrender.com
```

5. Deploy

### Step 5 — Verify

- [ ] Frontend loads at Vercel URL
- [ ] `/health` returns 200 on backend
- [ ] Login works with seeded or new account
- [ ] Swagger docs accessible at `/docs`
- [ ] CORS allows frontend origin

### File storage in production

For MVP on Render/Railway, disk is ephemeral. Options:
1. **AWS S3** — implement `S3StorageProvider` with boto3
2. **Azure Blob** — implement `AzureBlobStorageProvider`
3. **Cloudinary** — alternative for images

Set `STORAGE_PROVIDER=s3` when ready.

### Google Maps

Set `GOOGLE_MAPS_API_KEY` on backend and `NEXT_PUBLIC_GOOGLE_MAPS_KEY` on frontend when implementing real geocoding.

---

## CI/CD (recommended next step)

- GitHub Actions: run `pytest` on backend, `npm test` on frontend
- Auto-deploy main branch to Vercel + Render

## Security checklist for production

- [ ] Strong `SECRET_KEY`
- [ ] HTTPS everywhere
- [ ] httpOnly cookies for tokens (upgrade from localStorage)
- [ ] Rate limiting on auth endpoints
- [ ] Database SSL enabled (Neon default)
