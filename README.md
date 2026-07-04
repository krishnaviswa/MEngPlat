# MerchantHub AI

A **Merchant Engagement Platform** MVP that helps local businesses build trust through verified reviews, AI-powered feedback analysis, and actionable business insights.

Built as a portfolio-grade full-stack project demonstrating Forward Deployed Engineer capabilities.

## Stack

| Layer | Technology |
|-------|------------|
| Frontend | Next.js 15, React 19, TypeScript, Tailwind CSS |
| Backend | FastAPI, SQLAlchemy, Pydantic, Uvicorn |
| Database | PostgreSQL |
| Cache | Redis |
| AI | Swappable provider (Mock / OpenAI / DeepSeek) |
| Dev | Docker Compose |

## Quick Start

```bash
docker compose up --build
```

| Service | URL |
|---------|-----|
| App | http://localhost:3000 |
| API | http://localhost:8000 |
| API Docs | http://localhost:8000/docs |

### Demo accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@merchanthub.ai | admin12345 |
| Merchant | merchant@example.com | merchant123 |
| Customer | customer@example.com | customer123 |

## Features

- **Customers** — search businesses, write reviews, upload photos, like/report reviews
- **Merchants** — register businesses, respond to reviews, view analytics + AI insights
- **Admins** — approve businesses, moderate reviews, platform analytics
- **AI** — automatic sentiment analysis, summaries, image insights (presented as suggestions)

## Documentation

| Doc | Description |
|-----|-------------|
| [Master Build Prompt](docs/MERCHANTHUB_AI_BUILD_PROMPT.md) | Full specification + flows |
| [Architecture](docs/ARCHITECTURE.md) | System & component diagrams |
| [Flows](docs/FLOWS.md) | Sequence diagrams |
| [ERD](docs/ERD.md) | Database relationships |
| [API Reference](docs/API_REFERENCE.md) | REST endpoint docs |
| [Frontend Guide](docs/FRONTEND_GUIDE.md) | Components, props, state, SSR/CSR |
| [Deployment](docs/DEPLOYMENT.md) | Docker + Vercel/Render/Neon guide |
| [Folder Structure](docs/FOLDER_STRUCTURE.md) | Project layout |

## Development

```bash
# Backend tests
cd backend && pip install -r requirements.txt && pytest

# Frontend tests
cd frontend && npm install && npm test
```

## License

Portfolio / educational use.
