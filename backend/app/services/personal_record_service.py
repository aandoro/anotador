import asyncio
from typing import List, Dict, Any, Optional
from fastapi import HTTPException, status
from app.repositories.personal_record_repository import (
    PersonalRecordRepository,
    get_personal_record_repository,
)
from app.schemas.personal_record import (
    PersonalRecordCreateRequest,
    PersonalRecordUpdateRequest,
    PersonalRecordResponse,
    ProgressionPoint,
    ProgressionGroupResponse,
)


class PersonalRecordService:
    """
    Capa de servicio que orquesta la lógica de negocio y validación de Récords Personales.
    PROHIBIDO interactuar directamente con Supabase (debe consumir el repositorio).
    """

    def __init__(self, record_repo: PersonalRecordRepository = None):
        self.record_repo = record_repo or get_personal_record_repository()

    async def get_user_records(self, user_id: str) -> List[PersonalRecordResponse]:
        """
        Obtiene los récords personales pertenecientes al usuario autenticado.
        """
        models = await asyncio.to_thread(self.record_repo.list_by_user_id, user_id)
        return [PersonalRecordResponse(**model.model_dump()) for model in models]

    async def create_record(
        self,
        user_id: str,
        payload: PersonalRecordCreateRequest,
    ) -> PersonalRecordResponse:
        """
        Valida y registra un nuevo PR vinculado al usuario autenticado.
        """
        if payload.weight_kg <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El peso levantado debe ser mayor a 0 kg",
            )
        if payload.reps < 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="La cantidad de repeticiones debe ser al menos 1",
            )

        record_dict = {
            "user_id": user_id,
            "exercise_name": payload.exercise_name.strip(),
            "exercise_id": payload.exercise_id,
            "weight_kg": float(payload.weight_kg),
            "reps": int(payload.reps),
            "record_date": payload.record_date,
            "notes": payload.notes.strip() if payload.notes else None,
        }

        try:
            model = await asyncio.to_thread(self.record_repo.create, record_dict)
            return PersonalRecordResponse(**model.model_dump())
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al registrar el récord personal: {str(e)}",
            )

    async def update_record(
        self,
        record_id: str,
        user_id: str,
        payload: PersonalRecordUpdateRequest,
    ) -> PersonalRecordResponse:
        """
        Valida propiedad y actualiza un récord personal existente del usuario autenticado.
        """
        existing = await asyncio.to_thread(self.record_repo.get_by_id, record_id)
        if not existing or existing.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Récord personal no encontrado",
            )

        if payload.weight_kg is not None and payload.weight_kg <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El peso levantado debe ser mayor a 0 kg",
            )
        if payload.reps is not None and payload.reps < 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="La cantidad de repeticiones debe ser al menos 1",
            )

        update_dict = payload.model_dump(exclude_unset=True)
        if "exercise_name" in update_dict and update_dict["exercise_name"]:
            update_dict["exercise_name"] = update_dict["exercise_name"].strip()
        if "notes" in update_dict and update_dict["notes"]:
            update_dict["notes"] = update_dict["notes"].strip()

        if not update_dict:
            return PersonalRecordResponse(**existing.model_dump())

        try:
            updated_model = await asyncio.to_thread(
                self.record_repo.update, record_id, user_id, update_dict
            )
            if not updated_model:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Récord personal no encontrado",
                )
            return PersonalRecordResponse(**updated_model.model_dump())
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al actualizar el récord personal: {str(e)}",
            )

    async def delete_record(self, record_id: str, user_id: str) -> None:
        """
        Valida propiedad y elimina un récord personal existente del usuario autenticado.
        """
        existing = await asyncio.to_thread(self.record_repo.get_by_id, record_id)
        if not existing or existing.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Récord personal no encontrado",
            )

        try:
            deleted = await asyncio.to_thread(self.record_repo.delete, record_id, user_id)
            if not deleted:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Récord personal no encontrado",
                )
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al eliminar el récord personal: {str(e)}",
            )

    async def get_progression_summary(self, user_id: str) -> List[ProgressionGroupResponse]:
        """
        Agrupa los récords del usuario por ejercicio y repeticiones,
        calculando el PR máximo, el peso anterior, la diferencia (delta) y el historial ordenado cronológicamente.
        """
        models = await asyncio.to_thread(self.record_repo.list_by_user_id, user_id)
        if not models:
            return []

        # Agrupación por (nombre_normalizado, reps)
        groups_dict: Dict[tuple, Dict[str, Any]] = {}
        for m in models:
            norm_name = m.exercise_name.strip()
            key = (norm_name.lower(), m.reps)
            if key not in groups_dict:
                groups_dict[key] = {
                    "exercise_name": norm_name,
                    "exercise_id": m.exercise_id,
                    "reps": m.reps,
                    "items": [],
                }
            groups_dict[key]["items"].append(m)

        result: List[ProgressionGroupResponse] = []
        for group in groups_dict.values():
            # Orden cronológico ascendente por record_date y created_at
            sorted_items = sorted(
                group["items"],
                key=lambda x: (x.record_date, x.created_at.isoformat() if x.created_at else ""),
            )
            history = [
                ProgressionPoint(record_date=item.record_date, weight_kg=item.weight_kg)
                for item in sorted_items
            ]
            current_max = max(item.weight_kg for item in sorted_items)

            previous_weight: Optional[float] = None
            delta_kg: Optional[float] = None
            if len(sorted_items) >= 2:
                previous_weight = sorted_items[-2].weight_kg
                delta_kg = round(sorted_items[-1].weight_kg - previous_weight, 2)

            result.append(
                ProgressionGroupResponse(
                    exercise_name=group["exercise_name"],
                    exercise_id=group["exercise_id"],
                    reps=group["reps"],
                    current_pr_weight=current_max,
                    previous_weight=previous_weight,
                    delta_kg=delta_kg,
                    history=history,
                )
            )

        # Ordenar los grupos alfabéticamente por ejercicio y repeticiones
        result.sort(key=lambda g: (g.exercise_name.lower(), g.reps))
        return result


def get_personal_record_service() -> PersonalRecordService:
    return PersonalRecordService()

