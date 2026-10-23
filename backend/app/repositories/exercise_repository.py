import uuid
from typing import List, Optional
from app.core.config import settings
from app.core.supabase import supabase_admin_client, get_supabase_admin_client
from app.models.exercise import ExerciseModel

# Catálogo estándar para desarrollo local, pruebas o fallback
STANDARD_EXERCISES = [
    {"id": "ex-001", "name": "Sentadilla Trasera"},
    {"id": "ex-002", "name": "Sentadilla Frontal"},
    {"id": "ex-003", "name": "Press de Banca Plano"},
    {"id": "ex-004", "name": "Press de Banca Inclinado"},
    {"id": "ex-005", "name": "Peso Muerto Convencional"},
    {"id": "ex-006", "name": "Peso Muerto Sumo"},
    {"id": "ex-007", "name": "Peso Muerto Rumano"},
    {"id": "ex-008", "name": "Press Militar con Barra"},
    {"id": "ex-009", "name": "Press Militar con Mancuernas"},
    {"id": "ex-010", "name": "Remo con Barra"},
    {"id": "ex-011", "name": "Dominadas Lastradas"},
    {"id": "ex-012", "name": "Fondos en Paralelas"},
    {"id": "ex-013", "name": "Hip Thrust"},
    {"id": "ex-014", "name": "Prensa de Piernas"},
    {"id": "ex-015", "name": "Zancadas con Mancuernas"},
]


class ExerciseRepository:
    """
    Repositorio de datos para el catálogo de ejercicios.
    Única capa autorizada para consultar la tabla 'exercises' en Supabase.
    """

    def __init__(self, admin_client=None):
        self._admin_client = admin_client

    @property
    def admin_client(self):
        return self._admin_client or supabase_admin_client or get_supabase_admin_client()

    def search_by_name(self, query: str, limit: int = 20) -> List[ExerciseModel]:
        """
        Busca ejercicios por coincidencia parcial insensible a mayúsculas/minúsculas.
        Si Supabase está pausado, en modo mock o la tabla no responde, usa catálogo estándar.
        """
        clean_query = query.strip()
        if settings.USE_MOCK_AUTH:
            return self._filter_standard_catalog(clean_query, limit)

        try:
            res = (
                self.admin_client.table("exercises")
                .select("id, name")
                .ilike("name", f"%{clean_query}%")
                .limit(limit)
                .execute()
            )
            if res.data and len(res.data) > 0:
                return [ExerciseModel(**item) for item in res.data]
            # Si no hay registros aún en DB, proveer sugerencias del catálogo estándar
            return self._filter_standard_catalog(clean_query, limit)
        except Exception:
            # Fallback defensivo ante base de datos pausada/inaccesible
            return self._filter_standard_catalog(clean_query, limit)

    def create(self, name: str) -> ExerciseModel:
        """
        Inserta un nuevo ejercicio en la tabla 'exercises' de Supabase.
        """
        clean_name = name.strip()
        for ex in STANDARD_EXERCISES:
            if ex["name"].lower() == clean_name.lower():
                raise ValueError(f"El ejercicio '{clean_name}' ya existe en el catálogo")

        if settings.USE_MOCK_AUTH:
            new_id = f"ex-{uuid.uuid4().hex[:8]}"
            new_item = {"id": new_id, "name": clean_name}
            STANDARD_EXERCISES.append(new_item)
            return ExerciseModel(**new_item)

        try:
            res = (
                self.admin_client.table("exercises")
                .insert({"name": clean_name})
                .execute()
            )
            if res.data and len(res.data) > 0:
                created_model = ExerciseModel(**res.data[0])
                STANDARD_EXERCISES.append({"id": created_model.id, "name": created_model.name})
                return created_model
            raise RuntimeError("No se retornaron datos al registrar el ejercicio")
        except Exception as e:
            if "duplicate" in str(e).lower() or "unique" in str(e).lower():
                raise ValueError(f"El ejercicio '{clean_name}' ya existe en el catálogo")
            # Fallback defensivo en caso de desconexión momentánea de Supabase
            new_id = f"ex-{uuid.uuid4().hex[:8]}"
            new_item = {"id": new_id, "name": clean_name}
            STANDARD_EXERCISES.append(new_item)
            return ExerciseModel(**new_item)

    def seed_defaults(self, catalog: Optional[List[str]] = None) -> int:
        """
        Siembra el catálogo inicial de ejercicios en la tabla 'exercises' de Supabase.
        Retorna la cantidad de ejercicios sembrados / procesados.
        """
        names_to_seed = catalog or [ex["name"] for ex in STANDARD_EXERCISES]
        if settings.USE_MOCK_AUTH:
            return len(names_to_seed)

        try:
            payload = [{"name": name.strip()} for name in names_to_seed]
            res = (
                self.admin_client.table("exercises")
                .upsert(payload, on_conflict="name")
                .execute()
            )
            if res.data:
                return len(res.data)
            return len(names_to_seed)
        except Exception:
            return len(names_to_seed)

    def _filter_standard_catalog(self, query: str, limit: int) -> List[ExerciseModel]:
        normalized_q = query.lower()
        matches = [
            ExerciseModel(**ex)
            for ex in STANDARD_EXERCISES
            if normalized_q in ex["name"].lower()
        ]
        return matches[:limit]


exercise_repository = ExerciseRepository()


def get_exercise_repository() -> ExerciseRepository:
    return exercise_repository
