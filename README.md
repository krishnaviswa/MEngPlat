# MerchantHub AI

**A Merchant Engagement Platform** that helps local independent businesses — restaurants, grocers, salons, pharmacies, repair shops, clinics, cafés, retailers — build customer trust through verified reviews, AI-powered feedback analysis, and actionable business insights.

Built as a portfolio-grade full-stack MVP demonstrating Forward Deployed Engineer capabilities.

> **This file is the single source of truth for the project.** Everything that used to live across eleven separate documents is here. Live agent artifacts (slice/ADR/test templates) remain as files under `[docs/agents/](docs/agents/)` because the workflow copies from them.

---



## Read this by role


| You are a…              | Read                                                                                                                                                                                                             | Why                                                                         |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| **Architect**           | [§2 Logical design](#2-logical-design), [§3 Architecture](#3-architecture), [§4 Why this stack](#4-why-this-stack), [§9 Security](#9-security)                                                                   | Shape of the system, the pattern behind it, the trade-offs taken            |
| **Senior developer**    | §3, [§5 Domain model](#5-domain-model), [§6 Flows](#6-feature-flows), §9, [§14 Known gaps](#14-known-gaps--roadmap), [web↔mobile parity](#web--mobile-feature-parity-tracker)                                    | Where the seams are, what is not finished, and mobile gap status            |
| **Developer**           | [§1 Quick start](#1-quick-start), [§7 API](#7-api-reference), [§8 Frontend](#8-frontend-guide), [§12 Repo layout](#12-repo-layout--conventions) (incl. [web↔mobile parity](#web--mobile-feature-parity-tracker)) | Get running, then find the file — and the mobile status of each web feature |
| **Tester**              | [§11 Testing](#11-testing) (evaluation model), then §6, §7, §9, [§13 Workflow](#13-multi-agent-workflow), [ADR-009](docs/agents/adrs/ADR-009-web-functional-e2e.md)                                               | What is proven today, how new slices stay covered, Playwright staging plan  |
| **Industry / investor** | [§16 Industry and investor overview](#16-industry-and-investor-overview), then §2 and §14                                                                                                                        | Honest loop, what is shipped vs planned, fee model                          |


**In 60 seconds:** A Next.js frontend calls a FastAPI backend over REST. When a customer submits a review, the backend persists it, sends the text (and any photos) to a pluggable AI provider, stores the returned sentiment/summary/suggestions, refreshes the business's rolling AI summary, and invalidates the Redis search cache. Merchants read those insights on a dashboard; admins approve businesses and moderate reviews. The AI provider defaults to a local mock, so the whole thing runs offline with no API key and no cost.

---



## Table of contents


| §   | Section                                                                                                                              |
| --- | ------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | [Quick start](#1-quick-start)                                                                                                        |
| 2   | [Logical design](#2-logical-design)                                                                                                  |
| 3   | [Architecture](#3-architecture)                                                                                                      |
| 4   | [Why this stack](#4-why-this-stack)                                                                                                  |
| 5   | [Domain model](#5-domain-model)                                                                                                      |
| 6   | [Feature flows](#6-feature-flows)                                                                                                    |
| 7   | [API reference](#7-api-reference)                                                                                                    |
| 8   | [Frontend guide](#8-frontend-guide)                                                                                                  |
| 9   | [Security](#9-security)                                                                                                              |
| 10  | [Deployment](#10-deployment)                                                                                                         |
| 11  | [Testing](#11-testing)                                                                                                               |
| 12  | [Repo layout & conventions](#12-repo-layout--conventions) (incl. [Web ↔ mobile parity tracker](#web--mobile-feature-parity-tracker), [Mobile parity roadmap](#mobile-parity-roadmap)) |
| 13  | [Multi-agent workflow](#13-multi-agent-workflow)                                                                                     |
| 14  | [Known gaps & roadmap](#14-known-gaps--roadmap)                                                                                      |
| 15  | [Environment variables](#15-environment-variables)                                                                                   |
| 16  | [Industry and investor overview](#16-industry-and-investor-overview)                                                                 |


---



## 1. Quick start

```bash
docker compose up --build
```

This starts PostgreSQL, Redis, the backend (migrate → version-gated seed → `uvicorn --reload`), and the frontend together. Local Compose sets `SEED_MODE=if_outdated` so the full demo upsert runs once per `SEED_VERSION`, then skips on restart.


| Service           | URL                                                                      |
| ----------------- | ------------------------------------------------------------------------ |
| App               | [http://localhost:3000](http://localhost:3000)                           |
| API               | [http://localhost:8000](http://localhost:8000)                           |
| Swagger / OpenAPI | [http://localhost:8000/docs](http://localhost:8000/docs)                 |
| ReDoc             | [http://localhost:8000/redoc](http://localhost:8000/redoc)               |
| OpenAPI JSON      | [http://localhost:8000/openapi.json](http://localhost:8000/openapi.json) |
| Health check      | [http://localhost:8000/health](http://localhost:8000/health)             |
| PostgreSQL        | localhost:5432                                                           |
| Redis             | localhost:6379                                                           |


On Railway, the same paths (`/docs`, `/redoc`, `/openapi.json`, `/health`) hang off the **backend** public URL. Full curl recipes and “how the UI loads data” are in [§7 API reference — Trying the API](#where-to-try-every-endpoint-swagger).

### Demo accounts (seeded on first run)


| Role              | Email                                                       | Password       |
| ----------------- | ------------------------------------------------------------ | -------------- |
| Admin             | `admin@merchanthub.ai`                                       | `admin12345ok` |
| Merchant          | `merchant@example.com`                                       | `merchant1234` |
| Merchant (pending) | `merchant2@example.com`                                     | `merchant1234` |
| Customer          | `customer@example.com`                                       | `customer1234` |
| Chennai/US demo (×2) | `demo.customer1@example.com` … `demo.customer2@example.com` | `demo12345abc` |


**Password login requires an authenticator app.** Seeded demo accounts share TOTP secret `JBSWY3DPEHPK3PXP` (add to Google Authenticator / Authy as a time-based account). Gmail/Google sign-in does not require TOTP.

`backend/scripts/seed.py` creates the core demo users — including a second merchant (`merchant2@example.com`) whose business ("Riverside Auto Care") stays `pending` to demonstrate the admin approval queue — one approved Portland sample business, then upserts ~20 Chrompet / Radha Nagar businesses (`seed_chennai.py`) and 40 US listings (`seed_us.py`: Fremont, Union City, Brandon, Dallas). US JSON lives in `backend/data/real-businesses/` so the backend Docker image (Railway) includes it; a mirror under `data/real-businesses/` plus a Compose mount at `/data/real-businesses` are fallbacks. Both regional seeds use one synthetic hand-authored review per business (kept minimal — one review, one AI-analysis row, one occasional review photo per business, rather than several near-duplicates), Unsplash stock photos by category (not hotlinked listing photos), and mock AI analysis rows. One Chennai review also carries a merchant `Reply` to demonstrate the reply flow. Display ratings come from seeded reviews via `update_business_rating()` — JSON `rating` / `review_count` fields are ignored. Extra demo customers `demo.customer1@example.com` … `demo.customer2@example.com` share password `demo12345abc`. New registrations must be at least 12 characters with a letter and a digit; existing login hashes are unchanged until you re-seed (`SEED_VERSION` bump). Categories include `auto_repair` and `hospital` (ensured on re-run).

**Seed is version-gated** via `SEED_MODE` / `SEED_VERSION` and the `seed_runs` table (see §15). Compose uses `if_outdated` (skip when the current version marker exists). Railway production **does not** run seed on boot — migrate + API only. To refresh demo data on Railway (shell / one-shot):

```bash
PYTHONPATH=/app SEED_MODE=force python scripts/seed.py
```

Bump `SEED_VERSION` whenever seed content meaningfully changes so `if_outdated` re-applies once.

### Running natively (no Docker)

Requires PostgreSQL. Redis is optional — cache failures are swallowed in `[cache.py](backend/app/services/cache.py)`, so the app runs without it, just uncached.

> **Trap:** you cannot point `DATABASE_URL` at SQLite. The models import `sqlalchemy.dialects.postgresql.UUID` and `JSONB` directly ([models/init.py:17](backend/app/models/__init__.py)), so `aiosqlite` being present in `requirements.txt` is a red herring. A real PostgreSQL is required — Docker, native install, or hosted (Neon).

```sql
-- 1. Create the database and user the code expects
CREATE USER merchanthub WITH PASSWORD 'merchanthub';
CREATE DATABASE merchanthub OWNER merchanthub;
```

```bash
# 2. Backend
cd backend
python -m venv .venv && .venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env      # then change DATABASE_URL host: postgres -> localhost
alembic upgrade head
set SEED_MODE=force
python scripts/seed.py
uvicorn app.main:app --reload --port 8000
```

```bash
# 3. Frontend (separate terminal)
cd frontend
npm install
copy .env.example .env.local
npm run dev
```

---



## 2. Logical design

Before any technology: the platform exists to close **one feedback loop**.

```mermaid
flowchart LR
    C[Customer<br/>visits a business] -->|writes a review| R[(Review)]
    R -->|is read and interpreted| I[Insight<br/>what people praise / complain about]
    I -->|is acted on| M[Merchant<br/>improves + replies]
    M -->|better experience| C
    A[Admin] -.->|keeps the loop honest<br/>approves listings, moderates reviews| R
```



Everything else in this codebase is machinery for that loop. Three actors, three responsibilities:


| Actor        | Wants                              | Can do                                                                                                                                                                                                                                                                                          |
| ------------ | ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Customer** | find businesses worth trusting     | register/login (password + TOTP, Google), search & browse, view profiles, rate 1–5, write reviews with photos, like/report, favorite, password reset. **Not built:** edit/delete own reviews (parity M-40/M-41).                                                                                                                                          |
| **Merchant** | know what customers actually think | register a listing (pending approval), set address + map pin + contact, reply, dashboard KPIs + AI insights (suggestions) + time-series / rating mix / reply-rate / CSV (S-033) + charts/deltas (S-037) + competitor benchmark (S-038) + AI reply draft (S-039) + QR collect (S-040) + featured boost (S-036). **API exists, no web form:** logo/storefront/gallery upload and hours editor (M-55/M-56). |
| **Admin**    | keep the platform trustworthy      | approve/suspend **businesses**, moderate reviews (hide/remove/restore), five live platform **counts**, **and now platform time-series charts, category create/list, and user suspend/reactivate (S-034)**                                                                              |




### Why AI is in the loop at all

A merchant with 200 reviews cannot read patterns out of them by hand. The AI layer turns a pile of individual reviews into: sentiment per review, a rolling business summary, recurring praise themes, recurring complaint themes, monthly trends, and a draft reply the merchant can edit.

> **Design rule, enforced throughout:** all AI output is framed as **suggestions, never verdicts**. Every AI surface carries a disclaimer. An image analysis says "the storefront appears cluttered" — it never says "this business is unsanitary."



### User journeys

```mermaid
flowchart LR
    subgraph Customer
        CR[Register / Login] --> CS[Search & browse]
        CS --> CB[View business profile]
        CB --> CV[Write review + photos]
        CV --> CL[Like / edit / report]
    end
    subgraph Merchant
        MR[Register business] --> MP[Profile + map pin]
        MP --> MA[Pending admin approval]
        MA --> MD[Dashboard KPIs + AI insights]
        MD --> MI[Public reply to reviews]
    end
    subgraph Admin
        AR[Login as admin] --> AA[Approve / suspend businesses]
        AA --> AM[Moderate reviews]
        AM --> AP[Platform counts]
    end
```



---



## 3. Architecture



### The pattern

**A layered monolith with ports & adapters at the volatile edges.**

- **Layered** for everything stable: HTTP router → service → ORM model → PostgreSQL. Straightforward, easy to trace, no ceremony.
- **Ports & adapters (hexagonal)** only where vendors would otherwise weld the product: **AI**, **file storage**, **transactional email**, and **payments**. Each is a `Protocol` (or ABC for AI) plus a factory selected by one environment variable. Local/CI defaults are always the **mock** (or `local` disk) implementation.

The original write-up named two seams (AI + storage). Email (S-035 / ADR-007) and payments (S-036 / ADR-008) were added **using the same pattern**, not a new architecture. That is the intended drift: more adapters, same rule. Applying hexagonal architecture to the whole app would bury an MVP in indirection; applying none of it would weld the app to OpenAI, Resend, Razorpay, and a single cloud disk.

### System overview

```mermaid
flowchart TB
    subgraph Users
        C[Customer]
        M[Merchant]
        A[Administrator]
    end

    subgraph Frontend["Next.js Frontend :3000"]
        UI[React components + pages]
        SSR[SSR / CSR routing]
    end

    subgraph Backend["FastAPI Backend :8000"]
        API[REST API layer /api/v1]
        AUTH[JWT auth + RBAC + Google ID token]
        AI[AI provider port]
        STORAGE[Storage port]
        MAIL[Email provider port]
        PAY[Payment provider port]
    end

    subgraph Data
        PG[(PostgreSQL)]
        RD[(Redis cache)]
        FS[Local disk / S3 / Azure stub]
    end

    C --> UI
    M --> UI
    A --> UI
    UI -->|REST JSON| API
    API --> AUTH
    API --> PG
    API --> RD
    API --> AI
    API --> STORAGE
    API --> MAIL
    API --> PAY
    STORAGE --> FS
    AI --> LLM[OpenAI-compatible / Mock]
    MAIL --> MailVend[Mock log / Resend]
    PAY --> PayVend[Mock / Razorpay]
    API --> Maps[OpenStreetMap tiles + Leaflet]
```





### Components

```mermaid
flowchart LR
    subgraph FrontendComponents["Frontend components"]
        Nav[Navbar]
        BC[BusinessCard]
        RC[ReviewCard]
        RW[RatingWidget]
        AIC[AIInsights]
        Dash[Dashboard]
    end

    subgraph Routers["Backend routers"]
        Auth[auth]
        Biz[businesses]
        Rev[reviews]
        Photo[photos]
        AIr[ai]
        Search[search]
    end

    subgraph Services["Services / ports"]
        AIProv[AI provider]
        Store[Storage]
        Mail[Email]
        Pay[Payments]
        Cache[Redis cache helpers]
    end

    Nav --> Auth
    BC --> Biz
    RC --> Rev
    AIC --> AIr
    Dash --> AIr

    Rev --> AIProv
    Photo --> AIProv
    Photo --> Store
    Search --> Cache
```





### Request lifecycle

```mermaid
flowchart LR
    Req[HTTP request] --> CORS[CORS middleware<br/>origin allowlist]
    CORS --> Route[Router: path + method]
    Route --> Val[Pydantic schema validation]
    Val --> Dep["Dependencies:<br/>get_current_user / require_roles"]
    Dep --> Own[Ownership check<br/>get_owned_business]
    Own --> Svc[Service logic<br/>+ AI / storage / email / payments / cache]
    Svc --> ORM[SQLAlchemy async session]
    ORM --> DB[(PostgreSQL)]
    Svc --> Resp[Pydantic response model]
```





### Layer responsibilities


| Layer          | Responsibility                                 | Must not                           |
| -------------- | ---------------------------------------------- | ---------------------------------- |
| Frontend       | UI, routing, client-side auth token storage    | contain business rules             |
| API routers    | HTTP validation, auth checks, response mapping | call an LLM or touch disk directly |
| Services       | Business logic + AI / storage / email / payments / cache | know about HTTP                    |
| Models         | SQLAlchemy ORM, PostgreSQL persistence         | contain request logic              |
| Infrastructure | Docker Compose, PostgreSQL, Redis              | —                                  |


The rule that keeps this honest: **business logic and external integrations stay out of routers.**

### Integration ports (what is mocked vs live)

These four are **functionally in the product**. Tests and Compose must stay vendor-free. Switching a mock to a live vendor is an env change, not a rewrite.


| Port | Env | Default (Compose / CI / pytest) | Live adapter | Functional today? |
| ---- | --- | ------------------------------- | ------------ | ----------------- |
| AI | `AI_PROVIDER` | `mock` (deterministic suggestions, no network) | OpenAI-compatible HTTP (`AI_BASE_URL` + key) | Yes — review analysis, insights, reply draft |
| Storage | `STORAGE_PROVIDER` | `local` disk at `/uploads` | `s3` (boto3; optional `STORAGE_S3_PUBLIC_BASE_URL` for a CDN in front of the bucket) | Yes locally; **Azure class is still a stub** |
| Email | `EMAIL_PROVIDER` | `mock` (logs only) | `resend` | Yes — reset, listing approved, new review (best-effort) |
| Payments | `PAYMENTS_PROVIDER` | `mock` (no keys; DEBUG mock-complete) | `razorpay` Checkout + webhook HMAC | Yes — three featured SKUs; admin approve after capture |
| SMS | `SMS_PROVIDER` | `mock` (logs OTP) | `msg91` | Yes — Phone OTP login |
| Review sources | `GOOGLE_PLACES_API_KEY` | unset → `mock` (deterministic fixtures, no network) | Google Places Text Search + Place Details | Yes — merchant link/sync + public sample (**S-048**). Empty key must stay `""`, not `"placeholder"` |
| WhatsApp | `WHATSAPP_PROVIDER` | `mock` (HMAC + fixture media; no Meta calls) | `meta_cloud` (`app/services/whatsapp/providers/meta_cloud.py`) | **Not Accepted** (S-050..053 Testing). Mock + Jest/pytest passing locally; formal Tester report + PM Accept still required — [§14 cutover](#going-live-with-meta-whatsapp-cloud-api) |

**Staging policy:** spin the same Compose stack (or a Railway “staging” project) with those four defaults. Do not buy Resend/Razorpay/S3 to prove the web loop. Prove the loop against mocks; prove adapters with contract tests (`backend/tests/test_email_provider.py`, `test_payments.py`, `test_storage.py`, `test_ai_*`).

Architecture files for this layer: [ADR-007](docs/agents/adrs/ADR-007-transactional-email-port.md), [ADR-008](docs/agents/adrs/ADR-008-razorpay-featured-fee.md), [ADR-010](docs/agents/adrs/ADR-010-featured-sku-admin-approve.md), [ADR-011](docs/agents/adrs/ADR-011-phone-otp-sms.md), [ADR-012](docs/agents/adrs/ADR-012-whatsapp-cloud-api-port.md), [ADR-009](docs/agents/adrs/ADR-009-web-functional-e2e.md) (how we *prove* the loop), plus `.cursor/rules/ai-and-integrations.mdc` / `backend/app/services/CLAUDE.md`.

### Architecture vs original product design (drift)

The **logical loop in §2 is implemented** (customer review → AI suggestion → merchant action → admin honesty). What changed is machinery and a few capability promises, not the product:


| Topic | Original design | Built | Verdict |
| ----- | --------------- | ----- | ------- |
| Shape | Layered monolith + 2 ports | Same monolith + **4** ports | Pattern held; seams grew on purpose |
| Maps | Google Maps env vars | Leaflet + OSM tiles (ADR-006); Nominatim address lookup removed in S-084 | Intentional swap; keys unused |
| Auth | JWT in `localStorage` | Same + mandatory TOTP + Google ID-token | S-026 httpOnly cookies still Draft |
| AI | Suggestions only | Enforced in UI copy + mock default | No drift |
| Customer edit/delete review | Named in early actor table | No UI either client (M-40/M-41) | **Doc over-promise** — corrected in §2 |
| Merchant hours / gallery forms | Named in early actor table | Display + photo API; no merchant editor | **Deferred**, not abandoned |
| Google OAuth | Redirect/callback (S-009) | GIS ID-token, no redirect route | Simpler; S-009 “callback stub” is stale wording |
| Observability | Structured logs as NFR | `/health` only | Open gap (§14) |
| Web proof | Pytest + RTL + “manual integration” | Same + Playwright **manual** GHA (`web-e2e.yml`), not on every PR | S-010 / ADR-009 |

### Non-functional requirements


| Concern               | How it is met                                                                                       |
| --------------------- | --------------------------------------------------------------------------------------------------- |
| **Security**          | bcrypt password hashing, JWT expiry, role-based access control — see §9                             |
| **Performance**       | Redis caching for search results and business profiles; async I/O throughout                        |
| **Observability**     | `/health` endpoint returning app name + version; structured logging (not yet implemented — see §14) |
| **Beginner-friendly** | Inline comments, JSDoc on every frontend component, consistent naming, this document                |
| **Portfolio quality** | Clean folder structure, typed APIs end-to-end, generated OpenAPI spec                               |


---



## 4. Why this stack


| Choice                                                                 | Why it was chosen                                                                                                                                                                                                                                                                                                                                                                                                                                                         | Alternative rejected                                                                                                                                             |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **FastAPI + Uvicorn**                                                  | The hot path (submit review) is I/O-bound: one DB write, one or more LLM round-trips, one cache invalidation. Native `async` handles that without threads. OpenAPI/Swagger is generated from the type hints for free — and interactive API docs were a required deliverable.                                                                                                                                                                                              | Flask (no native async, no generated schema); Django (ORM + admin are heavyweight for a 10-router API)                                                           |
| **Async SQLAlchemy 2.0 +** `asyncpg`                                   | Keeps the async story end-to-end. A sync ORM inside an async framework blocks the event loop and quietly destroys the concurrency FastAPI was chosen for. `Mapped[]`/`mapped_column` typing gives static checking on the model layer.                                                                                                                                                                                                                                     | Sync SQLAlchemy; raw SQL (loses relationship mapping)                                                                                                            |
| **PostgreSQL**                                                         | Genuinely relational domain — users → merchants → businesses → reviews → analyses, plus two M:N joins. Also used for what it's uniquely good at: `JSONB` columns hold AI output whose shape evolves (`ai_positives`, `ai_complaints`, `image_insights`) without a migration per change.                                                                                                                                                                                   | MongoDB (the data is relational, joins would be hand-rolled); SQLite (**incompatible** — see the trap in §1)                                                     |
| **Redis, optional**                                                    | Search and business-profile reads are hot and repetitive. Deliberately a *cache*, not a dependency: every helper in `[cache.py](backend/app/services/cache.py)` wraps its call in `try/except` and returns `None` / no-ops on failure, so losing Redis degrades to uncached instead of erroring.                                                                                                                                                                          | In-memory cache (dies on restart, wrong across replicas)                                                                                                         |
| **AI provider as a** `Protocol` **port**                               | `AIProvider` in `[services/ai/base.py](backend/app/services/ai/base.py)` is a structural protocol — implementations need no inheritance. `get_ai_provider()` picks `MockAIProvider` or `OpenAICompatibleProvider` from `AI_PROVIDER`. Two payoffs: the app runs fully offline at **$0 with no API key** on `mock`, and swapping OpenAI → DeepSeek is an `AI_BASE_URL` change, not a code change.                                                                          | Calling the OpenAI SDK inline in routers (welds the app to one vendor, makes tests need network)                                                                 |
| **Storage as a** `Protocol` **port**                                   | Same shape: `StorageProvider` with `LocalStorageProvider` and `S3StorageProvider` (both implemented; `AzureBlobStorageProvider` still a stub). Local disk is right for dev; ephemeral container disk is wrong for production, and the port means that swap is a `STORAGE_PROVIDER=s3` config change, no code change. S3 credentials aren't a settings field — `boto3`'s own default chain (env vars, IAM role, `~/.aws/credentials`) covers every real deployment target. | Hardcoded local paths                                                                                                                                            |
| **Email as a** `Protocol` **port; Resend for the real vendor (S-035)** | Third port, same shape as AI/storage: `EmailProvider` with `MockEmailProvider` (logs only, no network) and `ResendEmailProvider` (a single HTTP adapter via `httpx`). Resend is a small typed transactional-send API with no SMTP/TLS/deliverability ops to run for a portfolio deploy, and local/demo/CI stay at $0 with no vendor key on `EMAIL_PROVIDER=mock` (ADR-007).                                                                                               | SMTP / SES / SendGrid (more ops and credentials for the same three transactional sends); vendor SDK inline in routers (welds review/approve/reset to one vendor) |
| **Pydantic Settings**                                                  | One typed `Settings` object loaded from env/`.env`. `Literal["mock","openai","deepseek"]` means a typo in `AI_PROVIDER` fails at **startup**, not at the first review submission in production.                                                                                                                                                                                                                                                                           | `os.getenv` scattered through modules (untyped, fails late)                                                                                                      |
| **JWT (**`python-jose`**) + bcrypt (**`passlib`**)**                   | Stateless auth — no session store, so the backend scales horizontally and works across the split Vercel/Render deployment. bcrypt is the deliberately-slow, salted standard for passwords.                                                                                                                                                                                                                                                                                | Server-side sessions (needs sticky sessions or shared store)                                                                                                     |
| **Next.js 15 App Router + React 19**                                   | Hybrid rendering matched to the page: Server Components render public pages (home, search, business profiles) on the server for SEO and fast first paint — these pages must be crawlable. `"use client"` is added only where browser APIs, event handlers, or auth state are needed (login, register, dashboards).                                                                                                                                                        | SPA (public listings invisible to search engines); full SSR (pointless for authenticated dashboards)                                                             |
| **TypeScript + Tailwind**                                              | Types across the API client boundary catch shape drift at compile time. Tailwind keeps styling colocated with markup — no separate CSS files to keep in sync in a small team.                                                                                                                                                                                                                                                                                             | Plain JS; CSS modules                                                                                                                                            |
| **Docker Compose**                                                     | One command reproduces the exact four-service topology on any machine. Also the artifact deployment reuses: Railway builds from the same verified `Dockerfile`s.                                                                                                                                                                                                                                                                                                          | Manual local installs (works-on-my-machine)                                                                                                                      |




---



## 5. Domain model



### ERD

```mermaid
erDiagram
    users ||--o| merchants : "has optional"
    merchants ||--o{ businesses : owns
    businesses }o--o{ categories : "via business_categories"
    users ||--o{ reviews : writes
    businesses ||--o{ reviews : receives
    reviews ||--o{ photos : attaches
    reviews ||--o| ai_analyses : "text analysis"
    photos ||--o| ai_analyses : "image analysis"
    reviews ||--o| replies : "merchant reply"
    users ||--o{ review_likes : likes
    users ||--o{ review_reports : reports
    users ||--o{ support_tickets : "opens"
    businesses ||--o{ support_tickets : "optional link"
    users ||--o{ business_reports : "shop reports"
    businesses ||--o{ business_reports : "flagged"
    business_reports ||--o{ business_report_messages : thread
    users ||--o{ favorites : saves
    users ||--o{ notifications : receives
    businesses ||--o{ payments : "featured checkout"
    payments ||--o| featured_placements : "activates"
    users ||--o{ payments : "merchant buyer"
    businesses ||--o{ external_reviews : "google sample"

    users {
        uuid id PK
        string email UK
        string hashed_password
        string full_name
        enum role
        bool is_active
        string phone
        string address_line1
        enum national_id_type
        string national_id_number
        bool totp_enabled
    }
    merchants {
        uuid id PK
        uuid user_id FK UK
        string phone
    }
    businesses {
        uuid id PK
        uuid merchant_id FK
        string name
        string slug UK
        string address
        string city
        float latitude
        float longitude
        enum status
        float average_rating
        int review_count
        jsonb ai_positives
        jsonb ai_complaints
        jsonb external_platform_refs
        int address_edit_count
    }
    categories {
        uuid id PK
        string name UK
        string slug UK
    }
    reviews {
        uuid id PK
        uuid business_id FK
        uuid author_id FK
        int rating
        text body
        enum status
        int like_count
    }
    ai_analyses {
        uuid id PK
        uuid review_id FK
        uuid photo_id FK
        enum sentiment
        text summary
        jsonb image_insights
        text suggested_response
    }
    photos {
        uuid id PK
        uuid business_id FK
        uuid review_id FK
        string url
        string photo_type
    }
    external_reviews {
        uuid id PK
        uuid business_id FK
        string source
        string external_review_id
        int rating
        text body
    }
```





### Tables


| Table                 | Purpose                                                             |
| --------------------- | ------------------------------------------------------------------- |
| `users`               | All platform users (role: customer, merchant, admin)                |
| `merchants`           | Merchant profile linked 1:1 to a user                               |
| `businesses`          | Business listings owned by a merchant                               |
| `categories`          | Business taxonomy                                                   |
| `business_categories` | M:N business ↔ category junction                                    |
| `reviews`             | Customer reviews on businesses (rating 1–5 embedded)                |
| `photos`              | Business gallery + review attachments                               |
| `ai_analyses`         | Text and image AI results                                           |
| `replies`             | Merchant responses to reviews                                       |
| `favorites`           | Customer saved businesses — **model exists, not wired up**, see §14 |
| `notifications`       | User notification queue. Unique `(user_id, scenario)` — one in-app notice per workflow scenario (**S-065**); duplicate rows pruned in migration `j4k5l6m7n8o9` (notifications table only) |
| `audit_logs`          | Admin action trail                                                  |
| `review_likes`        | Customer likes on reviews                                           |
| `review_reports`      | Reported reviews queue                                              |
| `support_tickets`     | Customer/merchant platform queries (S-088); optional shop link      |
| `business_reports`    | Shop-level reports, distinct from review reports (S-089)            |
| `business_report_messages` | Admin ↔ reporter thread on a shop report (S-089)               |
| `seed_runs`           | Demo seed version markers (`SEED_VERSION`) — skip re-upsert on boot |
| `payments`            | Featured-boost charges (SKU, paise, fee split, approve timestamps, no PAN) — S-036/S-042 |
| `featured_placements` | Time-bounded paid search boost (`starts_at` / `ends_at` / `disabled_at`) |
| `external_reviews`    | Third-party review sample (Google Places). **Never** blended into `average_rating` / `review_count` (**S-048**) |
| `whatsapp_sessions`   | Short-lived `MH-XXXXXXXX` token binding a WhatsApp phone to a business (**S-050**, mock default) |
| `business_update_drafts` | AI-extracted profile fields (`pending`/`applied`/`discarded`) — never auto-live (**S-052**) |


SQLAlchemy models live in a single file: `[backend/app/models/__init__.py](backend/app/models/__init__.py)`. `Business.external_platform_refs` is nullable JSONB (`{"google": "<place_id>"}` once linked; `NULL` when not). `Business.address_edit_count` (S-073) counts address-field edits since creation; `0` means the next address change needs no OTP, `>=1` means it does (see §7 `PATCH /businesses/{id}`). `BusinessUpdate.country` is included on PATCH (S-084); the `Business.country` column itself already existed.

### Relationships


| Relationship        | Cardinality | Notes                                                |
| ------------------- | ----------- | ---------------------------------------------------- |
| User → Merchant     | 1:0..1      | A user with role `merchant` has one merchant profile |
| Merchant → Business | 1:N         | A merchant can own multiple listings                 |
| Business ↔ Category | M:N         | Via `business_categories`                            |
| User → Review       | 1:N         | Customers write many reviews                         |
| Business → Review   | 1:N         | Each review belongs to one business                  |
| Review → Photo      | 1:N         | Reviews can carry photo attachments                  |
| Review → AIAnalysis | 1:1         | One text analysis per review                         |
| Photo → AIAnalysis  | 1:1         | One image analysis per photo                         |
| Review → Reply      | 1:1         | One public merchant reply per review                 |
| User → ReviewLike   | M:N         | Via `review_likes`                                   |
| User → Favorite     | M:N         | Customers save businesses                            |
| User → Notification | 1:N         | One row per `scenario` per user (**S-065**)          |
| User → AuditLog     | 1:N         | Admin actions are logged                             |
| Business → Payment  | 1:N         | Featured-boost checkout rows                         |
| Payment → Placement | 1:0..1      | Successful capture may create one 7-day window       |
| Business → ExternalReview | 1:N   | Google sample rows; unique `(business_id, source, external_review_id)` (**S-048**) |




### Enums


| Enum             | Values                                         |
| ---------------- | ---------------------------------------------- |
| `UserRole`       | `customer`, `merchant`, `admin`                |
| `BusinessStatus` | `pending`, `processing`, `approved`, `rejected`, `suspended` (**S-079**: `processing` is an optional, admin-triggered in-between state entered via "Start review" and left via "Return to pending" or the existing approve/suspend actions — visibility only, not a lock) |
| `ReviewStatus`   | `active`, `hidden`, `reported`, `removed`      |
| `PaymentStatus`  | `created`, `paid`, `failed`, `refunded`        |
| `DraftStatus`    | `pending`, `applied`, `discarded` (WhatsApp AI drafts, **S-052**; moved from `pending` to `applied`/`discarded` only by admin approve/reject since **S-053**, not merchant) |


### Notification scenarios (S-065)

In-app bell: **one row per merchant user per scenario**. A later event of the same kind **updates** that row (unread). Seed shops, photos, and addresses are not changed. Tests: `backend/tests/test_notification_scenarios.py` (one parametrized case per row).


| Scenario key | When | Copy (latest event) | Test id |
| ------------ | ---- | ------------------- | ------- |
| `listing_approved` | Admin approves a pending listing | Listing approved / now live | `listing_approved` |
| `new_review` | Customer submits a review | New N-star review on {shop} | `new_review` |
| `whatsapp_applied` | Admin approves a WhatsApp AI suggestion | WhatsApp update applied | `whatsapp_applied` |
| `whatsapp_rejected` | Admin rejects a WhatsApp AI suggestion | WhatsApp suggestion not applied | `whatsapp_rejected` |
| `payment_captured` | Featured payment captured (awaiting boost approve) | Featured payment received | `payment_captured` |
| `payment_boost_approved` | Admin approves featured placement | Featured boost is live | `payment_boost_approved` |


### Indexes & constraints

- Unique: `users.email`, `businesses.slug`, `categories.slug`
- Unique pairs: `(user_id, business_id)` on `favorites`, `(user_id, review_id)` on `review_likes`, `(author_id, business_id)` on `reviews` (`uq_author_business_review` — one review per user per business), `(business_id, source, external_review_id)` on `external_reviews`, `(user_id, scenario)` on `notifications` (**S-065**)
- Foreign keys with `CASCADE` on delete for reviews, photos, etc.

---



## 6. Feature flows



### Authentication

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant API as FastAPI
    participant DB as PostgreSQL
    participant Google as Google Identity Services

    alt Email / password
        User->>Frontend: Register or login
        Frontend->>API: POST /auth/register or /auth/login
        API->>DB: Create / verify user (bcrypt)
        API-->>Frontend: mfa_token (enroll or verify)
        alt First password login
            Frontend->>API: POST /auth/mfa/totp/setup + confirm
        else Already enrolled
            Frontend->>API: POST /auth/mfa/totp/verify
        end
        API-->>Frontend: access_token + refresh_token
        Frontend->>Frontend: Store tokens (localStorage today)
        Frontend->>API: GET /auth/me (Bearer)
        API-->>Frontend: User profile
    else Google sign-in
        User->>Frontend: "Continue with Google"
        Frontend->>Google: Client-side sign-in (GIS button)
        Google-->>Frontend: Signed ID token (credential)
        Frontend->>API: POST /auth/google { credential }
        API->>Google: Verify ID token against Google JWKS
        API->>DB: Look up or create user by google_sub
        API-->>Frontend: JWT access_token + refresh_token
    end

    Note over Frontend,API: All protected routes send Authorization: Bearer {token}
    Note over Frontend: Logout clears tokens, blocklists JTIs, hard-navigates; guards re-check on bfcache
```





### Password reset + transactional email (S-035)

Three v1 emails only: password reset, listing approved, new review. All go through the
`EmailProvider` port (`backend/app/services/email/`) — `mock` (default, logs only) or
`resend`, selected by `EMAIL_PROVIDER`. Review submit and business approve never fail on
a send error; email is best-effort and additive to the existing in-app notifications
(S-008 / S-015). The bell itself keeps **one row per scenario** (S-065); email is still
sent per event.

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant API as FastAPI
    participant Redis
    participant Mail as EmailProvider

    User->>Frontend: "Forgot password?" on /login
    Frontend->>API: POST /auth/forgot-password { email }
    alt Redis unreachable
        API-->>Frontend: 503
    else Redis reachable
        API->>API: Look up user by email
        opt Password account exists
            API->>Redis: SET auth:reset:{sha256(token)} → user_id, EX 3600
            API->>Mail: send password_reset (best-effort)
        end
        API-->>Frontend: 200 generic message (always, known or unknown email)
    end
    User->>Frontend: Open emailed link → /reset-password?token=
    Frontend->>API: POST /auth/reset-password { token, new_password }
    API->>Redis: GET + DEL token (single-use)
    API-->>Frontend: 200 (no session tokens) or 400 invalid/expired

    Note over API,Mail: Listing approved (admin approve) and new review (customer submit)<br/>each insert their in-app Notification, then best-effort email the merchant
```



Reset tokens are high-entropy, stored in Redis **hashed** (SHA-256) with a 1-hour TTL,
single-use, and looked up fail-closed — unlike login lockout, a Redis outage returns
**503** rather than silently skipping the reset (§9 Security has the full rationale).

### Featured listing boost (S-036, S-042)

Three SKUs: ₹299 / 7 days, ₹499 / 15 days, ₹899 / 30 days. Capture records the ledger; **admin approve** creates the placement. Search ranks active featured listings first. Copy on `/search` states this is a **paid boost**, not an AI quality judgment.

```mermaid
sequenceDiagram
    participant Merchant
    participant Web as Next.js
    participant API as FastAPI
    participant Pay as PaymentProvider
    participant Admin
    participant DB as PostgreSQL

    Merchant->>Web: Pick SKU tile
    Web->>API: POST /payments/featured/checkout sku_code
    API->>Pay: create_order
    API->>DB: payments status=created
    alt razorpay
        Web->>Pay: Checkout.js (PAN never hits our API)
        Pay->>API: POST /payments/webhooks/razorpay HMAC
    else mock DEBUG
        Note over Web,API: Admin POST /payments/mock/complete
    end
    API->>DB: paid fees only no placement
    Admin->>API: POST /payments/admin/payments/id/approve
    API->>DB: featured_placements window
    API->>API: invalidate search:*
```

### Review submission + AI analysis

The core path of the whole product.

```mermaid
sequenceDiagram
    participant Customer
    participant Frontend
    participant API as FastAPI
    participant DB as PostgreSQL
    participant AI as AI provider
    participant Cache as Redis

    Customer->>Frontend: Submit rating + review text + photos
    Frontend->>API: POST /api/v1/reviews
    API->>DB: Persist review
    API->>AI: analyze_review_text()
    AI-->>API: sentiment + summary + positives + complaints + suggested reply
    API->>DB: Insert ai_analyses record

    loop Each uploaded photo
        API->>AI: analyze_image()
        AI-->>API: Image insights (suggestions, not verdicts)
        API->>DB: Store photo + image analysis
    end

    API->>AI: generate_merchant_summary()
    API->>DB: Update business rating, review_count, rolling AI summary + trends
    API->>Cache: Invalidate business/review/search caches
    API-->>Frontend: Review + AI analysis
    Frontend-->>Customer: Confirmation + AI badge
```





### AI analysis branching

```mermaid
flowchart TD
    A[Review or photo uploaded] --> B{Type?}
    B -->|Text| C[AIProvider.analyze_review_text]
    B -->|Image| D[AIProvider.analyze_image]
    C --> E[Store AIAnalysis record]
    D --> E
    E --> F[Update merchant aggregate summary]
    F --> G[Invalidate Redis search cache]
    G --> H[Return suggestions to client]
```



**What the AI produces**


| Text analysis output                      | Image analysis signal              |
| ----------------------------------------- | ---------------------------------- |
| Sentiment — positive / neutral / negative | Store cleanliness                  |
| Review summary                            | Queue length (when visible)        |
| Rolling merchant summary                  | Product visibility / shelf display |
| Frequently mentioned positives            | Damaged products (when visible)    |
| Frequently mentioned complaints           | Outdoor appearance                 |
| Suggested owner response (editable draft) | Storefront quality / curb appeal   |
| Monthly trend analysis                    | Safety issues (when visible)       |


The port these implement (`[services/ai/base.py](backend/app/services/ai/base.py)`):

```python
class AIProvider(Protocol):
    async def analyze_review_text(self, text, context=None) -> ReviewAnalysisResult: ...
    async def analyze_image(self, image_url, context=None) -> ImageAnalysisResult: ...
    async def generate_merchant_summary(self, reviews, context=None) -> MerchantSummaryResult: ...
```



### Merchant dashboard

```mermaid
flowchart TD
    M[Merchant logs in] --> D["GET /dashboard/merchant/:id"]
    D --> R[Recent reviews feed]
    D --> S[Stats: reviews, rating, sentiment]
    D --> I["GET /ai/businesses/:id/insights"]
    R --> RESP[Respond to review]
    I --> POS[Frequently mentioned positives]
    I --> NEG[Frequently mentioned complaints]
    I --> TREND[Monthly trend analysis]
    I --> SUG[Suggested owner responses]
    S --> RAT[Rating distribution]
    S --> SEN[Sentiment over time]
    S --> VOL[Review volume]
    S --> UI[MerchantDashboard component]
    I --> UI
    UI --> CH[Charts + AIInsights panel]
    UI --> G[Google reviews card]
    G --> LINK["POST .../google-reviews/search + /link"]
    G --> SYNC["POST .../google-reviews/sync"]
```



`S` is filtered by an optional `range=30|90|all` query param (default `all`); `RAT`/`VOL` and reply-rate move with it, `S`'s totals/sentiment stay all-time. `UI` also offers **Export CSV** — `GET /dashboard/merchant/:id/reviews.csv`, same range, own business only (S-033).

**Google reviews (S-048):** owning merchant (or admin) links a Place ID once, then **Sync now** pulls Google's cap of 5 most-relevant reviews into `external_reviews`. Native `average_rating` / `review_count` do not change. Public profiles show a separate "Also reviewed on Google" section only when rows exist. No scheduler — manual sync only. Local/CI uses a mock provider unless `GOOGLE_PLACES_API_KEY` is set.

```mermaid
sequenceDiagram
    participant Merchant
    participant Dash as MerchantDashboard
    participant API as FastAPI
    participant Provider as mock or Google Places
    participant Visitor

    Merchant->>Dash: Link Google Business Profile
    Dash->>API: POST /dashboard/merchant/:id/google-reviews/search
    API->>Provider: Text Search
    Provider-->>Dash: candidates
    Merchant->>Dash: Confirm place
    Dash->>API: POST .../google-reviews/link
    Merchant->>Dash: Sync now
    Dash->>API: POST .../google-reviews/sync
    API->>Provider: Place Details reviews
    Visitor->>API: GET /businesses/:id/external-reviews
    API-->>Visitor: up to 5 rows (or [])
```

**WhatsApp shop updates (S-050..052 Testing, S-053 Accepted, mock default):** approved listings get a second QR beside collect. Inbound webhook binds `MH-XXXXXXXX`, stores photos as `general`, and parks AI-extracted text as pending drafts. Since **S-053**, only an admin can approve a draft onto the live listing — the merchant dashboard panel is read-only status (pending admin review / applied / discarded); admin review happens in a global cross-business queue at `/admin/whatsapp`, editable before approving.

```mermaid
sequenceDiagram
    participant Merchant
    participant Dash as MerchantDashboard
    participant API as FastAPI
    participant WA as WhatsAppProvider mock or meta_cloud
    participant AI as AIProvider
    participant Admin
    participant AdminUI as /admin/whatsapp

    Merchant->>Dash: Open approved listing
    Dash->>API: POST .../whatsapp/link
    API-->>Dash: wa.me + session token
    Note over API,WA: POST /webhooks/whatsapp HMAC
    API->>WA: parse inbound
    alt image on bound session
        API->>WA: download_media
        API->>API: save_business_photo general
    else text on bound session
        API->>AI: extract_business_profile
        API->>API: pending business_update_drafts
    end
    Admin->>AdminUI: GET /admin/whatsapp/drafts
    Admin->>AdminUI: edit field(s), Approve or Reject
    AdminUI->>API: POST .../approve or .../reject
    API->>API: write fields to Business (approve only) + audit_logs + Notification
    API-->>Merchant: in-app notification (+ best-effort email on approve)
```

### Merchant business registration

Merchants create listings at `/merchant/businesses/new` (wrapped in `RequireAuth role="merchant"`). The shared `BusinessForm` posts to `POST /businesses`; new rows start with `status=pending`. Country defaults to `IN` in the form (backend model default is `US` if omitted) and is a bundled ISO-3166 `<select>`; State is a cascading `<select>` of that country's subdivisions (S-084). Street address and city are plain text. Optional latitude/longitude can still be typed by hand — there is no address lookup or geocode button (S-084 product decision; see §14).

```mermaid
sequenceDiagram
    participant M as Merchant
    participant UI as BusinessForm
    participant Data as Bundled country/state list
    participant API as FastAPI

    M->>UI: Fill address, city; pick Country then State
    UI->>Data: getCountries / getStatesForCountry (no network)
    M->>UI: Submit for approval
    UI->>API: POST /businesses (Bearer merchant)
    API-->>UI: Business status=pending
```





### Search with location and map

The search page (`/search`) SSR-fetches via `GET /search/businesses` with optional `lat`, `lng`, and `radius_km`. **Use my location** sets those query params from browser geolocation. Results with coordinates render on a Leaflet map (`BusinessMap`) using OpenStreetMap tiles — not Google Maps. `FilterPanel` loads city chips from `GET /businesses/cities` and categories from `GET /businesses/categories/all`, and preserves existing `q`, `lat`, `lng`, and `radius_km` when applying city/category/rating filters.

```mermaid
flowchart LR
    U[User on /search] --> L[Use my location]
    L --> Q[URL ?lat=&lng=&radius_km=]
    Q --> S[GET /search/businesses]
    S --> M[BusinessMap markers]
    U --> F[FilterPanel Apply]
    F --> Q
```





### Admin moderation

```mermaid
sequenceDiagram
    participant A as Admin
    participant API as FastAPI
    participant DB as PostgreSQL

    A->>API: GET /dashboard/admin/platform
    API-->>A: Platform stats

    A->>API: GET /businesses?status_filter=pending
    Note over API: Non-approved status_filter requires admin Bearer token
    API-->>A: Pending business queue

    A->>API: POST /businesses/:id/approve
    API->>DB: status=approved + audit_log

    A->>API: GET /reviews/reported
    API-->>A: Reported review queue

    A->>API: POST /reviews/:id/moderate?action=hide
    API->>DB: status=hidden + audit_log
```



`/admin` also loads `GET /dashboard/admin/platform/series` (`granularity=day|week`, `days` 1-365, default `day`/`90`) for the trend row under the tiles — new users, businesses moved pending→approved (from `audit_logs`, not `Business.updated_at`), new reviews, new reports, all zero-filled and sourced from stored timestamps, never AI. **S-090** adds an operations nav and snapshot counts for open support tickets, repeat shop reports (distinct shops at ≥3 reports), and processing businesses on the same platform payload. Category create/list (`GET`/`POST /businesses/categories`) and user suspend/reactivate (`GET /admin/users`, `POST /admin/users/:id/suspend|reactivate`) round out the page; suspend/reactivate is refused (400) for the caller's own account or another admin (S-034).

---



## 7. API reference

Base URL (local): `http://localhost:8000/api/v1`  
Base URL (Railway): `https://<your-backend>.up.railway.app/api/v1` — replace with the backend service’s public domain from Railway → Settings → Networking.

### Where to try every endpoint (Swagger)

FastAPI generates interactive docs from the route type hints and docstrings. **You do not need a separate Swagger file in the repo** — it is served live by the running backend:


| Surface                             | Local                                                                    | Railway (example)                                    |
| ----------------------------------- | ------------------------------------------------------------------------ | ---------------------------------------------------- |
| **Swagger UI** (click “Try it out”) | [http://localhost:8000/docs](http://localhost:8000/docs)                 | `https://<your-backend>.up.railway.app/docs`         |
| **ReDoc** (read-only)               | [http://localhost:8000/redoc](http://localhost:8000/redoc)               | `https://<your-backend>.up.railway.app/redoc`        |
| **OpenAPI JSON** (machine-readable) | [http://localhost:8000/openapi.json](http://localhost:8000/openapi.json) | `https://<your-backend>.up.railway.app/openapi.json` |
| Health                              | [http://localhost:8000/health](http://localhost:8000/health)             | `https://<your-backend>.up.railway.app/health`       |


This project’s live backend (when deployed) is typically `https://backend-production-2783.up.railway.app` — open `/docs` on that host to exercise the full catalog.

**In Swagger UI**

1. Open `/docs`.
2. Expand any route → **Try it out** → **Execute**.
3. For protected routes: call `POST /api/v1/auth/login` first, copy `access_token`, click **Authorize**, enter `Bearer <token>` (or just the token if the UI prepends `Bearer`).
4. Demo accounts are in [§1 Quick start](#1-quick-start) (`customer@example.com` / `customer1234`, etc.).

The tables below are the human-readable contract; Swagger is always the up-to-date executable list (including request/response schemas).

### curl starter kit

Set the base once (local or Railway):

```bash
# Local
export API=http://localhost:8000

# Or Railway
# export API=https://backend-production-2783.up.railway.app
```

**Public reads (no auth)** — how the home/search pages load data:

```bash
# Health
curl -s "$API/health"

# Platform counts (home trust metrics)
curl -s "$API/api/v1/businesses/stats/summary"

# Distinct cities (FilterPanel chips + home neighborhood index)
curl -s "$API/api/v1/businesses/cities"

# Categories (home category index + search dropdown)
curl -s "$API/api/v1/businesses/categories/all"

# Search / filter (Redis-cached). Same query shape the Next.js search page uses.
curl -s "$API/api/v1/search/businesses?city=Chennai&category=cafe&sort=rating&page=1&page_size=20"

# Free-text q matches name, description, or city
curl -s "$API/api/v1/search/businesses?q=Chrompet"

# List approved businesses
curl -s "$API/api/v1/businesses"

# One business by slug (from search/list JSON → .slug)
curl -s "$API/api/v1/businesses/krishna-sweets-chrompet"

# Reviews for a business (use .id from the business JSON)
curl -s "$API/api/v1/reviews/business/<business-uuid>"

# Maps
curl -s "$API/api/v1/maps/config"
```

**Auth + Bearer calls**

```bash
# Password login → MFA challenge (demo accounts already have TOTP enrolled)
curl -s -X POST "$API/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"customer@example.com","password":"customer1234"}'
# → { "mfa_required": true, "mfa_token": "..." }

# Verify with current authenticator code (demo secret JBSWY3DPEHPK3PXP)
curl -s -X POST "$API/api/v1/auth/mfa/totp/verify" \
  -H "Content-Type: application/json" \
  -d '{"mfa_token":"<mfa_token>","code":"<6-digit>"}'

# Save token (bash). On PowerShell, copy access_token from the JSON manually.
export TOKEN='eyJ...'   # paste access_token

curl -s "$API/api/v1/auth/me" -H "Authorization: Bearer $TOKEN"

# Favorites (customer role)
curl -s "$API/api/v1/favorites" -H "Authorization: Bearer $TOKEN"

# Merchant / admin: login as merchant@example.com / merchant1234 or admin@merchanthub.ai / admin12345ok
curl -s "$API/api/v1/businesses/mine" -H "Authorization: Bearer $TOKEN"
curl -s "$API/api/v1/dashboard/admin/platform" -H "Authorization: Bearer $TOKEN"
```

**Write example (creates a review + mock AI analysis)** — use a business `id` you do not already own/review:

```bash
curl -s -X POST "$API/api/v1/reviews" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"business_id":"<uuid>","rating":5,"title":"Great visit","body":"Friendly staff and excellent food. Will return!"}'
```

For every other route (photos upload, notifications, AI refresh, moderate, …), use **Swagger → Try it out** — schemas and required fields are generated there. Dump the full path list anytime with:

```bash
curl -s "$API/openapi.json" | python -c "import sys,json; print('\n'.join(sorted(json.load(sys.stdin)['paths'])))"
```



### How the website extracts this data

```mermaid
flowchart LR
  Browser --> NextSSR[Next.js Server Component]
  NextSSR -->|"API_URL_INTERNAL or NEXT_PUBLIC_API_URL"| FastAPI
  FastAPI --> Postgres[(PostgreSQL)]
  FastAPI --> Redis[(Redis cache)]
  Browser -->|"client fetch + Bearer JWT"| FastAPI
```




| UI surface         | Calls (via `[frontend/src/lib/api.ts](frontend/src/lib/api.ts)`)               |
| ------------------ | ------------------------------------------------------------------------------ |
| Home `/`           | `stats`, `cities`, `categories/all`, then `search?city=<first city>` or `list` |
| Search `/search`   | `search/businesses?...`, `cities`, `categories/all`                            |
| Business profile   | `businesses/{slug}`, `reviews/business/{id}`, photos                           |
| Login / dashboards | Browser `fetch` with `Authorization: Bearer …` from `localStorage`             |


SSR prefers `API_URL_INTERNAL` inside the Next container (Railway must set it to the backend HTTPS URL); the browser uses `NEXT_PUBLIC_API_URL` (baked at **frontend build** time).

All ten routers are mounted with the `/api/v1` prefix in `[main.py](backend/app/main.py)`. `/health` and `/` sit outside the prefix. Uploaded files are served as static assets from `/uploads`.

### Authentication — `/auth`


| Method | Path                     | Auth             | Description                                                                                   |
| ------ | ------------------------ | ---------------- | --------------------------------------------------------------------------------------------- |
| POST   | `/auth/register`         | Public           | Create account                                                                                |
| POST   | `/auth/login`            | Public           | Password check → MFA challenge or enrollment (`LoginResult`)                                  |
| POST   | `/auth/forgot-password`  | Public           | Request password-reset email; **always 200**, generic copy (no account-existence enumeration) |
| POST   | `/auth/reset-password`   | Public           | Complete reset with emailed token; no session tokens issued                                   |
| POST   | `/auth/mfa/totp/setup`   | MFA enroll token | Start authenticator enrollment (QR + secret)                                                  |
| POST   | `/auth/mfa/totp/confirm` | MFA enroll token | Confirm first TOTP code → session tokens                                                      |
| POST   | `/auth/mfa/totp/verify`  | MFA verify token | Verify TOTP → session tokens                                                                  |
| POST   | `/auth/refresh`          | Public           | Refresh tokens                                                                                |
| GET    | `/auth/me`               | Bearer           | Current user                                                                                  |
| PATCH  | `/auth/me`               | Bearer           | Update profile (name, phone, address, national ID: pan/aadhaar/other). Schema still accepts `avatar_url`; the web profile form no longer submits it (**S-085** uses `POST /auth/me/avatar`). Merchant ID required before `POST /businesses`. Admin user list returns a **masked** number. |
| POST   | `/auth/me/avatar`        | Bearer           | **S-085:** upload/replace the caller's own profile photo (`multipart` `file`; same type/size rules as photo upload). Returns `UserResponse`. Own-user only (no `user_id`). 400 unsupported type or >5MB; 401 unauthenticated. Not `POST /photos/upload` — no `Photo` row, no AI image analysis. |
| POST   | `/auth/google`           | Public           | Google ID-token sign-in (register-or-login; no TOTP)                                          |
| POST   | `/auth/phone/request`    | Public           | Send SMS OTP (generic 200; mock logs the code). 400 invalid number; 503 if Redis/SMS down     |
| POST   | `/auth/phone/verify`     | Public           | Verify OTP → JWT (skips TOTP). First visit needs `full_name`; optional `role` customer/merchant |
| POST   | `/auth/national-id/aadhaar/mock-otp/request` | Bearer | S-070: start a MOCK Aadhaar OTP challenge (`{aadhaar_number}`, 12 digits). Not UIDAI — returns `dev_code` only when `DEBUG=true` |
| POST   | `/auth/national-id/aadhaar/mock-otp/verify`  | Bearer | S-070: verify the mock code (`{code}`); on success saves `national_id_type=aadhaar` + the number. 401 on wrong/expired code |
| POST   | `/auth/logout`           | Bearer           | Blocklist caller's access token (+ optional refresh token)                                    |


```jsonc
// POST /auth/register  →  201 User object
{ "email": "user@example.com", "full_name": "Jane Doe", "password": "securepass123", "role": "customer" }

// POST /auth/login  (password accounts never get session tokens here)
{ "email": "user@example.com", "password": "securepass123" }
// → first time:
{ "mfa_enrollment_required": true, "mfa_token": "eyJ..." }
// → later:
{ "mfa_required": true, "mfa_token": "eyJ..." }

// POST /auth/mfa/totp/verify (or /confirm after setup)
{ "mfa_token": "eyJ...", "code": "123456" }
// →
{ "access_token": "eyJ...", "refresh_token": "eyJ...", "token_type": "bearer" }

// POST /auth/forgot-password  →  always 200, same body for known and unknown addresses
{ "email": "user@example.com" }
// →
{ "message": "If an account exists for that email, we sent password-reset instructions." }

// POST /auth/reset-password  (token comes from the emailed link's ?token= query param)
{ "token": "raw-url-safe-token", "new_password": "newsecurepass123" }
// →
{ "message": "Password updated. Sign in with your new password." }
```



### Businesses — `/businesses`


| Method | Path                         | Auth           | Description                                                              |
| ------ | ---------------------------- | -------------- | ------------------------------------------------------------------------ |
| GET    | `/businesses`                | Public         | List businesses (default `status_filter=approved`)                       |
| GET    | `/businesses/mine`           | Merchant       | List businesses owned by current merchant (any status)                   |
| GET    | `/businesses/admin/all`      | Admin          | Browse businesses of every status, newest-registered first (S-021)       |
| GET    | `/businesses/categories/all` | Public         | List categories. Optional `q` (S-081): case-insensitive substring filter on `Category.name` |
| GET    | `/businesses/cities`         | Public         | Distinct cities from approved businesses (search filter chips)           |
| GET    | `/businesses/stats/summary`  | Public         | Public counts: businesses, reviews, categories, cities (no admin fields) |
| GET    | `/businesses/{slug}`         | Public         | Get by slug                                                              |
| GET    | `/businesses/{business_id}/external-reviews` | Public | Synced Google review sample, max 5, `[]` if none (**S-048**). Does not affect `average_rating` / `review_count` |
| POST   | `/businesses`                | Merchant       | Create business (status `pending`). 400 if merchant national ID missing  |
| PATCH  | `/businesses/{id}`           | Merchant/Admin | Update business. `BusinessUpdate` includes `country` (S-084). S-073: merchant edits to `address`/`city`/`state`/`postal_code`/`country` require `address_otp_code` once `address_edit_count >= 1` (400 missing, 401 wrong/expired). Admin edits bypass this gate. |
| POST   | `/businesses/{id}/address-verify/request` | Merchant (owner) | S-073: sends an OTP to confirm a 2nd+ address edit (SMS to business phone, falling back to the merchant's own phone). 409 if no prior address edit yet, 400 if no phone is on file |
| POST   | `/businesses/{id}/approve`   | Admin          | Approve listing (works from `pending` or `processing`)                  |
| POST   | `/businesses/{id}/suspend`   | Admin          | Suspend listing (works from `pending` or `processing`)                  |
| POST   | `/businesses/{id}/start-review` | Admin       | S-079: mark a `pending` business as `processing` (visibility only, not a lock). `409` if not currently `pending` |
| POST   | `/businesses/{id}/return-to-pending` | Admin  | S-079: revert a `processing` business back to `pending`. `409` if not currently `processing` |
| POST   | `/businesses/{id}/reports`   | User           | S-089: report a shop (not a review). `403` if the caller owns the listing |
| POST   | `/businesses/categories`     | Admin          | Create category. `409` if name or slug already exists (S-034)            |


Query on `GET /businesses`: `city`, `slugs` (comma-separated exact-slug filter, used by the homepage social-proof rail), `status_filter` (`approved` default). Listing with any non-`approved` `status_filter` (e.g. `pending`) requires an admin Bearer token; anonymous callers receive `403`.

### Reviews — `/reviews`


| Method | Path                              | Auth   | Description                                                                       |
| ------ | --------------------------------- | ------ | --------------------------------------------------------------------------------- |
| GET    | `/reviews/business/{business_id}` | Public | List reviews                                                                      |
| GET    | `/reviews/reported`               | Admin  | List reported reviews                                                             |
| GET    | `/reviews/admin/all`              | Admin  | Browse reviews across every business/status; optional `business_id` scope (S-021) |
| POST   | `/reviews`                        | User   | Create review (triggers AI)                                                       |


**POST** `/reviews` **errors:** `403` if a merchant reviews their own business (`"Cannot review your own business"`); `409` if the author already reviewed that business (`"You have already reviewed this business"`), including concurrent double-submit races caught by `uq_author_business_review`.
| PATCH  | `/reviews/{id}`                   | Author   | Edit review                 |
| DELETE | `/reviews/{id}`                   | Author   | Delete review               |
| POST   | `/reviews/{id}/like`              | User     | Like review                 |
| POST   | `/reviews/{id}/report`            | User     | Report review               |
| POST   | `/reviews/{id}/reply`             | Merchant | Reply to review             |
| POST   | `/reviews/{id}/moderate`          | Admin    | Hide / restore / remove     |

```jsonc
// POST /reviews  →  Review with ai_analysis { sentiment, summary, suggested_response }
{ "business_id": "uuid", "rating": 5, "title": "Great coffee!", "body": "Friendly staff and excellent pastries. Will return!" }
```



### Photos — `/photos`


| Method | Path                    | Auth           | Description              |
| ------ | ----------------------- | -------------- | ------------------------ |
| POST   | `/photos/upload`        | User           | Upload photo (multipart) |
| GET    | `/photos/business/{id}` | Public         | Business gallery         |
| DELETE | `/photos/{id}`          | Merchant/Admin | Delete photo             |


Upload form fields: `file`, `business_id`, `review_id`, `photo_type`, `caption`.

### AI analysis — `/ai`


| Method | Path                           | Auth     | Description          |
| ------ | ------------------------------ | -------- | -------------------- |
| GET    | `/ai/reviews/{review_id}`      | Public   | Review AI analysis   |
| GET    | `/ai/businesses/{id}/insights` | Merchant | Merchant AI insights |
| POST   | `/ai/businesses/{id}/refresh`  | Merchant | Refresh AI summary   |
| GET    | `/ai/businesses/{id}/topics`   | Merchant/Admin | AI topic clustering — named themes with count + sentiment, suggestion-labeled (S-049) |




### Dashboard — `/dashboard`


| Method | Path                                            | Auth            | Description                                                                                                                                                                                                                                                                             |
| ------ | ----------------------------------------------- | --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| GET    | `/dashboard/merchant/{business_id}`             | Merchant, Admin | Merchant dashboard stats. Query `range=30|90|all` (default `all`, 422 if invalid) filters `review_volume_by_month`, `rating_distribution`, `reply_rate`, plus S-037 previous-window counts. `total_reviews`/`average_rating`/`sentiment_breakdown`/`recent_reviews` stay all-time (**S-033**) |
| GET    | `/dashboard/merchant/{business_id}/benchmark`   | Merchant, Admin | Category + city rating medians from approved listings; null if fewer than 3 peers. Not an AI judgment (**S-038**) |
| GET    | `/dashboard/merchant/{business_id}/reviews.csv` | Merchant, Admin | Export that business's reviews as `text/csv` (same `range`, own business only, never cached) (**S-033**)                                                                                                                                                                                |
| POST   | `/dashboard/merchant/{business_id}/google-reviews/search` | Merchant, Admin | Places Text Search proxy; body `{query}` (min 2). `200` empty list is valid; `502` readable error (**S-048**) |
| GET    | `/dashboard/merchant/{business_id}/google-reviews` | Merchant, Admin | Link/sync status: `linked`, `place_id`, `review_count`, `last_synced_at` (**S-048**) |
| POST   | `/dashboard/merchant/{business_id}/google-reviews/link` | Merchant, Admin | Set `external_platform_refs.google`. `409` if already linked (**S-048**) |
| POST   | `/dashboard/merchant/{business_id}/google-reviews/sync` | Merchant, Admin | Fetch/upsert up to 5 reviews. `400` if unlinked; `200` `{debounced: true}` if a sync is in flight; `502` leaves rows untouched (**S-048**) |
| POST   | `/dashboard/merchant/{business_id}/whatsapp/link` | Merchant, Admin | Short-lived `wa.me` URL + session token (**S-050**). Mock is always `available` |
| GET    | `/dashboard/merchant/{business_id}/whatsapp/drafts` | Merchant, Admin | Read-only: every draft for this business, any status, newest first. Apply/discard is admin-only now — see `/admin/whatsapp/drafts` above (**S-052**, RBAC changed **S-053**) |
| GET    | `/dashboard/admin/platform`                     | Admin           | Snapshot `COUNT(*)` tiles: original five plus `open_support_tickets` (`open`+`in_progress`), `repeat_shop_reports` (distinct shops with ≥3 shop reports), `processing_businesses` (**S-090**) |
| GET    | `/dashboard/admin/platform/series`              | Admin           | Time series: `new_users`, `businesses_approved` (from `audit_logs` `approve`/`business`), `new_reviews`, `new_reports`. Query `granularity=day|week` (default `day`), `days` 1-365 (default `90`), zero-filled buckets (**S-034**)                                                      |




### Admin — `/admin`


| Method | Path                           | Auth  | Description                                                                                                                                                       |
| ------ | ------------------------------ | ----- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| GET    | `/admin/users`                 | Admin | List users, newest first. Optional `page`, `page_size` (cap 100), `q` substring on email/full_name. Never serializes `totp_secret`/`hashed_password`/`google_sub` |
| POST   | `/admin/users/{id}/suspend`    | Admin | Set `is_active=false` + `audit_logs` row. Idempotent. `400` if `id` is the caller or another admin, `404` unknown id                                              |
| POST   | `/admin/users/{id}/reactivate` | Admin | Set `is_active=true` + `audit_logs` row. Idempotent. `400` if `id` is the caller or another admin, `404` unknown id                                               |
| GET    | `/admin/whatsapp/drafts`       | Admin | Global, cross-business queue of pending `business_update_drafts`, oldest first. `page`, `page_size` (cap 100), `total` count (**S-053**) |
| POST   | `/admin/whatsapp/drafts/{id}/approve` | Admin | Write the (optionally edited) fields to the live `Business` row; `audit_logs` (`entity_type=business_update_draft`, `details.ai_fields`/`applied_fields`) + merchant `Notification` + best-effort email. `404`/`409` (**S-053**) |
| POST   | `/admin/whatsapp/drafts/{id}/reject` | Admin | Leave the live `Business` row untouched; `audit_logs` + merchant `Notification`. `404`/`409` (**S-053**) |
| GET    | `/admin/support-tickets` | Admin | S-088: list support tickets; optional `status` |
| PATCH  | `/admin/support-tickets/{id}` | Admin | S-088: set `status` and/or `admin_response` |
| GET    | `/admin/business-reports` | Admin | S-089: shop reports with `report_count` and `is_repeat` (≥3) |
| PATCH  | `/admin/business-reports/{id}` | Admin | S-089: set report `status` |
| POST   | `/admin/business-reports/{id}/messages` | Admin | S-089: reply on a shop-report thread |


### Support — `/support`, `/support-tickets`, `/business-reports`

| Method | Path | Auth | Description |
| ------ | ---- | ---- | ----------- |
| GET | `/support/contact` | Public | `{ email, support_path }` from `SUPPORT_EMAIL` (S-087) |
| POST | `/support-tickets` | Optional | Create ticket: name, phone, issue, optional `business_id` (S-088) |
| GET | `/support-tickets/mine` | User | Caller's tickets (S-088) |
| GET | `/business-reports/mine` | User | Caller's shop reports + messages (S-089) |
| POST | `/business-reports/{id}/messages` | Reporter | Follow-up on own shop report (S-089) |


Suspended/reactivated accounts are always `customer` or `merchant` — an admin can never suspend themselves or another admin. Existing login/refresh/`get_current_user` already reject `is_active=false` (S-034).

### Search — `/search`


| Method | Path                 | Auth   | Description                    |
| ------ | -------------------- | ------ | ------------------------------ |
| GET    | `/search/businesses` | Public | Search + filter (Redis-cached). Featured-active first; `is_featured` (S-036) |


Query params: `q`, `city`, `category`, `min_rating`, `sentiment`, `lat`, `lng`, `radius_km`, `page`, `page_size`, `sort` (`rating`  `name`  `reviews`). Active paid featured placements rank first (`is_featured`); among featured, sooner `ends_at` wins, then the requested `sort`. Geo search applies featured-first **after** the distance filter.


### Payments — `/payments`


| Method | Path | Auth | Description |
| ------ | ---- | ---- | ----------- |
| GET | `/payments/featured/skus` | Merchant or admin | Catalog: 7d ₹299, 15d ₹499, 30d ₹899 |
| POST | `/payments/featured/checkout` | Merchant | `{ business_id, sku_code }` for an owned **approved** listing. 400 unknown SKU / not approved; 409 already featured |
| POST | `/payments/webhooks/razorpay` | HMAC header | Capture/fail; ledger only; idempotent on `provider_order_id` |
| POST | `/payments/mock/complete` | Admin | DEBUG-only mock capture/fail (does not feature). **404** if `DEBUG=false` |
| GET | `/payments/businesses/{id}/placement` | Merchant (own) or admin | Active/expiry + SKU catalog. Admin sees fee split; merchant sees awaiting-approval without fees |
| GET | `/payments/admin/payments` | Admin | Paged ledger: shop, merchant, SKU, counts, approve/reject state |
| POST | `/payments/admin/payments/{id}/approve` | Admin | Create placement after `paid`. 409 if not paid / rejected / already featured |
| POST | `/payments/admin/payments/{id}/reject` | Admin | Refuse boost; no refund |
| POST | `/payments/admin/placements/{id}/disable` | Admin | Drop rank immediately; no refund |
| POST | `/payments/admin/payments/{id}/refund` | Admin | Provider refund + disable placement. 409 if not `paid` |


### Webhooks — `/webhooks`


| Method | Path | Auth | Description |
| ------ | ---- | ---- | ----------- |
| GET | `/webhooks/whatsapp` | Meta verify token | Subscription handshake — echoes `hub.challenge` (**S-050**) |
| POST | `/webhooks/whatsapp` | `X-Hub-Signature-256` HMAC | Inbound messages. `400` missing/invalid sig. Mock accepts `sha256=mock`. Photos + drafts; text never auto-publishes |


### Favorites — `/favorites`


| Method | Path                       | Auth     | Description                                       |
| ------ | -------------------------- | -------- | ------------------------------------------------- |
| GET    | `/favorites`               | Customer | List favorited businesses (newest first)          |
| POST   | `/favorites`               | Customer | Favorite an approved business (`{ business_id }`) |
| DELETE | `/favorites/{business_id}` | Customer | Remove favorite (idempotent 204)                  |




### Analytics — `/analytics` (deprecated)

Legacy aliases. The frontend must use `/dashboard` and `/ai`, not these routes. **Do not extend.** Removal is a later cleanup, not S-033/S-034.


| Method | Path                               | Auth     | Description              |
| ------ | ---------------------------------- | -------- | ------------------------ |
| GET    | `/analytics/merchant/{id}`         | Merchant | Unused AI insights alias |
| GET    | `/analytics/merchant/{id}/summary` | Merchant | Unused KPI summary       |




### Notifications — `/notifications`


| Method | Path                       | Auth   | Description        |
| ------ | -------------------------- | ------ | ------------------ |
| GET    | `/notifications`           | Bearer | List notices (at most one per `scenario` per user, **S-065**) |
| POST   | `/notifications/{id}/read` | Bearer | Mark one read      |
| POST   | `/notifications/read-all`  | Bearer | Mark all read      |




### Maps — `/maps` (OpenStreetMap)

Uses **Haversine** bounding-box queries for nearby approved businesses that already have coordinates. The frontend map is **Leaflet + OSM tiles** — no Google Maps API key required. Forward geocoding (`GET /maps/geocode`) and address autocomplete (`GET /maps/autocomplete`) were removed in **S-084**; merchants enter address text and pick Country/State from bundled dropdowns instead.


| Method | Path            | Auth   | Description                                       |
| ------ | --------------- | ------ | ------------------------------------------------- |
| POST   | `/maps/nearby`  | Public | Approved businesses within `radius_km` of a point |
| GET    | `/maps/config`  | Public | Provider config (`provider: osm`, tile URL)       |


Listings without `latitude`/`longitude` are omitted from nearby/map results (see §14).

### Health


| Method | Path      | Description             |
| ------ | --------- | ----------------------- |
| GET    | `/health` | Service health check    |
| GET    | `/`       | API welcome + doc links |


**When adding an endpoint,** document method + path, request body/query params, response schema, auth requirement, and error codes — here and in the route's docstring (Swagger reads it).

---



## 8. Frontend guide

Written to be readable by someone new to React/Next.js.

### Props

Props are **inputs passed from a parent component to a child**. They are read-only inside the child.

```tsx
<BusinessCard business={business} href="/custom-link" />
```


| Component      | Key props                                      |
| -------------- | ---------------------------------------------- |
| `Navbar`       | `user`, `onLogout`                             |
| `BusinessCard` | `business`, `href`                             |
| `ReviewCard`   | `review`, `onLike`, `onReport`, `showActions`  |
| `RatingWidget` | `value`, `onChange`, `readonly`, `size`        |
| `AIInsights`   | `insights`                                     |
| `Dashboard`    | `title`, `description`, `navItems`, `children` |




### State

State is **mutable data managed inside a component**. When it changes, React re-renders.


| Component           | State it holds                                           |
| ------------------- | -------------------------------------------------------- |
| `LoginForm`         | `email`, `password`, `error`, `loading`                  |
| `RatingWidget`      | `hover` — star preview                                   |
| `PhotoGallery`      | `selected` — lightbox index                              |
| `MerchantDashboard` | `business`, `stats`, `insights`, `range`, `exportingCsv` |




### Hooks


| Hook        | Purpose                           | Used in                                            |
| ----------- | --------------------------------- | -------------------------------------------------- |
| `useState`  | Local component state             | `LoginForm`, `RatingWidget`, `PhotoGallery`        |
| `useEffect` | Side effects — API calls on mount | `ClientLayout`, `MerchantDashboard`, `ProfilePage` |
| `useRouter` | Next.js navigation                | `LoginForm`, `RegisterForm`, `SettingsPage`        |


A custom `useAuth` hook could be added later to centralise token + user logic.

### Routing — App Router

File-based routing under `frontend/src/app/`. A `page.tsx` file defines a route.


| URL                              | File                                     | Type                             |
| -------------------------------- | ---------------------------------------- | -------------------------------- |
| `/`                              | `page.tsx`                               | Server Component (SSR)           |
| `/search`                        | `search/page.tsx`                        | Server Component                 |
| `/businesses/[slug]`             | `businesses/[slug]/page.tsx`             | Dynamic SSR                      |
| `/login`                         | `login/page.tsx`                         | Client form page                 |
| `/forgot-password`               | `forgot-password/page.tsx`               | Client form page (S-035)         |
| `/reset-password`                | `reset-password/page.tsx`                | Client form page (S-035)         |
| `/collect/[businessId]`          | `collect/[businessId]/page.tsx`          | Client collect wizard (S-040)    |
| `/register`                      | `register/page.tsx`                      | Client form page                 |
| `/profile`                       | `profile/page.tsx`                       | Client — click-to-upload avatar (S-085), independent of Save changes |
| `/settings`                      | `settings/page.tsx`                      | Client                           |
| `/merchant/dashboard`            | `merchant/dashboard/page.tsx`            | Client dashboard (`RequireAuth`) |
| `/merchant/businesses/new`       | `merchant/businesses/new/page.tsx`       | Client — create business         |
| `/merchant/businesses/[id]/edit` | `merchant/businesses/[id]/edit/page.tsx` | Client — edit owned business     |
| `/admin`                         | `admin/page.tsx`                         | Client ops console (`RequireAuth admin`, S-090) |




### SSR vs CSR

**SSR** — the server generates HTML *before* sending it to the browser. Used for public pages that need SEO and fast first paint: home, search results, business profiles.

```tsx
// No "use client" — runs on the server
export default async function HomePage() {
  const [listed, cities, categories, stats] = await Promise.all([
    businesses.list(),
    businesses.cities(),
    businesses.categoriesAll(),
    businesses.stats(),
  ]);
  // Featured grid: search by first city from GET /businesses/cities, else list()
  return <div>...</div>;
}
```

The home page loads cities, categories, stats, and (for the voices band) reviews from the API on SSR. Bands in order: brand-first hero (search + CTAs over a storefront photo plane — no stats overlays), live trust metrics (`GET /businesses/stats/summary` including `total_cities`), neighborhood and category indexes with counts derived from the listed catalog, featured listings with optional `ai_merchant_summary` suggestion blurbs, real review voices with AI summaries labeled as suggestions, how-it-works, and a merchant AI CTA. Featured section title and city-scoped grid come from `GET /businesses/cities` — not hardcoded place names.
**CSR** — the browser downloads JavaScript and fetches data *after* the page loads. Used for interactive forms and authenticated dashboards: login, register, merchant dashboard, admin panel.

```tsx
"use client";
export default function LoginPage() {
  const [email, setEmail] = useState("");
  // ...
}
```

**The hybrid rule:** App Router uses Server Components **by default**. Add `"use client"` only to files that need browser APIs, event handlers, or hooks.

### Components

All in `frontend/src/components/`. Each file carries a JSDoc comment explaining purpose, props, and state.


| Component                  | Description                                                                    |
| -------------------------- | ------------------------------------------------------------------------------ |
| `Navbar.tsx`               | Global nav, auth state, role-aware links; signed-in user shows `Avatar` + name linking to `/profile` (S-085) |
| `NotificationBell.tsx`     | Navbar notifications dropdown (S-015)                                          |
| `Footer.tsx`               | Multi-column site map: Discover, merchants, Account, Support (S-087) |
| `AdminBackLink.tsx`        | Shared “← Admin panel” on admin drill-downs (S-086)                    |
| `AdminOpsNav.tsx`          | Compact `/admin` operations jump nav (S-090)                       |
| `SupportTicketForm.tsx`    | Public support query form + my tickets / shop reports (S-088, S-089) |
| `ReportShopButton.tsx`     | Report a listing from the public profile (S-089)                       |
| `home/TrustMetrics.tsx`    | Editorial live platform counts on the home page                                |
| `home/CityIndex.tsx`       | Neighborhood links with listing counts                                         |
| `home/CategoryIndex.tsx`   | Category search index with counts                                              |
| `home/FeaturedGrid.tsx`    | Featured cards + optional AI suggestion blurbs                                 |
| `home/ReviewVoices.tsx`    | Real reviews with AI suggestion callouts                                       |
| `BusinessCard.tsx`         | Compact listing card for search results                                        |
| `ReviewCard.tsx`           | Review with rating, photos, likes, AI badge                                    |
| `RatingWidget.tsx`         | Interactive star rating input/display                                          |
| `FavoriteButton.tsx`       | Customer favorite toggle on business detail                                    |
| `BusinessHours.tsx`        | Opening-hours list for business detail                                         |
| `CategoryBadges.tsx`       | Full category Badge list; each badge links to `/search?category={slug}` (S-041) |
| `SearchBar.tsx`            | Query input with debounce                                                      |
| `FilterPanel.tsx`          | City chips from API + category/rating filters (preserves location params)      |
| `UseLocationButton.tsx`    | Browser geolocation → `/search?lat=&lng=`                                      |
| `BusinessMap.tsx`          | Leaflet map with OSM tiles for search results                                  |
| `BusinessForm.tsx`         | Merchant create/edit business form; Country/State dropdowns (S-084)            |
| `RequireAuth.tsx`          | Client route guard by role (JWT in localStorage)                               |
| `PendingBusinessQueue.tsx` | Admin pending-business approval queue                                          |
| `ReportedReviewsQueue.tsx` | Admin reported-review moderation queue (shop-name link via `showBusinessLink`) |
| `AllBusinessesQueue.tsx`   | Admin browse of businesses in every status (S-021)                             |
| `AllReviewsQueue.tsx`      | Admin browse of reviews across businesses; business-name drill-down (S-021)    |
| `AdminCategoryPanel.tsx`   | Admin category create + list; chips link to search by slug (S-034, S-041)      |
| `AdminPaymentPanel.tsx`    | Admin featured payment desk: mock complete, approve/reject, refund (S-042)     |
| `AdminUserPanel.tsx`       | Admin user list + suspend/reactivate panel (S-034)                             |
| `AdminSupportQueue.tsx`    | Admin support-ticket queue (S-088)                                             |
| `AdminBusinessReportsQueue.tsx` | Admin shop-report queue with Repeat badge (S-089)                         |
| `Dashboard.tsx`            | Layout shell for merchant/admin analytics                                      |
| `Charts.tsx`               | Recharts bar / area / line dashboard series                                    |
| `PhotoGallery.tsx`         | Image grid + lightbox                                                          |
| `PhoneOtpPanel.tsx`        | Phone OTP request/verify on login and register (S-044)                         |
| `RegisterForm.tsx`         | Registration form with validation                                              |
| `ui/Avatar.tsx`            | Image-or-initials primitive (`sm`/`lg`); `onError` fallback; no upload logic (S-085) |
| `ProfilePage.tsx`          | User account view; click-to-upload avatar via `POST /auth/me/avatar` (S-085)   |
| `SettingsPage.tsx`         | Settings + logout                                                              |
| `AIInsights.tsx`           | Merchant-facing AI summary panel                                               |
| `MerchantDashboard.tsx`    | Reviews + analytics + insights composite                                       |
| `MerchantNationalIdCard.tsx` | Merchant national ID (PAN/Aadhaar/Other); required before listing create (S-043) |
| `CollectQrCard.tsx`        | QR for `/collect/{id}` review wizard (S-040)                                   |
| `WhatsAppUpdateCard.tsx`   | `wa.me` QR to send shop details (S-050, mock; **not Accepted**)                |
| `WhatsAppDraftsPanel.tsx`  | Merchant read-only status (pending admin review / applied / discarded) for WhatsApp AI suggestions — apply/discard moved to admin (RBAC change shipped in **S-053, Accepted**; underlying draft source **S-052** still Testing) |
| `admin/AdminWhatsAppDraftsQueue.tsx` | Admin: global cross-business queue, editable AI suggestions, Approve/Reject (`/admin/whatsapp`, **S-053, Accepted**) |
| `BenchmarkCard.tsx`        | Category/city rating medians (S-038)                                           |
| `GooglePlacePicker.tsx`    | Search + Leaflet/OSM pins to link a Google Place ID (S-048)                    |
| `ExternalReviews.tsx`      | Public "Also reviewed on Google" sample; hidden when empty (S-048)             |


The API client lives in `[frontend/src/lib/api.ts](frontend/src/lib/api.ts)` and calls the backend directly via `NEXT_PUBLIC_API_URL` / `API_URL_INTERNAL` — there is no BFF or rewrite layer.

**File download pattern (S-033):** `dashboard.reviewsCsv()` is the first non-JSON API call — it can't route through the shared `apiFetch<T>()` JSON helper, so it does a plain authenticated `fetch()` and returns a `Blob`. Callers turn that into a download via `URL.createObjectURL` + a synthetic `<a download>` click (see `MerchantDashboard.tsx`'s `handleExportCsv`), not a direct link to the API URL (would drop the auth header).

**Status-aware error handling (S-082):** `apiFetch` throws `ApiError extends Error` (adds `.status`, the HTTP status code) instead of a plain `Error` on any non-2xx response reached from the server. Every existing `e instanceof Error ? e.message : "..."` call site keeps working unchanged (it's additive, not a breaking refactor); a caller that needs to branch by cause checks `e instanceof ApiError` first — a true network failure (fetch itself rejects — offline/DNS/CORS) is *not* an `ApiError` (no `Response` ever existed), so `instanceof ApiError` false + `instanceof Error` true distinguishes "reached the server" from "never reached the server". `AdminCategoryPanel.tsx`'s "Add category" error handling is the first adopter (409 duplicate vs. 401/403 auth vs. 5xx/network, each a distinct message) — other forms still use the older generic `e.message` pattern until they have a reason to adopt status-aware branching too.

**Avatar (S-085):** `ui/Avatar.tsx` is presentational only (photo if `avatar_url` is set, else initials from `full_name`; broken URLs fall back via `onError`). `Navbar` uses `size="sm"` inside the existing `/profile` link. `/profile` wraps `size="lg"` in a button that opens a hidden image file input; `auth.uploadAvatar()` applies immediately and dispatches `mh:user-updated` so `ClientLayout` refreshes the nav without a page reload. Not AI-analyzed content — no suggestion badge.

**`Badge` tone palette (S-083):** `Badge`'s `Tone` union now includes `info`/`brand` alongside the original `positive`/`negative`/`neutral`. The original three carry a good/bad/neutral *judgment* meaning (AI sentiment on `ReviewCard`, active/suspended account status) — `info`/`brand` are for judgment-neutral *classification* instead (e.g. `AdminUserPanel.tsx`'s role badge: `customer`→`neutral`, `merchant`→`info`, `admin`→`brand`), so a role never misreads as "this person is good/bad." Purely additive — no existing `Tone` value or caller changed.

### Design system (Figma)

The visual layer is mirrored in Figma as a token-driven design system, generated by reverse-engineering `frontend/src`. File: **MerchantHub AI — Design System**, key `X0XXhJiwW8SxFdMf39n2t3`.

**Authority split** — Figma leads for visual decisions (colour, spacing, type, component structure); code leads for behaviour (state, data fetching, routing). When the two disagree on a visual value, Figma wins and `tailwind.config.ts` is updated to match. Add the token in Figma first, then mirror the hex here.

#### Token architecture


| Collection   | Modes       | Contents                                                                                                                      |
| ------------ | ----------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `Primitives` | Value       | 36 raw ramps — `brand/50–900`, `gray/50–900`, red, green, yellow, base. Scoped `[]` so they never surface in property pickers |
| `Color`      | Light, Dark | 35 semantic tokens (`color/bg/*`, `color/text/*`, `color/border/*`), every one aliased to a primitive                         |
| `Spacing`    | Value       | `spacing/2xs`–`4xl` (2–64px), derived from the Tailwind utilities the app actually uses                                       |
| `Radius`     | Value       | `radius/sm` 4 · `md` 8 · `lg` 12 · `full`                                                                                     |
| `Typography` | Value       | `font-size/*` and `line-height/*` across the xs–4xl ramp                                                                      |


100 variables in total, plus 10 Inter text styles and 2 elevation styles matching `shadow-sm` / `shadow-md`. Every variable carries code syntax — semantic colours expose `var(--color-*)`, scales expose `theme(...)`.

The brand ramp was completed to 50–900 while building this. `border-brand-400` in `[AIInsights.tsx](frontend/src/components/AIInsights.tsx)` referenced a stop `tailwind.config.ts` never defined, so that blockquote border was silently rendering as no border.

**Dark mode is shipped in code (S-045, Accepted).** The `Color` collection's Light/Dark modes were the design intent; the working implementation (`next-themes`, class-based Tailwind dark mode, 5 semantic tokens, a swept ~65-file component pass) shipped ahead of a human pulling the real hex values out of Figma — the Color collection's 99 variables are local/unpublished, so Figma MCP tooling couldn't read them this session. Every dark-mode hex currently in code is a reasoned, contrast-checked, Material-3-grounded placeholder, not the canonical Figma value. See §14 for the follow-up.

### Theming (dark mode, S-045)

`darkMode: "class"` in `tailwind.config.ts` + the `next-themes` package (`ThemeProvider attribute="class" defaultTheme="system" enableSystem`, wired in `ClientLayout.tsx`) drive theme resolution — an inline pre-hydration script sets `.dark` on `<html>` before React hydrates, so there's no flash of the wrong theme on first paint, and an explicit choice made via the navbar's `ThemeToggle.tsx` persists to `localStorage` and overrides the OS preference from then on.

Five semantic Tailwind color tokens, each backed by a CSS custom property that flips value inside a `.dark { }` block in `globals.css`, replace the old grey-scale utility classes:

| Token | Replaces | Role |
| ----- | -------- | ---- |
| `bg-surface` | `bg-gray-50` | page / section background |
| `bg-surface-raised` | `bg-white` | cards, headers, panels, modals |
| `text-ink` | `text-gray-900` / `text-slate-900` | primary text |
| `text-muted` | `text-gray-500/600/700/800` | secondary/tertiary text |
| `border-border` | `border-gray-200` | card/divider borders |

**Convention going forward:** new components should reach for these 5 tokens instead of hardcoded `bg-white` / `text-gray-*` grey utilities, so they theme correctly for free. Tone-carrying colors (sentiment badges, star-rating fill, hover chrome) intentionally stay as explicit `dark:` pairs rather than folding into a generic token, since they carry meaning beyond surface/text role. `Charts.tsx` (Recharts) is the one place tokens can't reach — its SVG props read a `CHART_COLORS` light/dark map keyed off `useTheme().resolvedTheme` instead.

### Review-list interactivity (S-046)

`ReviewsList.tsx` (on `/businesses/[slug]`) reuses `FilterPanel`'s sort-`Select` + min-rating-pill *pattern* client-side, rather than the `FilterPanel` component itself — `FilterPanel` is a URL-param-driven server form built for `/search`'s full-page navigation model, while `ReviewsList` sorts/filters an already-fetched in-memory `Review[]` with a `useMemo` filter-then-sort derivation and no page reload. Sort (Newest / Oldest / Highest / Lowest) and a minimum-star-rating pill row (`All` / `3+` / `4+` / `5`) combine; a zero-match combination renders a distinct "No reviews match these filters" state with a Clear-filters affordance, kept visually separate from the existing "no reviews yet" empty state. `ReviewCard.tsx` also gained `line-clamp-3` truncation with a Read more/less toggle for long review bodies (280-char heuristic), and now wires its photo thumbnails through `PhotoGallery`'s existing lightbox instead of a raw `<img>` grid.

`ui/RatingWidget.tsx` gained half-star rendering (a width-clipped two-glyph unicode overlay) for its **readonly** display mode only — every readonly call site (`BusinessCard`, business profile header, `AllBusinessesQueue`, `ReviewVoices`, `ReviewCard`) picks this up for free. The interactive rating *picker* used on the review-submission form is untouched by construction — it never enters the half-star code path, whole-star selection only, same as before this slice.

#### Components and templates

18 components across 69 variants, one page per family:


| Figma page | Components                                                                                                  |
| ---------- | ----------------------------------------------------------------------------------------------------------- |
| Primitives | `Button`, `Input`, `Select`, `Badge`, `StatCard`, `ui/RatingWidget` (code in `frontend/src/components/ui/`) |
| Rating     | `RatingWidget` (legacy path + `ui/` copy)                                                                   |
| Cards      | `BusinessCard`, `ReviewCard`, `StatCard`                                                                    |
| Navigation | `Navbar` (4 role states), `Footer`, `NavItem`, `DashboardNav`                                               |
| Search     | `SearchBar`, `FilterPanel`                                                                                  |
| AI & Data  | `AIInsights`, `Chart`                                                                                       |
| Media      | `PhotoGallery`, `Lightbox`                                                                                  |


All nine routes are assembled as 1440px templates built purely from those instances. There are no detached layers and no hardcoded fills or strokes anywhere in the library — every visual property binds to a variable, so changing a token reflows the system.

#### Code Connect

`*.figma.tsx` files sit next to each component and map Figma nodes to the real React source, so Dev Mode shows the component rather than generated CSS.

```bash
cd frontend && npm install && npx figma connect publish
```

Config lives in `[frontend/figma.config.json](frontend/figma.config.json)`. These files are excluded from the app typecheck in `tsconfig.json` — they are tooling, not shipped code.

#### Deliberate deviations from code


| Figma                                                | Code                          | Why                                                                      |
| ---------------------------------------------------- | ----------------------------- | ------------------------------------------------------------------------ |
| SearchBar radius `radius/sm` (4px)                   | `rounded-lg` (8px)            | Every other input uses `rounded`; unified rather than tokenise a one-off |
| Neutral `Badge` text `color/text/primary` (gray-900) | `text-gray-800`               | A one-step difference does not earn its own token                        |
| Hero gradient stops are literal hex                  | `from-brand-700 to-brand-900` | Figma cannot bind variables to gradient stops                            |


---



## 9. Security

**2026-08-17 audit:** a full backend/frontend/infra security pass was done and its findings —
what was fixed, what was deferred and why, and how each fix was verified — are written up in
**[SECURITY_AUDIT.md](SECURITY_AUDIT.md)**. The tables below already reflect the fixes; the
audit doc is the detailed record.

### Authentication chain

Every protected request passes through this, in `[dependencies.py](backend/app/dependencies.py)`:

```mermaid
flowchart TD
    R[Request] --> H["HTTPBearer(auto_error=False)"]
    H -->|no credentials| E1[401 Not authenticated]
    H -->|token| D["decode_token() — verify HS256 signature + exp"]
    D -->|JWTError| E2[401 Invalid token]
    D --> T{"claim type == 'access'?"}
    T -->|no| E3[401 Invalid token type]
    T -->|yes| U["Load user by sub (UUID)"]
    U -->|missing or is_active false| E4[401 User not found or inactive]
    U --> RB{"require_roles(...)?"}
    RB -->|role not allowed| E5[403 Insufficient permissions]
    RB -->|allowed| O[Ownership check if resource-scoped]
    O --> OK[Handler runs]
```



`auto_error=False` is what makes `get_optional_user()` possible — public endpoints can personalise for a logged-in caller without rejecting anonymous ones.

### Token design

Implemented in `[core/security.py](backend/app/core/security.py)`, configured in `[config.py](backend/app/config.py)`.


| Property          | Value                                                                            | Why                                                                |
| ----------------- | -------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| Algorithm         | HS256 (symmetric)                                                                | One service signs and verifies; no key distribution problem        |
| Access token TTL  | 30 minutes                                                                       | Short enough that a leaked token expires quickly                   |
| Refresh token TTL | 7 days                                                                           | Keeps users logged in without long-lived access tokens             |
| Claims            | `sub` (user UUID), `exp`, `type`, optional `purpose` / `role`                    | —                                                                  |
| `type` claim      | `"access"`                                                                       | `"refresh"`                                                        |
| Password MFA      | Mandatory TOTP (authenticator app) for email/password login; Google OAuth exempt | Secrets Fernet-encrypted at rest; never returned on `UserResponse` |




### Password storage

`CryptContext(schemes=["bcrypt"], deprecated="auto")` — bcrypt is salted and deliberately slow, which is what makes offline brute-forcing of a leaked table impractical. `deprecated="auto"` means that if a stronger scheme is added to `schemes` later, passlib marks bcrypt hashes as outdated and they can be transparently re-hashed on next successful login — algorithm rotation without a forced password reset.

### Password reset tokens (S-035 / ADR-007)

`POST /auth/forgot-password` never confirms whether an email is registered — known and
unknown addresses get the same generic 200 message. A high-entropy token is generated,
stored in Redis as `auth:reset:{sha256(token)}` → `user_id` with a **1-hour TTL**, and
the **raw** token is only ever placed in the outbound email link — never logged, never
persisted in Postgres. `POST /auth/reset-password` deletes the key on use (single-use)
and returns a generic `400` for missing, expired, or already-used tokens alike.

This is the one place in the app that is **fail-closed** rather than fail-open: unlike
login lockout (`is_login_locked` / `record_login_failure`, which quietly no-ops if Redis
is down), a Redis outage on forgot/reset returns **503**. The reasoning: silently
skipping the reset would tell a user we emailed them a link that was never generated,
and accepting a password change with no stored challenge at all would be worse than
rejecting the request. `forgot-password` checks Redis reachability with a `PING`
*before* the account lookup, so the 503 path itself does not distinguish known accounts
from unknown ones (only whether Redis is up).

Google-only accounts (`hashed_password is None`) never receive a reset email and are not
converted to password accounts by this flow — there's no password to reset, and forgot
still returns the same generic 200. A successful reset does not revoke outstanding access
tokens (≤ 30 min TTL) or disable TOTP; both are accepted v1 trade-offs (ADR-007).

### Authorisation — two independent layers

Confusing these is the classic RBAC bug, so they are separate mechanisms:

**1. Role check** — `require_roles(*roles)` returns a dependency that 403s if `user.role` isn't in the allowed set.


| Endpoint group                                            | customer | merchant         | admin  |
| --------------------------------------------------------- | -------- | ---------------- | ------ |
| Register / login / refresh                                | public   | public           | public |
| Browse, search, view business, list reviews               | public   | public           | public |
| List businesses with non-approved status_filter           | —        | —                | ✅      |
| Create / edit / delete own review, like, report           | ✅        | ✅                | ✅      |
| Upload photo attached to own review                       | ✅        | ✅                | ✅      |
| Upload photo to a business gallery/logo/storefront        | —        | ✅ (own business) | ✅      |
| Create / update business                                  | —        | ✅                | ✅      |
| Reply to review                                           | —        | ✅ (own business) | ✅      |
| Merchant dashboard, AI insights                           | —        | ✅ (own business) | ✅      |
| Google review search / link / sync                        | —        | ✅ (own business) | ✅      |
| Approve / suspend business, create category API           | —        | —                | ✅      |
| Moderate review (hide/restore/remove)                     | —        | —                | ✅      |
| Platform counts (`GET .../admin/platform`)                | —        | —                | ✅      |
| User suspend/reactivate, category create, platform series | —        | —                | ✅      |
| Delete photo                                              | —        | ✅ (own)          | ✅      |


**2. Ownership check** — being a merchant is not the same as being *this business's* merchant. `get_merchant_for_user()` and `get_owned_business()` re-query with `Business.merchant_id == merchant.id` in the `WHERE` clause, returning **404** (not 403) so the existence of another merchant's business isn't leaked.

Author-scoped actions (edit/delete review) follow the same principle at the router level.

### Other controls in place


| Control             | Implementation                                                                                                                                                                                                                                                                             |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| CORS                | `CORSMiddleware` with an explicit origin allowlist from `cors_origin_list`, `allow_credentials=True` ([main.py](backend/app/main.py))                                                                                                                                                      |
| Security headers    | `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy` on FastAPI and Next; `Strict-Transport-Security` only when the request is HTTPS / `X-Forwarded-Proto: https` (local Compose HTTP is unchanged). Next also sends a `Content-Security-Policy` scoped to `self` + the API origin + `accounts.google.com` (Google Sign-In) + the OSM tile/Nominatim hosts Leaflet needs ([next.config.js](frontend/next.config.js)). |
| Input validation    | Pydantic request schemas on every endpoint — malformed bodies are rejected with 422 before any handler runs                                                                                                                                                                                |
| Password policy     | Register: min 12 characters, at least one letter and one digit (`UserRegister`). Login does not re-validate complexity.                                                                                                                                                                    |
| Rate limiting       | `slowapi`: `/auth/login` 10/min, `/auth/register` 5/min, `/auth/mfa/totp/verify` + `/auth/mfa/totp/confirm` 5/min, `/auth/refresh` 10/min — all per IP                                                                                                                                     |
| Account lockout     | After 5 failed **password** logins for an email, Redis lock 15 minutes (`auth:fail:` / `auth:lock:`). Fail-open if Redis is down (same idea as the token blocklist). Google sign-in is not counted.                                                                                        |
| Refresh rotation    | `POST /auth/refresh` blocklists the presented refresh `jti` before issuing a new pair                                                                                                                                                                                                      |
| SQL injection       | SQLAlchemy parameterised queries throughout; no string-built SQL                                                                                                                                                                                                                           |
| Slug generation     | `slugify()` strips non-word characters and appends 8 random hex chars — prevents slug collision and enumeration by name                                                                                                                                                                    |
| Upload paths        | Filenames are replaced with a server-generated `uuid4()`; the client-supplied name is used only for its extension, so path traversal via `filename` is not possible ([storage](backend/app/services/storage/__init__.py))                                                                  |
| Upload MIME/size    | Photo upload allows image JPEG/PNG/WebP/GIF only and caps at 5 MB ([photos.py](backend/app/routers/photos.py))                                                                                                                                                                             |
| Audit trail         | Admin approve/suspend/moderate actions write `audit_logs` rows, including user suspend/reactivate (`entity_type=user`, distinct from business suspend) (S-034)                                                                                                                             |
| National ID PII     | PAN / Aadhaar / Other on `users`. Merchant required before listing create. Admin lists **mask** the number. Not UIDAI/GSTN verified (S-043)                                                                                                                                               |
| Logout UX           | Client `performLogout` clears tokens, hard-navigates; `RequireAuth` / profile / settings re-check on bfcache `pageshow`                                                                                                                                                                    |
| TOTP MFA            | Password login requires authenticator app; Google/Gmail path does not                                                                                                                                                                                                                      |
| Password reset      | `/auth/forgot-password` + `/auth/reset-password` 5/minute per IP each; hashed single-use Redis token, 1-hour TTL, fail-closed 503 on Redis outage — see below                                                                                                                              |
| Transactional email | `EmailProvider` port (`mock`/`resend`) — best-effort, never blocks review create or business approve on a send failure; v1 templates carry no AI-generated text (S-035)                                                                                                                    |
| Featured payments   | `PaymentProvider` port (`mock`/`razorpay`); hosted Checkout so PAN never hits our API; webhook HMAC; mock-complete DEBUG-only (S-036)                                                                                                                                                      |




### Known weaknesses — read before deploying

These are real and currently unmitigated. They are acceptable for a local demo, not for a public deployment.


| #   | Weakness                                                                                     | Impact                                                      | Fix                                                                                                                                                                                                            |
| --- | -------------------------------------------------------------------------------------------- | ----------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Tokens stored in `localStorage`                                                              | Any XSS can exfiltrate both tokens                          | Move to `httpOnly` `Secure` `SameSite` cookies — **S-026 / ADR-004**, not this hardening batch (needs a dual-auth story; mobile stays Bearer)                                                                  |
| 2   | ✅ Fixed — `secret_key` had a hardcoded fallback in `[config.py](backend/app/config.py)`      | If unset in prod, anyone could forge a valid admin JWT      | Now a required field with no default — startup fails fast if `SECRET_KEY` is unset. Every documented workflow (Compose, `.env.example`, both CI workflows, the Railway guide below) already sets it explicitly |
| 3   | ✅ Fixed — rate limiting on `/auth/login` and `/auth/register`                                | Credential stuffing / bcrypt CPU exhaustion                 | `slowapi` 10/min login, 5/min register per IP; plus per-email lockout (5 failures / 15 min) when Redis is up                                                                                                   |
| 4   | ✅ Fixed — `debug: bool = True` default, and it wasn't even wired to FastAPI's own debug mode | Verbose tracebacks in HTTP responses can leak internals     | Default is now `False`; `main.py` passes it to `FastAPI(debug=...)` so the setting actually gates traceback responses, not just SQL echo logging. Compose/`.env.example` opt local dev back in explicitly      |
| 5   | ✅ Fixed — MIME/size validation on photo upload                                               | Arbitrary file content and size accepted into `/uploads`    | Image content types only; 5 MB cap in `[photos.py](backend/app/routers/photos.py)`                                                                                                                             |
| 6   | `/uploads` served as unauthenticated static files                                            | Any uploaded photo is world-readable to anyone with the URL | Acceptable for public gallery photos; use signed URLs if private media is ever added                                                                                                                           |
| 7   | ✅ Fixed — `POST /photos/upload` had no ownership check on the `business_id` path             | Any authenticated customer could upload/overwrite gallery, logo, or storefront photos on a business they don't own (IDOR) | Now requires `MERCHANT` (owning that business) or `ADMIN`, matching the check `DELETE /photos/{photo_id}` already had ([photos.py](backend/app/routers/photos.py)); regression tests in `backend/tests/test_photos.py` |
| 8   | ✅ Fixed — no rate limit on `/auth/mfa/totp/verify`, `/auth/mfa/totp/confirm`, `/auth/refresh` | A held `mfa_token` let an attacker brute-force the 6-digit TOTP code unthrottled          | Same `slowapi` limiter as login/register now applied to all three ([auth.py](backend/app/routers/auth.py))                                                                                                     |




### Production hardening checklist

- [x] Strong `SECRET_KEY` from env, no default
- [ ] HTTPS everywhere
- [ ] `httpOnly` cookies for tokens (upgrade from `localStorage`) — **S-026**, not started
- [x] Rate limiting on auth endpoints
- [x] Per-email lockout on failed password login (Redis, fail-open)
- [x] Refresh-token `jti` rotation
- [x] Register password policy (min 12 + letter + digit)
- [x] Baseline security headers + CSP (`self` + API origin + Google Sign-In + OSM tiles/Nominatim)
- [x] Dependabot for `backend/` pip, `frontend/` npm, and GitHub Actions
- [ ] Database SSL enabled (Neon does this by default)
- [x] `debug=False`
- [x] Upload MIME + size validation
- [ ] `CORS_ORIGINS` set to the real frontend origin only
- [x] Docker images run as a non-root user (`backend/Dockerfile`, `frontend/Dockerfile`)
- [x] Compose Postgres/Redis ports bound to `127.0.0.1` only, not all interfaces
- [x] CI workflows run with explicit least-privilege `permissions: contents: read` and an audit step (`pip-audit` / `npm audit`)

---



## 10. Deployment

> Rehosting the same app under a second geography/domain with fully isolated data? See
> [`docs/research/multi-geography-rehosting.md`](docs/research/multi-geography-rehosting.md) —
> reuses this section's Railway pattern as a second, independent deployment.



### Option A — Local (Docker Compose)

Prerequisites: Docker Desktop, Git. See [§1 Quick start](#1-quick-start). Four services: `frontend` (3000), `backend` (8000), `postgres` (5432), `redis` (6379).

### Hosted options compared

For low-traffic MVP / portfolio use:


|                        | **Option C — Vercel + Render + Neon + Upstash**                      | **Option D — Railway (all-in-one)**                                            |
| ---------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Frontend               | Vercel Hobby — $0                                                    | included                                                                       |
| Backend                | Render free — $0 (spins down after 15 min idle, ~30–60 s cold start) | included                                                                       |
| Postgres               | Neon free — $0 (permanent, scales to zero when idle)                 | included                                                                       |
| Redis                  | Upstash free — $0, or skip entirely (app no-ops without it)          | included                                                                       |
| Realistic monthly cost | **$0/mo** accepting cold starts, or ~$7/mo for always-on backend     | **~$5–15/mo** always-on (the Hobby plan's $5 credit is consumed by 24/7 usage) |
| Setup effort           | 4 dashboards to wire together                                        | 1 dashboard, deploys from the existing Dockerfiles                             |




### Option C — Vercel + Render + Neon + Upstash

```mermaid
flowchart LR
    DEV[Local: Docker Compose] --> GH[GitHub repo]
    GH --> V[Vercel — Next.js frontend]
    GH --> R[Render / Railway — FastAPI backend]
    R --> N[Neon PostgreSQL]
    R --> U[Upstash Redis — optional]
    V -->|NEXT_PUBLIC_API_URL| R
```



**1. Database — Neon.** Create an account at [neon.tech](https://neon.tech), create project `merchanthub-ai`, copy the connection string (use the **pooled** URL for serverless), and convert it to async form: `postgresql+asyncpg://user:pass@host/db?sslmode=require`.

**2. Backend — Render.** New Web Service → connect the GitHub repo → root directory `backend` → build `pip install -r requirements.txt` → start `uvicorn app.main:app --host 0.0.0.0 --port $PORT`. Environment:


| Variable           | Value                                 |
| ------------------ | ------------------------------------- |
| `DATABASE_URL`     | Neon connection string (asyncpg form) |
| `REDIS_URL`        | Upstash Redis URL (optional)          |
| `SECRET_KEY`       | Random 64-char string                 |
| `AI_PROVIDER`      | `mock` or `openai`                    |
| `AI_API_KEY`       | Your LLM key                          |
| `CORS_ORIGINS`     | `https://your-app.vercel.app`         |
| `STORAGE_PROVIDER` | `local` (or `s3` for production)      |


**3. Redis — Upstash** (optional). Create a free Redis at [upstash.com](https://upstash.com), copy `REDIS_URL` into the backend env.

**4. Frontend — Vercel.** Import the repo at [vercel.com](https://vercel.com), root directory `frontend`, framework preset Next.js, set `NEXT_PUBLIC_API_URL=https://your-backend.onrender.com`, deploy.

**5. Verify:** frontend loads · `/health` returns 200 · login works · `/docs` reachable · CORS allows the frontend origin.

> Not yet built out in this repo — no Render or Vercel config files exist.



### Option D — Railway (chosen; partially wired up)

`[backend/railway.json](backend/railway.json)` and `[frontend/railway.json](frontend/railway.json)` are already committed: `builder: DOCKERFILE` (reusing the existing verified Dockerfiles rather than Railway's auto-detecting Railpack builder), `sleepApplication: false`, single replica, `ams` region, restart-on-failure.

The backend's `railway.json` overrides the container start command to:

```
sh -c "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"
```

This keeps deploys fast: migrate + API only. Demo seed is **not** on the boot path (see `SEED_MODE` / `SEED_VERSION` in §15).

1. Runs `alembic upgrade head` so schema migrations apply before the API.
2. The Dockerfile's own `CMD` hardcodes port 8000 in exec form, which cannot expand Railway's injected `$PORT`. The `sh -c` override can.
3. Seed runs only when invoked explicitly (Railway shell / one-shot) with `SEED_MODE=force` (or `if_outdated` / `if_empty`). Local Compose still calls `scripts/seed.py` on start with `SEED_MODE=if_outdated`.
4. After a first deploy to an empty DB, run seed once manually so demo accounts and listings exist:

```bash
PYTHONPATH=/app SEED_MODE=force python scripts/seed.py
```

The frontend's `Dockerfile` now bakes a real production build into the image (`RUN npm run build`, with `NEXT_PUBLIC_API_URL` / `NEXT_PUBLIC_GOOGLE_CLIENT_ID` passed in as build `ARG`s — Railway auto-forwards matching service Variables as build args for Dockerfile builds). The Dockerfile's own `CMD` still runs `npm run dev` so `docker-compose.yml` keeps local hot-reload unchanged; `frontend/railway.json` overrides the deploy start command to `npm run start` (`next start`, which reads Railway's injected `$PORT` the same way `next dev` does). Previously the frontend had no start-command override at all, so Railway ran the dev server — including the dev-tools overlay — in production.

**Remaining steps (require a Railway account):**

1. New Project → Deploy from GitHub repo.
2. `+ New → Database → PostgreSQL` and `+ New → Database → Redis` in the same project.
3. `+ New → GitHub Repo` for the backend: root directory `backend`, config-as-code path `backend/railway.json`.
4. Same for the frontend: root directory `frontend`, config path `frontend/railway.json`.
5. Settings → Networking → Generate Domain for both services.
6. Backend → Variables:
  ```
   DATABASE_URL=postgresql+asyncpg://${{Postgres.PGUSER}}:${{Postgres.PGPASSWORD}}@${{Postgres.PGHOST}}:${{Postgres.PGPORT}}/${{Postgres.PGDATABASE}}
   REDIS_URL=${{Redis.REDIS_URL}}
   SECRET_KEY=<openssl rand -hex 32>
   AI_PROVIDER=mock
   STORAGE_PROVIDER=local
   STORAGE_LOCAL_PATH=/app/uploads
   CORS_ORIGINS=https://${{frontend.RAILWAY_PUBLIC_DOMAIN}}
   GOOGLE_CLIENT_ID=<from Google Cloud Console>
  ```
   Railway's Postgres plugin exposes `DATABASE_URL` as plain `postgresql://`, which does **not** match this codebase's required `postgresql+asyncpg://` ([config.py](backend/app/config.py)) — hence composing it from the individual `PG`* variables instead of referencing `DATABASE_URL` directly.
7. Frontend → Variables:
  ```
   NEXT_PUBLIC_API_URL=https://${{backend.RAILWAY_PUBLIC_DOMAIN}}
   API_URL_INTERNAL=https://${{backend.RAILWAY_PUBLIC_DOMAIN}}
   NEXT_PUBLIC_GOOGLE_MAPS_KEY=placeholder
   NEXT_PUBLIC_GOOGLE_CLIENT_ID=<same client ID as the backend's GOOGLE_CLIENT_ID>
  ```
   `NEXT_PUBLIC_API_URL` is baked into the client bundle at **build** time (must be set before a frontend rebuild). `API_URL_INTERNAL` is read at **runtime** by Server Components (`[frontend/src/lib/api.ts](frontend/src/lib/api.ts)`) so SSR does not fall back to `http://localhost:8000` inside the Railway container. Use the backend public HTTPS URL (or Railway private networking URL if you enable it). If Featured businesses stays empty after seed, open `https://<backend>/api/v1/businesses/cities` in a browser — non-empty JSON means seed is fine and the frontend Variables (then a frontend redeploy) are the fix. A `502` from that URL means the backend service itself is down, not the seed.
8. Redeploy both services (backend first so migrations apply, then frontend so `NEXT_PUBLIC_API_URL` is baked in). On a fresh Postgres, run seed once with `SEED_MODE=force` (see above).

**Caveats:**

- `STORAGE_LOCAL_PATH=/app/uploads` is ephemeral container disk — uploaded review photos are lost on every redeploy. Fine for prototyping, not for a persistent demo.
- `sleepApplication: false` keeps everything running 24/7, which burns the Hobby plan's $5/mo credit fastest. Set it to `true` in both `railway.json` files for a prototype you check occasionally.
- The `${{Postgres.*}}` / `${{Redis.*}}` / `${{frontend.*}}` / `${{backend.*}}` reference syntax assumes those are the literal service names Railway assigns — adjust if yours differ.



### File storage in production

On Render/Railway the disk is ephemeral. `S3StorageProvider` (boto3) is implemented — set `STORAGE_PROVIDER=s3`, `STORAGE_S3_BUCKET`, and `STORAGE_S3_REGION`, and supply AWS credentials the way boto3 expects (env vars, IAM role, or `~/.aws/credentials` — not a MerchantHub setting). `STORAGE_S3_ENDPOINT_URL` targets an S3-compatible service (Cloudflare R2, MinIO) instead; `STORAGE_S3_PUBLIC_BASE_URL` fronts the bucket with a CDN/custom domain. **Azure Blob** (`AzureBlobStorageProvider`) remains a stub.

### Maps (OpenStreetMap)

Search uses **Leaflet + OSM tiles** — no Google Maps API key is required. Legacy `GOOGLE_MAPS_API_KEY` / `NEXT_PUBLIC_GOOGLE_MAPS_KEY` env vars remain in config but are unused by the OSM path. Merchant listings no longer call Nominatim (S-084).

### Google sign-in

ID-token flow via Google Identity Services — no client secret, no redirect route. In [Google Cloud Console](https://console.cloud.google.com/apis/credentials): create an **OAuth client ID** of type **Web application**, and add both your local (`http://localhost:3000`) and deployed frontend origins under **Authorized JavaScript origins** (no path, no trailing slash — Google matches the origin exactly). Set the resulting client ID as `GOOGLE_CLIENT_ID` on the backend and `NEXT_PUBLIC_GOOGLE_CLIENT_ID` on the frontend — same value, both places. `POST /api/v1/auth/google` verifies the token's signature, audience, and issuer server-side before ever trusting it.

### CI/CD

GitHub Actions **defines** `pytest` (`[backend-tests.yml](.github/workflows/backend-tests.yml)`, throwaway Postgres/Redis) and `npm test` (`[frontend-tests.yml](.github/workflows/frontend-tests.yml)`). **As of 2026-08-15 those jobs are `workflow_dispatch` only** (PR/push triggers commented out). Playwright is a **separate** dispatch-only workflow ([`web-e2e.yml`](.github/workflows/web-e2e.yml)) — Compose + Chromium, traces as downloadable artifacts; not on push/PR and not a deploy step. Auto-deploy of `main` to Railway/Vercel on green CI is still a recommended next step, not wired up. See [§11](#11-testing).

---



## 11. Testing

This section is the **evaluation model** for the web product: what is proven today, what is deliberately mocked, how a new slice stays covered, and the second (browser) view. Mobile emulator CI is separate (`ANDROID_APP_STRATEGY.md`); this §11 is **web-first**.

Architecture: [ADR-009](docs/agents/adrs/ADR-009-web-functional-e2e.md) (Accepted). Oracles: [TP-S-010](docs/agents/test-plans/TP-S-010-e2e-flow-verification.md). Slice **S-010**: harness + role journeys in `backend/tests/e2e/` (opt-in `E2E=1`); GitHub run is manual [`web-e2e.yml`](.github/workflows/web-e2e.yml).

### What “done” means here

The product is **working in place** when the §2 loop can be exercised on Compose with mock vendors: register/login → search → review (+ AI suggestion) → merchant dashboard/reply → admin approve/moderate → optional featured mock checkout and password-reset **log** (not a real inbox).

That is **not** the same as: live Resend, live Razorpay, live S3/CDN, Playwright on every PR, or GitHub branch protection. Live vendors and required checks stay ops; Playwright stays a **manual** second view.

### Pyramid — what we actually run


| Layer | Tool | What it proves | Where it lives | CI today |
| ----- | ---- | -------------- | -------------- | -------- |
| 1. Adapter / unit | pytest | Mock AI/email/payments/storage contracts, helpers, RBAC matrices, JWT claims | `backend/tests/test_*.py` (~185 cases, ~39 files) | Workflow exists; **PR/push triggers are commented out** (manual `workflow_dispatch` only) |
| 2. API integration | pytest + `httpx.AsyncClient` + `ASGITransport` against `app.main:app` | HTTP + DB + Redis for routers that use the real app | Same folder; needs Postgres (Compose or CI service containers) | Same backend workflow (throwaway Postgres/Redis — never Railway) |
| 3. UI component | Jest + React Testing Library | Visible behaviour of pages/components with mocked `api.ts` | `frontend/src/**/__tests__/` (~29 files; ~102 cases as of TR-S-037–040, growing) | Same: dispatch-only |
| 4. Slice AC matrix | Tester report | Every numbered AC mapped to A (automated) or M (manual) | `docs/agents/test-plans/`, `test-reports/` | Not a runner — a gate in §13 |
| 5. Browser functional + technical | Playwright (Python) + Trace Viewer | Real Chromium against a **spun-up** frontend+API; UI `expect()` **and** API schema/status oracles | `backend/tests/e2e/` — smoke + role pack; opt-in `E2E=1` | Manual [`web-e2e.yml`](.github/workflows/web-e2e.yml) (`workflow_dispatch` only). Download `playwright-traces`. Not on push/PR, not a deploy step |
| 6. Hosted staging smoke | Same Playwright against a staging URL | Deployed Next.js + API with mock vendors | Not wired (Railway is production-shaped; no dedicated staging job) | Not wired |

```mermaid
flowchart TB
    subgraph cheap [Every change — cheap]
        U[pytest unit + adapter mocks]
        A[pytest ASGI + throwaway Postgres]
        J[Jest RTL]
    end
    subgraph s010 [S-010 — manual second view]
        P[Playwright role journeys]
        T[Trace Viewer zips]
        G[web-e2e.yml dispatch artifact]
    end
    U --> A --> J
    J -.->|does not replace| P
    P --> T
    G --> P
```

Layers 1–3 catch “easy fix broke a helper or a button.” They **cannot** catch: SSR home/search/detail wiring, MFA click-through, cookie/localStorage session, featured mock checkout in the browser, or “admin approve then merchant dashboard updates.” That is why S-010 is a second view, not more Jest.

### How we evaluate a slice today (and as the repo grows)

Do not invent a second checklist file. Use this sequence every time:

1. **Product** — numbered Given/When/Then on the slice (`docs/agents/slices/`). If an AC is unnumbered, Tester cannot map it.
2. **Architecture** — API/RBAC/data/cache on the same slice; ADR only if a vendor or auth/schema pattern changes.
3. **Builder** — code + this README (§6/§7/§12/§14 as applicable).
4. **Tester** — `TP-S-XXX` then `TR-S-XXX` with an AC coverage matrix. **Every AC** → pytest and/or RTL **or** an explicit Manual ID.
5. **Regression pack** — `cd backend && pytest` and `cd frontend && npm test` with `AI_PROVIDER=mock` (and email/payments/storage defaults). This is the pack that must stay green when someone “just fixes” a dashboard tile.
6. **Browser layer (S-010)** — local: Compose up, then `E2E=1 pytest tests/e2e`. GitHub: Actions → **Web e2e (Playwright)** → Run workflow → download `playwright-traces`. Not after every fix. A test with no `expect()` is a recording, not a test.

If the change is a **tiny fix** (copy, CSS, one handler): still run layers 1–3 locally. If it touches auth, payments, review create, or SSR data fetching: that is when you need layer 5, even if Jest is green.

**Growth rule:** new user-facing web capability → new or extended Playwright flow in TP-S-010 **plus** a §12 parity row. New port/vendor → adapter tests, not a live key in CI. New AC → a named test, not “covered by the old dashboard file.”

### Mocked vendors are in-scope functional behaviour

Treat mocks as **the staging truth** until keys exist. Assertions belong on the port, not the SaaS.


| Capability | Mock behaviour to assert | Do not assert in CI |
| ---------- | ------------------------ | ------------------- |
| AI | `AI_PROVIDER=mock` writes `ai_analyses`, sentiment ∈ {positive,neutral,negative}, UI says **suggestion** | Live LLM quality / cost |
| Email | `EMAIL_PROVIDER=mock` logs template + to; reset still needs Redis (fail-closed) | Resend delivery, spam |
| Payments | `PAYMENTS_PROVIDER=mock` + DEBUG `mock/complete` (or signed mock webhook) activates a 7-day placement | Live Razorpay settlement |
| Photos / CDN | `STORAGE_PROVIDER=local`; S3 adapter unit-tested; optional public base URL for a CDN in front of S3 | Azure Blob (stub), Cloudinary account |

### What is implemented vs what must still be built (web evaluation)


| Need | Status |
| ---- | ------ |
| Core loop on Compose (roles, reviews, AI mock, admin) | **In place** — §14 success criteria 1–6 |
| pytest + RTL regression pack | **In place and growing** — still not every router/page |
| Isolated disposable DB per test process | **Partial** — CI has throwaway Postgres; local pytest often assumes a reachable DB; no fully hermetic fixture story |
| Slice AC → test reports | **In place** for Accepted slices; quality varies |
| Playwright harness + Compose smoke (dual oracle) | **In place** (`backend/tests/e2e/`, opt-in `E2E=1`) |
| Playwright role journeys (anonymous / customer / merchant / admin + RBAC/JWT) | **In place** (opt-in `E2E=1`); needs Compose + seed for admin/listings |
| Playwright Trace Viewer as the inspection UI | **In place** (gitignored `test-results/*.zip`; GHA artifact `playwright-traces`); not Cypress |
| Manual Compose e2e on GitHub (`web-e2e.yml`) | **In place** — `workflow_dispatch` only; traces + logs as artifacts. Not a merge or deploy gate |
| Hosted staging (Railway) that runs the same Playwright | **Not built** — Compose on the runner is the stand-in |
| Branch protection requiring green CI | **Not set** (known gap) |
| Live Resend / Razorpay / S3-CDN | **Optional later** — adapters exist |
| Azure storage | **Stub** |
| Structured request logs / APM | **Not built** |

### How to run (today)

```bash
# Always mock AI (and keep Compose defaults for email/payments/storage)
export AI_PROVIDER=mock

cd backend && pip install -r requirements.txt && pytest
cd frontend && npm install && npm test
```

ASGI/DB cases need PostgreSQL (Docker Compose backend + Postgres, or the CI service containers). Redis is required for password-reset tests (fail-closed).

**Playwright (opt-in; Compose must already be up):**

```bash
docker compose up --build   # frontend :3000, API :8000, mock vendors
cd backend && pip install -r requirements.txt && playwright install chromium
E2E=1 FRONTEND_URL=http://localhost:3000 API_URL=http://localhost:8000/api/v1 \
  pytest tests/e2e -v
# Artifacts: tests/e2e/test-results/*.zip → Playwright Trace Viewer
# Default `pytest` skips these tests (no browser required).
# PowerShell: $env:E2E=1; pytest tests/e2e -v
```

**GitHub (manual):** Actions → **Web e2e (Playwright)** → Run workflow. The job starts Compose, runs the same `E2E=1 pytest tests/e2e`, and always uploads artifacts (`playwright-traces`, pytest log, Compose logs; 14-day retention). Download the zip and run `playwright show-trace <test-name>.zip`. This is not tied to push, pull request, or deploy.

A hosted staging URL with the same mock vendors is optional later; point `FRONTEND_URL` / `API_URL` at that stack if it exists.

### Why Playwright (not another UI test product)

The “second view” is **Playwright + Trace Viewer** (and Playwright UI mode locally): step-by-step screenshots, DOM snapshots, and network. TP-S-010 chose **Python** Playwright so the technical oracle can `model_validate` the same Pydantic schemas the API already ships — one contract, not a parallel JSON schema in Cypress. Cypress/Selenium are rejected for this repo: they would duplicate the pytest toolchain and not reuse `backend/app/schemas`.

SSR caveat (must stay in the e2e design): Home, Search, and Business detail fetch on the **Next.js server**, so the browser network log will not show `GET /api/v1/businesses`. Those steps use a parallel `APIRequestContext` call. Client pages (`/login`, dashboard, admin, collect, review form) are browser-visible.

### CI honesty

README §10 still describes pytest/Jest on every PR. **Current YAML:** `backend-tests.yml` and `frontend-tests.yml` are `workflow_dispatch` only (PR/push commented as a POC). Playwright is a **third** workflow, [`web-e2e.yml`](.github/workflows/web-e2e.yml), also dispatch-only — it must stay off push/PR and off deploy. Re-enabling pytest/Jest on PR is a separate choice and does **not** make Chromium a required check. Until then, **local pytest + npm test is the day-to-day gate.**

---




## 12. Repo layout & conventions

```
MEngPlat/
├── docker-compose.yml          # Local dev: postgres, redis, backend, frontend
├── README.md                   # ← this file, the single source of truth (business + status)
├── AGENTS.md                   # Pointer for AI coding agents
├── CLAUDE.md                   # Claude Code config (root) — mirrors .cursor/rules/project.mdc
├── ANDROID_APP_STRATEGY.md     # Play/AAB/signing strategy (day-to-day mobile is this §12)
├── CHECKLIST_GAPS.txt          # Scored 13 Aug 2026 matrix — living hold list is §14 (fold, do not treat as a second bible)
│
├── .cursor/rules/              # Cursor AI rules (builder + agent layers)
├── .claude/agents/             # Claude Code subagents — mirror .cursor/rules/agents/
├── .githooks/pre-commit        # Blocks commits on main; mobile analyze/test; Cursor/Claude sync
├── .github/workflows/          # CI, incl. the same config-sync check on every PR
├── .github/dependabot.yml      # Weekly pip / npm / Actions updates
├── scripts/check_agent_config_sync.py  # Enforces the Cursor ↔ Claude Code sync rule
│
├── docs/agents/                # Live multi-agent artifacts (see §13)
│   ├── slices/_TEMPLATE.md
│   ├── slices/S-011-customer-favorites.md
│   ├── adrs/_TEMPLATE.md
│   ├── test-plans/_TEMPLATE.md
│   └── test-reports/_TEMPLATE.md
│
├── backend/
│   ├── Dockerfile
│   ├── railway.json
│   ├── requirements.txt
│   ├── pytest.ini
│   ├── app/
│   │   ├── main.py              # FastAPI entry point, router mounting, lifespan
│   │   ├── config.py            # Pydantic settings from env
│   │   ├── database.py          # SQLAlchemy async engine + session
│   │   ├── dependencies.py      # Auth deps, RBAC, ownership helpers, slugify
│   │   ├── core/security.py     # JWT + password hashing
│   │   ├── models/__init__.py   # All 19 SQLAlchemy models
│   │   ├── schemas/__init__.py  # Pydantic request/response schemas
│   │   ├── routers/             # auth, businesses, reviews, photos, ai,
│   │   │                        #   dashboard, search, maps, analytics, notifications
│   │   └── services/
│   │       ├── ai/              # base.py (port), mock_provider, openai_provider
│   │       ├── storage/         # Local + S3 implemented; Azure is a stub
│   │       ├── cache.py         # Redis helpers (fail-soft)
│   │       └── business_service.py
│   ├── scripts/seed.py          # Demo data seeder (Portland + Chennai + US)
│   ├── scripts/seed_chennai.py  # Chrompet / Radha Nagar upsert
│   ├── scripts/seed_us.py       # US listings upsert (backend/data/real-businesses/)
│   ├── data/real-businesses/    # US seed JSON (packaged in backend image)
│   └── tests/test_api.py
│
├── frontend/
│   ├── Dockerfile
│   ├── railway.json
│   ├── package.json
│   ├── figma.config.json        # Code Connect config (see §8)
│   └── src/
│       ├── app/                 # Next.js App Router pages
│       │   ├── layout.tsx, ClientLayout.tsx, page.tsx, globals.css
│       │   ├── search/, businesses/[slug]/, login/, register/
│       │   ├── profile/, settings/, merchant/dashboard/, admin/
│       ├── components/          # 16 reusable React components + __tests__/
│       │   └── *.figma.tsx      # Code Connect mappings, one per mapped component
│       └── lib/api.ts           # API client
│
└── mobile/                      # Flutter client, third consumer of /api/v1 (see below)
    ├── openapi.json             # Snapshot of the backend's OpenAPI schema (regenerable)
    ├── scripts/generate_api_client.py  # Re-runs the OpenAPI → Dart codegen below
    ├── packages/merchanthub_api/       # Generated Dio client + models -- do not hand-edit
    ├── android/                        # Kept present; not the active dev loop yet (see below)
    └── lib/
        ├── main.dart, app.dart, router.dart
        ├── core/
        │   ├── config/app_config.dart      # API_BASE_URL via --dart-define
        │   ├── network/api_client.dart     # Wraps merchanthub_api's generated MerchanthubApi
        │   ├── network/auth_interceptor.dart
        │   └── storage/token_storage.dart  # flutter_secure_storage
        └── features/
            ├── auth/                # login_screen, auth_repository, auth_provider
            └── businesses/          # business_list_screen, business_repository
```



### Conventions

- **Backend routers** — one module per domain, all mounted at `/api/v1` in `main.py`
- **Services** — business logic and external integrations stay out of routers
- **Frontend App Router** — `page.tsx` defines a route; `"use client"` only where interactivity requires it
- **Ports** — new external integrations get a `Protocol` + factory, matching `services/ai/` and `services/storage/`
- **Docs** — this README is the only prose doc; update the relevant section rather than adding a new file



### Document map (what to open)

Use **this README** for business summary, site flow, and implemented vs next. Other files are tooling, strategy leftovers, or agent tickets.


| Path                                                                     | Purpose                                           | Disposition                                                                           |
| ------------------------------------------------------------------------ | ------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `README.md`                                                              | Product, API, security, parity, investor overview | **Keep** — only file to implement business/status against                             |
| `AGENTS.md`                                                              | Agent onboarding pointer                          | Keep (tooling)                                                                        |
| `CLAUDE.md` + nested `**/CLAUDE.md` + `.cursor/rules` + `.claude/agents` | Cursor ↔ Claude Code parity                       | Keep (CI-enforced)                                                                    |
| `ANDROID_APP_STRATEGY.md`                                                | Play/AAB/signing; Railway ≠ Play                  | Keep until Play subsection is enough; day-to-day mobile is this §12                   |
| `CHECKLIST_GAPS.txt`                                                     | Scored Have/Partial/Missing (13 Aug 2026)         | **Folded** — §14 is the living hold list; do not update the `.txt` as source of truth |
| `docs/agents/slices`, `adrs`, `test-plans`, `test-reports`               | PM → Architect → Tester tickets                   | Artifact. Web e2e architecture: [ADR-009](docs/agents/adrs/ADR-009-web-functional-e2e.md) |
| `docs/competitive-analysis-lentlo.md`                                    | Lentlo scrape (2026-08-09)                        | Appendix; 5–8 line box in [§16](#16-industry-and-investor-overview)                   |
| `docs/pivot-crowdsourced-live-status.md`                                 | Exploratory Waze-style pivot                      | **Not on the roadmap**                                                                |
| `docs/research/multi-geography-rehosting.md`                             | Plan: same codebase, second geography/domain, isolated data | Exploratory — see [§10 Deployment](#10-deployment) for the Railway pattern it reuses  |
| `docs/agents/DEVELOPMENT_HISTORY.md`                                     | Build narrative                                   | Artifact                                                                              |
| `mobile/README.md`                                                       | Flutter boilerplate                               | Prefer this §12                                                                       |
| `data/real-businesses/README.md`                                         | Seed note                                         | Leave                                                                                 |
| `mobile/packages/merchanthub_api/doc/*.md`                               | Generated OpenAPI                                 | Not human docs                                                                        |




### Mobile client (Flutter)

`mobile/` is a Flutter app -- a third REST client of the same `/api/v1` backend, alongside
the Next.js frontend. No backend changes were needed; see `[ANDROID_APP_STRATEGY.md](ANDROID_APP_STRATEGY.md)`
for architecture, phase status, APK vs AAB, and the Play Store release checklist.

**Dev loop:** Flutter Web (`-d web-server`), not an Android emulator -- avoids Windows
virtualization setup for day-to-day iteration. Android scaffolding (`mobile/android/`) is kept
present for when a real APK/AAB build is needed (Play release pipeline still deferred; see
`ANDROID_APP_STRATEGY.md` phase 5).

```bash
# Backend (from backend/, with PYTHONPATH set to backend/):
uvicorn app.main:app --host 127.0.0.1 --port 8000

# Mobile (from mobile/):
flutter run -d web-server --web-port=5000 --dart-define=API_BASE_URL=http://localhost:8000
```

`API_BASE_URL` **flavors** (read via `String.fromEnvironment` in `lib/core/config/app_config.dart`,
set with `--dart-define`): `http://localhost:8000` for local Compose/local backend; the Railway
backend URL for staging/prod builds. Same JWT login/refresh flow either way -- only the base URL
changes.

**OpenAPI codegen (**`mobile/packages/merchanthub_api/`**):** models and the Dio-based API client
are generated from the backend's live OpenAPI schema via `openapi-generator-cli` (`dart-dio`
target), not hand-written -- this is what `mobile/openapi.json` and `mobile/scripts/` are for.
`ApiClient` (`lib/core/network/api_client.dart`) wraps the generated `MerchanthubApi` with two
Dio instances (one carrying `AuthInterceptor`, one auth-free for login/refresh) so the generated
code's own auth interceptors are never used. **Regenerate after backend route/schema changes:**

```bash
python mobile/scripts/generate_api_client.py
cd mobile && flutter analyze && flutter test
```

Needs a JRE and `openapi-generator-cli-7.14.0.jar` on disk. Portable, no-installer layout used
on the original Windows setup: Temurin JRE under `C:\src\jre`, generator JAR under
`C:\src\openapi-generator\`, Flutter SDK under `C:\src\flutter` (add `bin` to `PATH`). Override
paths with `JAVA_BIN`, `OPENAPI_GENERATOR_JAR`, `FLUTTER_BIN`, and `DART_BIN` if yours live
elsewhere -- defaults in `mobile/scripts/generate_api_client.py` match that layout. The generated
package is committed (not gitignored) so the app builds without needing Java on every clone --
only regeneration needs it.

**Mandatory TOTP MFA (S-020):** `lib/features/auth/login_screen.dart` mirrors
`frontend/src/components/LoginForm.tsx`'s three-step flow -- credentials, then either
first-time enrollment (QR via `flutter_svg` + secret text) or a returning-user code-verify
step, driven by `LoginResult.mfa_required` / `mfa_enrollment_required` from `POST /auth/login`.
`AuthController` (`lib/features/auth/auth_provider.dart`) only resolves to a session after
`totpConfirm`/`totpVerify` succeeds -- `submitCredentials` alone never yields tokens for a
password account, matching the backend contract.

**Public browsing, P0–P4 (S-023–S-025, S-027–S-031):**
ADR-003 carves `/businesses` and `/businesses/:slug` out of the login redirect so guests can browse
and read reviews; `LoginScreen` has "Continue without signing in". Explore hosts search chrome
(`q`, city/category/rating/sort filters, Use my location, OSM results map via `flutter_map`,
infinite scroll, photo cards). Detail is a rich profile (contact, hours, gallery, map pin, AI
overview labeled as a **suggestion**) plus reviews, like/report, and merchant replies on `ReviewCard`.
Primary chrome is `AppShell` (`ShellRoute` + `NavigationBar`): Explore / Favorites (customer) /
Notifications / Account, with merchant and admin **Home** dashboards (`/merchant`, `/admin`) —
stats, AI insights (suggestion-only), reply composer, business create/edit, and admin queues.
Logout lives on Account. `/register` (customer|merchant) plus
Google sign-in (skips MFA; hidden if `GOOGLE_CLIENT_ID` is unset) and editable `/account/profile`.
`unreadCountProvider` still polls every 30s while the shell is mounted for a logged-in session.
Home marketing (M-13–M-18, M-76, M-77) is closed on Flutter (`/home`, S-064). Remaining tracker rows are `partial` chrome/reset/QR-deep-link (M-10, M-65, M-71) and FCM `future` (M-47).

**Mobile parity conventions (Tier 2/3/4/5, S-057..S-064):** `ThemeToggleButton`/`themeModeProvider`
(S-057) is the app-wide dark-mode pattern -- `ThemeMode.system` default, explicit override
persisted via `shared_preferences`. QR/native-share flows use `qr_flutter` (rendering) +
`share_plus` (native share sheet, including sharing in-memory bytes via
`ShareParams(files: [XFile.fromData(...)])`, not just text/links) -- introduced in S-059 for the
merchant review-collection QR/link, reused as-is by S-060 for CSV export. Charting uses
`fl_chart` -- introduced in S-060 for the merchant dashboard's review-volume and 1-5
rating-mix charts; reused as-is by S-061 for the admin platform time-series chart row (no
second charting package added). S-063 upgrades the merchant review-volume series in place from
`BarChart` to `LineChart` with an area fill (`belowBarData: BarAreaData(...)`); rating-mix stays
a `BarChart`. No new charting package. Repository layer follows one-concern-per-file
(`DashboardRepository`, `BusinessRepository`, `ReviewRepository`); S-061 added `AdminRepository`
for user-admin moderation (`listUsers`/`suspendUser`/`reactivateUser`) as a new instance of that
same existing convention, not a new pattern. S-064 adds a public `/home` marketing screen
(guest shell tab Home / Explore / Sign in); signed-in tab lists are unchanged. Home reuses
`BusinessCard` / `RatingStars` and existing public GETs (`listPublic`, `publicStats`,
`listCities`, `listCategories`, `searchBusinesses`, `listForBusiness`) — no new backend or
OpenAPI regen. Explore honors `?city=` and `?q=` in addition to the existing `?category=`.

**CI emulator check (**`.github/workflows/mobile-emulator-check.yml`**):** on push/PR touching
`mobile/**` or `backend/**` (and via manual `workflow_dispatch`), boots a real KVM-accelerated
Android emulator on GitHub's Linux runners (`reactivecircus/android-emulator-runner`) against a
throwaway Postgres/Redis + backend stood up in the same job -- never the Railway DB -- and runs
`mobile/integration_test/app_test.dart`, which signs in as the seeded demo customer, completes
the TOTP verify step using the fixed demo secret (`otp` package, RFC 6238), and asserts the
business list renders. Screenshot and backend log are uploaded as build artifacts either way.

#### Web ↔ mobile feature parity tracker

Mobile is a **separate Flutter client** of `/api/v1`, not a WebView of the Next.js UI. Every
user-facing web capability must have **exactly one row** below. When web ships a new route,
nav item, or major interaction — or when mobile closes a gap — **update this table in the
same change** (see docs sync in `.cursor/rules/docs-and-api.mdc`). Use it later for one-shot
consolidation: walk `unimplemented` / `partial` rows into slices (PM → Architect → Builder →
Tester). Play Store packaging is tracked separately in `[ANDROID_APP_STRATEGY.md](ANDROID_APP_STRATEGY.md)`
phase 5, not here.


| Status          | Meaning                                               |
| --------------- | ----------------------------------------------------- |
| `implemented`   | On mobile at roughly web capability                   |
| `partial`       | On mobile but thinner / different chrome              |
| `unimplemented` | On web, not on mobile yet                             |
| `n/a`           | Not on web either (shared gap — not mobile-only debt) |
| `future`        | Intentionally deferred (e.g. merchant Phase 4, FCM)   |


**Later build waves:** P0–P4 are on this branch (S-027 chrome, S-028 discovery, S-029
register/Google/profile edit, S-030 like/report/replies, S-031 merchant/admin dashboards).
Home marketing (M-13–M-18, M-76, M-77) is **closed** on Flutter (`/home`, S-064). FCM (M-47) remains `future`.
Combined `flutter analyze` / `flutter test` is deferred until you ask.

**Last reviewed:** 2026-08-18


| ID   | Area              | Feature                                                            | Web surface                                     | Mobile surface                                                         | Status          | Notes / slice                                                |
| ---- | ----------------- | ------------------------------------------------------------------ | ----------------------------------------------- | ---------------------------------------------------------------------- | --------------- | ------------------------------------------------------------ |
| M-01 | Auth              | Email/password login                                               | `/login` (`LoginForm`)                          | `/login` (`LoginScreen`)                                               | `implemented`   | S-020                                                        |
| M-02 | Auth              | MFA enroll (TOTP QR + secret)                                      | `/login` enroll step                            | `/login` enroll step                                                   | `implemented`   | S-020                                                        |
| M-03 | Auth              | MFA verify (TOTP code)                                             | `/login` verify step                            | `/login` verify step                                                   | `implemented`   | S-020                                                        |
| M-04 | Auth              | Google / Gmail sign-in                                             | `/login`, `/register` (`GoogleSignInButton`)    | `/login`, `/register` (`GoogleSignInButton`)                           | `implemented`   | S-029; skips MFA; hidden if `GOOGLE_CLIENT_ID` unset         |
| M-74 | Auth              | Phone OTP sign-in                                                  | `/login`, `/register` (`PhoneOtpPanel`)         | `/login`, `/register` (`PhoneOtpPanel`)                                | `implemented`   | S-044; S-055 (mobile, 2026-08-17); TOTP skipped, same as web  |
| M-05 | Auth              | Register (customer / merchant)                                     | `/register`                                     | `/register`                                                            | `implemented`   | S-029; then TOTP on first password login                     |
| M-06 | Auth              | Logout                                                             | Navbar, `/settings`, already-signed-in gate     | Account screen (`/account`)                                            | `implemented`   | S-027; was list app-bar only                                 |
| M-07 | Auth              | Session restore + refresh                                          | `ClientLayout` / `auth.me`                      | `AuthInterceptor` + secure storage                                     | `implemented`   |                                                              |
| M-08 | Auth              | Role switching (customer ↔ merchant)                               | —                                               | —                                                                      | `n/a`           | Role fixed at register / Google                              |
| M-09 | Auth              | Role-aware post-login home                                         | Merchant → dashboard; admin → `/admin`          | Customer → Explore; merchant → `/merchant` dashboard; admin → `/admin` | `implemented`   | S-027 landing + S-031 dashboards                             |
| M-10 | Chrome            | Global navbar + footer                                             | `ClientLayout`                                  | Bottom `NavigationBar` + Account brand control                         | `partial`       | S-027; mobile chrome, not a cloned web navbar/footer         |
| M-11 | Chrome            | Bottom nav / primary shell                                         | — (web uses top nav)                            | `AppShell` `NavigationBar`                                             | `implemented`   | S-027 / ADR-005                                              |
| M-12 | Chrome            | Brand / home link                                                  | Navbar → `/`                                    | Account `MerchantHub AI` → Explore                                     | `implemented`   | S-027                                                        |
| M-13 | Discovery         | Home hero + marketing sections                                     | `/`                                             | `/home` (`HomeScreen`)                                                 | `implemented`   | S-014 (web); S-064 (mobile) — guest tab; Explore stays search (S-028) |
| M-14 | Discovery         | Trust metrics                                                      | `/` (`TrustMetrics`)                            | `/home` trust-metrics row                                              | `implemented`   | S-064; omitted when stats fail, same as web |
| M-15 | Discovery         | City index                                                         | `/` (`CityIndex`)                               | `/home` city index → `/businesses?city=`                               | `implemented`   | S-064; city **filter** remains on Explore (M-20) |
| M-16 | Discovery         | Category index                                                     | `/` (`CategoryIndex`)                           | `/home` category index → `/businesses?category=`                       | `implemented`   | S-064; category **filter** remains on Explore (M-20) |
| M-17 | Discovery         | Featured businesses + photos                                       | `/` (`FeaturedGrid`)                            | `/home` featured grid (`BusinessCard`)                                 | `implemented`   | S-064 |
| M-18 | Discovery         | Review voices / how-it-works / merchant CTA                        | `/`                                             | `/home` voices + how-it-works + merchant CTA                           | `implemented`   | S-064 |
| M-19 | Discovery         | Search page + query `q`                                            | `/search`                                       | Explore search field (`/businesses`)                                   | `implemented`   | S-028                                                        |
| M-20 | Discovery         | Filters (city, category, min rating, sort)                         | `/search` (`FilterPanel`)                       | Explore Filters sheet                                                  | `implemented`   | S-028                                                        |
| M-21 | Discovery         | Use my location + radius                                           | `/search` (`UseLocationButton`)                 | Explore + Filters radius                                               | `implemented`   | S-028                                                        |
| M-22 | Discovery         | Results map (OSM)                                                  | `/search` Leaflet map                           | `flutter_map` OSM tiles                                                | `implemented`   | S-028 / ADR-006                                              |
| M-23 | Discovery         | Pagination / infinite scroll UI                                    | `/search`                                       | Infinite scroll on Explore                                             | `implemented`   | S-028                                                        |
| M-24 | Discovery         | Business cards with photos                                         | `BusinessCard`                                  | Photo `BusinessCard`                                                   | `implemented`   | S-028                                                        |
| M-25 | Business          | Public list browse (guest)                                         | `/`, `/search`                                  | `/businesses` + search chrome (ADR-003)                                | `implemented`   | S-028                                                        |
| M-26 | Business          | Detail: name, city/state, rating, count                            | `/businesses/[slug]`                            | `/businesses/:slug`                                                    | `implemented`   | S-023                                                        |
| M-27 | Business          | Detail: description, address, phone, website                       | Business profile                                | `/businesses/:slug`                                                    | `implemented`   | S-028                                                        |
| M-28 | Business          | Detail: categories                                                 | `CategoryBadges` → `/search?category=`          | Category chips                                                         | `implemented`   | S-028, S-041                                                 |
| M-29 | Business          | Detail: hours                                                      | `BusinessHours`                                 | Hours block                                                            | `implemented`   | S-028                                                        |
| M-30 | Business          | Detail: photo gallery / lightbox                                   | `PhotoGallery`                                  | Gallery + lightbox                                                     | `implemented`   | S-028                                                        |
| M-31 | Business          | Detail: map pin                                                    | Leaflet on profile                              | OSM pin (`flutter_map`)                                                | `implemented`   | S-028 / ADR-006                                              |
| M-32 | Business          | Detail: AI overview (suggestion)                                   | Profile AI blurb                                | Labeled suggestion-only                                                | `implemented`   | S-028                                                        |
| M-33 | Reviews           | List reviews + AI suggestion labels                                | `ReviewsList` / `ReviewCard`                    | `ReviewCard`                                                           | `implemented`   | S-023                                                        |
| M-34 | Reviews           | Create review (stars, title, body)                                 | `/businesses/[slug]/review`                     | `ReviewFormSheet`                                                      | `implemented`   | S-023                                                        |
| M-35 | Reviews           | Attach review photos (≤5)                                          | `ReviewForm`                                    | `image_picker` in sheet                                                | `implemented`   | S-023                                                        |
| M-36 | Reviews           | Show review photo strip                                            | `ReviewCard`                                    | `ReviewCard`                                                           | `implemented`   |                                                              |
| M-37 | Reviews           | Like review                                                        | Business page                                   | `ReviewCard`                                                           | `implemented`   | S-030                                                        |
| M-38 | Reviews           | Report review                                                      | Business page                                   | `ReviewCard`                                                           | `implemented`   | S-030                                                        |
| M-39 | Reviews           | Show merchant reply on card                                        | `ReviewCard`                                    | `ReviewCard`                                                           | `implemented`   | S-030                                                        |
| M-40 | Reviews           | Edit own review                                                    | —                                               | —                                                                      | `n/a`           | No UI on either client                                       |
| M-41 | Reviews           | Delete own review                                                  | —                                               | —                                                                      | `n/a`           | No UI on either client                                       |
| M-42 | Favorites         | Favorite toggle (list + detail)                                    | `FavoriteButton`                                | Heart + `FavoriteToggleButton`                                         | `implemented`   | S-024; customer only                                         |
| M-43 | Favorites         | Favorites list                                                     | `/profile` section                              | `/favorites` (Explore shell tab)                                       | `implemented`   | S-024 + S-027 tab                                            |
| M-44 | Notifications     | Unread bell + poll                                                 | Navbar `NotificationBell`                       | Notifications tab + badge                                              | `implemented`   | S-025 + S-027 shell                                          |
| M-45 | Notifications     | Full list + mark one / mark all                                    | Bell dropdown                                   | `/notifications`                                                       | `implemented`   | S-025                                                        |
| M-46 | Notifications     | Deep-link to business/review                                       | Weak / none                                     | None                                                                   | `n/a`           | Shared gap                                                   |
| M-47 | Notifications     | Push (FCM)                                                         | —                                               | —                                                                      | `future`        | Phase 4+; polling today                                      |
| M-48 | Account           | Profile edit                                                       | `/profile`                                      | `/account/profile`                                                     | `implemented`   | S-029; email/role read-only; favorites stay M-43             |
| M-49 | Account           | Settings (profile link + logout)                                   | `/settings`                                     | `/account` + `/account/profile` + logout                               | `implemented`   | S-027; profile edit is M-48                                  |
| M-50 | Merchant          | Dashboard shell + multi-business                                   | `/merchant/dashboard`                           | `/merchant`                                                            | `implemented`   | S-031                                                        |
| M-51 | Merchant          | Stats tiles + sentiment chart                                      | Dashboard                                       | Dashboard tiles + bars                                                 | `implemented`   | S-031                                                        |
| M-52 | Merchant          | AI insights + refresh                                              | `AIInsights`                                    | `AiInsightsPanel`                                                      | `implemented`   | S-031; suggestion-only                                       |
| M-53 | Merchant          | Reply to reviews                                                   | Dashboard `ReviewCard`                          | Dashboard `ReviewCard`                                                 | `implemented`   | S-031                                                        |
| M-54 | Merchant          | Create / edit business                                             | `/merchant/businesses/…`                        | `/merchant/businesses/new` + `…/:id/edit`                              | `partial`       | S-031; S-084 web Country/State `<select>`s (bundled ISO data); mobile editor is still free-text address/city/state/country |
| M-55 | Merchant          | Storefront / logo / gallery upload UI                              | —                                               | —                                                                      | `n/a`           | API exists; no web form yet                                  |
| M-56 | Merchant          | Business hours editor                                              | —                                               | —                                                                      | `n/a`           | Display-only on web                                          |
| M-57 | Admin             | Admin home + platform stats                                        | `/admin`                                        | `/admin`                                                               | `implemented`   | S-031                                                        |
| M-58 | Admin             | Pending business approve / suspend                                 | `/admin` queue                                  | `/admin` queue                                                         | `implemented`   | S-031                                                        |
| M-59 | Admin             | Reported reviews moderate                                          | `/admin` queue                                  | `/admin` queue                                                         | `implemented`   | S-031                                                        |
| M-60 | Admin             | All businesses / all reviews browse                                | `/admin/businesses`, `/admin/reviews`           | `/admin/businesses`, `/admin/reviews`                                  | `implemented`   | S-031                                                        |
| M-61 | Merchant          | Time-series volume, rating mix, date range, reply-rate, CSV        | `/merchant/dashboard`                           | —                                                                      | `implemented` | S-033 (web), S-060 (mobile) — both Accepted                            |
| M-62 | Admin             | Platform time-series charts                                        | `/admin`                                        | `/admin` chart row (`fl_chart`, below stat tiles)                     | `implemented` | S-034 (web), S-061 (mobile) — both Accepted                            |
| M-63 | Admin             | Category create / list UI                                          | `/admin`                                        | `/admin/categories`                                                    | `implemented` | S-034 (web), S-061 (mobile) — both Accepted; chips link to search (S-041 web, S-061 mobile) |
| M-64 | Admin             | User suspend / reactivate                                          | `/admin`                                        | `/admin/users`                                                         | `implemented` | S-034 (web), S-061 (mobile) — both Accepted                            |
| M-65 | Account           | Forgot / reset password (email)                                    | `/login`, `/forgot-password`, `/reset-password` | `/login`, `/forgot-password` (request half only — emailed link opens web `/reset-password`, no in-app reset step) | `partial`       | S-035; S-054 (mobile, 2026-08-17); no deep-link infra yet, so reset itself stays web-only |
| M-66 | Merchant          | Featured listing boost (paid)                                      | Dashboard SKU tiles + search rank + Featured badge | Dashboard SKU catalog + `POST /payments/featured/checkout`; mock pending order in-app; Razorpay finish-on-web after order create | `implemented` | S-036/S-042 (web); S-062 display + S-066 checkout. Native Razorpay SDK not bundled. |
| M-73 | Account           | National ID (PAN/Aadhaar/Other); merchant required                 | Profile + merchant dashboard                    | Profile screen (`ProfileScreen`)                                       | `implemented`   | S-043; S-056 (mobile, 2026-08-17); merchant-required 400 already surfaced generically in `business_editor_screen.dart` |
| M-67 | Notifications     | Listing-approved / new-review **email**                            | Transactional mail (mock/Resend, best-effort)   | Same backend emails for every client                                 | `n/a`           | Shared infra, not a mobile screen (S-035)                |
| M-68 | Merchant          | Dashboard area/line trend charts + period-over-period delta badges | `/merchant/dashboard`                           | Dashboard volume `LineChart` + area fill; reply-rate / reviews-in-range delta badges | `implemented`   | S-037 (web), S-063 (mobile) — both Accepted                  |
| M-69 | Merchant          | Competitor rating benchmarking (category + city median)            | `/merchant/dashboard`                           | Merchant Home `BenchmarkCard`                                          | `implemented`   | S-038 (web), S-066 (mobile)                              |
| M-70 | Merchant          | AI reply drafting ("Draft with AI" button on review cards)         | `/merchant/dashboard`                           | `ReviewCard` composer fills `suggested_response`                       | `implemented`   | S-039 (web), S-066 (mobile); suggestion, not auto-post   |
| M-71 | Merchant/Customer | Review collection flow (public QR/link wizard, no gating)          | `/collect/[businessId]`; mobile `/collect/:slug` + merchant QR/share sheet | —                                                                      | `partial` | S-040 (web), S-059 (mobile) — mobile QR/share + in-app landing shipped; cold QR scan resolves to the web page, not a native deep link (by design, see S-059). S-077 (web, 2026-08-19): a non-approved business now shows a "not approved yet" message instead of the QR card silently disappearing — mobile unaffected, not yet mirrored |
| M-75 | Chrome            | Dark mode (system-matched default, explicit toggle, persisted)     | Navbar `ThemeToggle` (`next-themes`)            | Theme toggle (`ThemeToggleButton`) in Account + Business list app bars | `implemented`   | S-045 (web); S-057 (mobile, Accepted 2026-08-18)              |
| M-72 | Reviews           | Review-list sort/filter/truncate/lightbox + half-star ratings      | `/businesses/[slug]` (`ReviewsList`, `ReviewCard`, `ui/RatingWidget`) | Business detail review list (`reviewFiltersButton` bottom sheet, `ReviewCard` truncation + photo lightbox) + `RatingStars` half-star on business detail header and `BusinessCard` | `implemented`   | S-046 (web); S-058 (mobile, Accepted 2026-08-18)              |
| M-76 | Home              | Social proof rail (businesses-using-MerchantHub strip)             | `/` (`SocialProofRail`)                         | `/home` social-proof rail                                              | `implemented`   | S-047 (web); S-064 (mobile)              |
| M-77 | Home              | Problem section (three named product gaps, numbered layout)        | `/` (`ProblemSection`)                          | `/home` problem section                                                | `implemented`   | S-047 (web); S-064 (mobile)              |
| M-78 | Merchant          | AI topic clustering (named themes, count + sentiment, "Common Themes" panel) | `/merchant/dashboard` (`AIInsights`)  | `AiInsightsPanel` Common Themes                                        | `implemented`   | S-049 (web), S-066 (mobile)                              |
| M-80 | Merchant/Customer | External review sync (Google) — dashboard link/sync + public sample | `/merchant/dashboard` Google card + `/businesses/[slug]` (`ExternalReviews`) | Merchant `GoogleReviewsPanel` + public `ExternalReviewsSection` | `implemented` | S-048 (web), S-066 (mobile); native ratings unchanged. S-076 (web, 2026-08-19): "Sync now" now also refetches dashboard stats/AI insights, not just the sync card — mobile unaffected, not yet mirrored |
| M-79 | Merchant          | WhatsApp shop-data ingestion (link/QR, photos, AI text drafts, admin approval gate) | `/merchant/dashboard` card + inbound webhook + `/admin/whatsapp` review queue | Merchant QR/share + draft list; admin `/admin/whatsapp` | `implemented` | S-050..053 (web); S-066 (mobile UI on existing APIs). S-078 (web, 2026-08-19): same "not approved yet" messaging as M-71, plus clarified copy when the WhatsApp provider itself isn't configured — mobile unaffected, not yet mirrored |
| M-81 | Admin             | Processing business status (admin-triggered visibility state between Pending and Approve/Suspend) | `/admin` Pending queue "Start review"/"Return to pending" + status badges | —                                                                      | `unimplemented` | S-079 (web, 2026-08-19); not yet on mobile admin ops (Tier 4, S-061) |
| M-82 | Admin             | Admin Users panel search (by name/email)                            | `/admin` Users panel                            | —                                                                      | `unimplemented` | S-080 (web, 2026-08-19); not yet on mobile admin ops (Tier 4, S-061) |
| M-83 | Admin             | Admin Categories panel search (by name)                              | `/admin` Categories panel                       | —                                                                      | `unimplemented` | S-081 (web, 2026-08-19); not yet on mobile admin ops (Tier 4, S-061) |
| M-84 | Admin             | Categories panel repositioned to top of `/admin`; distinct "Add category" error messages (409/401-403/network) | `/admin` Categories panel                       | —                                                                      | `unimplemented` | S-082 (web, 2026-08-19); not yet on mobile admin ops (Tier 4, S-061) |
| M-85 | Admin             | Admin Users panel role badge (customer/merchant/admin classification) | `/admin` Users panel                            | —                                                                      | `unimplemented` | S-083 (web, 2026-08-19); not yet on mobile admin ops (Tier 4, S-061) |
| M-86 | Admin             | Back navigation on admin drill-down screens                         | `/admin/whatsapp`, `/admin/reviews`, `/admin/businesses`, `/admin/businesses/[id]` | —                                                                      | `unimplemented` | S-086 Accepted (web, 2026-08-19) |
| M-87 | Chrome            | Support contact in footer + `/support`                              | `Footer`, `/support`                            | —                                                                      | `unimplemented` | S-087 Accepted (web); not in Navbar (S-085 owns header) |
| M-88 | Support           | Customer support tickets + admin queue                              | `/support`, `/admin/support`                    | —                                                                      | `unimplemented` | S-088 Accepted (web, 2026-08-19) |
| M-89 | Support           | Shop-level reports (not review reports) + admin queue               | public profile, `/admin/business-reports`       | —                                                                      | `unimplemented` | S-089 Accepted (web, 2026-08-19) |
| M-90 | Admin             | Operational `/admin` console (ops nav + queue tiles)                | `/admin`                                        | —                                                                      | `unimplemented` | S-090 Accepted (web, 2026-08-19); S-091 batched verify |
| M-91 | Account           | Click-to-upload profile avatar (nav + `/profile`, not URL paste)    | Navbar `Avatar` + `/profile`                    | —                                                                      | `unimplemented` | S-085 Accepted (web, 2026-08-19); mobile `/account/profile` still URL/text or existing picture field (M-48), no click-to-upload |


**Rollup (2026-08-19):** `implemented` 68 · `partial` 4 (M-10 chrome, M-54 merchant editor Country/State dropdowns on web only — S-084, M-65 reset completion, M-71 cold QR) · `unimplemented` 11 (M-81–M-91) · `n/a` 7 · `future` 1 · **total 91**.

#### Mobile parity roadmap

Mobile traffic outweighs web traffic for this product, so remaining `unimplemented`
rows above are sequenced here by mobile-first usage rather than by table order. This section
sequences — it does not pre-spec; concrete slice numbers get assigned via the normal PM →
Architect → Builder → Tester flow when a tier is picked up.

| Tier | Theme                              | Rows                                                | Why this order                                                                                                     |
| ---- | ----------------------------------- | ---------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| 1    | Auth reliability                    | ~~M-65, M-74, M-73~~ — **Done** (S-054/S-055/S-056, Accepted 2026-08-17) | Daily-driver flows; a merchant or customer locked out on mobile with no reset path is the worst kind of gap.       |
| 2    | Core review/discovery UX            | ~~M-72~~ (Done — S-058, Accepted 2026-08-18), ~~M-75~~ (Done — S-057, Accepted 2026-08-18), ~~M-71~~ (Done, `partial` — S-059, Accepted 2026-08-18) | Highest-frequency logged-in screens; QR review collection directly drives review volume from mobile users. **Tier 2 fully closed.** |
| 3    | Merchant monetization & analytics   | ~~M-61~~, ~~M-66~~, ~~M-68~~, ~~M-69~~, ~~M-70~~, ~~M-78~~, ~~M-79~~, ~~M-80~~ — **Done** (S-060..S-063, S-066, 2026-08-18). M-66 mock checkout is in-app; live Razorpay capture still finishes on web (no native SDK). | Revenue and retention for the paying side of the platform. **Tier 3 closed for capability; Razorpay native SDK and app-links remain later polish.** |
| 4    | Admin ops                           | ~~M-62~~, ~~M-63~~, ~~M-64~~ — **Done** (S-061, Accepted 2026-08-18) | Lower urgency — admins are more likely to be at a desk than on mobile. **Tier 4 fully closed.** |
| 5    | Marketing/home surfaces             | ~~M-13, M-14, M-15, M-16, M-17, M-18, M-76, M-77~~ — **Done** (S-064, Accepted 2026-08-18) | Logged-out acquisition pages; guest `/home` (cold start still `/login`). **Tier 5 fully closed.** |

M-67 (transactional email) is backend/shared infra (`n/a` on the tracker), not a mobile screen.
M-65 (in-app password reset) and M-71 (cold QR → native `/collect`) stay `partial` until app-link hosting is configured. FCM (M-47) remains `future`.

**Note on S-028–S-031:** these four slices are coded and merged, and their tracker rows above
already read `implemented` — but each slice file's own DoD checklist
(`docs/agents/slices/S-0XX-mobile-*.md`) still shows `Status: In Progress` / `Testing` and an
unchecked "PM Status set to Accepted" box, because `flutter analyze` / `flutter test` have not
been run against them yet. That's open bookkeeping debt on already-shipped mobile work, not a
sixth roadmap tier — closing it needs the existing Tester → PM steps, not new feature work.

This repo is built with both Cursor and Claude Code, so every convention is defined
**twice, in each tool's native format** — a session started in either tool should
understand the whole repo, and what the other tool already did to it.

- **Cursor** reads `.cursor/rules/`** (`.mdc` files, attached via `alwaysApply` or `globs`).
- **Claude Code** reads `CLAUDE.md` — the root file always, plus one nested in each scoped
directory below, loaded automatically the same way `globs` attaches a Cursor rule — and
invokes the PM/Architect/Tester roles as subagents from `.claude/agents/`.


| Layer   | Cursor rule (`.cursor/rules/`)    | Claude Code equivalent                          | Scope                          |
| ------- | --------------------------------- | ----------------------------------------------- | ------------------------------ |
| Builder | `project.mdc`                     | `CLAUDE.md` (root)                              | Always applies                 |
| Builder | `backend-fastapi.mdc`             | `backend/CLAUDE.md`                             | `backend/**/*`                 |
| Builder | `frontend-nextjs.mdc`             | `frontend/CLAUDE.md`                            | `frontend/**/*`                |
| Builder | `ai-and-integrations.mdc`         | `backend/app/services/CLAUDE.md`                | `backend/app/services/**/*`    |
| Builder | `database.mdc`                    | `backend/app/models/CLAUDE.md`                  | `backend/app/models/**/*`      |
| Builder | `docs-and-api.mdc`                | `docs/CLAUDE.md`                                | `docs/**/*`, `README.md`       |
| Builder | `testing.mdc`                     | `backend/tests/CLAUDE.md`, `frontend/CLAUDE.md` | test files                     |
| Agent   | `agents/workflow.mdc`             | "Multi-agent workflow" section of `CLAUDE.md`   | Multi-agent orchestration      |
| Agent   | `agents/role-product-manager.mdc` | `.claude/agents/product-manager.md`             | `docs/agents/slices/**/*`      |
| Agent   | `agents/role-architect.mdc`       | `.claude/agents/architect.md`                   | slices, ADRs, architecture     |
| Agent   | `agents/role-tester.mdc`          | `.claude/agents/tester.md`                      | test plans, reports, test code |


Neither side is enabled manually: Cursor auto-attaches by `alwaysApply`/`globs`; Claude
Code auto-loads `CLAUDE.md` by directory and the subagents by explicit role invocation
(e.g. *"Act as Architect for slice S-00X"*, or the Agent tool with `subagent_type: architect`).

**Enforcing the sync, not just documenting it.** A convention change is only real if it
lands in both files. Whoever does the code change — human, Cursor, or Claude Code — is
expected to update both sides in the same commit, and the repo checks that automatically:

- `[scripts/check_agent_config_sync.py](scripts/check_agent_config_sync.py)` encodes the
table above as pairs of files that must change together. Given a set of changed files,
it fails if one side of a pair changed without the other.
- `[.githooks/pre-commit](.githooks/pre-commit)` runs before every local commit (CLI or IDE):
refuses commits on `main`/`master` (use a feature branch + PR); runs the Cursor/Claude sync
check on staged files; if any `mobile/` path is staged, runs `flutter analyze && flutter test`.
One-time setup per clone: `git config core.hooksPath .githooks`.
- `[.github/workflows/agent-config-sync.yml](.github/workflows/agent-config-sync.yml)` runs
the same sync check over the full diff on every PR and push to `main`. Add it (and the mobile
`analyze-test` / ideally `emulator-test` jobs) as **required status checks** in GitHub branch
protection so the rules are non-bypassable, not just advisory. See
`ANDROID_APP_STRATEGY.md` § Testing & CI flow.

---



## 13. Multi-agent workflow

Three specialised agent roles plus a Builder collaborate through **shared artifacts** in `docs/agents/`, building the product in vertical slices.

```mermaid
flowchart LR
    PM[Product Manager] -->|Slice brief| AR[Architect]
    AR -->|Tech spec| DEV[Builder]
    DEV -->|Code| TE[Tester]
    TE -->|Test report| PM2[Product Manager]
    PM2 -->|Accepted| Done[Done]
```



**Status gate:** `Draft` → `Specified` → `In Progress` → `Testing` → `Accepted`
(set by PM → Architect → Builder → Tester → PM respectively)

> Do **not** implement until Status is `Specified` and the Architect checklist is complete.

When a slice is **Accepted**, the **same PR** must update this README: §14 implemented vs open (and §16 “built vs next” if the change is investor-visible); §12 parity if user-facing; §6 / §7 if flow or API changed. Do **not** add a new product `.md` / `.txt` checklist — slices, ADRs, and test artifacts stay under `docs/agents/` only.

### Stages


| #   | Role                | Produces                                                                                                                                                                               | Artifact path                                                        | Prompt                                                                                    |
| --- | ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| 1   | **Product Manager** | User story, numbered Given/When/Then acceptance criteria, UX notes, out-of-scope, dependencies, definition of done. Sets `Draft`.                                                      | `docs/agents/slices/S-00X-name.md` (copy `slices/_TEMPLATE.md`)      | *"Act as Product Manager. Create slice S-007 for admin moderation using the template."*   |
| 2   | **Architect**       | API contract table, RBAC matrix, data-model impact, cache/side-effects, frontend route + rendering choice, flow diagram, risks. ADR if the decision is irreversible. Sets `Specified`. | Same slice file + `docs/agents/adrs/ADR-XXX-*.md`                    | *"Act as Architect. Add technical spec to S-007 including API contract and RBAC matrix."* |
| 3   | **Builder**         | Code + doc updates. Sets `Testing`.                                                                                                                                                    | `backend/`, `frontend/`, README §7                                   | *"Implement slice S-007 per the architect spec."*                                         |
| 4   | **Tester**          | Test plan, then test report with an AC→test coverage matrix, plus pytest/RTL tests. Recommends Ship or Rework.                                                                         | `docs/agents/test-plans/TP-S-00X-*.md`, `test-reports/TR-S-00X-*.md` | *"Act as Tester. Verify S-007 and produce a test report with AC coverage."*               |
| 5   | **Product Manager** | Reviews the test report against the AC. Sets `Accepted`, or lists gaps and re-opens.                                                                                                   | Slice file                                                           | *"Act as Product Manager. Review TR-S-007 against the acceptance criteria."*              |


Which rules attach at which stage:


| Stage     | Agent rule (`.cursor/rules/agents/`) | Builder rules (auto-attached by file)                       |
| --------- | ------------------------------------ | ----------------------------------------------------------- |
| PM        | `role-product-manager.mdc`           | `docs-and-api.mdc`                                          |
| Architect | `role-architect.mdc`                 | `database.mdc`, `docs-and-api.mdc`                          |
| Builder   | —                                    | `project.mdc`, `backend-fastapi.mdc`, `frontend-nextjs.mdc` |
| Tester    | `role-tester.mdc`                    | `testing.mdc`                                               |


`project.mdc` applies to every session. You supply the feature idea and the role ("Act as Architect…"); the rule file supplies the behaviour and the template supplies the artifact shape.

**Full cycle in one prompt:**

> Run the multi-agent workflow for slice S-006: PM review AC → Architect gap analysis → implement gaps → Tester report. Stop after each stage for my approval.



### Worked example — S-011 Customer Favorites

`[docs/agents/slices/S-011-customer-favorites.md](docs/agents/slices/S-011-customer-favorites.md)` is the worked-example slice. The `Favorite` model already existed; S-011 added the router, API client, FavoriteButton, and profile favorites list. **Status: Accepted.**

Its five acceptance criteria: (1) favoriting an approved business as a logged-in customer saves it and shows a "Favorited" state; (2) clicking again removes it (toggle); (3) `/profile` lists favorites with name, city, rating; (4) an anonymous click redirects to `/login`; (5) favoriting an unapproved business returns 404/400 and creates nothing. Out of scope: sharing favorites, notifications, merchants seeing who favorited them.

What the Architect stage would produce for it:


| Method | Path                              | Auth     | Request                     | Response                                       |
| ------ | --------------------------------- | -------- | --------------------------- | ---------------------------------------------- |
| POST   | `/api/v1/favorites`               | customer | `{ "business_id": "uuid" }` | `{ "favorited": true, "business_id": "uuid" }` |
| DELETE | `/api/v1/favorites/{business_id}` | customer | —                           | 204 No Content                                 |
| GET    | `/api/v1/favorites`               | customer | —                           | `BusinessResponse[]`                           |


Data model impact: extend existing — `favorites` already carries `(user_id, business_id)` with a unique constraint, so no migration. Cache: none needed (favorites don't affect the search cache). Frontend: CSR on `/profile` and `/businesses/[slug]`, reusing `BusinessCard`.

Builder file checklist: `backend/app/routers/favorites.py`, register it in `backend/app/main.py`, schemas if needed, `frontend/src/lib/api.ts`, a Favorite toggle + `ProfilePage.tsx`, README §7.

Tester AC coverage would map AC 1/2/4/5 to `backend/tests/test_favorites.py` and AC 3 to a manual check.

### Slice backlog


| ID    | Title                                                                          | Phase        | Status                                   |
| ----- | ------------------------------------------------------------------------------ | ------------ | ---------------------------------------- |
| S-001 | Docker + auth + layout                                                         | 1 Foundation | Scaffolded                               |
| S-002 | Business CRUD + admin approval                                                 | 2 Core       | Scaffolded                               |
| S-003 | Review CRUD + photos                                                           | 2 Core       | Scaffolded                               |
| S-004 | Search + filter                                                                | 2 Core       | Scaffolded                               |
| S-005 | AI review analysis pipeline                                                    | 3 AI         | Scaffolded                               |
| S-006 | Merchant dashboard + AI insights                                               | 4 Dashboards | Accepted (closed by S-033)               |
| S-007 | Admin moderation + platform analytics                                          | 4 Dashboards | Accepted (closed by S-034)               |
| S-008 | Notifications                                                                  | 4 Dashboards | Accepted (UI wired)                      |
| S-065 | One in-app notice per workflow scenario                                        | 4 Dashboards | In Progress                              |
| S-066 | Mobile remaining web capability parity                                         | 4 Dashboards | Testing                                  |
| S-009 | OAuth + OpenStreetMap maps                                                     | 5 Polish     | Partial (maps done; OAuth callback stub) |
| S-010 | Test hardening + deploy verification                                           | 5 Polish     | In Progress — Playwright journeys + dispatch-only `web-e2e.yml`; not a required check |
| S-011 | Customer favorites                                                             | 2 Core       | Accepted                                 |
| S-012 | Business detail enrichment                                                     | 2 Core       | Accepted                                 |
| S-013 | Search pagination / sort / categories                                          | 2 Core       | Accepted                                 |
| S-014 | Home page enrichment                                                           | 5 Polish     | Accepted                                 |
| S-015 | Notifications UI                                                               | 4 Dashboards | Accepted                                 |
| S-016 | Profile & settings edit                                                        | 5 Polish     | Accepted                                 |
| S-017 | Design system primitives                                                       | 5 Polish     | Accepted (additive; migration deferred)  |
| S-018 | Secure logout / session UX                                                     | 1 Foundation | Accepted                                 |
| S-019 | User profile enrichment                                                        | 5 Polish     | Accepted                                 |
| S-020 | Mandatory TOTP for password login                                              | 1 Foundation | Accepted                                 |
| S-021 | Admin business & review drill-down                                             | 4 Dashboards | Accepted                                 |
| S-022 | Merchant dashboard tile interactivity                                          | 4 Dashboards | Accepted                                 |
| S-026 | httpOnly cookie auth migration (web) + dual Bearer/cookie backend              | 1 Foundation | Draft                                    |
| S-023 | Mobile reviews (Flutter)                                                       | 2 Core       | Accepted                                 |
| S-024 | Mobile favorites (Flutter)                                                     | 2 Core       | Accepted                                 |
| S-025 | Mobile notifications (Flutter)                                                 | 5 Polish     | Accepted                                 |
| S-027 | Mobile P0 chrome (shell, role home, account/logout)                            | 1 Foundation | Accepted                                 |
| S-028 | Mobile P1 discovery + rich business detail                                     | 2 Core       | In Progress                              |
| S-029 | Mobile P2 register, Google sign-in, profile edit                               | 1 Foundation | In Progress                              |
| S-030 | Mobile P3 like / report / replies                                              | 2 Core       | In Progress                              |
| S-031 | Mobile P4 merchant / admin                                                     | 4 Dashboards | In Progress                              |
| S-033 | Merchant analytics (time-series, rating mix, range, reply-rate)                | 4 Dashboards | Accepted (closes S-006)                  |
| S-034 | Admin platform series + category UI + account suspend                          | 4 Dashboards | Accepted (closes S-007)                  |
| S-035 | Transactional email (mock + Resend)                                            | 5 Polish     | Accepted                                 |
| S-036 | Featured boost + Razorpay transaction fee                                      | 5 Polish     | Accepted                                 |
| S-037 | Merchant dashboard chart upgrade (area/line charts, period-over-period deltas) | 4 Dashboards | Accepted                                 |
| S-063 | Mobile dashboard trend chart + period-over-period deltas (M-68 parity)         | 4 Dashboards | Accepted                                 |
| S-038 | Competitor rating benchmarking (category + city median vs. own rating)         | 4 Dashboards | Accepted                                 |
| S-039 | AI reply drafting — surface `suggested_response` in merchant reply UI          | 2 Core       | Accepted                                 |
| S-041 | Admin category chips open public search                                        | 5 Polish     | Accepted                                 |
| S-044 | Phone OTP login (mock SMS + Msg91 port)                                        | 1 Foundation | Accepted                                 |
| S-047 | Home marketing sections (social proof + problem)                               | 5 Polish     | Accepted                                 |
| S-064 | Mobile home marketing surfaces (Tier 5: M-13–M-18, M-76, M-77)                 | 5 Polish     | Accepted                                 |
| S-048 | Multi-platform review aggregator foundation (Google Places)                    | 2 Core       | Accepted                                 |
| S-049 | AI topic clustering for merchant reviews                                       | 3 AI         | Accepted                                 |
| S-050 | WhatsApp link foundation (session + inbound webhook + dashboard QR)            | 4 Dashboards | Testing (Jest pass; pytest not run; not Accepted) |
| S-051 | WhatsApp photo ingestion (reuse existing photo/storage pipeline)               | 2 Core       | Testing (pytest not run; not Accepted)   |
| S-052 | WhatsApp AI text drafts (extract → merchant Apply/Discard)                     | 3 AI         | Testing (Jest pass; pytest not run; not Accepted) |
| S-053 | WhatsApp admin approval gate (global review queue, editable AI suggestions, merchant self-apply removed) | 4 Dashboards | **Accepted** |
| S-085 | Profile avatar click-to-upload (nav + `/profile`) | 2 Core | **Accepted** |
| S-086 | Admin back navigation on drill-downs | 5 Polish | **Accepted** |
| S-087 | Support contact in footer + `/support` | 5 Polish | **Accepted** |
| S-088 | Customer support tickets | 2 Core | **Accepted** |
| S-089 | Shop-level business reports | 2 Core | **Accepted** |
| S-090 | Admin operational console (G1 + E2) | 4 Dashboards | **Accepted** |
| S-091 | End-to-end merchant + admin verification (H1) | 5 Polish | **Accepted** |




### Conflict rules


| Topic                 | Decision owner  |
| --------------------- | --------------- |
| Feature priority      | Product Manager |
| API / schema design   | Architect       |
| Release readiness     | Tester          |
| Code style / patterns | Builder rules   |




### Common mistakes

1. **Skipping the Architect** → API drift and wrong RBAC
2. **Slice too big** → split into S-0XXa (API) and S-0XXb (UI)
3. **Acceptance criteria not numbered** → the Tester cannot build a coverage matrix
4. **Implementing before** `Specified` → violates the workflow gate
5. **Forgetting to update README §7** → docs drift from Swagger

---



## 14. Known gaps & roadmap

An honest delta between the original specification and what the code actually does today.

### Built and working


| Area            | State                                                                                                                                                                                                                                                                                                                                                                                    |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Backend routers | 14, all wired into `main.py` (includes favorites, admin, payments, support) |
| Data models     | SQLAlchemy models in `app/models/__init__.py` (incl. `external_reviews`, S-048)                                                                                                                                                                                                                                                                                                           |
| Auth            | JWT access/refresh with refresh `jti` rotation, bcrypt, RBAC, Redis logout blocklist + best-effort login lockout, mandatory TOTP for password login, Google OAuth and Phone OTP exempt                                                                                                                                                                                                   |
| AI layer        | **In the product today.** Review submit runs text + photo analysis + merchant rolling summary via `AIProvider`. Default `mock` (no key, no cost). Real vendors are env + key. Output is **suggestions**, never verdicts. `monthly_trends` (mock or real) are AI-estimated, not review dates — shown as a labeled suggestion list only, never charted as fact (S-033).                    |
| Storage         | `local` disk and `s3` (boto3) providers implemented; `azure` still a stub                                                                                                                                                                                                                                                                                                                |
| Email           | `mock` (logs only) and `resend` providers implemented via `EmailProvider` port. Three transactional sends: password reset, listing approved, new review — best-effort, never blocks the triggering request (S-035, Accepted). In-app bell is one notice per scenario (**S-065**). |
| Payments        | `mock` and `razorpay` via `PaymentProvider` port. Three SKUs (₹299/7d, ₹499/15d, ₹899/30d); capture then admin-approve; PAN never stored (S-042)                                                                                                                                                                        |
| SMS             | `mock` and `msg91` via `SmsProvider` port. Phone OTP login (S-044)                                                                                                                                                                                                                                                       |
| Frontend        | Home (+ social proof rail, problem section, S-047), search (map + location, paid **Featured** badge), business detail (+ "Also reviewed on Google", S-048), login (MFA steps) + forgot/reset password (S-035, Accepted), register, enriched profile + click-to-upload avatar (S-085), settings, merchant dashboard (+ time-series volume/rating-mix/reply-rate/CSV export, S-033; featured boost CTA, S-036; AI topic clustering "Common Themes" panel, S-049; Google reviews link/sync card, S-048) + business create/edit, admin moderation queues (+ platform trend charts, category admin, user suspend/reactivate, S-034; placement disable/refund) |
| Maps            | Leaflet + OpenStreetMap tiles; nearby search via Haversine. Nominatim address geocode/autocomplete removed (S-084).                                                                                                                                                                                                      |
| Seeding         | `scripts/seed.py` — Portland + Chennai + US; gated by `SEED_MODE` / `seed_runs` (Railway: not on boot)                                                                                                                                                                                                                                                                                   |
| Local dev       | `docker compose up --build`                                                                                                                                                                                                                                                                                                                                                              |
| Admin ops (S-076–S-083) | Google review sync now refetches stats/insights, not just the sync card (S-076); merchant review-QR and WhatsApp-QR cards show a clear "not approved yet" / "not configured yet" message instead of silently disappearing (S-077, S-078); admin queue gained an optional `Processing` business status between Pending and Approve/Suspend, admin-triggered, visibility-only (S-079); admin Users and Categories panels gained debounced search (S-080, S-081); Categories panel moved to the top of `/admin` and "Add category" now shows distinct 409/401-403/network error messages via a new `ApiError` HTTP-status-carrying class (S-082); admin Users panel shows a role badge (customer/merchant/admin) alongside the existing account-status badge (S-083). All admin-only or merchant-dashboard-only — no new customer-facing surface. |
| Support & shop reports (S-086–S-089) | **Accepted.** Admin drill-downs have a shared back link (S-086). Footer + `/support` + `GET /support/contact` (S-087; Navbar unchanged). `support_tickets` + admin `/admin/support` (S-088). Shop-level `business_reports` + thread, repeat flag at 3+, `/admin/business-reports`, public “Report this shop” (S-089). Distinct from `review_reports`. Run `alembic upgrade head`. |
| Admin operational console (S-090) | **Accepted.** `/admin` is an ops console: wider shell, jump nav to existing queues/drill-downs, extra snapshot counts (open tickets, repeat shops, processing listings) on `GET /dashboard/admin/platform`. Feedback = support tickets; Complaints = shop reports. No Inspections/FAQ product. |
| Profile avatar (S-085) | **Accepted.** Navbar shows a circular photo or initials; `/profile` click-to-upload via `POST /auth/me/avatar` (own user only, no AI analysis). Replaces the Avatar URL text field. Not on mobile (M-91 `unimplemented`). |




### Not built


| Gap                         | Detail                                                                                                                                                                                                                                                                           |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Azure storage is a stub** | Raises `NotImplementedError` ([storage](backend/app/services/storage/__init__.py)). `local` and `s3` both work.                                                                                                                                                                  |
| **Thin tests / incomplete browser e2e** | Layers 1–3 (pytest + RTL) are real. Playwright journeys exist (`E2E=1`); GitHub run is **manual** [`web-e2e.yml`](.github/workflows/web-e2e.yml) (artifact traces). pytest/Jest workflows are also dispatch-only. See §11. |
| **Design-system migration** | Complete. `Select` / `StatCard` / `ui/RatingWidget` (S-017) now back every remaining call site — native `<select>`s, inline stat tiles, and the duplicate top-level `RatingWidget` (removed, canonical copy is `ui/RatingWidget`) all migrated.                                  |
| **Security items 1–6**      | §9: rate limit, upload MIME/size, lockout, refresh rotation, headers, password policy are in. Remaining: `localStorage` tokens (S-026) and world-readable `/uploads`. Commercial SaaS/legal items: [Deferred](#deferred-for-commercial--enterprise).                             |
| **No structured logging**   | `/health` exists, but there is no request logging or structured log output — an observability requirement not yet met.                                                                                                                                                           |
| **No CI/CD auto-deploy**    | `backend-tests.yml` / `frontend-tests.yml` run pytest/Jest on every PR and push to `main`, but there is still no auto-deploy step to Railway/Vercel.                                                                                                                             |
| **Android Play release**    | Signed AAB + Play Console listing / internal-testing track not wired yet (see `[ANDROID_APP_STRATEGY.md](ANDROID_APP_STRATEGY.md)` phase 5). Feature-level web↔mobile gaps live in the [§12 parity tracker](#web--mobile-feature-parity-tracker) — not duplicated here.          |
| **Mobile web parity**       | P0–P4 (S-023–S-025, S-027–S-031) are on Flutter; S-028–S-031 DoD checklists are still open (`flutter analyze`/`flutter test` not run — see the S-028–S-031 note in [§12 Mobile parity roadmap](#mobile-parity-roadmap)). Tier 1 (Auth reliability — M-65 forgot/reset password, M-74 phone OTP, M-73 National ID) is **closed**: S-054/S-055/S-056 Accepted 2026-08-17 (M-65 is request-half only on mobile — no in-app reset screen, the emailed link opens the web app; M-74 and M-73 are full parity). M-75 (dark mode, Tier 2) and M-72 (review-list sort/filter/truncate/lightbox + half-star ratings, Tier 2) are now also **closed**: mobile dark-mode S-057 Accepted 2026-08-18 — system-matched default, explicit toggle (Account + Business list app bars), local persistence, full legibility sweep across all primary screens; mobile review-list interactivity S-058 Accepted 2026-08-18 — bottom-sheet sort/min-rating filter, distinct zero-results empty state, `ReviewCard` truncate/"Read more" toggle, review-photo lightbox (reusing `PhotoGallery.openLightbox`), and `Icons.star_half` readonly average-rating display on the business detail header and `BusinessCard`; all 8 AC covered by automated `flutter_test` (167/167 passing, `flutter analyze` clean) per `TR-S-058-mobile-review-list-interactivity.md`. A non-blocking follow-up was flagged: `ReviewCard`'s new photo thumbnails lack an `errorBuilder` unlike `PhotoGallery`'s (no broken-image placeholder on load failure) — tracked for a future small polish pass, not required by any AC. M-71 (review-collection flow, Tier 2) is now also closed, `partial`: mobile S-059 Accepted 2026-08-18 — merchant-side QR/share sheet (`qr_flutter`/`share_plus`) and a new in-app, ungated `/collect/:slug` landing+submission screen; `partial` rather than `implemented` because a cold physical-QR scan resolves to the existing web `/collect/[businessId]` page in the device browser, not a native deep link into the app — a deliberate scope decision (a plain `https://` QR payload works for any camera regardless of app-install state; a custom URI scheme would fail outright for the common case), not a gap in any of the slice's 6 AC. **Tier 2 of the mobile parity roadmap is now fully closed** (M-72, M-75, M-71). Tier 3 (merchant monetization & analytics) is in progress: M-61 (dashboard time-series volume, 1-5 rating mix, 30/90/all date-range filter, reply-rate incl. null-vs-zero handling, CSV export) is now closed: mobile S-060 Accepted 2026-08-18 — no backend gap (every field/endpoint AC 1-6 needed already existed via S-033's Accepted web contract, this was mobile-UI-only), new `fl_chart`-based volume and rating-mix charts, CSV export reuses S-059's `share_plus` (bytes shared via `ShareParams.files`, no new package), all 8 AC covered by automated `flutter_test` (210/210 passing, `flutter analyze` clean) per `TR-S-060-mobile-dashboard-analytics.md`. M-66 (featured listing boost, paid) is now also closed, `partial`: mobile S-062 Accepted 2026-08-18 — SKU catalog display + placement active/expiry/awaiting-approval status (`FeaturedBoostPanel` on the merchant dashboard) + a `Featured` badge and non-AI-judgment disclaimer on `BusinessCard`/search results; no backend gap (every field/endpoint already existed via S-036/S-042's Accepted web contract). `partial` rather than `implemented` because mobile-initiated checkout (`POST /payments/featured/checkout`) is deliberately still out of scope — a merchant completes purchase on the web dashboard via an explicit, honestly-labeled hand-off button, since adding a Razorpay mobile SDK is a materially larger, PCI-adjacent surface reserved for a future dedicated slice; all 10 AC covered by automated `flutter_test` (222/222 passing, `flutter analyze` clean) per `TR-S-062-mobile-featured-listing-boost.md`. M-68 (dashboard area/line trend + period-over-period deltas, Tier 3) is now also closed: mobile S-063 Accepted 2026-08-18 — same `review_volume_by_month` series as S-060, upgraded in place to `LineChart` with area fill, plus reply-rate / reviews-in-range delta badges from already-present `DashboardStats` previous-window fields (no backend gap); all 6 AC covered by automated `flutter_test` (226/226 passing, `flutter analyze` clean) per `TR-S-063-mobile-dashboard-trend-deltas.md`. Tier 4 (Admin ops — M-62 platform time-series charts, M-63 category create/list, M-64 user suspend/reactivate) is now also closed: mobile S-061 Accepted 2026-08-18 — `admin_home_screen.dart` gains an in-page `fl_chart` chart row (new users, businesses approved, new reviews, new reports) below the existing stat tiles, plus two new sub-routes (`/admin/categories`, `/admin/users`, mirroring the existing `/admin/businesses`/`/admin/reviews` pattern) for category create/list (with tap-to-search chip navigation, S-041 parity) and user suspend/reactivate (Suspend/Reactivate controls hidden entirely for admin rows and the signed-in admin's own row, mirroring web's S-034 self/admin refusal choice); no new backend endpoint — all six calls reuse S-034's already-Accepted, unmodified backend surface; all 11 AC covered (10 automated, 1 by code-inspection regression check) by automated `flutter_test` (210/210 passing, `flutter analyze` clean) per `TR-S-061-mobile-admin-ops-parity.md`. **Tier 4 of the mobile parity roadmap is now fully closed** (M-62, M-63, M-64). Tier 5 (marketing/home surfaces — M-13–M-18, M-76, M-77) is now also closed: mobile S-064 Accepted 2026-08-18 — public `/home` (`HomeScreen`) with web section order (hero, social proof, problem, trust metrics, city/category indexes, featured grid, review voices, how-it-works, merchant CTA); guest shell is Home / Explore / Sign in; "Continue without signing in" lands on `/home`; signed-in tab lists unchanged; no new backend (existing public GETs); all 16 AC covered by automated `flutter_test` (240/240 passing, `flutter analyze` clean) per `TR-S-064-mobile-home-marketing.md`. **Tier 5 of the mobile parity roadmap is now fully closed.** S-066 (2026-08-18) closes remaining merchant/admin capability gaps on Flutter: M-69 benchmark, M-70 Draft with AI, M-78 Common Themes, M-80 Google link/sync + public samples, M-79 WhatsApp QR/drafts + admin queue, M-66 in-app mock checkout. Tracker rollup: `implemented` 69 · `partial` 3 (M-10 chrome, M-65 reset completion, M-71 cold QR) · `unimplemented` 0 · `n/a` 7 · `future` 1 (FCM). Living checklist: [§12 Web ↔ mobile feature parity tracker](#web--mobile-feature-parity-tracker). |
| **Optional seed ops**       | Core seed gating is done (`SEED_MODE` / `seed_runs`). Still optional later: a Railway one-shot/cron seed service (never on the web dyno), blue-green app cutover on one DB, or a disposable dual-DB demo reset — not required for normal deploys.                                |
| **Dark mode hex values are placeholder** | Dark mode itself is shipped (S-045, Accepted — `next-themes`, class-based Tailwind, 5 semantic tokens, ~65-file sweep). What's still open: every dark-mode hex (`globals.css` `--mh-*` vars, `Charts.tsx` `CHART_COLORS.dark`, Badge/RatingWidget `dark:` pairs) is a contrast-checked, Material-3-grounded placeholder — the real Figma `Color` collection (`X0XXhJiwW8SxFdMf39n2t3`, 99 variables, Light+Dark) is local/unpublished and unreachable via Figma MCP tooling this session. A human needs to open the file directly, diff the real values against the table in the S-045 slice spec, and file a follow-up patch if they drift. |
| **WhatsApp shop-data ingestion** | **S-053 Accepted; S-050..052 still `Testing`.** S-053 closes the "merchant approves their own AI draft" gap — a `BusinessUpdateDraft` now only reaches the live `Business` row via admin approve at `/admin/whatsapp`, not merchant self-apply; formal Tester report + PM Accept complete (`pytest tests/test_whatsapp.py` 21/21, `tests/test_whatsapp_admin_asgi.py` 20/20 against real Postgres, Jest 197/197). Along the way, S-053's Tester found and Builder fixed a real bug shared by all four slices: the Postgres `draftstatus` enum only accepted lowercase labels while SQLAlchemy wrote uppercase names, so no `BusinessUpdateDraft.status` write had ever actually succeeded against a real database (`backend/app/models/__init__.py`, one-line `values_callable` fix, no migration). S-050..052's own Tester reports predate both that fix and a working pytest environment (most of their AC are marked "not run" for unrelated environment reasons) — PM did not accept them by inference and instead flagged a follow-up: re-run their test suites for real, then bring back for an accept/rework decision. Live Meta is a later **env/ops cutover**: [Going live with Meta WhatsApp](#going-live-with-meta-whatsapp-cloud-api). |
| **No automatic Google review polling** | **S-048** ships merchant-triggered Sync now only (Google's Place Details cap of 5 most-relevant reviews). Scheduled polling is backlog. Native `average_rating` / `review_count` stay first-party only. |
| **Listings often lack map coordinates** | **S-084** dropped Nominatim lookup from the merchant address form (product decision: typed address + Country/State dropdowns, no live geocode). Latitude/longitude remain optional manual fields, so most new/edited listings will have no coordinates and will not appear in `POST /maps/nearby` distance search or on the search map until a merchant types them by hand. |




### Original success criteria

The MVP is complete when: (1) a customer can register, search, and submit a review with photos; (2) AI analysis runs automatically and displays sentiment + suggestions; (3) a merchant can register a business, get approved, and view AI insights; (4) an admin can approve businesses and moderate reviews; (5) the app runs via `docker compose up`; (6) documentation exists; (7) the deployment guide enables a hosted deployment without guesswork.

**1–6 are met. 7 is met for Railway (Option D, repo-side config done) and documented-but-unbuilt for Option C.**

### Deferred for commercial / enterprise

These are **held off** until product needs them. They are not in-house leftovers of this repo’s MVP bar. The scored 13 Aug 2026 matrix still lives in `[CHECKLIST_GAPS.txt](CHECKLIST_GAPS.txt)`; **do not treat that file as the living product plan** — this section and [§16](#16-industry-and-investor-overview) are.


| Held item                                                                                    | Why it waits                                                                                                           |
| -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **S-026 httpOnly cookies** (ADR-004)                                                         | Dedicated slice: dual web cookie + mobile Bearer. Not in the in-house hardening batch so Flutter auth stays untouched. |
| Managed IdP / enterprise SAML SSO (Auth0, Clerk, WorkOS, Cognito)                            | Rented identity; rewrite of session ownership                                                                          |
| Error/APM SaaS (Sentry, Datadog, New Relic)                                                  | Rented integration                                                                                                     |
| Uptime SaaS (UptimeRobot etc.)                                                               | Optional free-tier wiring; not required for local/Compose                                                              |
| CDN / object-storage **accounts** and paid edge (Cloudflare, Cloudinary)                     | S3 provider **code** exists; a real bucket is ops                                                                      |
| Message queues / Celery workers / serverless job platforms                                   | Scale theatre until volume exists                                                                                      |
| Feature-flag vendors, canary / blue-green platforms                                          | Ops product, not an API gap                                                                                            |
| Legal: ToS, Privacy, cookie CMP, GDPR program, lawyer-reviewed retention (incl. national ID) | Lawyers, not a PR                                                                                                      |
| Third-party pentest and SOC 2 / ISO audits                                                   | External agency                                                                                                        |
| GitHub branch protection / Railway auto-deploy                                               | Settings in GitHub/Railway UI you own, not only code                                                                   |
| Event **grants** / merchant show sponsorship                                                 | Needs fee revenue from **S-036** first                                                                                 |


**Payments / PCI** for v1 is **S-042** (three featured SKUs, Razorpay, capture then admin-approve, no cards stored). Stripe and a second gateway stay out of scope. Event grants still wait on neighborhood traffic.

### Going live with Meta WhatsApp Cloud API

The product code talks to WhatsApp only through `get_whatsapp_provider()` ([ADR-012](docs/agents/adrs/ADR-012-whatsapp-cloud-api-port.md)). **Do not add Meta HTTP calls in routers.** Compose/pytest stay on `WHATSAPP_PROVIDER=mock`. When a neighborhood launch needs real chats, this is the rework — env + Meta console, not a new ingest pipeline:

1. Finish S-050..053 against **mock** (pytest + RTL + Tester report + PM `Accepted`) before flipping production. The live adapter is unproven until that gate.
2. Create a Meta app with **WhatsApp Cloud API**, a business phone number, and a webhook. Subscribe to `messages`. Callback URL: `https://<api-host>/api/v1/webhooks/whatsapp` (GET handshake + POST inbound). Verify token must match `META_WHATSAPP_VERIFY_TOKEN`.
3. Set production env (empty defaults — never `"placeholder"`): `WHATSAPP_PROVIDER=meta_cloud`, `WHATSAPP_BUSINESS_NUMBER` (digits for `wa.me`), `META_WHATSAPP_ACCESS_TOKEN`, `META_WHATSAPP_PHONE_NUMBER_ID`, `META_WHATSAPP_VERIFY_TOKEN`, `META_WHATSAPP_APP_SECRET` (HMAC for `X-Hub-Signature-256` — this is the **app secret**, not the access token). Optional: `WHATSAPP_SESSION_TTL_HOURS` (default 24).
4. Factory already falls back to mock if `meta_cloud` is selected but the access token is blank — a missing token must not take production “live” silently. After keys are set, smoke: GET challenge, signed POST of a token-bearing text, one image, one admin Approve/Reject at `/admin/whatsapp`. HMAC failures must stay 400.
5. **Do not rewrite** session bind, photo `save_business_photo`, or admin draft approve/reject for Meta. If Graph payloads or media URLs drift, change only `providers/meta_cloud.py` (and add a contract test with a recorded fixture). AI text still never auto-publishes.

### Suggested next steps (evaluation and leftovers)

Product intel slices S-033–S-040 are **Accepted**. WhatsApp S-050..053 are **Testing** — mock code + Jest/pytest passing locally; **not** PM-Accepted (formal Tester report still required). Remaining proof/ops leftovers still apply.

1. **WhatsApp:** run `pytest tests/test_whatsapp.py` with Postgres, close Tester rework items, then PM Accept. Only then run the Meta cutover above.
2. **S-010:** run Actions → **Web e2e (Playwright)** when you want the second view; download `playwright-traces`. Keep it off PR/deploy.
3. Optionally **re-enable** `push`/`pull_request` on `backend-tests.yml` / `frontend-tests.yml` only — do not require Playwright on `main`.
4. Leftovers: structured logs, hermetic test DB, CSP, **S-026** cookies, Azure stub, Play Store phase 5, mobile parity (§12).
5. Live Resend / Razorpay / S3-CDN when a neighborhood launch needs them — adapters already exist; WhatsApp Cloud API follows the cutover list above.

**Good position today:** working loop **including AI**, transactional email (S-035), featured fee SKU (S-036), merchant intel (S-037–S-040), Google review sample (S-048, mock by default), with vendor mocks. **Bad position:** claiming Playwright-on-staging, live Razorpay traffic, live Places quota, or neighborhood traction.

---



## 15. Environment variables

Complete list, verified against `[backend/app/config.py](backend/app/config.py)`.

### Backend


| Variable                      | Default                                                                  | Purpose                                                                                       |
| ----------------------------- | ------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------- |
| `APP_NAME`                    | `MerchantHub AI`                                                         | Shown in Swagger and `/health`                                                                |
| `APP_VERSION`                 | `0.1.0`                                                                  | Shown in Swagger and `/health`                                                                |
| `DEBUG`                       | `true`                                                                   | Verbose errors — set `false` in production                                                    |
| `DATABASE_URL`                | `postgresql+asyncpg://merchanthub:merchanthub@postgres:5432/merchanthub` | **Must** use the `+asyncpg` driver; SQLite is not supported                                   |
| `REDIS_URL`                   | `redis://redis:6379/0`                                                   | Optional — app degrades to uncached if unreachable                                            |
| `SECRET_KEY`                  | `change-me-in-production-use-openssl-rand`                               | JWT signing key — **always override**                                                         |
| `ALGORITHM`                   | `HS256`                                                                  | JWT algorithm                                                                                 |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `30`                                                                     | Access token TTL                                                                              |
| `REFRESH_TOKEN_EXPIRE_DAYS`   | `7`                                                                      | Refresh token TTL                                                                             |
| `AI_PROVIDER`                 | `mock`                                                                   | `mock`                                                                                        |
| `AI_API_KEY`                  | *(empty)*                                                                | Required when `AI_PROVIDER` is not `mock`                                                     |
| `AI_BASE_URL`                 | `https://api.openai.com/v1`                                              | Point at DeepSeek or any OpenAI-compatible endpoint                                           |
| `AI_MODEL`                    | `gpt-4o-mini`                                                            | Model name passed to the provider                                                             |
| `STORAGE_PROVIDER`            | `local`                                                                  | `local`                                                                                       |
| `STORAGE_LOCAL_PATH`          | `./uploads`                                                              | Served as static files at `/uploads`                                                          |
| `STORAGE_S3_BUCKET`           | *(empty)*                                                                | Required when `STORAGE_PROVIDER=s3`                                                           |
| `STORAGE_S3_REGION`           | `us-east-1`                                                              | AWS region for the bucket                                                                     |
| `STORAGE_S3_ENDPOINT_URL`     | *(empty)*                                                                | S3-compatible services only (MinIO, Cloudflare R2, LocalStack)                                |
| `STORAGE_S3_PUBLIC_BASE_URL`  | *(empty)*                                                                | CDN/custom domain fronting the bucket; defaults to the bucket's own virtual-hosted-style URL  |
| `EMAIL_PROVIDER`              | `mock`                                                                   | `mock` (logs only) | `resend`                                                                 |
| `RESEND_API_KEY`              | *(empty)*                                                                | Required when `EMAIL_PROVIDER=resend` — fails at startup if missing                           |
| `EMAIL_FROM`                  | *(empty)*                                                                | Required when `EMAIL_PROVIDER=resend` — must be a Resend-verified sending domain              |
| `PUBLIC_APP_URL`              | `http://localhost:3000`                                                  | Origin used to build password-reset links in email copy — not a secret                        |
| `PAYMENTS_PROVIDER`           | `mock`                                                                   | `mock` (no keys) or `razorpay`                                                                |
| `RAZORPAY_KEY_ID`             | *(empty)*                                                                | Required when `PAYMENTS_PROVIDER=razorpay`                                                    |
| `RAZORPAY_KEY_SECRET`         | *(empty)*                                                                | Required when `PAYMENTS_PROVIDER=razorpay`                                                    |
| `RAZORPAY_WEBHOOK_SECRET`     | *(empty)*                                                                | HMAC secret; mock uses this or `mock-webhook-secret`                                          |
| `SMS_PROVIDER`                | `mock`                                                                   | `mock` (logs OTP) or `msg91`                                                                  |
| `MSG91_AUTH_KEY`              | *(empty)*                                                                | Required when `SMS_PROVIDER=msg91`                                                            |
| `MSG91_TEMPLATE_ID`           | *(empty)*                                                                | Required when `SMS_PROVIDER=msg91`                                                            |
| `WHATSAPP_PROVIDER`           | `mock`                                                                   | `mock` (no Meta calls) or `meta_cloud`. Compose/CI stay `mock`. Cutover: §14                   |
| `WHATSAPP_BUSINESS_NUMBER`    | *(empty)*                                                                | Public click-to-chat digits for `wa.me`. Mock uses a demo number if empty                     |
| `WHATSAPP_SESSION_TTL_HOURS`  | `24`                                                                     | How long a dashboard QR token / bound phone stays valid                                       |
| `META_WHATSAPP_ACCESS_TOKEN`  | *(empty)*                                                                | Cloud API token when `WHATSAPP_PROVIDER=meta_cloud` — never commit a real value               |
| `META_WHATSAPP_PHONE_NUMBER_ID` | *(empty)*                                                              | Meta phone-number ID for send/ack when using the live provider                                |
| `META_WHATSAPP_VERIFY_TOKEN`  | *(empty)*                                                                | Shared secret for the webhook GET handshake (`hub.verify_token`)                              |
| `META_WHATSAPP_APP_SECRET`    | *(empty)*                                                                | HMAC for `X-Hub-Signature-256` (app secret, not the access token). Mock uses `mock-webhook-secret` if empty |
| `CORS_ORIGINS`                | `http://localhost:3000`                                                  | Comma-separated allowlist                                                                     |
| `GOOGLE_MAPS_API_KEY`         | `placeholder`                                                            | Unused — maps use OpenStreetMap tiles                                                         |
| `GOOGLE_CLIENT_ID`            | *(empty)*                                                                | OAuth client ID for Google sign-in — must match the frontend's `NEXT_PUBLIC_GOOGLE_CLIENT_ID` |
| `GOOGLE_PLACES_API_KEY`       | *(empty)*                                                                | Places Text Search + Place Details. Empty → mock review-source provider (**S-048**). Must stay `""`, not `"placeholder"` |
| `SEED_MODE`                   | `off`                                                                    | `off`                                                                                         |
| `SEED_VERSION`                | `2026-08-13-password-policy-v1`                                          | Marker written to `seed_runs`; bump when demo seed content changes                            |
| `SUPPORT_EMAIL`               | `support@merchanthub.example`                                            | Public support inbox shown via `GET /support/contact` and the footer (S-087)                  |




### Frontend


| Variable                       | Default                 | Purpose                                                                                                                                               |
| ------------------------------ | ----------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `NEXT_PUBLIC_API_URL`          | `http://localhost:8000` | Backend base URL, browser-side (baked at **frontend build** time on Railway)                                                                          |
| `API_URL_INTERNAL`             | same as above locally   | Backend URL for Server Components inside Docker/Railway — **required** on Railway or home SSR falls back to `localhost:8000` and Featured stays empty |
| `NEXT_PUBLIC_GOOGLE_MAPS_KEY`  | `placeholder`           | Unused — Leaflet uses OSM tiles directly                                                                                                              |
| `NEXT_PUBLIC_GOOGLE_CLIENT_ID` | *(empty)*               | OAuth client ID for Google sign-in                                                                                                                    |


---



## 16. Industry and investor overview

**Honest position:** we can demo a product loop including AI, email, merchant charts, and a featured-boost SKU (mock checkout locally). We cannot yet claim traction or live production Razorpay volume.

Pitch: **local review capture + merchant operating loop + AI suggestions (already wired) + one listing-boost fee**. Do not pitch a payments company.

### Problem

Google/Maps reviews are high-friction (find the pin, public identity, permanent-feeling score). Category apps (food vs health vs auto) split the street. Owners get a star average, not themes they can act on the same day.

### Product

One neighborhood graph: cafés, clinics, shops, repair — not five vertical apps. QR / short link at the counter. **AI is already in the loop** as suggestion only (mock locally; live LLM via `AI_PROVIDER` + a key).

### Site flow (high level)

Discover on the map → open a listing → read reviews and photos → write a review → AI labels sentiment/themes (suggestion) → merchant sees dashboard KPIs + draft reply → admin keeps listings and reports honest.

```mermaid
flowchart LR
  subgraph shipped [Shipped]
    Cust[Customer review]
    AI[AI suggestions]
    Merch[Merchant reply]
    Adm[Admin queues]
    Charts[Real time series]
    Email[Transactional email]
    Fees[Featured boost SKU]
    Intel[Area charts, benchmark, AI draft, QR collect]
    E2E[Manual Playwright audit]
  end
  subgraph later [Later / ops]
    Keys[Live Resend / Razorpay / S3]
  end
  Cust --> AI --> Merch
  Adm --> Cust
  Charts --> Email --> Fees --> Intel
  Intel -.-> E2E
  Fees -.-> Keys
```





### Three roles


| Role         | Today                                                                                                                                                           | Still open                                                                                           |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **Customer** | Find nearby, photos, labeled sentiment, write review, favorite, report, password-reset mail (S-035 web; S-054 mobile request), paid **Featured** search first (S-036), QR collect (S-040) | Edit/delete own review |
| **Merchant** | Listing after approve; KPI + S-033/S-037 charts; benchmark (S-038); AI draft (S-039); ₹499 featured week (S-036) | Hours/gallery editors; live Razorpay keys; mobile parity for intel/fees |
| **Admin**    | Approve/suspend, moderate, platform series, categories, user suspend (S-034); featured disable/refund (S-036) | — |




### AI status (do not tell VCs we lack AI)

Shipped: `AIProvider` port, factory, analysis on review submit, stored `ai_analyses`, review-card labels, merchant `AIInsights`. Default mock so demo/tests cost nothing. OpenAI-compatible and other adapters exist in code; production uses them only with keys.

Shipped as of S-033 (Accepted): DB-backed review volume + rating-mix charts and reply-rate, sourced from `Review.created_at` — not AI JSON. Still not shipped (and not an "add AI" slice): token-billing UI, chatbot, auto-send replies.

### Moat (honest)

Density in a few neighborhoods + merchant workflow + suggestion-grade AI. Not a Google replacement. Not a proprietary model. TAM for the first neighborhood is **to be measured**, not invented.

### Competitor box (Lentlo, scraped 2026-08-09)

Lentlo is a national India directory (listings, reviews, claim, premium packages). MerchantHub is narrower: **capture + merchant action + AI suggestions** in a dense neighborhood, with an admin trust layer. Lentlo’s “business analytics” was not visible beyond claim/reply in that scrape — we will not copy that oversell; our charts wait for S-033/S-034. Full notes: `[docs/competitive-analysis-lentlo.md](docs/competitive-analysis-lentlo.md)`. Crowdsourced live-status (Waze-style) is **not on the roadmap**.

### Fee numbers (S-042)

INR inclusive listed prices: **₹299 / 7 days**, **₹499 / 15 days**, **₹899 / 30 days** (29900 / 49900 / 89900 paise). `gateway_fee_paise` is Razorpay `fee` (GST typically inside `fee`; do not add `tax`). `platform_fee_paise` = captured − gateway. Mock estimates ~2%+GST when `fee` is absent. Capture does **not** feature the listing; admin approve does. Production Checkout needs live Razorpay keys; Compose stays `PAYMENTS_PROVIDER=mock`.

### Monetization (live SKU in mock; production keys optional)

- **SKUs:** featured listing / search boost — ₹299/7d, ₹499/15d, ₹899/30d.
- **Gateway:** Razorpay only (India-first). Never store cards. ~2% + GST recorded as `gateway_fee`; remainder is `platform_fee`.
- **Later:** recycle a share of take into merchant **event grants** (shows/camps) once a neighborhood has traffic — not v1.
- **Not v1:** marketplace GMV on food orders.



### Traction and ask

Demo / seeded listings only. A fundraise ask should be **pre-seed for one neighborhood launch + the fee stack**, not Series A language.

### Built vs next


| Built                                                                                                                                                                                                                                                                                                                       | Next (not yet Accepted)                                                                                                                                                                                                                                                                                                                                                                                                               |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Auth (password + TOTP, Google) + forgot/reset + email, search + OSM + paid Featured, reviews, favorites, merchant dashboard (S-033 charts, S-037 area/deltas, S-038 benchmark, S-039 AI draft, S-040 QR collect), admin queues (S-034) + placement refund, **S-036** featured SKU (mock/Razorpay port), **S-045** dark mode (system default + toggle, ~65-file sweep), **S-046** review-list sort/filter/truncate/lightbox + half-star ratings, **S-047** home social proof rail + problem section, **S-048** Google review sample (link + Sync now, native ratings unchanged), **S-049** AI topic clustering ("Common Themes" panel), **S-053** WhatsApp admin approval gate (global review queue at `/admin/whatsapp`, editable AI suggestions, merchant self-apply removed), **S-065** one in-app notice per workflow scenario (listing / review / WhatsApp / featured payment; duplicate notice rows pruned, seed shops untouched), **S-010** Playwright journeys + manual `web-e2e.yml`, **S-057** mobile dark mode (system default + explicit toggle + persistence, parity for M-75), **S-058** mobile review-list interactivity (sort/filter bottom sheet, truncate + "Read more", photo lightbox, half-star ratings, parity for M-72), **S-059** mobile review-collection flow (merchant QR/share sheet + in-app `/collect/:slug` landing, `partial` parity for M-71 — cold QR scan opens the web page, not a native deep link, by design), **S-060** mobile merchant dashboard analytics (`fl_chart` volume + rating-mix charts, date-range filter, reply-rate, CSV export via `share_plus`, parity for M-61), **S-061** mobile admin ops parity (`fl_chart` platform time-series chart row, `/admin/categories` create/list with tap-to-search chips, `/admin/users` suspend/reactivate with self/admin controls hidden, parity for M-62/M-63/M-64 — Tier 4 fully closed), **S-062** mobile featured listing boost, browse-only (SKU catalog + placement status panel, `Featured` badge + disclaimer on `BusinessCard`/search, `partial` parity for M-66 — checkout stays web-only by design, no Razorpay mobile SDK added), **S-063** mobile dashboard trend chart + period-over-period deltas (`LineChart` area fill on the existing volume series, reply-rate / reviews-in-range delta badges, parity for M-68), **S-064** mobile home marketing (public `/home`, guest Home tab, web section order, parity for M-13–M-18 / M-76 / M-77 — Tier 5 fully closed), **S-085** click-to-upload profile avatar (Navbar + `/profile`, `POST /auth/me/avatar`; not AI-analyzed) | Leftovers: structured logs, isolated test DB, CSP, **S-026** cookies, Azure stub, Play Store phase 5, remaining mobile parity (Tier 3: M-69 benchmark, M-70 AI reply draft, M-78 topic clustering, M-79 WhatsApp, M-80 Google review sync), optional re-enable pytest/Jest on PR; **S-050..052** WhatsApp foundation (Testing, **not Accepted** — pending a real Tester re-run now that S-053 fixed the shared `draftstatus` enum bug blocking real-DB draft writes; Meta cutover in §14) |


Play Store packaging is distribution (`ANDROID_APP_STRATEGY.md` phase 5), not this story.

---



## License

Portfolio / educational use.