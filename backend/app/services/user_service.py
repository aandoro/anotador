from datetime import datetime, timezone
from typing import Optional
from fastapi import HTTPException, status
from app.repositories.user_repository import UserRepository, get_user_repository
from app.schemas.user import UserProfileResponse, UserProfileUpdateRequest
from app.utils.file_utils import (
    resolve_and_validate_image_mime,
    generate_storage_file_path,
)


class UserService:
    """
    Capa de servicio que orquesta la lógica de negocio para
    perfiles de usuario y gestión de avatares.
    """

    def __init__(self, user_repo: UserRepository = None):
        self.user_repo = user_repo or get_user_repository()

    async def get_profile(self, user_id: str) -> UserProfileResponse:
        """Recupera el perfil de un usuario."""
        profile = self.user_repo.get_profile_by_id(user_id)
        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Perfil de usuario no encontrado",
            )
        return UserProfileResponse(**profile.model_dump())

    async def update_profile(
        self,
        user_id: str,
        payload: UserProfileUpdateRequest,
    ) -> UserProfileResponse:
        """
        Actualiza first_name y last_name del usuario.
        El campo email es inmutable.
        """
        update_data = payload.model_dump(exclude_unset=True)
        if "email" in update_data:
            del update_data["email"]

        if not update_data:
            profile = self.user_repo.get_profile_by_id(user_id)
            if not profile:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Perfil no encontrado",
                )
            return UserProfileResponse(**profile.model_dump())

        update_data["updated_at"] = datetime.now(timezone.utc).isoformat()

        updated_profile = self.user_repo.update_profile(user_id, update_data)
        if not updated_profile:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No se pudo actualizar el perfil",
            )

        return UserProfileResponse(**updated_profile.model_dump())

    async def upload_avatar(
        self,
        user_id: str,
        file_bytes: bytes,
        filename: Optional[str],
        content_type: Optional[str],
    ) -> UserProfileResponse:
        """
        Valida el formato/tamaño del archivo, lo almacena en el bucket
        y actualiza la URL pública en el perfil.
        """
        resolved_mime = resolve_and_validate_image_mime(
            content_type=content_type,
            filename=filename,
            file_bytes=file_bytes,
        )
        storage_path = generate_storage_file_path(user_id, filename)

        try:
            self.user_repo.upload_avatar(
                storage_path=storage_path,
                file_bytes=file_bytes,
                content_type=resolved_mime,
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al subir imagen al bucket de Storage: {str(e)}",
            )

        public_url = self.user_repo.get_avatar_public_url(storage_path)

        updated_profile = self.user_repo.update_profile(
            user_id=user_id,
            update_data={
                "profile_image_url": public_url,
                "updated_at": datetime.now(timezone.utc).isoformat(),
            },
        )

        if not updated_profile:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Imagen subida pero no se pudo actualizar el perfil",
            )

        return UserProfileResponse(**updated_profile.model_dump())


# Helper para inyección de dependencias en FastAPI
def get_user_service() -> UserService:
    return UserService()
