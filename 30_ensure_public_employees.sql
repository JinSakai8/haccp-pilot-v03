-- 30_ensure_public_employees.sql
-- Directive: Ensure public_employees view exists and has correct columns for HR module.
-- Fixes: "Status Aktywny" toggle not working (likely due to missing is_active column or RLS)

BEGIN;

-- 1. Drop existing view to ensure clean slate
DROP VIEW IF EXISTS public_employees;

-- 2. Recreate View with ALL required columns for HR Module
-- Note: we EXCLUDE pin_hash for security.
CREATE VIEW public_employees AS
SELECT 
  id,
  full_name,
  role,
  is_active,
  sanepid_expiry,
  created_at,
  updated_at
FROM employees;

-- 3. Grant Permissions
-- Kiosk Mode uses 'anon' or 'authenticated' depending on sign-in state.
-- We grant SELECT to both.
GRANT SELECT ON public_employees TO anon, authenticated, service_role;

COMMIT;
