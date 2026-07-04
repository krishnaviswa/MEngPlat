# MerchantHub AI — Master Build Prompt

> **Purpose:** This document captures the full product specification, architectural intent, and implementation flows for MerchantHub AI. Use it as the single source of truth when building, extending, or onboarding contributors to this portfolio-grade MVP.

---

## 1. Executive Summary

**MerchantHub AI** is a Merchant Engagement Platform that helps local independent businesses (restaurants, grocery stores, salons, pharmacies, repair shops, clinics, cafés, retailers, and service providers) build customer trust through verified reviews, AI-powered feedback analysis, and actionable business insights.

**Target audience for this codebase:**
- Beginners learning full-stack development
- Portfolio reviewers evaluating Forward Deployed Engineer capabilities
- Startup-style MVP demonstrating production patterns

**Core value proposition:**
- **Customers** discover and support local businesses; leave ratings, reviews, and photos
- **Merchants** manage profiles, respond to reviews, and act on AI-generated insights
- **Administrators** moderate content, approve businesses, and monitor platform health

---

## 2. My Understanding — System Flow

### 2.1 High-Level Platform Flow

```mermaid
flowchart TB
    subgraph Users
        C[Customer]
        M[Merchant]
        A[Administrator]
    end

    subgraph Frontend["Next.js Frontend"]
        UI[React Components + Pages]
        SSR[SSR / CSR Routing]
    end

    subgraph Backend["FastAPI Backend"]
        API[REST API Layer]
        AUTH[JWT + OAuth Placeholder]
        AI[AI Abstraction Layer]
        STORAGE[File Storage Abstraction]
    end

    subgraph Data
        PG[(PostgreSQL)]
        RD[(Redis Cache)]
        FS[Local / S3 / Azure Blob]
    end

    C --> UI
    M --> UI
    A --> UI
    UI --> API
    API --> AUTH
    API --> PG
    API --> RD
    API --> AI
    API --> STORAGE
    STORAGE --> FS
    AI --> LLM[OpenAI / DeepSeek / Compatible LLM]
```

### 2.2 User Journey Flow

```mermaid
flowchart LR
    subgraph Customer Journey
        CR[Register / Login] --> CS[Search & Browse]
        CS --> CB[View Business Profile]
        CB --> CV[Write Review + Upload Photos]
        CV --> CL[Like / Edit / Report Reviews]
    end

    subgraph Merchant Journey
        MR[Register Business] --> MP[Complete Profile + Map Pin]
        MP --> MA[Pending Admin Approval]
        MA --> MD[Dashboard + Analytics]
        MD --> MI[AI Insights + Respond to Reviews]
    end

    subgraph Admin Journey
        AR[Login as Admin] --> AA[Approve / Suspend Businesses]
        AA --> AM[Moderate Reviews]
        AM --> AP[Platform Analytics + Categories]
    end
```

### 2.3 Review Submission & AI Analysis Flow

```mermaid
sequenceDiagram
    participant Customer
    participant Frontend
    participant API as FastAPI
    participant DB as PostgreSQL
    participant AI as AI Provider
    participant Cache as Redis

    Customer->>Frontend: Submit review + rating + photos
    Frontend->>API: POST /api/v1/reviews
    API->>DB: Persist review (status: pending_analysis)
    API->>AI: Analyze text (sentiment, summary, themes)
    AI-->>API: Sentiment + summary + positives + complaints
    API->>DB: Store AIAnalysis record

    loop Each uploaded photo
        API->>AI: Analyze image (cleanliness, queue, etc.)
        AI-->>API: Image insights (suggestions, not verdicts)
        API->>DB: Store photo + image analysis
    end

    API->>AI: Update merchant aggregate summary
    API->>DB: Update merchant AI summary + trends
    API->>Cache: Invalidate business/review caches
    API-->>Frontend: Review created + AI preview
    Frontend-->>Customer: Confirmation + insights display
```

### 2.4 Authentication Flow

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant API as FastAPI
    participant DB as PostgreSQL
    participant OAuth as OAuth Provider (placeholder)

    alt Email / Password
        User->>Frontend: Register or Login
        Frontend->>API: POST /auth/register or /auth/login
        API->>DB: Create / verify user
        API-->>Frontend: JWT access + refresh tokens
        Frontend->>Frontend: Store tokens (httpOnly cookie or secure storage)
    else OAuth (placeholder)
        User->>Frontend: Click "Continue with Google"
        Frontend->>OAuth: Redirect to provider
        OAuth-->>Frontend: Authorization code
        Frontend->>API: POST /auth/oauth/callback
        API->>OAuth: Exchange code (stub)
        API->>DB: Upsert user
        API-->>Frontend: JWT tokens
    end

    Note over Frontend,API: All protected routes send Authorization: Bearer {token}
