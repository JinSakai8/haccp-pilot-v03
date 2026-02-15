-- 26_fix_sensor_rls.sql
-- Cel: Naprawa uprawnień RLS (Row Level Security).
-- Aplikacja nie widzi sensorów, mimo że są w bazie, bo brakuje polityki SELECT dla authenticated users.

BEGIN;

-- 1. Upewnij się, że RLS jest włączone
ALTER TABLE sensors ENABLE ROW LEVEL SECURITY;
ALTER TABLE temperature_logs ENABLE ROW LEVEL SECURITY;

-- 2. Usuń stare polityki (żeby nie dublować)
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON sensors;
DROP POLICY IF EXISTS "Sensors readable by all authenticated" ON sensors;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON temperature_logs;
DROP POLICY IF EXISTS "Logs readable by all authenticated" ON temperature_logs;

-- 3. Dodaj politykę: Każdy zalogowany użytkownik widzi WSZYSTKIE sensory
-- (W przyszłości można ograniczyć do przypisanej strefy, ale na start - full access)
CREATE POLICY "Sensors readable by all authenticated"
ON sensors
FOR SELECT
TO authenticated
USING (true);

-- 4. Dodaj politykę: Każdy zalogowany użytkownik widzi WSZYSTKIE logi
CREATE POLICY "Logs readable by all authenticated"
ON temperature_logs
FOR SELECT
TO authenticated
USING (true);

-- 5. Dodaj politykę UPDATE dla logów (potwierdzanie alarmów)
CREATE POLICY "Logs updateable by authenticated"
ON temperature_logs
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

COMMIT;
