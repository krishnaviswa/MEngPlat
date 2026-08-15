"""add aadhaar to nationalidtype

Revision ID: f8a9b0c1d2e3
Revises: e7f8a9b0c1d2
Create Date: 2026-08-15 13:00:00.000000
"""

from collections.abc import Sequence

from alembic import op

revision: str = "f8a9b0c1d2e3"
down_revision: str | None = "e7f8a9b0c1d2"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute("ALTER TYPE nationalidtype ADD VALUE IF NOT EXISTS 'aadhaar'")


def downgrade() -> None:
    # PostgreSQL cannot easily drop an enum value; leave aadhaar in place.
    pass