```

### 2.5 Merchant Dashboard Flow

```mermaid
flowchart TD
    M[Merchant logs in] --> D[Merchant Dashboard]
    D --> R[Recent Reviews Feed]
    D --> A[Analytics Charts]
    D --> I[AI Insights Panel]
    R --> RESP[Respond to Review]
    I --> POS[Frequently Mentioned Positives]
    I --> NEG[Frequently Mentioned Complaints]
    I --> TREND[Monthly Trend Analysis]
    I --> SUG[Suggested Owner Responses]
    A --> RAT[Rating Distribution]
    A --> SEN[Sentiment Over Time]
    A --> VOL[Review Volume]
```

### 2.6 Deployment Flow (Option A — Learning Deployment)

```mermaid
flowchart LR
    DEV[Local: Docker Compose] --> GIT[Push to GitHub]
    GIT --> FE[Vercel: Next.js Frontend]
    GIT --> BE[Render / Railway: FastAPI]
    BE --> NEON[Neon PostgreSQL]
    BE --> UPSTASH[Upstash Redis optional]
    FE -->|NEXT_PUBLIC_API_URL| BE
```

---

## 3. Technology Stack (Required)

| Layer | Technology |
|-------|------------|
| Frontend | Next.js, React, TypeScript, Tailwind CSS |
| Backend | FastAPI, Uvicorn, SQLAlchemy, Pydantic |
| Database | PostgreSQL |
| Cache | Redis |
| Auth | JWT, OAuth placeholder |
| AI | Provider abstraction (OpenAI, DeepSeek, swappable via config) |
| File Storage | Local (dev), interfaces for Azure Blob & Amazon S3 |
| Maps | Google Maps integration placeholder |
| API Docs | Swagger / OpenAPI |
| Testing | Pytest, React Testing Library |
| Local Dev | Docker Compose |
| VCS | GitHub |

---

## 4. User Roles & Capabilities

### 4.1 Customer

| Action | Description |
|--------|-------------|
| Register / Login | Create account, authenticate |
| Search businesses | Text search with filters |
| Browse nearby | Location-based discovery (maps placeholder) |
| View business profile | Details, hours, photos, reviews |
| Give rating | 1–5 star rating |
| Write review | Text review tied to business |
| Upload photos | Attach images to reviews |
| Edit / Delete review | Own reviews only |
| Like reviews | Social engagement |
| Report review | Flag inappropriate content |

### 4.2 Merchant

| Action | Description |
|--------|-------------|
| Register business | Create listing (pending approval) |
| Upload logo / storefront / gallery | Media management |
| Enter address + map pin | Location data |
| Business hours & contact | Operational info |
| Respond to reviews | Public merchant replies |
| Analytics dashboard | Charts and KPIs |
| AI insights | Sentiment, themes, trends, suggested responses |

### 4.3 Administrator

| Action | Description |
|--------|-------------|
| Approve businesses | Moderate new listings |
| Moderate reviews | Hide / remove / restore |
| Suspend accounts | User / merchant enforcement |
| Platform analytics | Global metrics |
| Manage categories | CRUD business categories |

---

## 5. AI Features (Required Behavior)

> **Important:** All AI output must be framed as **suggestions**, not definitive judgments.

### 5.1 Text Review Analysis (automatic on every review)

| Output | Description |
|--------|-------------|
| Sentiment | Positive / Neutral / Negative |
| Review summary | Short AI summary of the review |
| Merchant summary | Rolling aggregate summary for the business |
| Frequently mentioned positives | Recurring praise themes |
| Frequently mentioned complaints | Recurring issue themes |
| Suggested owner response | Draft reply for merchant (editable) |
| Monthly trend analysis | Sentiment and volume trends |

### 5.2 Image Analysis (automatic on uploaded photos)

| Signal | Description |
|--------|-------------|
| Store cleanliness | Suggested observation |
| Queue length | When visible |
| Product visibility | Shelf / display assessment |
| Damaged products | When visible |
| Outdoor appearance | Exterior condition |
| Storefront quality | Curb appeal signals |
| Safety issues | When visible |

### 5.3 AI Abstraction Requirements

```python
# Conceptual interface — implement in backend/app/services/ai/
class AIProvider(Protocol):
    async def analyze_review_text(self, text: str, context: dict) -> ReviewAnalysis: ...
    async def analyze_image(self, image_url: str, context: dict) -> ImageAnalysis: ...
    async def generate_merchant_summary(self, reviews: list) -> MerchantSummary: ...
