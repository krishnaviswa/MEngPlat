from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.config import get_settings
from app.database import Base, engine
from app.routers import ai, analytics, auth, businesses, dashboard, maps, notifications, photos, reviews, search

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    Path(settings.storage_local_path).mkdir(parents=True, exist_ok=True)
    yield


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="Merchant Engagement Platform with AI-powered review analysis",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

api_prefix = "/api/v1"
app.include_router(auth.router, prefix=api_prefix)
app.include_router(businesses.router, prefix=api_prefix)
app.include_router(reviews.router, prefix=api_prefix)
app.include_router(photos.router, prefix=api_prefix)
app.include_router(ai.router, prefix=api_prefix)
app.include_router(dashboard.router, prefix=api_prefix)
app.include_router(search.router, prefix=api_prefix)
app.include_router(maps.router, prefix=api_prefix)
app.include_router(analytics.router, prefix=api_prefix)
app.include_router(notifications.router, prefix=api_prefix)

uploads_path = Path(settings.storage_local_path)
uploads_path.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(uploads_path)), name="uploads")


@app.get("/health")
async def health_check():
    return {"status": "healthy", "app": settings.app_name, "version": settings.app_version}


@app.get("/")
async def root():
    return {
        "message": "Welcome to MerchantHub AI API",
        "docs": "/docs",
        "health": "/health",
    }
