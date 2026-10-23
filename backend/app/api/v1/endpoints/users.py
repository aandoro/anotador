from fastapi import APIRouter, Depends, UploadFile, File
from app.core.security import get_current_user
from app.services.user_service import UserService, get_user_service
from app.schemas.user import UserProfileResponse, UserProfileUpdateRequest

router = APIRouter()


@router.get("/me", response_model=UserProfileResponse)
async def get_my_profile(
    current_user: UserProfileResponse = Depends(get_current_user),
):
    """Retorna el perfil del usuario actualmente autenticado."""
    return current_user


@router.put("/me", response_model=UserProfileResponse)
async def update_my_profile(
    payload: UserProfileUpdateRequest,
    current_user: UserProfileResponse = Depends(get_current_user),
    service: UserService = Depends(get_user_service),
):
    """
    Actualiza first_name y last_name del usuario.
    El campo email es estrictamente inmutable.
    """
    return await service.update_profile(current_user.id, payload)


@router.post("/me/avatar", response_model=UserProfileResponse)
async def upload_my_avatar(
    file: UploadFile = File(...),
    current_user: UserProfileResponse = Depends(get_current_user),
    service: UserService = Depends(get_user_service),
):
    """
    Sube un archivo de imagen (JPG, PNG, WebP) al bucket de Supabase Storage
    y actualiza la URL pública en public.profiles.
    """
    contents = await file.read()
    return await service.upload_avatar(
        user_id=current_user.id,
        file_bytes=contents,
        filename=file.filename,
        content_type=file.content_type,
    )