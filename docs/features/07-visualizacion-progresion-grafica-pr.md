# [FEAT-07] Visualización Distribuida y Progresión Gráfica de Personal Records (PRs)

## 1. Información General
- **ID**: `FEAT-07`
- **Nombre**: Visualización distribuida de PRs por ejercicio/repeticiones y gráfico de evolución temporal
- **Módulo / Ámbito**: `full-stack`
- **Plataformas**: Todas (Mobile, Web, Desktop)
- **Estado**: `Completado`

---

## 2. Objetivo y Contexto de Negocio
Solucionar el problema de la lista plana cronológica de marcas personales. Permite al usuario:
- Ver sus PRs organizados y agrupados por **Ejercicio** y **Rango de Repeticiones**.
- Visualizar de forma inmediata cómo subió el peso a lo largo del tiempo mediante un **gráfico de curvas interactivo** y ligero.
- Identificar deltas de mejora respecto a levantamientos anteriores (`▲ +5 kg`, `▼ -2.5 kg` o badge `Primer PR`).
- Continuar registrando nuevos PRs con un flujo ágil y reactivo que actualiza los gráficos al instante.

---

## 3. Requerimientos Funcionales
1. **Agrupación por Ejercicio y Repeticiones**: Los PRs de un mismo ejercicio con distintos esquemas de repeticiones (ej. 1RM, 3RM, 5RM) se agrupan en una tarjeta interactiva con selector de chips.
2. **Visualización Gráfica**: Gráfico nativo con Flutter `CustomPainter` que dibuja la serie temporal de cargas en kilogramos, resaltando el valor máximo y las fechas de sesión.
3. **Métricas de Superación**: Cálculo y renderizado de delta de peso respecto a la sesión anterior.
4. **Carga Continua**: Botón de acción flotante `+ Nuevo PR` accesible en ambas pestañas con recálculo automático y sincronización con el backend.
5. **Edición y Eliminación Completa (CRUD)**: Los usuarios pueden editar cualquier dato de un PR existente (peso, repeticiones, fecha, notas) o eliminarlo tras confirmación de diálogo, actualizando de inmediato tanto la lista como las curvas de progresión.
6. **Notas y Observaciones Opcionales**: Campo de texto multilínea enriquecido en `AddRecordModal` que permite documentar RPE, sensaciones o técnica, mostrándose de forma estilizada en las tarjetas del historial.

---

## 4. Diseño y Comportamiento UI / UX (Frontend)
- **Pantalla**: `RecordsScreen` (`frontend/lib/features/records/presentation/screens/records_screen.dart`).
- **Pestañas (TabBar)**:
  - **Progresión**: Tarjetas de ejercicios (`ProgressionCard`) con selector de repeticiones, PR actual y gráfico de evolución (`ProgressionChart`).
  - **Historial**: Lista cronológica de todos los PRs registrados con pull-to-refresh, visualización de notas asociadas y menú contextual (Editar y Eliminar) por cada registro.
- **Modal de Carga / Edición**: `AddRecordModal` reutilizable que incluye campo de notas multilínea (`_notesController`, límite de 500 caracteres), precarga valores al editar y cambia título a "Editar Récord Personal" y botón a "Guardar Cambios".
- **Gráfico Nativo**:
  - Implementado con `CustomPainter` (`frontend/lib/features/records/presentation/widgets/progression_chart.dart`).
  - Cero dependencias externas adicionales en `pubspec.yaml`.
  - Gradiente inferior con color corporativo `AppColors.primary`.

---

## 5. Datos y Backend (Python FastAPI)
- **Arquitectura en 3 Capas**:
  - `app/api/v1/endpoints/records.py`: Endpoints `GET /progression`, `GET ""`, `POST ""`, `PUT "/{record_id}"`, `DELETE "/{record_id}"`.
  - `app/services/personal_record_service.py`: Lógica de negocio para `update_record` y `delete_record` con validación estricta de propiedad multitenant (`404` si no pertenece al usuario).
  - `app/repositories/personal_record_repository.py`: Métodos de persistencia `update` y `delete` con filtros de `user_id`.
  - `app/schemas/personal_record.py`: Modelos Pydantic `PersonalRecordCreateRequest`, `PersonalRecordUpdateRequest`, `PersonalRecordResponse`, `ProgressionPoint` y `ProgressionGroupResponse`.

---

## 6. Criterios de Aceptación Cumplidos
- [x] Los PRs se distribuyen y agrupan por ejercicio y repeticiones.
- [x] Se dibuja la curva de progresión de cargas con CustomPainter en orden cronológico.
- [x] Se muestran deltas (+kg) y badges de superación cuando el peso sube.
- [x] La carga de nuevos PRs permanece accesible y refresca tanto el historial como la gráfica.
- [x] Suite completa de pruebas unitarias y de integración pasando al 100% (`pytest` y `flutter test`).
- [x] Código limpio verificado con `flutter analyze` sin warnings.
