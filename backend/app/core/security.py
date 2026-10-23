from typing import Dict, Any
import jwt
from jwt.exceptions import PyJWTError, ExpiredSignatureError
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.config import settings
from app.core.supabase import supabase_admin_client, get_supabase_admin_client
from app.schemas.user import UserProfileResponse

security = HTTPBearer()


def verify_supabase_jwt(token: str) -> Dict[str, Any]:
    """
    Decodifica y valida la firma del token JWT generado por Supabase Auth
    utilizando SUPABASE_JWT_SECRET con algoritmo HS256.
    """
    if not settings.SUPABASE_JWT_SECRET:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="SUPABASE_JWT_SECRET no configurado en el servidor",
        )
    try:
        payload = jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            options={"verify_aud": False},
        )
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token inválido: falta identificador de usuario (sub)",
                headers={"WWW-Authenticate": "Bearer"},
            )
        return payload
    except ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="El token de acceso ha expirado",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except PyJWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token inválido: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> UserProfileResponse:
    """
    Dependencia FastAPI que extrae el token Bearer, decodifica el 'sub' (User UUID)
    y obtiene el perfil de la tabla public.profiles.
    """
    token = credentials.credentials
    payload = verify_supabase_jwt(token)
    user_id = payload.get("sub")

    from app.repositories.user_repository import get_user_repository

    user_repo = get_user_repository()
    profile = user_repo.get_profile_by_id(user_id)

    if not profile:
        try:
            admin_client = supabase_admin_client or get_supabase_admin_client()
            auth_user_res = admin_client.auth.admin.get_user_by_id(user_id)
            user_obj = auth_user_res.user if hasattr(auth_user_res, "user") else auth_user_res
            meta = getattr(user_obj, "user_metadata", {}) or {}
            fallback_profile = {
                "id": user_id,
                "email": getattr(user_obj, "email", payload.get("email", "")),
                "first_name": meta.get("first_name") or "Usuario",
                "last_name": meta.get("last_name") or "",
                "role": meta.get("role") or "trainer",
                "profile_image_url": meta.get("profile_image_url"),
            }
            profile = user_repo.upsert_profile(fallback_profile)
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Perfil de usuario no encontrado en la base de datos",
            )

    return UserProfileResponse(**profile.model_dump())


def require_admin_user(
    current_user: UserProfileResponse = Depends(get_current_user),
) -> UserProfileResponse:
    """
    Dependencia de autorización que exige que el usuario tenga rol 'admin'.
    Si el usuario no es admin, lanza HTTP 403 Forbidden.
    """
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Se requieren permisos de administrador para realizar esta acción",
        )
    return current_user