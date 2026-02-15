-- 31_update_create_employee_rpc.sql
-- Directive: Update create_employee RPC to accept array of zone_ids.
-- Fixes: New employees having no zones assigned, preventing login.

BEGIN;

-- 1. Drop old function signature (to avoid ambiguity)
DROP FUNCTION IF EXISTS create_employee(text, text, text, timestamptz, boolean);

-- 2. Create updated function with zone_ids parameter
CREATE OR REPLACE FUNCTION create_employee(
  name_input text,
  pin_hash_input text,
  role_input text,
  sanepid_input timestamptz,
  zone_ids_input uuid[], -- ARRAY of UUIDs
  is_active_input boolean DEFAULT true
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER -- Bypass RLS
AS $$
DECLARE
  new_id uuid;
  z_id uuid;
BEGIN
  -- A. Insert Employee
  INSERT INTO employees (full_name, pin_hash, role, sanepid_expiry, is_active)
  VALUES (name_input, pin_hash_input, role_input, sanepid_input, is_active_input)
  RETURNING id INTO new_id;

  -- B. Insert Zone Assignments
  IF zone_ids_input IS NOT NULL THEN
    FOREACH z_id IN ARRAY zone_ids_input
    LOOP
      INSERT INTO employee_zones (employee_id, zone_id)
      VALUES (new_id, z_id)
      ON CONFLICT DO NOTHING;
    END LOOP;
  END IF;

  RETURN new_id;
END;
$$;

-- 3. Grant Permissions
GRANT EXECUTE ON FUNCTION create_employee(text, text, text, timestamptz, uuid[], boolean) TO anon, authenticated, service_role;

COMMIT;
