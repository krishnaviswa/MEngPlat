# Folder Structure

```
MEngPlat/
├── docker-compose.yml          # Local dev: postgres, redis, backend, frontend
├── README.md
│
├── docs/
│   ├── MERCHANTHUB_AI_BUILD_PROMPT.md   # Master build specification
│   ├── ARCHITECTURE.md
│   ├── FLOWS.md
│   ├── ERD.md
│   ├── API_REFERENCE.md
│   ├── FRONTEND_GUIDE.md
│   ├── FOLDER_STRUCTURE.md
│   └── DEPLOYMENT.md
│
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── pytest.ini
│   ├── app/
│   │   ├── main.py              # FastAPI app entry point
│   │   ├── config.py            # Pydantic settings from env
│   │   ├── database.py          # SQLAlchemy async engine + session
│   │   ├── dependencies.py      # Auth deps, RBAC, helpers
│   │   ├── core/
│   │   │   └── security.py      # JWT + password hashing
│   │   ├── models/
│   │   │   └── __init__.py      # All SQLAlchemy models
│   │   ├── schemas/
│   │   │   └── __init__.py      # Pydantic request/response schemas
│   │   ├── routers/
│   │   │   ├── auth.py
│   │   │   ├── businesses.py
│   │   │   ├── reviews.py
│   │   │   ├── photos.py
│   │   │   ├── ai.py
│   │   │   ├── dashboard.py
│   │   │   ├── search.py
│   │   │   ├── maps.py
│   │   │   ├── analytics.py
│   │   │   └── notifications.py
│   │   └── services/
│   │       ├── ai/              # AI provider abstraction
│   │       ├── storage/         # Local / S3 / Azure placeholders
│   │       ├── cache.py         # Redis helpers
│   │       └── business_service.py
│   ├── scripts/
│   │   └── seed.py              # Demo data seeder
│   └── tests/
│       └── test_api.py
│
└── frontend/
    ├── Dockerfile
    ├── package.json
    ├── src/
    │   ├── app/                 # Next.js App Router pages
    │   │   ├── layout.tsx
    │   │   ├── page.tsx         # Home (SSR)
    │   │   ├── search/
    │   │   ├── businesses/[slug]/
    │   │   ├── login/
    │   │   ├── register/
    │   │   ├── profile/
    │   │   ├── settings/
    │   │   ├── merchant/dashboard/
    │   │   └── admin/
    │   ├── components/          # Reusable React components
    │   └── lib/
    │       └── api.ts           # API client
    └── src/components/__tests__/
```

## Key Conventions

- **Backend routers** — one module per domain, mounted at `/api/v1`
- **Frontend App Router** — `page.tsx` files define routes; `"use client"` for interactive pages
- **Services** — business logic and external integrations stay out of routers
- **Docs** — all architecture and onboarding material in `docs/`
