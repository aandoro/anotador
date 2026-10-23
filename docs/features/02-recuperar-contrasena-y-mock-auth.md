# [FEAT-002] Recuperación de Contraseña y Modo Mock de Autenticación

## 1. Información General
- **ID**: `FEAT-002`
- **Nombre**: Flujo de Recuperación de Contraseña y Soporte de Mock Auth
- **Módulo / Ámbito**: `full-stack` (Frontend Flutter & Backend FastAPI)
- **Plataformas**: Mobile (Android / iOS) & Web / Desktop
- **Estado**: `Implementado y Aprobado` (Auditoría QA Completada)

---

## 2. Objetivo y Contexto de Negocio
1. **Recuperación de Contraseña**: Cuando un usuario olvida su contraseña no tiene actualmente ninguna vía para restablecer su acceso a la cuenta. Se requiere proveer un flujo seguro y amigable para solicitar el reseteo por email e ingresar la nueva contraseña.
2. **Modo Mock / Fallback de Autenticación**: Debido a que los proyectos en el tier gratuito de Supabase se pausan automáticamente por inactividad, se proveerá una bandera (`USE_MOCK_AUTH=True`) que permita el login y testing de flujos de autenticación localmente sin bloquear el desarrollo de Frontend y Backend.

---

## 3. Requerimientos Funcionales

### Backend (Python / FastAPI)
1. **Endpoint `POST /api/v1/auth/forgot-password`**:
   - Recibe el email del usuario.
   - En modo Supabase real: ejecuta `reset_password_for_email`.
   - Protección anti-enumeración: siempre devuelve respuesta exitosa (HTTP 200) independientemente de si el correo existe o no en la base de datos.
2. **Endpoint `POST /api/v1/auth/reset-password`**:
   - Recibe el token/código OTP y la nueva contraseña (`min_length=8`).
   - Valida el token y actualiza la credencial del usuario.
3. **Bandera `USE_MOCK_AUTH` (en `app/core/config.py`)**:
   - Si está activa (`USE_MOCK_AUTH=True`), `/auth/login` permite autenticar con credenciales de prueba retornando un usuario mock y JWT válido sin necesidad de conexión activa a Supabase.
   - `/auth/forgot-password` y `/auth/reset-password` simulan éxito inmediato (HTTP 200).

### Frontend (Flutter)
1. **Enlace en `LoginScreen`**:
   - Botón de texto *"¿Olvidaste tu contraseña?"* que redirige a `ForgotPasswordScreen`.
2. **Pantalla `ForgotPasswordScreen`**:
   - Campo para ingresar el email con validación de formato.
   - Botón para enviar solicitud de restablecimiento con indicador de carga.
   - Mensaje de confirmación instructivo al enviar ("Si el correo está registrado, recibirás las instrucciones para restablecer tu contraseña").
   - Opción para navegar a `ResetPasswordScreen` o volver al login.
3. **Pantalla `ResetPasswordScreen`**:
   - Campo para el código/token de verificación y campos de `Nueva Contraseña` y `Confirmar Contraseña` (mínimo 8 caracteres).
   - Botón para confirmar restablecimiento.
   - Redirección al login con feedback visual exitoso tras completar el cambio.
4. **Estado e Integración**:
   - Métodos en `AuthRemoteDataSource` y `AuthRepository`.
   - Nuevos métodos y estados en `AuthProvider` (`forgotPassword`, `resetPassword`).

---

## 4. Contratos de Datos y Esquemas

### Backend Schemas (`app/schemas/auth.py`)
```python
class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class ResetPasswordRequest(BaseModel):
    token: str  # Código de verificación u OTP
    new_password: str = Field(..., min_length=8, description="Nueva contraseña (mínimo 8 caracteres)")

class MessageResponse(BaseModel):
    message: str
```

---

## 5. Criterios de Aceptación (Definición de Terminado)
- [x] **Flujo Completo de Recuperación**: Un usuario puede solicitar el reseteo desde la app e ingresar su nueva contraseña.
- [x] **Seguridad Anti-Enumeración**: `POST /auth/forgot-password` retorna HTTP 200 con mensaje genérico tanto si el correo existe como si no.
- [x] **Modo Mock Auth**: Al activar `USE_MOCK_AUTH=True`, el backend permite loguearse y probar las pantallas sin conexión activa a Supabase.
- [x] **Validación de Formularios**: Frontend y Backend validan formato de email y longitud mínima de contraseña (8 caracteres).
- [x] **Tests Automatizados**:
  - Tests unitarios en backend para `/auth/forgot-password` (anti-enumeración y modo mock).
  - Tests unitarios en frontend para las nuevas funciones de `AuthProvider`.
- [x] **Calidad de Código**: `flutter analyze` (0 warnings) y `pytest` (9 tests pasando) superados con éxito.
