from fastapi import APIRouter, status
from app.core.config import settings
from app.schemas.health import HealthStatusResponse

router = APIRouter()


@router.get(
    "",
    response_model=HealthStatusResponse,
    status_code=status.HTTP_200_OK,
    summary="Health check endpoint",
    description="Returns the operational status, application name, environment, and version.",
)
async def get_health_status() -> HealthStatusResponse:
    return HealthStatusResponse(
        status="ok",
        project_name=settings.PROJECT_NAME,
        environment=settings.ENVIRONMENT,
        version=settings.VERSION,
    )
