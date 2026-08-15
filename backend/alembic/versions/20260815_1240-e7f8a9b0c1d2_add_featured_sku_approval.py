"""add featured sku columns and approval timestamps on payments

Revision ID: e7f8a9b0c1d2
Revises: d5e6f7a8b9c0
Create Date: 2026-08-15 12:40:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "e7f8a9b0c1d2"
down_revision: str | None = "d5e6f7a8b9c0"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "payments",
        sa.Column("sku_code", sa.String(length=32), nullable=False, server_default="featured_7d"),
    )
    op.add_column(
        "payments",
        sa.Column("duration_days", sa.Integer(), nullable=False, server_default="7"),
    )
    op.add_column("payments", sa.Column("approved_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("payments", sa.Column("rejected_at", sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column("payments", "rejected_at")
    op.drop_column("payments", "approved_at")
    op.drop_column("payments", "duration_days")
    op.drop_column("payments", "sku_code")
