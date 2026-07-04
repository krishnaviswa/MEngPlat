from functools import lru_cache
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "MerchantHub AI"
    app_version: str = "0.1.0"
    debug: bool = True

    database_url: str = "postgresql+asyncpg://merchanthub:merchanthub@postgres:5432/merchanthub"
    redis_url: str = "redis://redis:6379/0"

    secret_key: str = "change-me-in-production-use-openssl-rand"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7

    ai_provider: Literal["mock", "openai", "deepseek"] = "mock"
    ai_api_key: str = ""
    ai_base_url: str = "https://api.openai.com/v1"
    ai_model: str = "gpt-4o-mini"

    storage_provider: Literal["local", "s3", "azure"] = "local"
    storage_local_path: str = "/app/uploads"

    cors_origins: str = "http://localhost:3000"

    google_maps_api_key: str = "placeholder"

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
