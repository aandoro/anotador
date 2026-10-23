from typing import Dict, Any, Optional
from app.core.supabase import supabase_client, get_supabase_client


class AuthRepository:
    """
    Repositorio de datos para operaciones de autenticación.
    Única capa autorizada para invocar el cliente de Supabase Auth.
    """

    def __init__(self, client=None):
        self._client = client

    @property
    def client(self):
        return self._client or supabase_client or get_supabase_client()

    def sign_up(self, email: str, password: str, data: Dict[str, Any]):
        """Registra un nuevo usuario en Supabase Auth."""
        return self.client.auth.sign_up({
            "email": email,
            "password": password,
            "options": {"data": data},
        })

    def sign_in_with_password(self, email: str, password: str):
        """Inicia sesión con email y contraseña en Supabase Auth."""
        return self.client.auth.sign_in_with_password({
            "email": email,
            "password": password,
        })

    def refresh_session(self, refresh_token: str):
        """Renueva la sesión activa utilizando el refresh token en Supabase Auth."""
        return self.client.auth.refresh_session(refresh_token)

    def reset_password_for_email(self, email: str):
        """Envía correo de recuperación de contraseña."""
        return self.client.auth.reset_password_for_email(email)

    def verify_otp(self, token: str, otp_type: str = "recovery"):
        """Verifica token OTP de recuperación o confirmación."""
        return self.client.auth.verify_otp({"token": token, "type": otp_type})

    def update_user(self, attributes: Dict[str, Any]):
        """Actualiza atributos del usuario actualmente autenticado (ej. password)."""
        return self.client.auth.update_user(attributes)


# Instancia por defecto / singleton para inyección de dependencias
auth_repository = AuthRepository()


def get_auth_repository() -> AuthRepository:
    return auth_repository
