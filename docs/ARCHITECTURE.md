# Architecture

## System Overview

```mermaid
flowchart TB
    subgraph Client
        Browser[Browser / Next.js]
    end

    subgraph Application
        FE[Frontend :3000]
        BE[FastAPI :8000]
    end

    subgraph Data
        PG[(PostgreSQL)]
        RD[(Redis)]
        FS[Local Uploads / S3 / Azure]
    end

    subgraph External
        LLM[OpenAI / DeepSeek / Mock AI]
        Maps[Google Maps placeholder]
    end

    Browser --> FE
    FE -->|REST JSON| BE
    BE --> PG
    BE --> RD
    BE --> FS
    BE --> LLM
    BE -.-> Maps
```

## Component Diagram

```mermaid
flowchart LR
    subgraph Frontend Components
        Nav[Navbar]
        BC[BusinessCard]
        RC[ReviewCard]
        RW[RatingWidget]
        AI[AIInsights]
        Dash[Dashboard]
    end

    subgraph Backend Modules
        Auth[auth router]
        Biz[businesses router]
        Rev[reviews router]
        Photo[photos router]
        AIr[ai router]
        Search[search router]
    end

    subgraph Services
        AIProv[AI Provider Abstraction]
        Store[Storage Abstraction]
        Cache[Redis Cache]
    end

    Nav --> Auth
    BC --> Biz
    RC --> Rev
    AI --> AIr
    Dash --> AIr

    Rev --> AIProv
    Photo --> AIProv
    Photo --> Store
    Search --> Cache
```

## Layer Responsibilities

| Layer | Responsibility |
|-------|----------------|
| Frontend | UI, routing, client auth token storage |
| API Routers | HTTP validation, auth checks, response mapping |
| Services | AI analysis, caching, storage, business logic |
| Models | SQLAlchemy ORM, PostgreSQL persistence |
| Infrastructure | Docker Compose, PostgreSQL, Redis |

## Security

- Passwords hashed with bcrypt
- JWT access tokens (30 min) + refresh tokens (7 days)
- Role-based access: customer, merchant, admin
- CORS restricted to configured origins

## AI Design

All AI outputs include disclaimers. The `AIProvider` protocol allows swapping:
- `mock` — local development (default)
- `openai` / `deepseek` — OpenAI-compatible APIs via env config
