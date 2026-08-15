"""add payments and featured_placements

Revision ID: d5e6f7a8b9c0
Revises: c3d4e5f6a7b8
Create Date: 2026-08-15 10:37:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "d5e6f7a8b9c0"
down_revision: str | None = "c3d4e5f6a7b8"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

payment_status = sa.Enum("CREATED", "PAID", "FAILED", "REFUNDED", name="paymentstatus")


def upgrade() -> None:
    payment_status.create(op.get_bind(), checkfirst=True)
    op.create_table(
        "payments",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("business_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("businesses.id", ondelete="CASCADE"), nullable=False),
        sa.Column("merchant_user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("provider", sa.String(length=20), nullable=False),
        sa.Column("provider_order_id", sa.String(length=255), nullable=False),
        sa.Column("provider_payment_id", sa.String(length=255), nullable=True),
        sa.Column("status", payment_status, nullable=False),
        sa.Column("amount_paise", sa.Integer(), nullable=False),
        sa.Column("currency", sa.String(length=8), nullable=False),
        sa.Column("platform_fee_paise", sa.Integer(), nullable=True),
        sa.Column("gateway_fee_paise", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_payments_business_id", "payments", ["business_id"])
    op.create_index("ix_payments_merchant_user_id", "payments", ["merchant_user_id"])
    op.create_index("ix_payments_provider_order_id", "payments", ["provider_order_id"], unique=True)

    op.create_table(
        "featured_placements",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("business_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("businesses.id", ondelete="CASCADE"), nullable=False),
        sa.Column("payment_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("payments.id", ondelete="CASCADE"), nullable=False),
        sa.Column("starts_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ends_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("disabled_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_featured_placements_business_id", "featured_placements", ["business_id"])
    op.create_index("ix_featured_placements_payment_id", "featured_placements", ["payment_id"], unique=True)


def downgrade() -> None:
    op.drop_index("ix_featured_placements_payment_id", table_name="featured_placements")
    op.drop_index("ix_featured_placements_business_id", table_name="featured_placements")
    op.drop_table("featured_placements")
    op.drop_index("ix_payments_provider_order_id", table_name="payments")
    op.drop_index("ix_payments_merchant_user_id", table_name="payments")
    op.drop_index("ix_payments_business_id", table_name="payments")
    op.drop_table("payments")
    payment_status.drop(op.get_bind(), checkfirst=True)
