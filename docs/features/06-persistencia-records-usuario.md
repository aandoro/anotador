# [FEAT-005] Persistencia de Personal Records vinculados al Usuario (Supabase + FastAPI + Flutter)

## 1. Información General
- **ID**: `FEAT-005`
- **Nombre**: Persistencia y Consulta de Personal Records vinculados al Usuario
- **Módulos / Ámbitos**: `backend` (FastAPI / Supabase PostgreSQL) y `frontend` (Flutter)
- **Estado**: `Implementado y Aprobado`

---

## 2. Objetivo y Contexto de Negocio
Actualmente, la pantalla de Personal Records en Flutter muestra 4 registros mock hardcodeados en memoria y el formulario modal únicamente añade registros a una lista local volátil.
El objetivo es:
1. Crear la tabla `public.personal_records` en Supabase con clave foránea hacia el usuario autenticado (`profiles.id`) y políticas RLS estrictas (cada usuario solo puede consultar y registrar sus propios récords).
2. Implementar en el backend la arquitectura en 4 capas (`Router -> Service -> Repository -> Models/Schemas`) para exponer:
   - `GET /api/v1/records`: Lista de récords del usuario logueado.
   - `POST /api/v1/records`: Creación y persistencia de un nuevo récord.
3. Actualizar la aplicación Flutter para:
   - Eliminar los datos mock fijos.
   - Consultar la API al ingresar a `RecordsScreen`.
   - Mostrar estado de carga (`CircularProgressIndicator`), estado vacío amigable si no tiene récords, o la lista con sus tarjetas reales.
   - Persistir en la base de datos al guardar desde `AddRecordModal` y actualizar la lista en tiempo real.

---

## 3. Diseño de Base de Datos (`backend/supabase/schema_personal_records.sql`)

```sql
CREATE TABLE IF NOT EXISTS public.personal_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    exercise_id UUID NULL REFERENCES public.exercises(id) ON DELETE SET NULL,
    exercise_name TEXT NOT NULL,
    weight_kg NUMERIC(6, 2) NOT NULL,
    reps INTEGER NOT NULL DEFAULT 1,
    record_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Habilitar Row Level Security
ALTER TABLE public.personal_records ENABLE ROW LEVEL SECURITY;

-- 1. Política de Lectura (SELECT): Solo registros propios
DROP POLICY IF EXISTS "Usuarios leen sus propios records" ON public.personal_records;
CREATE POLICY "Usuarios leen sus propios records" 
    ON public.personal_records FOR SELECT 
    USING (auth.uid() = user_id);

-- 2. Política de Inserción (INSERT): Solo registrar bajo el propio user_id
DROP POLICY IF EXISTS "Usuarios insertan sus propios records" ON public.personal_records;
CREATE POLICY "Usuarios insertan sus propios records" 
    ON public.personal_records FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- 3. Política de Modificación / Borrado (UPDATE/DELETE):
DROP POLICY IF EXISTS "Usuarios modifican sus propios records" ON public.personal_records;
CREATE POLICY "Usuarios modifican sus propios records" 
    ON public.personal_records FOR UPDATE 
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Usuarios eliminan sus propios records" ON public.personal_records;
CREATE POLICY "Usuarios eliminan sus propios records" 
    ON public.personal_records FOR DELETE 
    USING (auth.uid() = user_id);

-- Índices de consulta eficiente
CREATE INDEX IF NOT EXISTS idx_personal_records_user ON public.personal_records (user_id);
CREATE INDEX IF NOT EXISTS idx_personal_records_user_date ON public.personal_records (user_id, record_date DESC);
```

---

## 4. Especificación Técnica Backend (Arquitectura en 4 Capas)

### 4.1. Router (`app/api/v1/endpoints/records.py`)
- `GET /api/v1/records`:
  - Seguridad: `current_user: UserProfileResponse = Depends(get_current_user)`.
  - Retorna `List[PersonalRecordResponse]`, status `200 OK`.
- `POST /api/v1/records`:
  - Seguridad: `current_user: UserProfileResponse = Depends(get_current_user)`.
  - Body: `PersonalRecordCreateRequest`.
  - Retorna `PersonalRecordResponse`, status `201 Created`.

### 4.2. Service (`app/services/personal_record_service.py`)
- `get_user_records(user_id: str) -> List[PersonalRecordResponse]`
- `create_record(user_id: str, data: PersonalRecordCreateRequest) -> PersonalRecordResponse`
- Validaciones: `weight_kg > 0`, `reps >= 1`, normalización de notas y fecha. Delegación asíncrona con `asyncio.to_thread`.

### 4.3. Repository (`app/repositories/personal_record_repository.py`)
- `list_by_user_id(user_id: str) -> List[PersonalRecordModel]`: Consulta Supabase `personal_records` ordenada por `record_date DESC`.
- `create(record_data: dict) -> PersonalRecordModel`: Inserta en la tabla y retorna el modelo creado.
- Soporte de fallback en memoria si `USE_MOCK_AUTH` está activo o en tests.

### 4.4. Models & Schemas
- `app/models/personal_record.py`: `PersonalRecordModel` (entidad desacoplada).
- `app/schemas/personal_record.py`:
  - `PersonalRecordCreateRequest(exercise_name, exercise_id?, weight_kg, reps, record_date, notes?)`
  - `PersonalRecordResponse(id, user_id, exercise_id?, exercise_name, weight_kg, reps, record_date, notes?, created_at)`

---

## 5. Especificación Técnica Frontend (Flutter)

### 5.1. Capa Data & Red
- `api_endpoints.dart`: Ruta `records = '/api/v1/records'`.
- `PersonalRecordRemoteDataSource`: Métodos `fetchUserRecords()` y `createRecord(PersonalRecord record)`.

### 5.2. Capa Estado (`RecordsProvider`)
- Retiro de los datos mock en memoria como estado base.
- Estado: `List<PersonalRecord> _records = []`, `bool _isLoading = false`, `String? _errorMessage`.
- `Future<void> loadRecords()`: Trae los récords del usuario logueado.
- `Future<bool> addRecord(PersonalRecord record)`: Llama al backend, inserta al inicio de la lista y notifica a los listeners.

### 5.3. Interfaz de Usuario
- `RecordsScreen`:
  - Carga automática en `initState` / postFrame.
  - Indicador `CircularProgressIndicator` durante la carga inicial.
  - Vista vacía con mensaje motivador e ícono si la lista está vacía (`_records.isEmpty`).
  - Lista de tarjetas si hay registros.
- `AddRecordModal`:
  - Envía el PR al provider y maneja feedback con SnackBar.

---

## 6. Criterios de Aceptación (Definición de Terminado)
- [x] Endpoints `/api/v1/records` (GET y POST) exigen autenticación obligatoria y aíslan datos por `user_id`.
- [x] Script SQL DDL provisto con RLS (`auth.uid() = user_id`) e índices.
- [x] La pantalla `RecordsScreen` no muestra datos fijos al arrancar; realiza fetch a la API mostrando spinner y luego la lista o el estado vacío.
- [x] El modal `AddRecordModal` persiste el nuevo PR en la base de datos y lo refleja inmediatamente en la UI.
- [x] Pruebas unitarias backend (pytest) y frontend (flutter test) al 100%, con 0 issues en `flutter analyze`.
