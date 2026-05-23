"""add status to media table

Revision ID: 0006
Revises: 0005
Create Date: 2026-05-23 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '0006'
down_revision: Union[str, None] = '0005'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create Enum
    sa.Enum('pending', 'confirmed', 'error', name='media_status_enum').create(op.get_bind())

    # Add Column
    op.add_column('media', sa.Column('status', postgresql.ENUM('pending', 'confirmed', 'error', name='media_status_enum', create_type=False), server_default='pending', nullable=False))


def downgrade() -> None:
    # Drop Column
    op.drop_column('media', 'status')

    # Drop Enum
    sa.Enum(name='media_status_enum').drop(op.get_bind())
