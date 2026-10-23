import uuid
from typing import List, Dict, Any, Optional
from datetime import datetime
from app.core.config import settings
from app.core.supabase import supabase_admin_client, get_supabase_admin_client
from app.models.personal_record import PersonalRecordModel

# Almacenamiento en memoria para modo mock o fallback en pruebas/desarrollo local
MOCK_PERSONAL_RECORDS: List[Dict[str, Any]] = []


class PersonalRecordRepository:
    """
    Repositorio de datos para récords personales (PRs).
    Única capa autorizada para consultar y modificar la tabla 'personal_records' en Supabase.
    """

    def __init__(self, admin_client=None):
        self._admin_client = admin_client

    @property
    def admin_client(self):
        return self._admin_client or supabase_admin_client or get_supabase_admin_client()

    def list_by_user_id(self, user_id: str) -> List[PersonalRecordModel]:
        """
        Retorna la lista de récords personales pertenecientes al usuario indicado,
        ordenados de forma descendente por fecha de récord.
        """
        if settings.USE_MOCK_AUTH:
            return self._filter_mock_records(user_id)

        try:
            res = (
                self.admin_client.table("personal_records")
                .select("*")
                .eq("user_id", user_id)
                .order("record_date", desc=True)
                .execute()
            )
            if res.data:
                return [PersonalRecordModel(**row) for row in res.data]
            return []
        except Exception:
            # Fallback defensivo ante base de datos inaccesible o en tests
            return self._filter_mock_records(user_id)

    def create(self, record_data: Dict[str, Any]) -> PersonalRecordModel:
        """
        Inserta un nuevo récord personal en Supabase.
        """
        if settings.USE_MOCK_AUTH:
            return self._create_mock_record(record_data)

        try:
            # Asegurar serialización de fechas para Supabase
            payload = dict(record_data)
            if hasattr(payload.get("record_date"), "isoformat"):
                payload["record_date"] = payload["record_date"].isoformat()

            res = (
                self.admin_client.table("personal_records")
                .insert(payload)
                .execute()
            )
            if res.data and len(res.data) > 0:
                created = PersonalRecordModel(**res.data[0])
                # Mantener sincronizado en memoria para consistencia
                MOCK_PERSONAL_RECORDS.append(created.model_dump())
                return created
            raise RuntimeError("No se retornaron datos al registrar el récord personal")
        except Exception:
            # Fallback defensivo ante desconexión o entorno local sin Supabase activo
            return self._create_mock_record(record_data)

    def _create_mock_record(self, record_data: Dict[str, Any]) -> PersonalRecordModel:
        new_data = dict(record_data)
        if "id" not in new_data or not new_data["id"]:
            new_data["id"] = f"pr-{uuid.uuid4().hex[:8]}"
        if "created_at" not in new_data or not new_data["created_at"]:
            new_data["created_at"] = datetime.now()
        model = PersonalRecordModel(**new_data)
        MOCK_PERSONAL_RECORDS.append(model.model_dump())
        return model

    def _filter_mock_records(self, user_id: str) -> List[PersonalRecordModel]:
        user_records = [
            PersonalRecordModel(**r)
            for r in MOCK_PERSONAL_RECORDS
            if r.get("user_id") == user_id
        ]
        # Orden descendente por record_date
        user_records.sort(key=lambda x: x.record_date, reverse=True)
        return user_records

    def get_by_id(self, record_id: str) -> Optional[PersonalRecordModel]:
        """
        Retorna el récord personal por su ID, o None si no existe.
        """
        if settings.USE_MOCK_AUTH:
            return self._find_mock_record(record_id)

        try:
            res = (
                self.admin_client.table("personal_records")
                .select("*")
                .eq("id", record_id)
                .execute()
            )
            if res.data and len(res.data) > 0:
                return PersonalRecordModel(**res.data[0])
            return None
        except Exception:
            return self._find_mock_record(record_id)

    def update(
        self, record_id: str, user_id: str, update_data: Dict[str, Any]
    ) -> Optional[PersonalRecordModel]:
        """
        Actualiza un récord personal verificando que pertenezca al usuario indicado.
        """
        if settings.USE_MOCK_AUTH:
            return self._update_mock_record(record_id, user_id, update_data)

        try:
            payload = dict(update_data)
            if hasattr(payload.get("record_date"), "isoformat"):
                payload["record_date"] = payload["record_date"].isoformat()

            res = (
                self.admin_client.table("personal_records")
                .update(payload)
                .eq("id", record_id)
                .eq("user_id", user_id)
                .execute()
            )
            if res.data and len(res.data) > 0:
                updated = PersonalRecordModel(**res.data[0])
                self._update_mock_record(record_id, user_id, update_data)
                return updated
            return None
        except Exception:
            return self._update_mock_record(record_id, user_id, update_data)

    def delete(self, record_id: str, user_id: str) -> bool:
        """
        Elimina un récord personal verificando que pertenezca al usuario indicado.
        """
        if settings.USE_MOCK_AUTH:
            return self._delete_mock_record(record_id, user_id)

        try:
            self.admin_client.table("personal_records").delete().eq("id", record_id).eq("user_id", user_id).execute()
            self._delete_mock_record(record_id, user_id)
            return True
        except Exception:
            return self._delete_mock_record(record_id, user_id)

    def _find_mock_record(self, record_id: str) -> Optional[PersonalRecordModel]:
        for r in MOCK_PERSONAL_RECORDS:
            if r.get("id") == record_id:
                return PersonalRecordModel(**r)
        return None

    def _update_mock_record(
        self, record_id: str, user_id: str, update_data: Dict[str, Any]
    ) -> Optional[PersonalRecordModel]:
        for i, r in enumerate(MOCK_PERSONAL_RECORDS):
            if r.get("id") == record_id and r.get("user_id") == user_id:
                for k, v in update_data.items():
                    if v is not None:
                        r[k] = v
                updated_model = PersonalRecordModel(**r)
                MOCK_PERSONAL_RECORDS[i] = updated_model.model_dump()
                return updated_model
        return None

    def _delete_mock_record(self, record_id: str, user_id: str) -> bool:
        for i, r in enumerate(MOCK_PERSONAL_RECORDS):
            if r.get("id") == record_id and r.get("user_id") == user_id:
                MOCK_PERSONAL_RECORDS.pop(i)
                return True
        return False


personal_record_repository = PersonalRecordRepository()


def get_personal_record_repository() -> PersonalRecordRepository:
    return personal_record_repository
