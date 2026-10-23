# [FEAT-004] Persistencia y Gestión de Catálogo de Ejercicios en Supabase (Solo Admin para Creación)

## 1. Información General
- **ID**: `FEAT-004`
- **Nombre**: Persistencia y Gestión del Catálogo de Ejercicios en Supabase con Control de Roles (RBAC)
- **Módulo / Ámbito**: `backend` (Python / FastAPI / Supabase SQL)
- **Estado**: `Implementado y Aprobado`

---

## 2. Objetivo y Contexto de Negocio
Actualmente, los ejercicios estándar estaban almacenados en una lista hardcodeada dentro del repositorio.
El objetivo es:
1. **Crear y normalizar la tabla `public.exercises` en Supabase**: Con clave primaria UUID, nombre único y políticas RLS para lectura pública/autenticada y escritura reservada a `service_role`.
2. **Autorización Estricta de Creación (Solo Admin)**:
   - Los usuarios comunes y trainers **solo tienen permisos para buscar y seleccionar** ejercicios (`GET /api/v1/exercises?search=`).
   - Únicamente los usuarios con rol `admin` tienen autorización para crear nuevos ejercicios (`POST /api/v1/exercises`) o disparar el sembrado (`POST /api/v1/exercises/seed`). Intentos por usuarios sin rol admin son rechazados con `403 Forbidden`.
3. **Proveer Seeder Automatizado**:
   - Script CLI (`backend/scripts/seed_exercises.py`) que usa la `service_role_key` para poblar Supabase directamente desde la terminal.
   - Endpoint administrativo `POST /api/v1/exercises/seed` protegido para admin.

---

## 3. Diseño de Base de Datos (`backend/supabase/schema_exercises.sql`)

```sql
CREATE TABLE IF NOT EXISTS public.exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Habilitar Row Level Security
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;

-- Políticas de Lectura
CREATE POLICY "Lectura publica de ejercicios" 
    ON public.exercises FOR SELECT 
    USING (true);

-- Política de Inserción (Service Role / Backend)
CREATE POLICY "Insercion autorizada de ejercicios" 
    ON public.exercises FOR INSERT 
    WITH CHECK (true);
```

---

## 4. Especificación Técnica Backend (4 Capas)

### 4.1. Seguridad y Autorización (`app/core/security.py`)
- Dependencia `require_admin_user(current_user: UserProfileResponse = Depends(get_current_user))`:
  - Valida `current_user.role == "admin"`.
  - Si es distinto, eleva `HTTPException(status_code=403, detail="Se requieren permisos de administrador para realizar esta acción")`.

### 4.2. Models & Schemas
- `app/models/exercise.py`: `ExerciseModel(id: str, name: str)`
- `app/schemas/exercise.py`: `ExerciseCreateRequest(name: str)`, `ExerciseResponse(id: str, name: str)`

### 4.3. Repositorio (`app/repositories/exercise_repository.py`)
- `search_by_name(query: str, limit: int) -> List[ExerciseModel]`: Realiza consulta con `.ilike("name", f"%{query}%")`.
- `create(name: str) -> ExerciseModel`: Inserta en Supabase tabla `exercises`.
- `seed_defaults(catalog: List[str]) -> int`: Inserta lote con control de duplicados en Supabase.

### 4.4. Servicio (`app/services/exercise_service.py`)
- `search_exercises(query: str) -> List[ExerciseResponse]`
- `create_exercise(name: str) -> ExerciseResponse`
- `seed_default_exercises() -> int`

### 4.5. Router (`app/api/v1/endpoints/exercises.py`)
- `GET /api/v1/exercises?search=`: Abierto a cualquier usuario autenticado/regular para buscar.
- `POST /api/v1/exercises`: Protegido con `Depends(require_admin_user)`.
- `POST /api/v1/exercises/seed`: Protegido con `Depends(require_admin_user)`.

---

## 5. Criterios de Aceptación (Definición de Terminado)
- [x] Intentar crear un ejercicio o sembrar sin rol `admin` devuelve HTTP 403 Forbidden.
- [x] Usuarios regulares y trainers pueden buscar ejercicios exitosamente (`GET`).
- [x] Script DDL SQL provisto en `backend/supabase/schema_exercises.sql`.
- [x] Script CLI `backend/scripts/seed_exercises.py` carga el catálogo inicial en Supabase.
- [x] Cobertura de pruebas unitarias actualizada con tests de permisos de admin (403 y 201) pasando al 100%.
