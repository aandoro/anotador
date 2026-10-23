from typing import Optional, List
from datetime import date, datetime
from pydantic import BaseModel, Field


class PersonalRecordCreateRequest(BaseModel):
    exercise_name: str = Field(
        ...,
        min_length=2,
        max_length=150,
        description="Nombre del ejercicio asociado al récord",
    )
    exercise_id: Optional[str] = Field(
        None,
        description="ID opcional del ejercicio seleccionado del catálogo",
    )
    weight_kg: float = Field(
        ...,
        gt=0,
        description="Peso levantado en kilogramos (debe ser mayor a 0)",
    )
    reps: int = Field(
        1,
        ge=1,
        description="Cantidad de repeticiones completadas (mínimo 1)",
    )
    record_date: date = Field(
        default_factory=date.today,
        description="Fecha en la que se logró el récord",
    )
    notes: Optional[str] = Field(
        None,
        max_length=500,
        description="Notas u observaciones opcionales",
    )


class PersonalRecordUpdateRequest(BaseModel):
    exercise_name: Optional[str] = Field(
        None,
        min_length=2,
        max_length=150,
        description="Nombre del ejercicio asociado al récord",
    )
    exercise_id: Optional[str] = Field(
        None,
        description="ID opcional del ejercicio seleccionado del catálogo",
    )
    weight_kg: Optional[float] = Field(
        None,
        gt=0,
        description="Peso levantado en kilogramos (debe ser mayor a 0)",
    )
    reps: Optional[int] = Field(
        None,
        ge=1,
        description="Cantidad de repeticiones completadas (mínimo 1)",
    )
    record_date: Optional[date] = Field(
        None,
        description="Fecha en la que se logró el récord",
    )
    notes: Optional[str] = Field(
        None,
        max_length=500,
        description="Notas u observaciones opcionales",
    )


class PersonalRecordResponse(BaseModel):
    id: str
    user_id: str
    exercise_name: str
    exercise_id: Optional[str] = None
    weight_kg: float
    reps: int
    record_date: date
    notes: Optional[str] = None
    created_at: Optional[datetime] = None


class ProgressionPoint(BaseModel):
    record_date: date
    weight_kg: float


class ProgressionGroupResponse(BaseModel):
    exercise_name: str
    exercise_id: Optional[str] = None
    reps: int
    current_pr_weight: float
    previous_weight: Optional[float] = None
    delta_kg: Optional[float] = None
    history: List[ProgressionPoint]
