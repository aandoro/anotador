"""
Script CLI para inicializar y sembrar el catálogo de ejercicios en Supabase.
Uso:
    python backend/scripts/seed_exercises.py
    o
    python -m scripts.seed_exercises (desde el directorio backend/)
"""

import sys
import os
from pathlib import Path

# Asegurar que el directorio raíz de backend esté en sys.path
backend_dir = Path(__file__).resolve().parent.parent
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from app.core.config import settings
from app.repositories.exercise_repository import STANDARD_EXERCISES, ExerciseRepository
from app.core.supabase import get_supabase_admin_client


def run_seeder():
    print("=" * 60)
    print("MIO - Inicializador del Catálogo de Ejercicios en Supabase")
    print("=" * 60)

    try:
        admin_client = get_supabase_admin_client()
    except Exception as e:
        admin_client = None
        print(f"[AVISO] No se pudo inicializar el cliente de Supabase: {e}")
        print("Asegúrate de configurar SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY en backend/.env")
        if not settings.USE_MOCK_AUTH:
            return

    repo = ExerciseRepository(admin_client=admin_client)
    names = [ex["name"] for ex in STANDARD_EXERCISES]
    print(f"Sembrando {len(names)} ejercicios estándar en la tabla 'exercises'...")

    try:
        count = repo.seed_defaults(names)
        print(f"[ÉXITO] Catálogo sembrado correctamente. Total procesados: {count}")
    except Exception as e:
        print(f"[ERROR] Ocurrió un error al sembrar ejercicios: {e}")


if __name__ == "__main__":
    run_seeder()
