from pydantic import BaseModel, Field


class HealthStatusResponse(BaseModel):
    status: str = Field(
        default="ok",
        description="Current health status of the service",
        examples=["ok"],
    )
    project_name: str = Field(
        description="Official name of the service",
        examples=["Mio API"],
    )
    environment: str = Field(
        description="Operational environment",
        examples=["development"],
    )
    version: str = Field(
        description="SemVer release version of the application",
        examples=["0.1.0"],
    )
