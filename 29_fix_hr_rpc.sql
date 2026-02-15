-- 29_fix_hr_rpc.sql
-- Directive: Fix HR Module RLS issues by providing Secure RPCs for Kiosk Mode (Anon/Authenticated)
-- This allows the application to manage employees without exposing the employees table to direct writes from anon users.

BEGIN;

-- =============================================================================
-- 1. check_pin_availability
-- =============================================================================
CREATE OR REPLACE FUNCTION check_pin_availability(pin_input text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER -- Bypass RLS
AS $$
DECLARE
  exists_count int;
BEGIN
  SELECT count(*)
  INTO exists_count
  FROM employees
  WHERE pin_hash = pin_input;

  RETURN exists_count = 0;
END;
$$;

GRANT EXECUTE ON FUNCTION check_pin_availability(text) TO anon, authenticated, service_role;

-- =============================================================================
-- 2. create_employee
-- =============================================================================
CREATE OR REPLACE FUNCTION create_employee(
  name_input text,
  pin_hash_input text,
  role_input text,
  sanepid_input timestamptz,
  is_active_input boolean DEFAULT true
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER -- Bypass RLS
AS $$
DECLARE
  new_id uuid;
BEGIN
  INSERT INTO employees (full_name, pin_hash, role, sanepid_expiry, is_active)
  VALUES (name_input, pin_hash_input, role_input, sanepid_input, is_active_input)
  RETURNING id INTO new_id;

  RETURN new_id;
END;
$$;

GRANT EXECUTE ON FUNCTION create_employee(text, text, text, timestamptz, boolean) TO anon, authenticated, service_role;

-- =============================================================================
-- 3. update_employee_sanepid
-- =============================================================================
CREATE OR REPLACE FUNCTION update_employee_sanepid(
  employee_id uuid,
  new_expiry timestamptz
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- Bypass RLS
AS $$
BEGIN
  UPDATE employees
  SET sanepid_expiry = new_expiry,
      updated_at = now()
  WHERE id = employee_id;
END;
$$;

GRANT EXECUTE ON FUNCTION update_employee_sanepid(uuid, timestamptz) TO anon, authenticated, service_role;

-- =============================================================================
-- 4. toggle_employee_active
-- =============================================================================
CREATE OR REPLACE FUNCTION toggle_employee_active(
  employee_id uuid,
  new_status boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- Bypass RLS
AS $$
BEGIN
  UPDATE employees
  SET is_active = new_status,
      updated_at = now()
  WHERE id = employee_id;
END;
$$;

GRANT EXECUTE ON FUNCTION toggle_employee_active(uuid, boolean) TO anon, authenticated, service_role;

COMMIT;
