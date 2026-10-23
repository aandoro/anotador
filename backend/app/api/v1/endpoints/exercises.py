from typing import List
from fastapi import APIRouter, Depends, Query, status
from app.services.exercise_service import ExerciseService, get_exercise_service
from app.schemas.exercise import ExerciseCreateRequest, ExerciseResponse
from app.schemas.auth import MessageResponse
from app.schemas.user import UserProfileResponse
from app.core.security import require_admin_user

router = APIRouter()


@router.get("", response_model=List[ExerciseResponse], status_code=status.HTTP_200_OK)
async def search_exercises(
    search: str = Query(
        ...,
        min_length=3,
        description="Término de búsqueda de ejercicios (mínimo 3 caracteres)",
    ),
    service: ExerciseService = Depends(get_exercise_service),
):
    """
    Busca ejercicios en la base de datos que coincidan con el término indicado.
    Requiere un mínimo de 3 caracteres. Abierto a cualquier usuario.
    """
    return await service.search_exercises(search)


@router.post("", response_model=ExerciseResponse, status_code=status.HTTP_201_CREATED)
async def create_exercise(
    payload: ExerciseCreateRequest,
    current_admin: UserProfileResponse = Depends(require_admin_user),
    service: ExerciseService = Depends(get_exercise_service),
):
    """
    Registra un nuevo ejercicio en el catálogo de Supabase.
    SOLO USUARIOS CON ROL ADMIN.
    """
    return await service.create_exercise(payload.name)


@router.post("/seed", response_model=MessageResponse, status_code=status.HTTP_200_OK)
async def seed_exercises(
    current_admin: UserProfileResponse = Depends(require_admin_user),
    service: ExerciseService = Depends(get_exercise_service),
):
    """
    Puebla la base de datos con el catálogo inicial de ejercicios estándar.
    SOLO USUARIOS CON ROL ADMIN.
    """
    count = await service.seed_default_exercises()
    return MessageResponse(
        message=f"Catálogo de ejercicios sembrado exitosamente ({count} registros procesados)"
    )
