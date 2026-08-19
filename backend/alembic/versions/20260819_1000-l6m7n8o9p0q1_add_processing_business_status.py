"""add processing business status (S-079)

Revision ID: l6m7n8o9p0q1
Revises: k5l6m7n8o9p0
Create Date: 2026-08-19 10:00:00.000000

Additive enum value only -- no existing row is altered or backfilled; PROCESSING
is reachable only via the new POST /businesses/{id}/start-review endpoint.

Note: the `businesses.status` column has no `values_callable` override
(`app/models/__init__.py`), so SQLAlchemy's default Enum(BusinessStatus) type persists
Python enum *member names*, not `.value` -- the initial migration's raw
`sa.Enum('PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED', name='businessstatus')` confirms
the native Postgres type stores uppercase names. The new label must match that
convention (PROCESSING, not processing).
"""

from collections.abc import Sequence

from alembic import op

revision: str = "l6m7n8o9p0q1"
down_revision: str | None = "k5l6m7n8o9p0"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute("ALTER TYPE businessstatus ADD VALUE IF NOT EXISTS 'PROCESSING' AFTER 'PENDING'")


def downgrade() -> None:
    # Postgres cannot DROP a single enum value; downgrade is a documented no-op,
    # matching this repo's existing precedent for additive enum values (ADR-013's
    # aadhaar migration has the same limitation).
    pass
