from typing import AsyncGenerator
from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import AsyncSessionLocal
from app.redis import get_redis_client

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()

async def get_redis() -> AsyncGenerator[Redis, None]:
    redis = get_redis_client()
    try:
        yield redis
    finally:
        await redis.close()
