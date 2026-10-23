from typing import Optional, Literal
from pydantic import BaseModel, EmailStr
from datetime import datetime


UserRole = Literal["admin", "trainer"]


class ProfileModel(BaseModel):
    id: str
    email: EmailStr
    first_name: str
    last_name: str
    role: UserRole = "trainer"
    profile_image_url: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class UserModel(BaseModel):
    id: str
    email: EmailStr
    profile: Optional[ProfileModel] = None
