from typing import List
from fastapi import APIRouter, Depends, status
from app.core.security import get_current_user
from app.schemas.user import UserProfileResponse
from app.schemas.personal_record import (
    PersonalRecordCreateRequest,
    PersonalRecordUpdateRequest,
    PersonalRecordResponse,
    ProgressionGroupResponse,
)
from app.services.personal_record_service import (
    PersonalRecordService,
    get_personal_record_service,
)

router = APIRouter()


@router.get(
    "/progression",
    response_model=List[ProgressionGroupResponse],
    status_code=status.HTTP_200_OK,
)
async def get_my_records_progression(
    current_user: UserProfileResponse = Depends(get_current_user),
    service: PersonalRecordService = Depends(get_personal_record_service),
):
    """
    Retorna el resumen de progresión de récords del usuario autenticado,
    agrupado por ejercicio y repeticiones, con historial ordenado cronológicamente y deltas.
    """
    return await service.get_progression_summary(current_user.id)


@router.get("", response_model=List[PersonalRecordResponse], status_code=status.HTTP_200_OK)
async def get_my_records(
    current_user: UserProfileResponse = Depends(get_current_user),
    service: PersonalRecordService = Depends(get_personal_record_service),
):
    """
    Retorna la lista de récords personales pertenecientes al usuario autenticado.
    Requiere autenticación obligatoria con Bearer token.
    """
    return await service.get_user_records(current_user.id)


@router.post("", response_model=PersonalRecordResponse, status_code=status.HTTP_201_CREATED)
async def create_my_record(
    payload: PersonalRecordCreateRequest,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: PersonalRecordService = Depends(get_personal_record_service),
):
    """
    Registra un nuevo récord personal vinculado al usuario autenticado.
    Requiere autenticación obligatoria con Bearer token.
    """
    return await service.create_record(current_user.id, payload)


@router.put(
    "/{record_id}",
    response_model=PersonalRecordResponse,
    status_code=status.HTTP_200_OK,
)
async def update_my_record(
    record_id: str,
    payload: PersonalRecordUpdateRequest,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: PersonalRecordService = Depends(get_personal_record_service),
):
    """
    Actualiza un récord personal existente del usuario autenticado.
    Requiere autenticación obligatoria con Bearer token.
    """
    return await service.update_record(record_id, current_user.id, payload)


@router.delete(
    "/{record_id}",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def delete_my_record(
    record_id: str,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: PersonalRecordService = Depends(get_personal_record_service),
):
    """
    Elimina un récord personal existente del usuario autenticado.
    Requiere autenticación obligatoria con Bearer token.
    """
    await service.delete_record(record_id, current_user.id)
    return None
