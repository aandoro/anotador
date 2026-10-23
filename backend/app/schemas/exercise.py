from pydantic import BaseModel, Field


class ExerciseCreateRequest(BaseModel):
    name: str = Field(
        ...,
        min_length=2,
        max_length=150,
        description="Nombre del ejercicio a registrar en el catálogo",
    )


class ExerciseResponse(BaseModel):
    id: str
    name: str
