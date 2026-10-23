# Repositorio de Skills del Proyecto

Esta carpeta contiene las **Skills** (habilidades y procedimientos especializados) para los agentes de Antigravity en este workspace.

Antigravity descubre automáticamente cualquier habilidad ubicada en `.agents/skills/<nombre-skill>/SKILL.md` mediante **Progressive Disclosure** (carga únicamente el nombre y la descripción en el contexto, y solo lee el procedimiento completo cuando se activa).

---

## Estructura de una Skill

Cada skill debe tener su propio subdirectorio con un archivo obligatorio `SKILL.md`:

```text
.agents/skills/<nombre-skill>/
├── SKILL.md            # [Obligatorio] Instrucciones y frontmatter YAML
├── scripts/            # [Opcional] Scripts auxiliares ejecutables (PowerShell, Bash, Python)
├── examples/           # [Opcional] Ejemplos de referencia y snippets
├── resources/          # [Opcional] Plantillas, esquemas o assets
└── references/         # [Opcional] Documentación extendida o manuales detallados
```

---

## Plantilla para `SKILL.md`

El archivo `SKILL.md` debe comenzar con un bloque YAML con `name` y `description`:

```markdown
---
name: nombre-de-la-skill
description: >-
  Describe con precisión qué hace esta skill y cuándo debe usarla el agente.
  Escribe en tercera persona. Ejemplo: "Usa esta skill al configurar migraciones
  de base de datos con Alembic o cuando el usuario solicite migrar esquemas."
---

# Nombre de la Skill

Instrucciones claras y paso a paso para que el agente ejecute el procedimiento.

## Procedimiento

1. Paso 1...
2. Paso 2...
```

---

## Buenas Prácticas

1. **Nombre único**: Usa minúsculas y guiones (ej. `flutter-state-management`, `fastapi-alembic-migrations`).
2. **Descripción precisa**: El campo `description` es lo más crítico; el orquestador lo lee para decidir cuándo invocar la habilidad.
3. **Progressive Disclosure**: Mantén `SKILL.md` conciso. Mueve documentación pesada a la subcarpeta `references/` y enlázala con links relativos.
