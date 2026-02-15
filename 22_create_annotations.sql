-- 22_create_annotations.sql
-- Cel: Stworzyć tabelę do przechowywania adnotacji na wykresach temperatur (np. "Dostawa", "Mycie")

BEGIN;

CREATE TABLE IF NOT EXISTS annotations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_id UUID NOT NULL REFERENCES sensors(id) ON DELETE CASCADE,
    label TEXT NOT NULL,          -- 'Dostawa', 'Defrost', 'Mycie', 'Awaria', 'Inne'
    comment TEXT,
    created_by UUID REFERENCES employees(id), -- Opcjonalne, jeśli user jest null w seedzie
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Włącz RLS
ALTER TABLE annotations ENABLE ROW LEVEL SECURITY;

-- Polityki (uproszczone dla Kiosk Mode, dopasuj jeśli masz rygorystyczny auth)
DROP POLICY IF EXISTS "Annotations readable by all" ON annotations;
CREATE POLICY "Annotations readable by all" ON annotations FOR SELECT USING (true);

DROP POLICY IF EXISTS "Annotations insertable by authenticated" ON annotations;
CREATE POLICY "Annotations insertable by authenticated" ON annotations FOR INSERT WITH CHECK (true);

COMMIT;
