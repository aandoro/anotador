from fastapi import APIRouter, Depends, status
from app.services.auth_service import AuthService, get_auth_service
from app.schemas.auth import (
    UserRegisterRequest,
    UserLoginRequest,
    RefreshTokenRequest,
    TokenResponse,
    ForgotPasswordRequest,
    ResetPasswordRequest,
    MessageResponse,
)

router = APIRouter()


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register_user(
    payload: UserRegisterRequest,
    service: AuthService = Depends(get_auth_service),
):
    """Registra un nuevo usuario y retorna los tokens junto con el perfil."""
    return await service.register(payload)


@router.post("/login", response_model=TokenResponse, status_code=status.HTTP_200_OK)
async def login_user(
    payload: UserLoginRequest,
    service: AuthService = Depends(get_auth_service),
):
    """Autentica al usuario en Supabase Auth o modo mock y retorna los tokens."""
    return await service.login(payload)


@router.post("/refresh", response_model=TokenResponse, status_code=status.HTTP_200_OK)
async def refresh_token(
    payload: RefreshTokenRequest,
    service: AuthService = Depends(get_auth_service),
):
    """Renueva el token de acceso utilizando un refresh token válido."""
    return await service.refresh_token(payload)


@router.post("/forgot-password", response_model=MessageResponse, status_code=status.HTTP_200_OK)
async def forgot_password(
    payload: ForgotPasswordRequest,
    service: AuthService = Depends(get_auth_service),
):
    """Envía solicitud de restablecimiento de contraseña al correo indicado."""
    return await service.forgot_password(payload.email)


@router.post("/reset-password", response_model=MessageResponse, status_code=status.HTTP_200_OK)
async def reset_password(
    payload: ResetPasswordRequest,
    service: AuthService = Depends(get_auth_service),
):
    """Restablece la contraseña utilizando el código OTP o token recibido."""
    return await service.reset_password(payload.token, payload.new_password)