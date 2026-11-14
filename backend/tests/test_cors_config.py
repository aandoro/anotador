from fastapi.testclient import TestClient
from app.core.config import Settings
from app.main import app


def test_cors_origins_empty_env_string():
    """Render puede inyectar BACKEND_CORS_ORIGINS="" ; no debe romper el boot."""
    settings = Settings(BACKEND_CORS_ORIGINS="")
    assert settings.BACKEND_CORS_ORIGINS == []


def test_cors_origins_empty_json_array():
    settings = Settings(BACKEND_CORS_ORIGINS="[]")
    assert settings.BACKEND_CORS_ORIGINS == []


def test_cors_origins_csv_parsing():
    settings = Settings(BACKEND_CORS_ORIGINS="https://app.vercel.app, http://localhost:3000/")
    assert "https://app.vercel.app" in settings.BACKEND_CORS_ORIGINS
    assert "http://localhost:3000" in settings.BACKEND_CORS_ORIGINS
    assert len(settings.BACKEND_CORS_ORIGINS) == 2


def test_cors_origins_json_parsing():
    settings = Settings(BACKEND_CORS_ORIGINS='["https://app.vercel.app/", "https://mio.example.com"]')
    assert settings.BACKEND_CORS_ORIGINS == ["https://app.vercel.app", "https://mio.example.com"]


def test_cors_origins_strips_trailing_slash_and_whitespace():
    settings = Settings(BACKEND_CORS_ORIGINS=["  https://my-app.vercel.app/  ", "https://api.domain.com/"])
    assert settings.BACKEND_CORS_ORIGINS == ["https://my-app.vercel.app", "https://api.domain.com"]


def test_cors_origins_excludes_wildcard():
    settings = Settings(BACKEND_CORS_ORIGINS="*, https://allowed.com, *")
    assert "*" not in settings.BACKEND_CORS_ORIGINS
    assert settings.BACKEND_CORS_ORIGINS == ["https://allowed.com"]


def test_cors_preflight_allowed_origin():
    client = TestClient(app)
    headers = {
        "Origin": "http://localhost:3000",
        "Access-Control-Request-Method": "GET",
        "Access-Control-Request-Headers": "authorization,content-type",
    }
    response = client.options("/api/v1/health", headers=headers)
    assert response.status_code == 200
    assert response.headers.get("access-control-allow-origin") == "http://localhost:3000"
    assert response.headers.get("access-control-allow-credentials") == "true"


def test_cors_preflight_regex_match():
    client = TestClient(app)
    headers = {
        "Origin": "http://127.0.0.1:45678",
        "Access-Control-Request-Method": "GET",
    }
    response = client.options("/api/v1/health", headers=headers)
    assert response.status_code == 200
    assert response.headers.get("access-control-allow-origin") == "http://127.0.0.1:45678"


def test_cors_disallowed_origin():
    client = TestClient(app)
    headers = {
        "Origin": "https://unauthorized-domain.com",
        "Access-Control-Request-Method": "GET",
    }
    response = client.options("/api/v1/health", headers=headers)
    assert response.headers.get("access-control-allow-origin") is None
