"""support_tickets + business_reports (S-088, S-089)

Revision ID: m7n8o9p0q1r2
Revises: l6m7n8o9p0q1
Create Date: 2026-08-19 07:30:00.000000

New tables only. Status columns are strings (ADR-016), not Postgres enums.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "m7n8o9p0q1r2"
down_revision: str | None = "l6m7n8o9p0q1"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "support_tickets",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("phone", sa.String(50), nullable=False),
        sa.Column("issue", sa.Text(), nullable=False),
        sa.Column("business_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("reporter_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("status", sa.String(50), nullable=False, server_default="open"),
        sa.Column("admin_response", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["business_id"], ["businesses.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["reporter_id"], ["users.id"], ondelete="SET NULL"),
    )
    op.create_index("ix_support_tickets_business_id", "support_tickets", ["business_id"])
    op.create_index("ix_support_tickets_reporter_id", "support_tickets", ["reporter_id"])

    op.create_table(
        "business_reports",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("business_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("reporter_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("reason", sa.Text(), nullable=False),
        sa.Column("status", sa.String(50), nullable=False, server_default="open"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["business_id"], ["businesses.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["reporter_id"], ["users.id"], ondelete="CASCADE"),
    )
    op.create_index("ix_business_reports_business_id", "business_reports", ["business_id"])
    op.create_index("ix_business_reports_reporter_id", "business_reports", ["reporter_id"])

    op.create_table(
        "business_report_messages",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("report_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("author_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["report_id"], ["business_reports.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["author_id"], ["users.id"], ondelete="CASCADE"),
    )
    op.create_index("ix_business_report_messages_report_id", "business_report_messages", ["report_id"])


def downgrade() -> None:
    op.drop_index("ix_business_report_messages_report_id", table_name="business_report_messages")
    op.drop_table("business_report_messages")
    op.drop_index("ix_business_reports_reporter_id", table_name="business_reports")
    op.drop_index("ix_business_reports_business_id", table_name="business_reports")
    op.drop_table("business_reports")
    op.drop_index("ix_support_tickets_reporter_id", table_name="support_tickets")
    op.drop_index("ix_support_tickets_business_id", table_name="support_tickets")
    op.drop_table("support_tickets")
