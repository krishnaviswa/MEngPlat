"""add businesses.address_edit_count (S-073)

Revision ID: k5l6m7n8o9p0
Revises: j4k5l6m7n8o9
Create Date: 2026-08-18 15:00:00.000000

Additive column, no backfill needed -- existing rows default to 0 (no
address edits yet through the new gated PATCH path).
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "k5l6m7n8o9p0"
down_revision: str | None = "j4k5l6m7n8o9"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "businesses",
        sa.Column("address_edit_count", sa.Integer(), nullable=False, server_default="0"),
    )


def downgrade() -> None:
    op.drop_column("businesses", "address_edit_count")
