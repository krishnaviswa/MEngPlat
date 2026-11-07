"""Shared pytest fixtures.

`app.database.engine` is a module-level singleton, and pytest-asyncio gives each
test its own event loop. Without cleanup, pooled asyncpg connections stay bound
to the first test's loop and every later DB-backed test fails with "another
operation is in progress" / "attached to a different loop". Disposing the pool
after each test (and resetting the in-memory rate limiter, whose per-IP buckets
would otherwise accumulate across tests) lets one `pytest` run cover the suite.
"""

import pytest

from app.core.rate_limit import limiter
from app.database import engine


@pytest.fixture(autouse=True)
async def _isolate_engine_and_limiter():
    limiter.reset()
    yield
    await engine.dispose()
    limiter.reset()
