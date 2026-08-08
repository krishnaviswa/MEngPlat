"""Alembic environment.

The database URL comes from app.config.get_settings() (the DATABASE_URL env var)
rather than alembic.ini, so migrations and the app can never disagree about which
database they are pointed at.
"""

import asyncio
from logging.config import fileConfig

from alembic import context
from sqlalchemy import create_engine, pool
from sqlalchemy.engine import Connection, make_url
from sqlalchemy.ext.asyncio import create_async_engine

from app.config import get_settings
from app.database import Base

# Importing the models package registers every table on Base.metadata.
# Without this, autogenerate would see an empty schema and try to drop everything.
import app.models  # noqa: F401  (imported for the side effect)

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def _database_url() -> str:
    """Resolve the target URL.

    Precedence: `alembic -x url=...` (one-off overrides, e.g. pointing a sync
    driver at a remote database) then DATABASE_URL via Settings.
    """
    return context.get_x_argument(as_dictionary=True).get("url") or get_settings().database_url


def _configure_kwargs() -> dict:
    return {
        "target_metadata": target_metadata,
        # Detect column type and server-default changes, not just added/dropped
        # columns. Off by default in alembic and a common source of silent drift.
        "compare_type": True,
        "compare_server_default": True,
    }


def run_migrations_offline() -> None:
    """Emit SQL to stdout instead of running it (`alembic upgrade head --sql`)."""
    context.configure(
        url=_database_url(),
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        **_configure_kwargs(),
    )
    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection) -> None:
    context.configure(connection=connection, **_configure_kwargs())
    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations(url: str) -> None:
    connectable = create_async_engine(url, poolclass=pool.NullPool)
    try:
        async with connectable.connect() as connection:
            await connection.run_sync(do_run_migrations)
    finally:
        await connectable.dispose()


def run_sync_migrations(url: str) -> None:
    connectable = create_engine(url, poolclass=pool.NullPool)
    try:
        with connectable.connect() as connection:
            do_run_migrations(connection)
    finally:
        connectable.dispose()


def run_migrations_online() -> None:
    """Run migrations against a live database.

    Both sync and async drivers are supported. The app itself is async-only, but
    migrations gain nothing from async, and a sync driver avoids the greenlet
    dependency -- which matters for running these from a workstation.
    """
    url = _database_url()
    if make_url(url).get_dialect().is_async:
        asyncio.run(run_async_migrations(url))
    else:
        run_sync_migrations(url)


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
