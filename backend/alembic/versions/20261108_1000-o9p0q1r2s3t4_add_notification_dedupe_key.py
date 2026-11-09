"""notifications.dedupe_key: one notice per scenario per entity (S-126)

Revision ID: o9p0q1r2s3t4
Revises: n8o9p0q1r2s3
Create Date: 2026-11-08 10:00:00
"""

import sqlalchemy as sa
from alembic import op

revision = "o9p0q1r2s3t4"
down_revision = "n8o9p0q1r2s3"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # '' for every existing row (merchant scenarios keep one row per user+scenario); customer
    # notices carry the review / business id so a second shop never overwrites the first.
    op.add_column(
        "notifications",
        sa.Column("dedupe_key", sa.String(length=64), nullable=False, server_default=""),
    )
    op.drop_constraint("uq_user_notification_scenario", "notifications", type_="unique")
    op.create_unique_constraint(
        "uq_user_notification_scenario_key", "notifications", ["user_id", "scenario", "dedupe_key"]
    )


def downgrade() -> None:
    # Keyed rows are the S-126 customer notices; several per (user, scenario) cannot fit the old
    # constraint. They are transient bell items, not records, so downgrade drops them.
    op.execute(sa.text("DELETE FROM notifications WHERE dedupe_key <> ''"))
    op.drop_constraint("uq_user_notification_scenario_key", "notifications", type_="unique")
    op.drop_column("notifications", "dedupe_key")
    op.create_unique_constraint("uq_user_notification_scenario", "notifications", ["user_id", "scenario"])
