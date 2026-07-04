from app.config import get_settings
from app.services.ai.base import AIProvider
from app.services.ai.mock_provider import MockAIProvider
from app.services.ai.openai_provider import OpenAICompatibleProvider

settings = get_settings()


def get_ai_provider() -> AIProvider:
    if settings.ai_provider == "mock":
        return MockAIProvider()
    return OpenAICompatibleProvider()
