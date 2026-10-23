# Mio App - Frontend Flutter

Aplicación cliente en Flutter para la plataforma **Mio**, estructurada bajo Clean Architecture (Domain, Data, Presentation) y Material 3.

## Prerrequisitos
- Flutter SDK (versión >= 3.0.0)
- Navegador Google Chrome (para desarrollo web) o entorno C++ Desktop para Windows

## Instalación y Ejecución

### 1. Descargar dependencias
```bash
flutter pub get
```

### 2. Análisis estático y linter
```bash
flutter analyze
```

### 3. Ejecución de pruebas unitarias
```bash
flutter test
```

### 4. Levantar la aplicación
Asegúrate de que el Backend esté ejecutándose en `http://127.0.0.1:8000`.

- Para ejecutar en Google Chrome (fijando el puerto configurado en CORS):
```bash
flutter run -d chrome --web-port=3000
```

- Para ejecutar en Windows Desktop:
```bash
flutter run -d windows
```

## Configuración de Red
La URL base del backend se encuentra configurada en `lib/core/constants/api_endpoints.dart`. Si utilizas un emulador de Android, cambia `127.0.0.1` por `10.0.2.2`.
