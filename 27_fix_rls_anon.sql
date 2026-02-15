-- 27_fix_rls_anon.sql
-- ROOT CAUSE FIX: App uses signInAnonymously() which may use 'anon' role.
-- Previous RLS policies only allowed 'authenticated' role.
-- This fix allows BOTH 'anon' AND 'authenticated' to read sensors and logs.

BEGIN;

-- ═══════════════════════════════════════════
-- SENSORS
-- ═══════════════════════════════════════════
DROP POLICY IF EXISTS "Sensors readable by all authenticated" ON sensors;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON sensors;
DROP POLICY IF EXISTS "Sensors readable by all" ON sensors;

CREATE POLICY "Sensors readable by all"
ON sensors
FOR SELECT
TO anon, authenticated
USING (true);

-- ═══════════════════════════════════════════
-- TEMPERATURE_LOGS
-- ═══════════════════════════════════════════
DROP POLICY IF EXISTS "Logs readable by all authenticated" ON temperature_logs;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON temperature_logs;
DROP POLICY IF EXISTS "Logs readable by all" ON temperature_logs;
DROP POLICY IF EXISTS "Logs updateable by authenticated" ON temperature_logs;
DROP POLICY IF EXISTS "Logs updateable by all" ON temperature_logs;

CREATE POLICY "Logs readable by all"
ON temperature_logs
FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Logs updateable by all"
ON temperature_logs
FOR UPDATE
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- ═══════════════════════════════════════════
-- ANNOTATIONS
-- ═══════════════════════════════════════════
DROP POLICY IF EXISTS "Annotations readable by all" ON annotations;
DROP POLICY IF EXISTS "Annotations insertable by authenticated" ON annotations;
DROP POLICY IF EXISTS "Annotations readable" ON annotations;
DROP POLICY IF EXISTS "Annotations insertable" ON annotations;

CREATE POLICY "Annotations readable"
ON annotations
FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "Annotations insertable"
ON annotations
FOR INSERT
TO anon, authenticated
WITH CHECK (true);

COMMIT;
