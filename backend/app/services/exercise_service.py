import asyncio
from typing import List
from fastapi import HTTPException, status
from app.repositories.exercise_repository import (
    ExerciseRepository,
    get_exercise_repository,
)
from app.schemas.exercise import ExerciseResponse


class ExerciseService:
    """
    Capa de servicio que orquesta la búsqueda y normalización de ejercicios.
    """

    def __init__(self, exercise_repo: ExerciseRepository = None):
        self.exercise_repo = exercise_repo or get_exercise_repository()

    async def search_exercises(self, query: str) -> List[ExerciseResponse]:
        """
        Busca ejercicios coincidentes por nombre con un mínimo de 3 caracteres.
        """
        trimmed = query.strip()
        if len(trimmed) < 3:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El término de búsqueda debe tener al menos 3 caracteres",
            )

        models = await asyncio.to_thread(self.exercise_repo.search_by_name, trimmed)
        return [ExerciseResponse(**model.model_dump()) for model in models]

    async def create_exercise(self, name: str) -> ExerciseResponse:
        """
        Crea un nuevo ejercicio en el catálogo validando longitud mínima y evitando duplicados.
        """
        clean_name = name.strip()
        if len(clean_name) < 2:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="El nombre del ejercicio debe tener al menos 2 caracteres",
            )

        try:
            model = await asyncio.to_thread(self.exercise_repo.create, clean_name)
            return ExerciseResponse(id=model.id, name=model.name)
        except (ValueError, Exception) as e:
            err_str = str(e).lower()
            if "duplicate" in err_str or "unique" in err_str or "ya existe" in err_str:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"El ejercicio '{clean_name}' ya existe en el catálogo",
                )
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Error al registrar el ejercicio: {str(e)}",
            )

    async def seed_default_exercises(self) -> int:
        """
        Puebla la base de datos con el catálogo inicial de ejercicios estándar.
        """
        return await asyncio.to_thread(self.exercise_repo.seed_defaults)


def get_exercise_service() -> ExerciseService:
    return ExerciseService()
