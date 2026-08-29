"""partners + partner_merchant_links + partner_review_requests; reviews.source / verified_purchase (S-123)

Revision ID: n8o9p0q1r2s3
Revises: m7n8o9p0q1r2
Create Date: 2026-08-29 12:00:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "n8o9p0q1r2s3"
down_revision: str | None = "m7n8o9p0q1r2"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "partners",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("slug", sa.String(length=50), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("api_key_hash", sa.String(length=64), nullable=False),
        sa.Column("hmac_secret", sa.String(length=128), nullable=False),
        sa.Column("callback_url", sa.String(length=512), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="active"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_partners_slug", "partners", ["slug"], unique=True)
    op.create_index("ix_partners_api_key_hash", "partners", ["api_key_hash"], unique=True)

    op.create_table(
        "partner_merchant_links",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "partner_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("partners.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("partner_merchant_ref", sa.String(length=255), nullable=False),
        sa.Column(
            "business_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("businesses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint("partner_id", "partner_merchant_ref", name="uq_partner_merchant_ref"),
    )
    op.create_index("ix_partner_merchant_links_partner_id", "partner_merchant_links", ["partner_id"])
    op.create_index("ix_partner_merchant_links_business_id", "partner_merchant_links", ["business_id"])

    op.create_table(
        "partner_review_requests",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "partner_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("partners.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "business_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("businesses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("partner_merchant_ref", sa.String(length=255), nullable=False),
        sa.Column("partner_txn_ref", sa.String(length=255), nullable=False),
        sa.Column("partner_customer_ref", sa.String(length=128), nullable=True),
        sa.Column("token", sa.String(length=64), nullable=False),
        sa.Column("channel", sa.String(length=32), nullable=False, server_default="invoice_link"),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="pending"),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("redeemed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "review_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("reviews.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint("partner_id", "partner_txn_ref", name="uq_partner_txn_ref"),
    )
    op.create_index("ix_partner_review_requests_partner_id", "partner_review_requests", ["partner_id"])
    op.create_index("ix_partner_review_requests_business_id", "partner_review_requests", ["business_id"])
    op.create_index(
        "ix_partner_review_requests_partner_customer_ref",
        "partner_review_requests",
        ["partner_customer_ref"],
    )
    op.create_index(
        "ix_partner_review_requests_token", "partner_review_requests", ["token"], unique=True
    )

    op.add_column(
        "reviews",
        sa.Column("source", sa.String(length=20), nullable=False, server_default="organic"),
    )
    op.add_column(
        "reviews",
        sa.Column(
            "verified_purchase", sa.Boolean(), nullable=False, server_default=sa.false()
        ),
    )


def downgrade() -> None:
    op.drop_column("reviews", "verified_purchase")
    op.drop_column("reviews", "source")

    op.drop_index("ix_partner_review_requests_token", table_name="partner_review_requests")
    op.drop_index(
        "ix_partner_review_requests_partner_customer_ref", table_name="partner_review_requests"
    )
    op.drop_index("ix_partner_review_requests_business_id", table_name="partner_review_requests")
    op.drop_index("ix_partner_review_requests_partner_id", table_name="partner_review_requests")
    op.drop_table("partner_review_requests")

    op.drop_index("ix_partner_merchant_links_business_id", table_name="partner_merchant_links")
    op.drop_index("ix_partner_merchant_links_partner_id", table_name="partner_merchant_links")
    op.drop_table("partner_merchant_links")

    op.drop_index("ix_partners_api_key_hash", table_name="partners")
    op.drop_index("ix_partners_slug", table_name="partners")
    op.drop_table("partners")
