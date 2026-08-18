"""one in-app notice per user+scenario; prune duplicate notification rows

Revision ID: j4k5l6m7n8o9
Revises: i3j4k5l6m7n8
Create Date: 2026-08-18 11:28:00.000000

Touches `notifications` only — not businesses, photos, or addresses.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "j4k5l6m7n8o9"
down_revision: str | None = "i3j4k5l6m7n8"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column("notifications", sa.Column("scenario", sa.String(length=64), nullable=True))
    op.execute(
        sa.text(
            """
            UPDATE notifications SET scenario = CASE
              WHEN type::text IN ('REVIEW', 'review') THEN 'new_review'
              WHEN type::text IN ('APPROVAL', 'approval')
                   AND title ILIKE '%WhatsApp%' THEN 'whatsapp_applied'
              WHEN type::text IN ('APPROVAL', 'approval') THEN 'listing_approved'
              WHEN type::text IN ('SYSTEM', 'system')
                   AND title ILIKE '%WhatsApp%' THEN 'whatsapp_rejected'
              WHEN type::text IN ('SYSTEM', 'system')
                   AND (title ILIKE '%boost%' OR title ILIKE '%Featured%')
                   THEN 'payment_boost_approved'
              WHEN type::text IN ('SYSTEM', 'system')
                   AND title ILIKE '%payment%' THEN 'payment_captured'
              ELSE 'listing_approved'
            END
            WHERE scenario IS NULL OR scenario = ''
            """
        )
    )
    op.execute(
        sa.text(
            """
            DELETE FROM notifications n
            WHERE n.id NOT IN (
              SELECT DISTINCT ON (user_id, scenario) id
              FROM notifications
              ORDER BY user_id, scenario, created_at DESC, id DESC
            )
            """
        )
    )
    op.alter_column("notifications", "scenario", existing_type=sa.String(length=64), nullable=False)
    op.create_unique_constraint("uq_user_notification_scenario", "notifications", ["user_id", "scenario"])


def downgrade() -> None:
    op.drop_constraint("uq_user_notification_scenario", "notifications", type_="unique")
    op.drop_column("notifications", "scenario")
