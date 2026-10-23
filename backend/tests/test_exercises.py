from fastapi.testclient import TestClient
from app.main import app
from app.repositories.exercise_repository import ExerciseRepository
from app.services.exercise_service import ExerciseService, get_exercise_service
from app.models.exercise import ExerciseModel

client = TestClient(app)


def test_search_exercises_validation_min_length():
    """Verifica que búsquedas de menos de 3 caracteres retornen 422 Unprocessable Entity."""
    res = client.get("/api/v1/exercises?search=se")
    assert res.status_code == 422


def test_search_exercises_success_matching_catalog():
    """Verifica búsqueda exitosa de ejercicios con al menos 3 caracteres."""
    res = client.get("/api/v1/exercises?search=banca")
    assert res.status_code == 200
    data = res.json()
    assert isinstance(data, list)
    assert len(data) > 0
    # Verifica que todos los resultados contengan 'banca' insensible a mayúsculas
    for item in data:
        assert "banca" in item["name"].lower()
        assert "id" in item


def test_search_exercises_empty_when_no_match():
    """Verifica lista vacía cuando no hay coincidencias."""
    res = client.get("/api/v1/exercises?search=inexistente999")
    assert res.status_code == 200
    data = res.json()
    assert data == []


def test_exercise_service_direct_unit():
    """Prueba unitaria directa del ExerciseService."""
    class FakeExerciseRepo(ExerciseRepository):
        def search_by_name(self, query: str, limit: int = 20):
            return [ExerciseModel(id="test-1", name="Sentadilla Búlgara")]

    service = ExerciseService(exercise_repo=FakeExerciseRepo())
    import asyncio
    results = asyncio.run(service.search_exercises("búl"))
    assert len(results) == 1
    assert results[0].name == "Sentadilla Búlgara"


# ==============================================================================
# Pruebas de Autorización y Control de Roles (RBAC: Solo Admin para Creación)
# ==============================================================================
from app.schemas.user import UserProfileResponse
from app.core.security import get_current_user

MOCK_ADMIN = UserProfileResponse(
    id="admin-uuid-123",
    email="admin@mio.app",
    first_name="Admin",
    last_name="Sistema",
    role="admin",
    profile_image_url=None,
    created_at=None,
    updated_at=None,
)

MOCK_TRAINER = UserProfileResponse(
    id="trainer-uuid-456",
    email="trainer@mio.app",
    first_name="Carlos",
    last_name="Trainer",
    role="trainer",
    profile_image_url=None,
    created_at=None,
    updated_at=None,
)


def test_create_exercise_unauthorized_without_token():
    """Verifica que POST /api/v1/exercises sin autenticación devuelva 401 o 403."""
    res = client.post("/api/v1/exercises", json={"name": "Clean and Jerk"})
    assert res.status_code in (401, 403)


def test_create_exercise_forbidden_for_trainer():
    """Verifica que un usuario con rol 'trainer' reciba 403 Forbidden al intentar crear un ejercicio."""
    app.dependency_overrides[get_current_user] = lambda: MOCK_TRAINER
    try:
        res = client.post("/api/v1/exercises", json={"name": "Clean and Jerk"})
        assert res.status_code == 403
        assert "administrador" in res.json()["detail"].lower()
    finally:
        app.dependency_overrides.clear()


def test_create_exercise_success_for_admin():
    """Verifica que un usuario con rol 'admin' pueda crear exitosamente un nuevo ejercicio (201 Created)."""
    app.dependency_overrides[get_current_user] = lambda: MOCK_ADMIN
    try:
        res = client.post("/api/v1/exercises", json={"name": "Snatch Olímpico"})
        assert res.status_code == 201
        data = res.json()
        assert data["name"] == "Snatch Olímpico"
        assert "id" in data
    finally:
        app.dependency_overrides.clear()


def test_create_exercise_duplicate_conflict():
    """Verifica que si se intenta crear un ejercicio ya existente, devuelva 409 Conflict."""
    app.dependency_overrides[get_current_user] = lambda: MOCK_ADMIN
    try:
        # 'Sentadilla Trasera' ya existe en el catálogo inicial
        res = client.post("/api/v1/exercises", json={"name": "Sentadilla Trasera"})
        assert res.status_code == 409
        assert "ya existe" in res.json()["detail"].lower()
    finally:
        app.dependency_overrides.clear()


def test_seed_exercises_forbidden_for_trainer():
    """Verifica que un usuario con rol 'trainer' reciba 403 Forbidden al intentar sembrar ejercicios."""
    app.dependency_overrides[get_current_user] = lambda: MOCK_TRAINER
    try:
        res = client.post("/api/v1/exercises/seed")
        assert res.status_code == 403
        assert "administrador" in res.json()["detail"].lower()
    finally:
        app.dependency_overrides.clear()


def test_seed_exercises_success_for_admin():
    """Verifica que un usuario con rol 'admin' pueda ejecutar el sembrado de ejercicios (200 OK)."""
    app.dependency_overrides[get_current_user] = lambda: MOCK_ADMIN
    try:
        res = client.post("/api/v1/exercises/seed")
        assert res.status_code == 200
        data = res.json()
        assert "sembrado exitosamente" in data["message"].lower()
    finally:
        app.dependency_overrides.clear()
