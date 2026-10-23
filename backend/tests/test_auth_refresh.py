import asyncio
from unittest.mock import MagicMock
import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.core.config import settings
from app.services.auth_service import AuthService
from app.schemas.auth import RefreshTokenRequest
from app.models.user import ProfileModel, UserModel
from fastapi import HTTPException

client = TestClient(app)


def test_refresh_token_endpoint_success_mock(monkeypatch):
    """Valida 200 OK con mock auth habilitado."""
    monkeypatch.setattr(settings, "USE_MOCK_AUTH", True)
    res = client.post("/api/v1/auth/refresh", json={"refresh_token": "valid_mock_token"})
    assert res.status_code == 200
    data = res.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"
    assert data["user"]["email"] == "dev.trainer@mio.app"


def test_refresh_token_endpoint_invalid_token(monkeypatch):
    """Valida 401 Unauthorized ante un refresh_token inválido."""
    monkeypatch.setattr(settings, "USE_MOCK_AUTH", True)
    res = client.post("/api/v1/auth/refresh", json={"refresh_token": "invalid_token"})
    assert res.status_code == 401
    assert "inválido" in res.json()["detail"].lower()


def test_refresh_token_endpoint_validation_empty():
    """Valida 422 Unprocessable Entity si el token está vacío o solo contiene espacios."""
    res = client.post("/api/v1/auth/refresh", json={"refresh_token": "   "})
    assert res.status_code == 422


def test_refresh_token_endpoint_missing_payload():
    """Valida 422 Unprocessable Entity si falta el payload requerido."""
    res = client.post("/api/v1/auth/refresh", json={})
    assert res.status_code == 422


def test_auth_service_refresh_token_supabase_success(monkeypatch):
    """Prueba unitaria de AuthService con Supabase simulado exitoso (USE_MOCK_AUTH=False)."""
    monkeypatch.setattr(settings, "USE_MOCK_AUTH", False)

    mock_auth_repo = MagicMock()
    mock_user_repo = MagicMock()

    mock_session = MagicMock()
    mock_session.access_token = "new_sb_access_token"
    mock_session.refresh_token = "new_sb_refresh_token"
    mock_session.expires_in = 3600

    mock_user = MagicMock()
    mock_user.id = "sb-user-uuid"

    mock_response = MagicMock()
    mock_response.session = mock_session
    mock_response.user = mock_user
    mock_auth_repo.refresh_session.return_value = mock_response

    mock_user_repo.get_profile_by_id.return_value = ProfileModel(
        id="sb-user-uuid",
        email="supabase@mio.app",
        first_name="Supabase",
        last_name="User",
        role="trainer",
        profile_image_url=None,
    )

    service = AuthService(auth_repo=mock_auth_repo, user_repo=mock_user_repo)
    result = asyncio.run(service.refresh_token(RefreshTokenRequest(refresh_token="valid_sb_token")))

    assert result.access_token == "new_sb_access_token"
    assert result.refresh_token == "new_sb_refresh_token"
    assert result.user.email == "supabase@mio.app"
    mock_auth_repo.refresh_session.assert_called_once_with("valid_sb_token")


def test_auth_service_refresh_token_supabase_failure(monkeypatch):
    """Prueba unitaria de AuthService cuando Supabase rechaza el refresh_token."""
    monkeypatch.setattr(settings, "USE_MOCK_AUTH", False)

    mock_auth_repo = MagicMock()
    mock_auth_repo.refresh_session.side_effect = Exception("Supabase Auth token expired")

    service = AuthService(auth_repo=mock_auth_repo, user_repo=MagicMock())
    with pytest.raises(HTTPException) as exc_info:
        asyncio.run(service.refresh_token(RefreshTokenRequest(refresh_token="expired_token")))

    assert exc_info.value.status_code == 401
