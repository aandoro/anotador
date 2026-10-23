# [FEAT-003] Formulario de Carga de PR con Búsqueda Dinámica de Ejercicios en BD

## 1. Información General
- **ID**: `FEAT-003`
- **Nombre**: Formulario de Carga de PR con Búsqueda Normalizada de Ejercicios en BD
- **Módulo / Ámbito**: `full-stack` (Backend FastAPI & Frontend Flutter)
- **Estado**: `Implementado y Aprobado` (Auditado por QA)

---

## 2. Objetivo y Contexto de Negocio
1. **Evitar Ejercicios Inventados**: El formulario para registrar Personal Records no debe permitir la entrada libre de cualquier texto, sino exigir que el usuario seleccione un ejercicio normalizado de la base de datos.
2. **Búsqueda Dinámica al Escribir**: Cuando el usuario escribe 3 o más letras en el campo de ejercicio, la aplicación debe consultar automáticamente a la base de datos (`GET /api/v1/exercises?search=...`) con *debounce* y sugerir las coincidencias.
3. **Limpieza Visual de Cards**: En `RecordsScreen`, remover la etiqueta redundante `(1RM)` dejando `1 rep`, `3 reps`, etc.
4. **Estado Reactivo en Memoria**: Conservar los datos mock iniciales de la sesión e insertar inmediatamente cualquier nuevo PR creado en la lista.

---

## 3. Especificación Técnica Backend (Arquitectura Obligatoria en 4 Capas)

### 3.1. Modelos (`app/models/exercise.py`)
```python
class ExerciseModel(BaseModel):
    id: str
    name: str
```

### 3.2. Schemas (`app/schemas/exercise.py`)
```python
class ExerciseResponse(BaseModel):
    id: str
    name: str
```

### 3.3. Repositorio (`app/repositories/exercise_repository.py`)
- `ExerciseRepository`:
  - `search_by_name(query: str) -> List[ExerciseModel]`:
    - Consulta a la tabla `exercises` en Supabase con `.ilike("name", f"%{query}%")`.
    - Soporte defensivo con catálogo estándar en caso de base de datos vacía o modo mock (`USE_MOCK_AUTH`).

### 3.4. Servicio (`app/services/exercise_service.py`)
- `ExerciseService`:
  - `search_exercises(query: str) -> List[ExerciseResponse]`:
    - Valida y normaliza la consulta y delega en `ExerciseRepository`.

### 3.5. Router (`app/api/v1/endpoints/exercises.py`)
- `GET /api/v1/exercises`:
  - Parámetro: `search: str = Query(..., min_length=3, description="Término de búsqueda (mínimo 3 caracteres)")`.
  - Inyecta `ExerciseService` vía `Depends()`. Cero queries directas.
  - Registrado en `app/api/v1/router.py`.

---

## 4. Especificación Técnica Frontend (Flutter)

### 4.1. Datasource de Ejercicios
- `ExerciseRemoteDataSource`:
  - `searchExercises(String query) -> Future<List<ExerciseModel>>`
  - Consulta `GET /api/v1/exercises?search={query}`.

### 4.2. Formulario Modal (`AddRecordModal`)
- **Campo de Ejercicio (Autocompletado con BD)**:
  - Solo activa la búsqueda si el texto tiene $\ge 3$ caracteres.
  - Aplica retardo (*debounce* de 350ms) para no saturar peticiones.
  - Muestra la lista de sugerencias traídas de la base de datos.
  - **Validación Estricta**: Obliga a seleccionar un ejercicio de la lista (no permite guardar texto libre).
- **Campos Adicionales**:
  - Peso (kg): numérico, validación $> 0$.
  - Repeticiones: entero, validación $\ge 1$, por defecto `1`.
  - Fecha: selector DatePicker, por defecto hoy.
- **Acción**: Guarda el nuevo PR en `RecordsProvider`, cierra el modal y muestra confirmación.

### 4.3. Visualización en `RecordsScreen`
- Cards limpias sin `(1RM)`.
- El botón flotante abre el formulario modal.

---

## 5. Criterios de Aceptación (Definición de Terminado)
- [x] Backend cuenta con `GET /api/v1/exercises?search=` bajo la arquitectura estricta de 4 capas.
- [x] Escribir menos de 3 caracteres en el selector de ejercicio no dispara peticiones de red.
- [x] Escribir 3 o más caracteres consulta la base de datos y despliega las opciones coincidentes.
- [x] El usuario está obligado a seleccionar un ejercicio válido sugerido para poder guardar el PR.
- [x] Las cards mock de `RecordsScreen` muestran las repeticiones sin `(1RM)`.
- [x] Al guardar, el nuevo PR se visualiza de inmediato en la lista de records.
- [x] Pruebas unitarias pasando en Backend (`pytest` con 18 tests) y Frontend (`flutter test` con 14 tests) y `flutter analyze` limpio sin advertencias.
