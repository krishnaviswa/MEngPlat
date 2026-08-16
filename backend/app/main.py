from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from app.config import get_settings
from app.core.rate_limit import limiter
from app.core.security_headers import SecurityHeadersMiddleware
from app.routers import (
    admin,
    ai,
    analytics,
    auth,
    businesses,
    dashboard,
    favorites,
    maps,
    notifications,
    payments,
    photos,
    reviews,
    search,
    webhooks,
)
from app.services.ai import validate_startup_config as validate_ai_startup_config
from app.services.ai.http_client import close_shared_client
from app.services.email import validate_startup_config as validate_email_startup_config
from app.services.payments import validate_startup_config as validate_payments_startup_config
from app.services.sms import validate_startup_config as validate_sms_startup_config

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # The schema is owned by Alembic -- `alembic upgrade head` runs in the start
    # command, before this process boots. Base.metadata.create_all() used to run
    # here, but it only ever CREATEs missing tables and never ALTERs existing
    # ones, so any column added to a model after its table already existed was
    # silently ignored on every deployed database.
    Path(settings.storage_local_path).mkdir(parents=True, exist_ok=True)
    # Catch an unregistered AI_PROVIDER or a missing API key here, not on the
    # first review a customer submits.
    validate_ai_startup_config()
    validate_email_startup_config()
    validate_payments_startup_config()
    validate_sms_startup_config()
    yield
    await close_shared_client()


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="Merchant Engagement Platform with AI-powered review analysis",
    lifespan=lifespan,
    # Starlette's debug mode returns a plaintext traceback in the HTTP
    # response body on unhandled exceptions -- useful locally, an internals
    # leak in production. See app/config.py's `debug` field.
    debug=settings.debug,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(SecurityHeadersMiddleware)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

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
app.include_router(favorites.router, prefix=api_prefix)
app.include_router(admin.router, prefix=api_prefix)
app.include_router(payments.router, prefix=api_prefix)
app.include_router(webhooks.router, prefix=api_prefix)

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
