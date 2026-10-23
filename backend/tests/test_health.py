from fastapi.testclient import TestClient
from app.main import app
from app.core.config import settings

client = TestClient(app)


def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert data["docs"] == "/docs"
    assert data["health"] == f"{settings.API_V1_STR}/health"


def test_health_check_endpoint():
    response = client.get(f"{settings.API_V1_STR}/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["project_name"] == settings.PROJECT_NAME
    assert data["environment"] == settings.ENVIRONMENT
    assert data["version"] == settings.VERSION
