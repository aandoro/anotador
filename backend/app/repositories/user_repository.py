from typing import Optional, Dict, Any
from app.core.config import settings
from app.core.supabase import supabase_admin_client, get_supabase_admin_client
from app.models.user import ProfileModel


class UserRepository:
    """
    Repositorio de datos para entidades de usuario y perfiles.
    Única capa autorizada para consultar la tabla 'profiles' y el Storage de Supabase.
    """

    def __init__(self, admin_client=None):
        self._admin_client = admin_client

    @property
    def admin_client(self):
        return self._admin_client or supabase_admin_client or get_supabase_admin_client()

    def get_profile_by_id(self, user_id: str) -> Optional[ProfileModel]:
        """Obtiene un perfil por ID de usuario desde la tabla profiles."""
        res = self.admin_client.table("profiles").select("*").eq("id", user_id).execute()
        if res.data and len(res.data) > 0:
            return ProfileModel(**res.data[0])
        return None

    def upsert_profile(self, profile_data: Dict[str, Any]) -> ProfileModel:
        """Inserta o actualiza un registro en la tabla profiles."""
        res = self.admin_client.table("profiles").upsert(profile_data).execute()
        if res.data and len(res.data) > 0:
            return ProfileModel(**res.data[0])
        return ProfileModel(**profile_data)

    def update_profile(self, user_id: str, update_data: Dict[str, Any]) -> Optional[ProfileModel]:
        """Actualiza campos específicos de un perfil."""
        res = (
            self.admin_client.table("profiles")
            .update(update_data)
            .eq("id", user_id)
            .execute()
        )
        if res.data and len(res.data) > 0:
            return ProfileModel(**res.data[0])
        return None

    def upload_avatar(
        self,
        storage_path: str,
        file_bytes: bytes,
        content_type: str,
    ) -> None:
        """Sube un archivo de avatar al bucket de Supabase Storage."""
        bucket_name = settings.SUPABASE_AVATARS_BUCKET
        self.admin_client.storage.from_(bucket_name).upload(
            path=storage_path,
            file=file_bytes,
            file_options={"content-type": content_type, "upsert": "true"},
        )

    def get_avatar_public_url(self, storage_path: str) -> str:
        """Obtiene la URL pública del archivo en Storage."""
        bucket_name = settings.SUPABASE_AVATARS_BUCKET
        return self.admin_client.storage.from_(bucket_name).get_public_url(storage_path)


# Instancia por defecto / singleton para inyección de dependencias
user_repository = UserRepository()


def get_user_repository() -> UserRepository:
    return user_repository
