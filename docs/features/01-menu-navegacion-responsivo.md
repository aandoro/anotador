# [FEAT-001] Menú de Navegación Responsivo (Mobile & Web) y Separación de Páginas

## 1. Información General
- **ID**: `FEAT-001`
- **Nombre**: Menú de Navegación Adaptativo y Shell de Páginas
- **Módulo / Ámbito**: `frontend` (Flutter)
- **Plataformas**: Mobile (Android / iOS) & Web / Desktop
- **Estado**: `Implementado y Aprobado`

---

## 2. Objetivo y Contexto de Negocio
Actualmente, tras iniciar sesión, la app dirige directamente a la pantalla de perfil (`ProfileScreen`). 
El objetivo es proveer una estructura de navegación principal (Shell / Layout) que permita alternar de forma fluida entre las diferentes páginas del sistema (Perfil, Estado de Salud/Servicio y futuras vistas), adaptando la experiencia de usuario según se visualice en un dispositivo móvil o en un navegador web / pantalla de escritorio.

---

## 3. Requerimientos Funcionales
1. **Navegación Centralizada**: Al autenticarse el usuario, se debe cargar una estructura contenedora (`AppShell` o `MainNavigationScaffold`) en lugar de ir directo a una sola pantalla.
2. **Separación de Páginas**:
   - **Página 1 - Inicio / Dashboard**: Pantalla de bienvenida o resumen inicial (placeholder preparado para nuevas funcionalidades).
   - **Página 2 - Personal Records**: Pantalla donde el trainer va a poder ver sus PR y capaz tambien cargarlos (placeholder preparado para nuevas funcionalidades).
   - **Página 3 - Perfil**: Integrar la pantalla existente `ProfileScreen`.
3. **Persistencia de Estado entre Pestañas**: Cambiar entre pestañas no debe reiniciar el estado de la pantalla anterior (usar `IndexedStack` o patrón equivalente).
4. **Cierre de Sesión Accesible**: Mantener solo visible y accesible la opción para cerrar sesión en la pantalla de profile.

---

## 4. Diseño y Comportamiento UI / UX (Frontend)
- **Breakpoint de Adaptabilidad**: 640px de ancho de pantalla (o estándar de Material 3).
- **Modo Mobile (< 640px)**:
  - Barra de navegación inferior (`NavigationBar` de Material 3).
  - Iconos y etiquetas claras para cada sección (Inicio, Perfil, Salud).
- **Modo Web / Desktop (>= 640px)**:
  - Menú lateral (`NavigationRail` o Sidebar expansible).
  - Acceso directo a las secciones con etiquetas e iconos en el lateral izquierdo.
  - El contenido principal se muestra en el área restante a la derecha con márgenes cómodos.
- **Header / AppBar**:
  - AppBar consistente que muestre el título de la sección activa o el logo de la aplicación.

---

## 5. Datos y Backend
- **¿Requiere nuevos endpoints?**: No en esta fase. Reutiliza los providers y repositorios existentes (`AuthProvider`, datos locales de sesión).
- **Persistencia de Navegación**: Opcionalmente recordar la última pestaña seleccionada en memoria durante la sesión.

---

## 6. Criterios de Aceptación Iniciales
- [x] En pantallas angostas (Mobile), la barra de navegación se ubica en la parte inferior.
- [x] En pantallas anchas (Web / Desktop), la barra de navegación se transforma en un riel/menú lateral izquierdo.
- [x] Al cambiar de pestaña (ej. de Perfil a Records o Inicio), el estado de la pestaña anterior no se destruye ni se reinicia.
- [x] La acción de logout sigue funcionando correctamente y sólo desde la pantalla de Perfil.
- [x] El código pasa `flutter analyze` sin errores de linter.

---

## 7. Notas Técnicas y Sugerencias
- Ubicación sugerida del componente: `frontend/lib/features/navigation/` o `frontend/lib/core/layout/`.
- Usar widgets nativos de Flutter adaptativos (`LayoutBuilder` y `MediaQuery`).
