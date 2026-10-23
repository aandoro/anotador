import logging
from fastapi import HTTPException, status
from app.core.config import settings
from app.repositories.auth_repository import AuthRepository, get_auth_repository
from app.repositories.user_repository import UserRepository, get_user_repository
from app.schemas.auth import (
    UserRegisterRequest,
    UserLoginRequest,
    RefreshTokenRequest,
    TokenResponse,
    MessageResponse,
)
from app.schemas.user import UserProfileResponse

logger = logging.getLogger(__name__)


class AuthService:
    """
    Capa de servicio que orquesta la lógica de negocio para autenticación,
    soporte de mock auth para desarrollo y recuperación de contraseña.
    """

    def __init__(
        self,
        auth_repo: AuthRepository = None,
        user_repo: UserRepository = None,
    ):
        self.auth_repo = auth_repo or get_auth_repository()
        self.user_repo = user_repo or get_user_repository()

    async def register(self, payload: UserRegisterRequest) -> TokenResponse:
        """Registra un nuevo usuario en Auth y sincroniza su perfil en la base de datos."""
        try:
            auth_response = self.auth_repo.sign_up(
                email=payload.email,
                password=payload.password,
                data={
                    "first_name": payload.first_name,
                    "last_name": payload.last_name,
                    "role": payload.role,
                },
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Error al registrar usuario en Supabase Auth: {str(e)}",
            )

        user = getattr(auth_response, "user", None)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No se pudo crear el usuario.",
            )

        session = getattr(auth_response, "session", None)
        if not session:
            try:
                login_res = self.auth_repo.sign_in_with_password(
                    email=payload.email, password=payload.password
                )
                session = getattr(login_res, "session", None)
            except Exception:
                pass

        access_token = session.access_token if session else ""
        refresh_token = getattr(session, "refresh_token", None) if session else None
        expires_in = getattr(session, "expires_in", None) if session else None

        # Sincronización o recuperación de perfil
        profile = self.user_repo.get_profile_by_id(user.id)
        if not profile:
            fallback_data = {
                "id": user.id,
                "email": payload.email,
                "first_name": payload.first_name,
                "last_name": payload.last_name,
                "role": payload.role,
                "profile_image_url": None,
            }
            profile = self.user_repo.upsert_profile(fallback_data)

        return TokenResponse(
            access_token=access_token,
            token_type="bearer",
            expires_in=expires_in,
            refresh_token=refresh_token,
            user=UserProfileResponse(**profile.model_dump()),
        )

    async def login(self, payload: UserLoginRequest) -> TokenResponse:
        """
        Autentica al usuario. Si USE_MOCK_AUTH está activo,
        retorna un token y usuario de prueba para trabajar sin Supabase.
        """
        if settings.USE_MOCK_AUTH:
            mock_profile = UserProfileResponse(
                id="00000000-0000-0000-0000-000000000001",
                email=payload.email,
                first_name="Dev",
                last_name="Trainer",
                role="trainer",
                profile_image_url=None,
            )
            return TokenResponse(
                access_token="mock_access_token_dev_environment",
                token_type="bearer",
                expires_in=86400,
                refresh_token="mock_refresh_token_dev",
                user=mock_profile,
            )

        try:
            auth_response = self.auth_repo.sign_in_with_password(
                email=payload.email,
                password=payload.password,
            )
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Credenciales incorrectas o usuario no encontrado",
            )

        session = getattr(auth_response, "session", None)
        user = getattr(auth_response, "user", None)

        if not session or not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Credenciales inválidas",
            )

        profile = self.user_repo.get_profile_by_id(user.id)
        if not profile:
            meta = getattr(user, "user_metadata", {}) or {}
            fallback_profile = {
                "id": user.id,
                "email": getattr(user, "email", payload.email),
                "first_name": meta.get("first_name") or "Usuario",
                "last_name": meta.get("last_name") or "",
                "role": meta.get("role") or "trainer",
                "profile_image_url": meta.get("profile_image_url"),
            }
            profile = self.user_repo.upsert_profile(fallback_profile)

        return TokenResponse(
            access_token=session.access_token,
            token_type="bearer",
            expires_in=getattr(session, "expires_in", None),
            refresh_token=getattr(session, "refresh_token", None),
            user=UserProfileResponse(**profile.model_dump()),
        )

    async def refresh_token(self, payload: RefreshTokenRequest) -> TokenResponse:
        """
        Renueva el access token a partir de un refresh token válido.
        Soporta modo mock auth y Supabase Auth en producción.
        """
        if settings.USE_MOCK_AUTH:
            if payload.refresh_token == "invalid_token":
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Refresh token inválido o expirado",
                )
            mock_profile = UserProfileResponse(
                id="00000000-0000-0000-0000-000000000001",
                email="dev.trainer@mio.app",
                first_name="Dev",
                last_name="Trainer",
                role="trainer",
                profile_image_url=None,
            )
            return TokenResponse(
                access_token="mock_access_token_dev_environment_refreshed",
                token_type="bearer",
                expires_in=86400,
                refresh_token="mock_refresh_token_dev_refreshed",
                user=mock_profile,
            )

        try:
            auth_response = self.auth_repo.refresh_session(payload.refresh_token)
        except Exception as exc:
            logger.warning("Fallo al refrescar sesión en Supabase Auth: %s", exc)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token inválido o expirado",
            )

        session = getattr(auth_response, "session", None)
        user = getattr(auth_response, "user", None)

        if not session or not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="No se pudo renovar la sesión con el token provisto",
            )

        profile = self.user_repo.get_profile_by_id(user.id)
        if not profile:
            meta = getattr(user, "user_metadata", {}) or {}
            fallback_profile = {
                "id": user.id,
                "email": getattr(user, "email", ""),
                "first_name": meta.get("first_name") or "Usuario",
                "last_name": meta.get("last_name") or "",
                "role": meta.get("role") or "trainer",
                "profile_image_url": meta.get("profile_image_url"),
            }
            profile = self.user_repo.upsert_profile(fallback_profile)

        return TokenResponse(
            access_token=session.access_token,
            token_type="bearer",
            expires_in=getattr(session, "expires_in", None),
            refresh_token=getattr(session, "refresh_token", None) or payload.refresh_token,
            user=UserProfileResponse(**profile.model_dump()),
        )

    async def forgot_password(self, email: str) -> MessageResponse:
        """
        Envía enlace de restablecimiento garantizando respuesta idéntica
        para mitigar enumeración de cuentas.
        """
        generic_msg = (
            "Si el correo está registrado, recibirás un enlace o código "
            "para restablecer tu contraseña."
        )
        if settings.USE_MOCK_AUTH:
            return MessageResponse(message=generic_msg)

        try:
            self.auth_repo.reset_password_for_email(email)
        except Exception:
            pass

        return MessageResponse(message=generic_msg)

    async def reset_password(self, token: str, new_password: str) -> MessageResponse:
        """Verifica token y actualiza la contraseña del usuario."""
        if settings.USE_MOCK_AUTH:
            return MessageResponse(message="Contraseña restablecida exitosamente.")

        try:
            verify_res = self.auth_repo.verify_otp(token=token, otp_type="recovery")
            if verify_res and getattr(verify_res, "session", None):
                self.auth_repo.update_user({"password": new_password})
            else:
                raise ValueError("Token inválido o expirado")
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"No se pudo restablecer la contraseña: {str(e)}",
            )

        return MessageResponse(message="Contraseña restablecida exitosamente.")


# Helper para inyección de dependencias en FastAPI
def get_auth_service() -> AuthService:
    return AuthService()
