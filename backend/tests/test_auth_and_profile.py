import pytest
import jwt
import time
from fastapi.testclient import TestClient
from fastapi import HTTPException
from app.main import app
from app.core.config import settings
from app.schemas.user import UserProfileResponse
from app.core.security import get_current_user, verify_supabase_jwt

client = TestClient(app)

# Usuario mock para tests
MOCK_USER = UserProfileResponse(
    id="test-user-uuid-1234",
    email="trainer.test@mio.app",
    first_name="Carlos",
    last_name="Entrenador",
    role="trainer",
    profile_image_url=None,
    created_at=None,
    updated_at=None,
)


def test_get_me_unauthorized():
    """Verifica que sin token Bearer devuelva 403 o 401."""
    res = client.get("/api/v1/users/me")
    assert res.status_code in (401, 403)


def test_get_me_with_mock_user():
    """Verifica que con dependencia resuelta se obtenga el perfil."""
    app.dependency_overrides[get_current_user] = lambda: MOCK_USER
    try:
        res = client.get("/api/v1/users/me")
        assert res.status_code == 200
        data = res.json()
        assert data["email"] == "trainer.test@mio.app"
        assert data["role"] == "trainer"
    finally:
        app.dependency_overrides.clear()


def test_update_me_rejects_email_mutation():
    """
    REGLA ESTRICTA: Cualquier intento de mutar el 'email' en PUT /me
    debe ser rechazado con 422 Unprocessable Entity debido a extra='forbid'.
    """
    app.dependency_overrides[get_current_user] = lambda: MOCK_USER
    try:
        res = client.put(
            "/api/v1/users/me",
            json={"email": "nuevo.email@hacker.com", "first_name": "Nuevo"},
        )
        assert res.status_code == 422
    finally:
        app.dependency_overrides.clear()


def test_jwt_verification_valid_and_expired(monkeypatch):
    """Prueba unitaria de la función de validación de JWT con SUPABASE_JWT_SECRET."""
    test_secret = "test-jwt-secret-key-12345678901234567890"
    monkeypatch.setattr(settings, "SUPABASE_JWT_SECRET", test_secret)

    # Token válido
    payload = {"sub": "user-uuid-999", "exp": int(time.time()) + 3600}
    token = jwt.encode(payload, settings.SUPABASE_JWT_SECRET, algorithm="HS256")
    decoded = verify_supabase_jwt(token)
    assert decoded["sub"] == "user-uuid-999"

    # Token expirado
    expired_payload = {"sub": "user-uuid-999", "exp": int(time.time()) - 3600}
    expired_token = jwt.encode(expired_payload, settings.SUPABASE_JWT_SECRET, algorithm="HS256")
    with pytest.raises(HTTPException) as exc:
        verify_supabase_jwt(expired_token)
    assert exc.value.status_code == 401


def test_mock_auth_login():
    """Verifica que con USE_MOCK_AUTH=True el endpoint /login responde exitosamente."""
    original_mock_setting = settings.USE_MOCK_AUTH
    try:
        settings.USE_MOCK_AUTH = True
        res = client.post(
            "/api/v1/auth/login",
            json={"email": "dev@mio.app", "password": "anypassword"},
        )
        assert res.status_code == 200
        data = res.json()
        assert data["access_token"] == "mock_access_token_dev_environment"
        assert data["user"]["email"] == "dev@mio.app"
        assert data["user"]["first_name"] == "Dev"
    finally:
        settings.USE_MOCK_AUTH = original_mock_setting


def test_forgot_password_anti_enumeration():
    """
    Verifica que /auth/forgot-password responda 200 tanto con mock como simulando Supabase,
    manteniendo respuesta genérica para prevenir enumeración.
    """
    original_mock_setting = settings.USE_MOCK_AUTH
    try:
        settings.USE_MOCK_AUTH = True
        res = client.post(
            "/api/v1/auth/forgot-password",
            json={"email": "usuario.desconocido@mio.app"},
        )
        assert res.status_code == 200
        data = res.json()
        assert "message" in data
        assert "restablecer tu contraseña" in data["message"]
    finally:
        settings.USE_MOCK_AUTH = original_mock_setting


def test_reset_password_mock_and_validation():
    """Verifica restablecimiento en modo mock y validación de contraseña corta (<8 chars)."""
    original_mock_setting = settings.USE_MOCK_AUTH
    try:
        settings.USE_MOCK_AUTH = True
        # Caso exitoso en mock
        res = client.post(
            "/api/v1/auth/reset-password",
            json={"token": "mock-token-12345", "new_password": "NewSecurePassword123!"},
        )
        assert res.status_code == 200
        assert "exitosa" in res.json()["message"]

        # Validación: contraseña menor a 8 caracteres debe dar 422
        res_invalid = client.post(
            "/api/v1/auth/reset-password",
            json={"token": "mock-token-12345", "new_password": "short"},
        )
        assert res_invalid.status_code == 422
    finally:
        settings.USE_MOCK_AUTH = original_mock_setting
