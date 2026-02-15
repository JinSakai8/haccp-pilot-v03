-- 32_reapply_hr_rpcs.sql
-- Directive: Re-apply HR RPCs to ensure Sanepid Update works
-- This is a precautionary step to ensure the function signature and permissions are 100% correct.

BEGIN;

-- 1. Ensure update_employee_sanepid exists with correct signature
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

-- 2. Grant Permissions (Explicitly)
GRANT EXECUTE ON FUNCTION update_employee_sanepid(uuid, timestamptz) TO anon, authenticated, service_role;

COMMIT;
