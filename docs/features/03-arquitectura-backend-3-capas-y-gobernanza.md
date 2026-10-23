# [ARCH-001] Arquitectura Backend en Capas (Router -> Service -> Repository -> Model) y Gobernanza

## 1. Información General
- **ID**: `ARCH-001`
- **Nombre**: Arquitectura Backend en Capas (Router -> Service -> Repository -> Model/Schema) y Gobernanza de Agentes
- **Módulo / Ámbito**: `backend` (Python / FastAPI) y `.agents/` (Gobernanza)
- **Estado**: `Implementado y Aprobado` (Auditado por QA)

---

## 2. Objetivo y Contexto de Negocio
Actualmente, los endpoints en `backend/app/api/v1/endpoints/` contienen directamente lógica de negocio, consultas a Supabase y manipulación de Storage.

Siguiendo las mejores prácticas de Clean Architecture y la indicación del usuario, establecemos la separación estricta:
1. **Router / Resource (`app/api/`)**: Recibe HTTP, valida esquemas DTO de entrada, invoca al Service y devuelve códigos HTTP / esquemas DTO de salida.
2. **Service (`app/services/`)**: Contiene la lógica pura de negocio, orquestación, reglas de dominio, validaciones complejas, mock auth fallback e interactúa exclusivamente con la capa de Repositorios.
3. **Repository (`app/repositories/`)**: Encapsula el acceso a datos. Es la **única** capa autorizada para comunicarse con clientes de base de datos (Supabase Client, tablas de profiles, autenticación y storage). Retorna modelos de dominio.
4. **Models & Schemas (`app/models/` y `app/schemas/`)**:
   - `models/`: Entidades de dominio (`ProfileModel`, `UserModel`, etc.) independientes del framework HTTP.
   - `schemas/`: Pydantic DTOs para validación de requests/responses HTTP.
5. **Utils (`app/utils/`)**: Funciones transversales sin estado (validación de archivos, tipos MIME, nombres de storage).

---

## 3. Especificación de Componentes a Implementar

### 3.1. Models (`app/models/`)
- `app/models/user.py`: Entidades de dominio `ProfileModel`, `UserModel` y enumeración de roles `UserRole`.

### 3.2. Utils (`app/utils/`)
- `app/utils/file_utils.py`:
  - `validate_image_file(content_type, size_bytes)`
  - `generate_storage_path(user_id, filename)`

### 3.3. Repositories (`app/repositories/`)
- `app/repositories/auth_repository.py`:
  - `AuthRepository`: `sign_up()`, `sign_in_with_password()`, `reset_password_for_email()`, `verify_otp()`, `update_user_password()`.
- `app/repositories/user_repository.py`:
  - `UserRepository`: `get_profile_by_id()`, `upsert_profile()`, `update_profile()`, `upload_avatar_file()`, `get_avatar_public_url()`.

### 3.4. Services (`app/services/`)
- `app/services/auth_service.py`:
  - `AuthService`: Orquesta login, registro, recuperación y reseteo de contraseñas, mock auth fallback.
- `app/services/user_service.py`:
  - `UserService`: Orquesta obtención de perfil, actualización de datos de perfil, validación y subida de avatar.

### 3.5. Routers / Resources (`app/api/v1/endpoints/`)
- `auth.py`: Inyecta `AuthService` exclusivamente. Cero llamadas a Supabase.
- `users.py`: Inyecta `UserService` exclusivamente. Cero llamadas a Supabase.

---

## 4. Actualización de Gobernanza (`AGENTS.md` y `.agents/agents/`)
- **`AGENTS.md`**: Establece la arquitectura de capas obligatoria (`Router -> Service -> Repository -> Model/Schema`) y el uso de `app/utils/`.
- **`.agents/agents/analista.md`**: Obliga a especificar la división Router, Service, Repository, Model/Schema y Utils en todo requerimiento de backend.
- **`.agents/agents/developer.md`**: Prohíbe queries en routers y en services; exige usar repositorios para la persistencia.
- **`.agents/agents/reviewer.md`**: Fija como motivo de rechazo inmediato cualquier query o llamada a Supabase/DB fuera de `app/repositories/`, o lógica de negocio fuera de `app/services/`.

---

## 5. Criterios de Aceptación (Definición de Terminado)
- [x] La capa `app/api/` solo contiene lógica de enrutamiento y delegación a `app/services/`.
- [x] La capa `app/services/` solo contiene lógica de negocio y consume `app/repositories/`.
- [x] La capa `app/repositories/` es la única que interactúa con el cliente Supabase / DB / Storage.
- [x] La capa `app/models/` y `app/utils/` están creadas y en uso.
- [x] 100% de compatibilidad: los 14 tests de `pytest backend/tests` pasan exitosamente.
- [x] `AGENTS.md` y los 3 subagentes (`analista`, `developer`, `reviewer`) tienen las directivas formalizadas.
