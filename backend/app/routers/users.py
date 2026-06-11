from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from app.dependencies.db import get_db
from app.dependencies.auth import get_current_user
from app.models.user import User

router = APIRouter()

class FCMTokenUpdate(BaseModel):
    fcm_token: str

@router.patch("/me/fcm-token", status_code=status.HTTP_204_NO_CONTENT)
async def update_fcm_token(
    payload: FCMTokenUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    current_user.fcm_token = payload.fcm_token
    await db.commit()
    return
