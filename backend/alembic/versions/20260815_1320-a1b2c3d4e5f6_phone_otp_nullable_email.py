"""nullable email for phone-only users; unique phone when present

Revision ID: a1b2c3d4e5f6
Revises: f8a9b0c1d2e3
Create Date: 2026-08-15 13:20:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "g0h1i2j3k4l5"
down_revision: str | None = "f8a9b0c1d2e3"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.alter_column("users", "email", existing_type=sa.String(length=255), nullable=True)
    op.create_index(
        "uq_users_phone_not_null",
        "users",
        ["phone"],
        unique=True,
        postgresql_where=sa.text("phone IS NOT NULL"),
    )


def downgrade() -> None:
    op.drop_index("uq_users_phone_not_null", table_name="users")
    op.alter_column("users", "email", existing_type=sa.String(length=255), nullable=False)
