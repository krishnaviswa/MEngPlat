"""whatsapp_sessions + business_update_drafts

Revision ID: i3j4k5l6m7n8
Revises: h1i2j3k4l5m6
Create Date: 2026-08-16 18:45:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "i3j4k5l6m7n8"
down_revision: str | None = "h1i2j3k4l5m6"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "whatsapp_sessions",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "business_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("businesses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("token", sa.String(length=32), nullable=False),
        sa.Column("phone_e164", sa.String(length=32), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("redeemed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_whatsapp_sessions_business_id", "whatsapp_sessions", ["business_id"])
    op.create_index("ix_whatsapp_sessions_token", "whatsapp_sessions", ["token"], unique=True)
    op.create_index("ix_whatsapp_sessions_phone_e164", "whatsapp_sessions", ["phone_e164"])

    draft_status = postgresql.ENUM("pending", "applied", "discarded", name="draftstatus")
    draft_status.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "business_update_drafts",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "business_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("businesses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("source", sa.String(length=50), nullable=False),
        sa.Column("extracted_fields", postgresql.JSONB(), nullable=False),
        sa.Column(
            "status",
            postgresql.ENUM("pending", "applied", "discarded", name="draftstatus", create_type=False),
            nullable=False,
        ),
        sa.Column("degraded", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            onupdate=sa.func.now(),
        ),
    )
    op.create_index("ix_business_update_drafts_business_id", "business_update_drafts", ["business_id"])


def downgrade() -> None:
    op.drop_index("ix_business_update_drafts_business_id", table_name="business_update_drafts")
    op.drop_table("business_update_drafts")
    op.execute("DROP TYPE IF EXISTS draftstatus")
    op.drop_index("ix_whatsapp_sessions_phone_e164", table_name="whatsapp_sessions")
    op.drop_index("ix_whatsapp_sessions_token", table_name="whatsapp_sessions")
    op.drop_index("ix_whatsapp_sessions_business_id", table_name="whatsapp_sessions")
    op.drop_table("whatsapp_sessions")
