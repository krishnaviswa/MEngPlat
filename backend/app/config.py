from functools import lru_cache
from typing import Literal

from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class AIProviderCredentials(BaseModel):
    """Per-provider override, set via AI_PROVIDERS__<NAME>__<FIELD>.

    e.g. AI_PROVIDERS__DEEPSEEK__API_KEY, AI_PROVIDERS__GROQ__MODEL. Blank
    fields fall through to a vendor-native env alias, then the legacy triple
    below (for the active provider only), then the provider's own default --
    see provider_config.resolve_provider_config().
    """

    api_key: str = ""
    base_url: str = ""
    model: str = ""
    vision_model: str = ""


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        # Enables AI_PROVIDERS__<NAME>__<FIELD>. Checked against every existing
        # env var name in the repo -- none contain "__" -- before turning this on.
        env_nested_delimiter="__",
    )

    app_name: str = "MerchantHub AI"
    app_version: str = "0.1.0"
    debug: bool = True

    database_url: str = "postgresql+asyncpg://merchanthub:merchanthub@postgres:5432/merchanthub"
    redis_url: str = "redis://redis:6379/0"

    secret_key: str = "change-me-in-production-use-openssl-rand"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7

    # Was Literal["mock", "openai", "deepseek"]. A closed Literal meant adding a
    # provider required editing this file; now any registered name works, and
    # an unregistered one is caught at startup (main.py lifespan) rather than
    # here, so this module never has to import the provider registry.
    ai_provider: str = "mock"
    ai_fallback_provider: str = "mock"

    # Legacy single-provider config, applied only to whichever provider
    # ai_provider currently names (see provider_config.py). Left blank by
    # default rather than defaulting to OpenAI's URL/model, which used to be
    # applied even when ai_provider was something else entirely.
    ai_api_key: str = ""
    ai_base_url: str = ""
    ai_model: str = ""
    ai_vision_model: str = ""

    # New providers need zero edits here -- see providers/openai_family.py.
    ai_providers: dict[str, AIProviderCredentials] = Field(default_factory=dict)

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
