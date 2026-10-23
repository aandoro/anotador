from typing import Optional
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field


class UserProfileResponse(BaseModel):
    id: str
    email: str
    first_name: str
    last_name: str
    role: str
    profile_image_url: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class UserProfileUpdateRequest(BaseModel):
    """
    Esquema para actualización de perfil.
    REGLA ESTRICTA: El campo 'email' NO es aceptado ni editable.
    extra='forbid' rechaza cualquier intento de enviar 'email' con error 422.
    """
    first_name: Optional[str] = Field(None, min_length=1, max_length=100)
    last_name: Optional[str] = Field(None, min_length=1, max_length=100)

    model_config = ConfigDict(extra="forbid")