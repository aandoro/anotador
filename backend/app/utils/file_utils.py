import uuid
from typing import Optional
from fastapi import HTTPException, status

ALLOWED_IMAGE_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024  # 5 MB


def resolve_and_validate_image_mime(
    content_type: Optional[str],
    filename: Optional[str],
    file_bytes: bytes,
) -> str:
    """
    Resuelve el MIME type considerando fallback por extensión
    y valida que esté dentro de los formatos permitidos y tamaño máximo.
    """
    resolved_type = content_type
    if (resolved_type == "application/octet-stream" or not resolved_type) and filename:
        ext = filename.split(".")[-1].lower()
        mapping = {
            "jpg": "image/jpeg",
            "jpeg": "image/jpeg",
            "png": "image/png",
            "webp": "image/webp",
        }
        resolved_type = mapping.get(ext, resolved_type)

    if resolved_type not in ALLOWED_IMAGE_MIME_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Formato no permitido ({resolved_type}). Solo JPG, PNG y WebP.",
        )

    if len(file_bytes) > MAX_IMAGE_SIZE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="La imagen excede el tamaño máximo permitido de 5 MB.",
        )

    return resolved_type


def generate_storage_file_path(user_id: str, filename: Optional[str]) -> str:
    """Genera una ruta única para Supabase Storage: <user_id>/<unique_id>.<ext>."""
    file_ext = filename.split(".")[-1].lower() if filename and "." in filename else "jpg"
    unique_name = f"{uuid.uuid4().hex}.{file_ext}"
    return f"{user_id}/{unique_name}"
