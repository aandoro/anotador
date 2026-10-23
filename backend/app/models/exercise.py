from pydantic import BaseModel


class ExerciseModel(BaseModel):
    id: str
    name: str
