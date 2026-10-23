from typing import Optional
from datetime import date, datetime
from pydantic import BaseModel


class PersonalRecordModel(BaseModel):
    """
    Modelo de dominio interno para un Récord Personal (PR).
    Desacoplado de los esquemas HTTP de entrada y salida.
    """
    id: str
    user_id: str
    exercise_name: str
    exercise_id: Optional[str] = None
    weight_kg: float
    reps: int = 1
    record_date: date
    notes: Optional[str] = None
    created_at: Optional[datetime] = None
