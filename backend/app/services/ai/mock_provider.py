"""Back-compat shim. The implementation moved to providers/mock.py.

README section 12 and .cursor/rules reference this path.
"""

from app.services.ai.providers.mock import MockAIProvider

__all__ = ["MockAIProvider"]
