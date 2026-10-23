-- ==============================================================================
-- Tabla: public.exercises
-- Catálogo oficial de ejercicios de fuerza y acondicionamiento
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Habilitar Row Level Security (RLS)
ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;

-- 1. Política de Lectura (SELECT):
-- Permitida a todos los usuarios (anónimos o autenticados) para autocompletar PRs
DROP POLICY IF EXISTS "Lectura publica de ejercicios" ON public.exercises;
CREATE POLICY "Lectura publica de ejercicios" 
    ON public.exercises FOR SELECT 
    USING (true);

-- 2. Política de Inserción (INSERT):
-- Únicamente administradores (vía profiles.role = 'admin') o service_role
DROP POLICY IF EXISTS "Insercion autorizada de ejercicios" ON public.exercises;
CREATE POLICY "Insercion autorizada de ejercicios" 
    ON public.exercises FOR INSERT 
    WITH CHECK (
        (auth.jwt() ->> 'role') = 'service_role' OR 
        auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin')
    );

-- 3. Política de Actualización (UPDATE):
-- Únicamente administradores o service_role
DROP POLICY IF EXISTS "Modificacion autorizada de ejercicios" ON public.exercises;
CREATE POLICY "Modificacion autorizada de ejercicios" 
    ON public.exercises FOR UPDATE 
    USING (
        (auth.jwt() ->> 'role') = 'service_role' OR 
        auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin')
    );

-- Índices para optimizar búsquedas por nombre insensible a mayúsculas
CREATE INDEX IF NOT EXISTS idx_exercises_name_lower ON public.exercises (lower(name));

-- 4. Carga inicial del catálogo estándar (idempotente)
INSERT INTO public.exercises (name) VALUES
    ('Sentadilla Trasera'),
    ('Sentadilla Frontal'),
    ('Press de Banca Plano'),
    ('Press de Banca Inclinado'),
    ('Peso Muerto Convencional'),
    ('Peso Muerto Sumo'),
    ('Peso Muerto Rumano'),
    ('Press Militar con Barra'),
    ('Press Militar con Mancuernas'),
    ('Remo con Barra'),
    ('Dominadas Lastradas'),
    ('Fondos en Paralelas'),
    ('Hip Thrust'),
    ('Prensa de Piernas'),
    ('Zancadas con Mancuernas')
ON CONFLICT (name) DO NOTHING;
