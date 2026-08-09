"""add uq_author_business_review

Revision ID: a1b2c3d4e5f6
Revises: 8d3b69ac7c38
Create Date: 2026-08-09 12:30:00.000000
"""

from collections.abc import Sequence

from alembic import op


revision: str = "a1b2c3d4e5f6"
down_revision: str | None = "8d3b69ac7c38"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_unique_constraint(
        "uq_author_business_review",
        "reviews",
        ["author_id", "business_id"],
    )


def downgrade() -> None:
    op.drop_constraint("uq_author_business_review", "reviews", type_="unique")
