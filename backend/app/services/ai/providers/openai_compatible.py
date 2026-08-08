"""Back-compat shim. The implementation moved to openai_family.py, which now
serves all OpenAI-shaped vendors (openai, deepseek, groq, gemini, qwen, glm,
kimi) via one spec-driven class instead of one hardcoded client.

Deliberately does not call register_provider itself -- openai_family.py's
SPECS loop already registers "openai" and "deepseek"; doing it again here
would trip the duplicate-registration guard in registry.py.
"""

from app.services.ai.providers.openai_family import OpenAICompatibleProvider, OpenAISpec

__all__ = ["OpenAICompatibleProvider", "OpenAISpec"]