```

Configuration via environment:
- `AI_PROVIDER=openai|deepseek|mock`
- `AI_API_KEY`, `AI_BASE_URL`, `AI_MODEL`

---

## 6. Frontend Requirements

### 6.1 Reusable Components (build + document each)

| Component | Purpose |
|-----------|---------|
| Navbar | Global navigation, auth state, role-aware links |
| Footer | Links, legal, platform info |
| BusinessCard | Compact listing card for search results |
| ReviewCard | Single review with rating, photos, likes, AI badge |
| RatingWidget | Interactive star rating input/display |
| SearchBar | Query input with debounce |
| FilterPanel | Category, rating, distance, sentiment filters |
| Dashboard | Layout shell for merchant/admin analytics |
| Charts | Recharts-based sentiment, volume, rating charts |
| PhotoGallery | Lightbox gallery for business/review photos |
| Login / Registration | Auth forms with validation |
| Profile / Settings | User account management |
| AIInsights | Merchant-facing AI summary panel |
| MerchantDashboard | Reviews + analytics + insights composite |

### 6.2 Educational Documentation (include in docs/FRONTEND_GUIDE.md)

Explain for beginners:
- **Props** — data passed parent → child
- **State** — component-local mutable data
- **Hooks** — useState, useEffect, useContext, custom hooks
- **Routing** — Next.js App Router file-based routes
- **SSR** — Server-Side Rendering (initial HTML on server)
- **CSR** — Client-Side Rendering (hydration + client interactivity)

---

## 7. Backend Requirements

### 7.1 REST API Modules

| Module | Base Path | Responsibility |
|--------|-----------|----------------|
| Authentication | `/api/v1/auth` | Register, login, refresh, OAuth stub |
| Businesses | `/api/v1/businesses` | CRUD, approval, gallery |
| Reviews | `/api/v1/reviews` | CRUD, likes, reports |
| Photos | `/api/v1/photos` | Upload, list, delete |
| AI Analysis | `/api/v1/ai` | Trigger / retrieve analysis |
| Dashboard | `/api/v1/dashboard` | Role-based dashboard data |
| Search | `/api/v1/search` | Full-text + filter search |
| Maps | `/api/v1/maps` | Geocode / nearby placeholder |
| Merchant Analytics | `/api/v1/analytics` | Merchant KPIs |
| Notifications | `/api/v1/notifications` | In-app notifications |

Document every endpoint with:
- HTTP method + path
- Request body / query params
- Response schema
- Auth requirements
- Error codes

(See `docs/API_REFERENCE.md` and live Swagger at `/docs`.)

---

## 8. Database Schema (PostgreSQL — Normalized)

### 8.1 Core Entities

| Table | Purpose |
|-------|---------|
| users | All platform users (role: customer, merchant, admin) |
| merchants | Merchant profile linked 1:1 to user |
| businesses | Business listings owned by merchant |
| categories | Business taxonomy |
| business_categories | M:N business ↔ category |
| reviews | Customer reviews on businesses |
| ratings | Denormalized or embedded in reviews (1–5) |
| photos | Business gallery + review attachments |
| ai_analyses | Text + image AI results |
| replies | Merchant responses to reviews |
| favorites | Customer saved businesses |
| notifications | User notification queue |
| audit_logs | Admin action trail |
| review_likes | Customer likes on reviews |
| review_reports | Reported reviews queue |

### 8.2 Key Relationships

```mermaid
erDiagram
    users ||--o| merchants : "may have"
    merchants ||--o{ businesses : owns
    businesses }o--o{ categories : "tagged with"
    users ||--o{ reviews : writes
    businesses ||--o{ reviews : receives
    reviews ||--o{ photos : attaches
    reviews ||--o| ai_analyses : "text analysis"
    photos ||--o| ai_analyses : "image analysis"
    reviews ||--o| replies : "merchant responds"
    users ||--o{ review_likes : likes
    users ||--o{ favorites : saves
    users ||--o{ notifications : receives
    users ||--o{ audit_logs : "admin actions"
```

(Full ERD in `docs/ERD.md`.)

---

## 9. Project Documentation Deliverables

| Document | Location |
|----------|----------|
| Architecture diagram | `docs/ARCHITECTURE.md` |
| Sequence diagrams | `docs/FLOWS.md` |
| Component diagram | `docs/ARCHITECTURE.md` |
| API documentation | `docs/API_REFERENCE.md` + Swagger |
| Folder structure | `docs/FOLDER_STRUCTURE.md` |
| Entity relationship diagram | `docs/ERD.md` |
| Authentication flow | `docs/FLOWS.md` |
| Review submission flow | `docs/FLOWS.md` |
| AI analysis flow | `docs/FLOWS.md` |
| Merchant dashboard flow | `docs/FLOWS.md` |
| Frontend guide | `docs/FRONTEND_GUIDE.md` |
| Deployment guide | `docs/DEPLOYMENT.md` |

---

## 10. Deployment Requirements

### 10.1 Local Development

```bash
docker compose up --build
```

Services:
- `frontend` — Next.js on port 3000
- `backend` — FastAPI on port 8000
- `postgres` — PostgreSQL on port 5432
- `redis` — Redis on port 6379

### 10.2 Option A — Simple Learning Deployment

| Component | Platform | Notes |
|-----------|----------|-------|
| Frontend | Vercel | Connect GitHub repo, set `NEXT_PUBLIC_API_URL` |
| Backend | Render or Railway | Docker or native Python, set env vars |
| Database | Neon PostgreSQL | Connection string in backend env |
| Redis | Upstash (optional) | For production cache |
| File storage | Local → S3 later | Start with backend disk or S3 |

(Full step-by-step in `docs/DEPLOYMENT.md`.)

---

## 11. Testing Requirements

| Layer | Tool | Scope |
|-------|------|-------|
| Backend | Pytest | Auth, reviews, AI mock, business CRUD |
| Frontend | React Testing Library | Key components, auth forms |

---

## 12. Implementation Phases (Recommended Build Order)

### Phase 1 — Foundation
- [ ] Docker Compose (postgres, redis, backend, frontend)
- [ ] Database models + Alembic migrations
- [ ] JWT auth (register, login, refresh)
- [ ] Basic Next.js layout (Navbar, Footer)

### Phase 2 — Core Features
- [ ] Business CRUD + admin approval
- [ ] Review CRUD + photos (local storage)
- [ ] Search + filter API
- [ ] Business profile + review pages

### Phase 3 — AI Layer
- [ ] AI provider abstraction + mock provider
- [ ] Auto-analyze on review submit
- [ ] Merchant AI insights endpoint + UI

### Phase 4 — Dashboards
- [ ] Merchant analytics + charts
- [ ] Admin moderation panel
- [ ] Notifications

### Phase 5 — Polish
- [ ] OAuth placeholder UI
- [ ] Maps placeholder
- [ ] Tests + documentation
- [ ] Deployment guides

---

## 13. Non-Functional Requirements

- **Security:** Password hashing (bcrypt), JWT expiry, role-based access control
- **Performance:** Redis caching for search results and business profiles
- **Observability:** Structured logging, health check endpoints
- **Beginner-friendly:** Inline comments, comprehensive docs, consistent naming
- **Portfolio quality:** Clean folder structure, typed APIs, OpenAPI spec

---

## 14. Environment Variables Reference

### Backend
```
DATABASE_URL=postgresql+asyncpg://user:pass@postgres:5432/merchanthub
REDIS_URL=redis://redis:6379/0
SECRET_KEY=change-me
AI_PROVIDER=mock
AI_API_KEY=
AI_MODEL=gpt-4o-mini
STORAGE_PROVIDER=local
STORAGE_LOCAL_PATH=/app/uploads
CORS_ORIGINS=http://localhost:3000
```

### Frontend
```
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_GOOGLE_MAPS_KEY=placeholder
```

---

## 15. Success Criteria

The MVP is complete when:

1. A customer can register, search businesses, and submit a review with photos
2. AI analysis runs automatically and displays sentiment + suggestions
3. A merchant can register a business, get approved, and view AI insights
4. An admin can approve businesses and moderate reviews
5. The app runs locally via `docker compose up`
6. All documentation listed in Section 9 exists
7. Deployment guide enables Option A deployment without guesswork

---

*Generated as the master build prompt for MerchantHub AI — MEngPlat repository.*
