from supabase import create_client, Client
from app.core.config import settings


def get_supabase_client() -> Client:
    """Crea y retorna un cliente Supabase con la anon/public key."""
    if not settings.SUPABASE_URL or not settings.SUPABASE_KEY:
        raise RuntimeError("SUPABASE_URL y SUPABASE_KEY deben estar configuradas")
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)


def get_supabase_admin_client() -> Client:
    """Crea y retorna un cliente Supabase administrativo con service_role key."""
    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        raise RuntimeError("SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY deben estar configuradas")
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)


# Instancias globales reutilizables
try:
    supabase_client: Client = get_supabase_client()
except Exception:
    supabase_client = None  # Permite arranque en entornos de test/mock

try:
    supabase_admin_client: Client = get_supabase_admin_client()
except Exception:
    supabase_admin_client = None