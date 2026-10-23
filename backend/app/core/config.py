import json
from typing import List, Optional, Union
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "Mio API"
    ENVIRONMENT: str = "development"
    API_V1_STR: str = "/api/v1"
    VERSION: str = "0.1.0"

    # Configuración de CORS
    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8000",
        "http://localhost:8080",
        "http://127.0.0.1",
        "http://127.0.0.1:8000",
    ]
    BACKEND_CORS_ORIGIN_REGEX: Optional[str] = r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"

    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        """
        Valida y normaliza la lista de orígenes permitidos.
        Soporta:
          - Listas nativas de Python
          - Strings con formato JSON: '["https://mio.vercel.app"]'
          - Strings delimitados por comas: 'https://a.com, https://b.com'
        Elimina espacios en blanco, remueve trailing slashes y descarta el comodín '*'
        para mantener compatibilidad estricta con allow_credentials=True.
        """
        if isinstance(v, str):
            v_trimmed = v.strip()
            if not v_trimmed:
                return []
            if v_trimmed.startswith("[") and v_trimmed.endswith("]"):
                try:
                    parsed = json.loads(v_trimmed)
                    raw_origins = parsed if isinstance(parsed, list) else [str(parsed)]
                except Exception:
                    raw_origins = [item.strip() for item in v_trimmed.strip("[]").split(",") if item.strip()]
            else:
                raw_origins = [item.strip() for item in v_trimmed.split(",") if item.strip()]
        elif isinstance(v, (list, tuple, set)):
            raw_origins = list(v)
        else:
            raw_origins = []

        cleaned_origins: List[str] = []
        for origin in raw_origins:
            if not isinstance(origin, str):
                origin = str(origin)
            origin = origin.strip().rstrip("/")
            if origin and origin != "*":
                cleaned_origins.append(origin)

        return cleaned_origins

    # Supabase Configuration
    SUPABASE_URL: str = ""
    SUPABASE_KEY: str = ""
    SUPABASE_SERVICE_ROLE_KEY: str = ""
    SUPABASE_JWT_SECRET: str = ""
    SUPABASE_AVATARS_BUCKET: str = "profiles"

    # Mock Auth for local development when Supabase is paused or unavailable
    USE_MOCK_AUTH: bool = False

    model_config = SettingsConfigDict(
        env_file=(".env", "../.env"),
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )


settings = Settings()