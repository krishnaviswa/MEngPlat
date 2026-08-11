"""add user profile fields and totp mfa

Revision ID: c3d4e5f6a7b8
Revises: b2c3d4e5f6a7
Create Date: 2026-08-11 16:40:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "c3d4e5f6a7b8"
down_revision: str | None = "b2c3d4e5f6a7"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

national_id_type = sa.Enum("pan", "other", name="nationalidtype")


def upgrade() -> None:
    national_id_type.create(op.get_bind(), checkfirst=True)
    op.add_column("users", sa.Column("phone", sa.String(length=50), nullable=True))
    op.add_column("users", sa.Column("address_line1", sa.String(length=255), nullable=True))
    op.add_column("users", sa.Column("address_line2", sa.String(length=255), nullable=True))
    op.add_column("users", sa.Column("city", sa.String(length=100), nullable=True))
    op.add_column("users", sa.Column("state", sa.String(length=100), nullable=True))
    op.add_column("users", sa.Column("postal_code", sa.String(length=20), nullable=True))
    op.add_column("users", sa.Column("country", sa.String(length=100), nullable=True))
    op.add_column("users", sa.Column("national_id_type", national_id_type, nullable=True))
    op.add_column("users", sa.Column("national_id_number", sa.String(length=64), nullable=True))
    op.add_column("users", sa.Column("totp_secret", sa.String(length=512), nullable=True))
    op.add_column(
        "users",
        sa.Column("totp_enabled", sa.Boolean(), nullable=False, server_default=sa.false()),
    )


def downgrade() -> None:
    op.drop_column("users", "totp_enabled")
    op.drop_column("users", "totp_secret")
    op.drop_column("users", "national_id_number")
    op.drop_column("users", "national_id_type")
    op.drop_column("users", "country")
    op.drop_column("users", "postal_code")
    op.drop_column("users", "state")
    op.drop_column("users", "city")
    op.drop_column("users", "address_line2")
    op.drop_column("users", "address_line1")
    op.drop_column("users", "phone")
    national_id_type.drop(op.get_bind(), checkfirst=True)
