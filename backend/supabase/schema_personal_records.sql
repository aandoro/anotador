-- ==============================================================================
-- Tabla: public.personal_records
-- Persistencia de marcas y récords personales (PRs) vinculados a cada usuario
-- ==============================================================================

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

-- Habilitar Row Level Security (RLS)
ALTER TABLE public.personal_records ENABLE ROW LEVEL SECURITY;

-- 1. Política de Lectura (SELECT):
-- Cada usuario solo puede consultar sus propios récords personales
DROP POLICY IF EXISTS "Usuarios leen sus propios records" ON public.personal_records;
CREATE POLICY "Usuarios leen sus propios records" 
    ON public.personal_records FOR SELECT 
    USING (auth.uid() = user_id);

-- 2. Política de Inserción (INSERT):
-- Cada usuario solo puede registrar récords asociados a su propio user_id
DROP POLICY IF EXISTS "Usuarios insertan sus propios records" ON public.personal_records;
CREATE POLICY "Usuarios insertan sus propios records" 
    ON public.personal_records FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- 3. Política de Modificación (UPDATE):
DROP POLICY IF EXISTS "Usuarios modifican sus propios records" ON public.personal_records;
CREATE POLICY "Usuarios modifican sus propios records" 
    ON public.personal_records FOR UPDATE 
    USING (auth.uid() = user_id);

-- 4. Política de Eliminación (DELETE):
DROP POLICY IF EXISTS "Usuarios eliminan sus propios records" ON public.personal_records;
CREATE POLICY "Usuarios eliminan sus propios records" 
    ON public.personal_records FOR DELETE 
    USING (auth.uid() = user_id);

-- Índices para optimizar consultas filtradas por usuario y ordenadas por fecha
CREATE INDEX IF NOT EXISTS idx_personal_records_user ON public.personal_records (user_id);
CREATE INDEX IF NOT EXISTS idx_personal_records_user_date ON public.personal_records (user_id, record_date DESC);
