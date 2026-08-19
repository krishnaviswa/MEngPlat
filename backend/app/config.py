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
    # Safe-by-default: SQL echo logging and FastAPI's traceback-in-response
    # debug mode (main.py) are both off unless an environment opts in.
    # docker-compose.yml and .env.example opt local dev back in explicitly.
    debug: bool = False

    database_url: str = "postgresql+asyncpg://merchanthub:merchanthub@postgres:5432/merchanthub"
    redis_url: str = "redis://redis:6379/0"

    # No insecure default -- every documented workflow (docker-compose.yml,
    # .env.example, both CI workflows) already sets this explicitly. Missing
    # it now fails at startup instead of silently forging JWTs with a
    # publicly-known key. README §9 known weakness #2.
    secret_key: str
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 7
    # Short-lived JWT between password check and TOTP verify/enroll.
    mfa_token_expire_minutes: int = 10

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

    # Gateway reliability knobs (app/services/ai/gateway.py). Retries apply
    # only to 429/5xx/timeout/connect errors -- a 401/403 goes straight to the
    # fallback since retrying a bad key just burns time for the same result.
    ai_max_retries: int = 2
    ai_total_deadline_seconds: float = 25.0
    # On exhausted retries, serve the fallback provider's result (with
    # meta.degraded=True) instead of raising into the request. Set False in
    # tests that need to assert failure actually propagates.
    ai_degrade_on_failure: bool = True

    # Merchant-summary prompt bounds (app/services/business_service.py). The
    # summary used to json.dumps up to 50 full review bodies on every single
    # review submission -- unbounded input size on the hottest AI call path.
    ai_max_reviews_per_summary: int = 30
    ai_max_review_chars: int = 600
    # Redis SET NX EX lock TTL: a burst of reviews within this window triggers
    # one summary refresh, not one per review.
    ai_summary_debounce_seconds: int = 300

    # Topic clustering (app/routers/ai.py, S-049). A business is eligible once
    # it has this many ACTIVE reviews with non-trivial body text; below that,
    # the endpoint returns insufficient_data=True without paying for an LLM call.
    ai_topics_min_reviews: int = 5
    ai_topics_min_review_chars: int = 20
    # Cache-aside TTL for a business's computed topic clusters (not persisted --
    # see the slice's Architect spec for why this differs from the summary's
    # background+debounce+persisted-column pattern).
    ai_topics_cache_ttl_seconds: int = 900

    storage_provider: Literal["local", "s3", "azure"] = "local"
    storage_local_path: str = "./uploads"
    # S3 credentials are NOT settings fields on purpose -- boto3's default
    # chain (env vars, IAM role, ~/.aws/credentials) already covers every real
    # deployment target without us inventing a parallel secret store.
    storage_s3_bucket: str = ""
    storage_s3_region: str = "us-east-1"
    # Override for S3-compatible services (MinIO, Cloudflare R2, LocalStack).
    storage_s3_endpoint_url: str = ""
    # Override for a CDN/custom domain fronting the bucket; defaults to the
    # bucket's virtual-hosted-style URL when blank.
    storage_s3_public_base_url: str = ""

    # Transactional email (backend/app/services/email/). mock (default) logs
    # only -- no vendor key needed for local/demo. Unrecognised values and a
    # resend selection missing its key/from fail at startup (main.py lifespan),
    # same pattern as ai_provider above.
    email_provider: str = "mock"
    resend_api_key: str = ""
    email_from: str = ""
    # Origin used to build password-reset links in email copy. Not a secret.
    public_app_url: str = "http://localhost:3000"

    # Featured-boost payments (app/services/payments/). mock (default) needs no
    # Razorpay keys. razorpay fails at startup if keys/webhook secret are missing.
    payments_provider: str = "mock"
    razorpay_key_id: str = ""
    razorpay_key_secret: str = ""
    razorpay_webhook_secret: str = ""

    cors_origins: str = "http://localhost:3000"

    google_maps_api_key: str = "placeholder"
    # S-048 review aggregator. Default "" (not "placeholder" like the leftover
    # above, which is truthy and would silently defeat a bool(...) check) --
    # get_review_source_provider() falls back to the mock provider when blank.
    google_places_api_key: str = ""
    # Redis SET NX EX debounce TTL for "Sync now" (AC9). Also the crash/timeout
    # safety net after which a stuck lock self-expires -- see
    # review_sync_service.sync_google_reviews, which releases the lock early
    # in the common case via cache.release_lock.
    google_reviews_sync_debounce_seconds: int = 20
    # OAuth 2.0 client ID (not secret -- it's public, embedded in frontend JS)
    # for Google Identity Services. Verifying an ID token without this set
    # would accept a token minted for any Google application, not just ours.
    google_client_id: str = ""

    sms_provider: str = "mock"
    msg91_auth_key: str = ""
    msg91_template_id: str = ""

    # WhatsApp Cloud API (app/services/whatsapp/). mock (default) needs no
    # Meta keys. Defaults are empty strings -- never "placeholder" (truthy
    # leftovers would defeat availability checks). HMAC uses the *app secret*,
    # not the access token (ADR-012).
    whatsapp_provider: str = "mock"
    whatsapp_business_number: str = ""
    whatsapp_session_ttl_hours: int = 24
    meta_whatsapp_access_token: str = ""
    meta_whatsapp_phone_number_id: str = ""
    meta_whatsapp_verify_token: str = ""
    meta_whatsapp_app_secret: str = ""

    # Demo seed gate (scripts/seed.py). Default `off` so production boots never
    # re-upsert; Compose sets `if_outdated`. Manual refresh: SEED_MODE=force.
    seed_mode: Literal["off", "if_empty", "if_outdated", "force"] = "off"
    seed_version: str = "2026-08-19-demo-otp-phones-v1"

    # Public support inbox (S-087). Display-only; not a vendor integration.
    support_email: str = "support@merchanthub.example"

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
