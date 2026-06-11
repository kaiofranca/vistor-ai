from redis.asyncio import Redis, from_url
from app.config import settings

def get_redis_client() -> Redis:
    return from_url(settings.REDIS_URL, encoding="utf-8", decode_responses=True)
