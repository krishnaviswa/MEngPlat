"""add external_platform_refs to businesses and external_reviews table

Revision ID: h1i2j3k4l5m6
Revises: g0h1i2j3k4l5
Create Date: 2026-08-16 10:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "h1i2j3k4l5m6"
down_revision: str | None = "g0h1i2j3k4l5"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # Nullable, no default -- an unlinked business has external_platform_refs
    # IS NULL, not {}. No backfill needed (additive/nullable).
    op.add_column("businesses", sa.Column("external_platform_refs", postgresql.JSONB(), nullable=True))

    op.create_table(
        "external_reviews",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "business_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("businesses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("source", sa.String(length=50), nullable=False),
        sa.Column("external_review_id", sa.String(length=255), nullable=False),
        sa.Column("author_name", sa.String(length=255), nullable=False),
        sa.Column("author_photo_url", sa.String(length=512), nullable=True),
        sa.Column("rating", sa.Integer(), nullable=False),
        sa.Column("body", sa.Text(), nullable=True),
        sa.Column("language", sa.String(length=10), nullable=True),
        sa.Column("source_url", sa.String(length=512), nullable=True),
        sa.Column("external_posted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("raw_response", postgresql.JSONB(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            onupdate=sa.func.now(),
        ),
    )
    op.create_index("ix_external_reviews_business_id", "external_reviews", ["business_id"])
    op.create_unique_constraint(
        "uq_external_review_source_id",
        "external_reviews",
        ["business_id", "source", "external_review_id"],
    )


def downgrade() -> None:
    op.drop_constraint("uq_external_review_source_id", "external_reviews", type_="unique")
    op.drop_index("ix_external_reviews_business_id", table_name="external_reviews")
    op.drop_table("external_reviews")
    op.drop_column("businesses", "external_platform_refs")
