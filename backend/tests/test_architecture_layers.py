import pytest
from fastapi import HTTPException
from app.models.user import ProfileModel, UserModel
from app.utils.file_utils import (
    resolve_and_validate_image_mime,
    generate_storage_file_path,
    MAX_IMAGE_SIZE_BYTES,
)
from app.services.auth_service import AuthService, get_auth_service
from app.services.user_service import UserService, get_user_service
from app.repositories.auth_repository import AuthRepository
from app.repositories.user_repository import UserRepository


def test_models_profile_and_user_creation():
    """Valida la creación y tipos de las entidades de dominio en app/models."""
    profile = ProfileModel(
        id="user-123",
        email="test@mio.app",
        first_name="Test",
        last_name="User",
        role="trainer",
    )
    assert profile.id == "user-123"
    assert profile.role == "trainer"

    user = UserModel(id="user-123", email="test@mio.app", profile=profile)
    assert user.profile.first_name == "Test"


def test_file_utils_image_validation_valid_and_fallback():
    """Verifica resolución correcta de MIME type y validación de tamaño."""
    # MIME directo
    mime = resolve_and_validate_image_mime("image/png", "avatar.png", b"fakebytes")
    assert mime == "image/png"

    # Fallback por extensión cuando content-type es octet-stream
    fallback_mime = resolve_and_validate_image_mime(
        "application/octet-stream", "foto.webp", b"fakebytes"
    )
    assert fallback_mime == "image/webp"


def test_file_utils_image_validation_invalid_type_and_oversize():
    """Verifica rechazo con HTTPException 400 ante tipos no soportados o tamaño excesivo."""
    # Tipo inválido (pdf)
    with pytest.raises(HTTPException) as exc_type:
        resolve_and_validate_image_mime("application/pdf", "document.pdf", b"fakebytes")
    assert exc_type.value.status_code == 400

    # Tamaño excedido
    oversized_bytes = b"0" * (MAX_IMAGE_SIZE_BYTES + 1)
    with pytest.raises(HTTPException) as exc_size:
        resolve_and_validate_image_mime("image/jpeg", "huge.jpg", oversized_bytes)
    assert exc_size.value.status_code == 400


def test_file_utils_storage_path_generation():
    """Verifica que la ruta generada contenga el user_id y preserve extensión."""
    path = generate_storage_file_path("user-abc-123", "perfil.png")
    assert path.startswith("user-abc-123/")
    assert path.endswith(".png")


def test_services_and_repositories_dependency_injection():
    """Verifica que los servicios instancien e inyecten correctamente los repositorios."""
    auth_service = get_auth_service()
    assert isinstance(auth_service, AuthService)
    assert isinstance(auth_service.auth_repo, AuthRepository)
    assert isinstance(auth_service.user_repo, UserRepository)

    user_service = get_user_service()
    assert isinstance(user_service, UserService)
    assert isinstance(user_service.user_repo, UserRepository)
