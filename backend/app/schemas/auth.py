from typing import Optional, Literal
from pydantic import BaseModel, EmailStr, Field, field_validator
from app.schemas.user import UserProfileResponse


class UserRegisterRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6, description="Contraseña de al menos 6 caracteres")
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    role: Literal["admin", "trainer"] = "trainer"


class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str


class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(..., min_length=1, description="Refresh token para renovar la sesión")

    @field_validator("refresh_token")
    @classmethod
    def clean_refresh_token(cls, v: str) -> str:
        trimmed = v.strip()
        if not trimmed:
            raise ValueError("El refresh token no puede estar vacío.")
        return trimmed


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str = Field(..., min_length=1, description="Token o código de verificación")
    new_password: str = Field(..., min_length=8, description="Nueva contraseña (mínimo 8 caracteres)")

    @field_validator("token")
    @classmethod
    def clean_token(cls, v: str) -> str:
        return v.strip()


class MessageResponse(BaseModel):
    message: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: Optional[int] = None
    refresh_token: Optional[str] = None
    user: UserProfileResponse