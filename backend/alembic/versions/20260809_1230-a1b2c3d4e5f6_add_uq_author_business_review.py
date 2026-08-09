"""add uq_author_business_review

Revision ID: a1b2c3d4e5f6
Revises: 8d3b69ac7c38
Create Date: 2026-08-09 12:30:00.000000

Railway / existing DBs may already contain duplicate (author_id, business_id)
rows from before this integrity rule. Deduplicate first, then add the constraint.
"""

from collections.abc import Sequence

from alembic import op
from sqlalchemy import text


revision: str = "a1b2c3d4e5f6"
down_revision: str | None = "8d3b69ac7c38"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # Keep the earliest review per (author_id, business_id); CASCADE removes
    # related ai_analyses / photos / likes / reports / replies on the extras.
    op.execute(
        text(
            """
            DELETE FROM reviews
            WHERE id IN (
                SELECT id FROM (
                    SELECT id,
                           ROW_NUMBER() OVER (
                               PARTITION BY author_id, business_id
                               ORDER BY created_at ASC NULLS LAST, id ASC
                           ) AS rn
                    FROM reviews
                ) ranked
                WHERE rn > 1
            )
            """
        )
    )
    op.create_unique_constraint(
        "uq_author_business_review",
        "reviews",
        ["author_id", "business_id"],
    )


def downgrade() -> None:
    op.drop_constraint("uq_author_business_review", "reviews", type_="unique")
