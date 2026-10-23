# Mio API - Backend

Backend en FastAPI para el proyecto **Mio**, estructurado modularmente con tipado estricto, esquemas Pydantic v2 y configuración por entornos.

## Prerrequisitos
- Python 3.10 o superior (recomendado 3.11+)

## Instalación y Puesta en Marcha

### 1. Crear y activar el entorno virtual
En Windows (PowerShell):
```powershell
python -m venv .venv
.\.venv\Scripts\activate.bat
```

En Linux / macOS:
```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 2. Instalar dependencias
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 3. Configurar variables de entorno
```powershell
# En Windows PowerShell:
Copy-Item .env.example .env

# En Linux / macOS:
cp .env.example .env
```

### 4. Iniciar el servidor de desarrollo
```bash
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

### 5. Documentación Interactiva y Health Check
- Swagger UI: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- ReDoc: [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)
- Health Check: [http://127.0.0.1:8000/api/v1/health](http://127.0.0.1:8000/api/v1/health)

## Ejecutar Pruebas Automatizadas
```bash
pytest -v
```
