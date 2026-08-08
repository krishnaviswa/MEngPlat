"""Back-compat shim. The implementation moved to providers/openai_compatible.py.

README section 12 and .cursor/rules reference this path.
"""

from app.services.ai.providers.openai_compatible import OpenAICompatibleProvider

__all__ = ["OpenAICompatibleProvider"]
