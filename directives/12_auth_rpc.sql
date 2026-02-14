-- Directive 12: Secure Login RPC
-- Run this in Supabase SQL Editor to fix login issues caused by RLS.

-- =============================================================================
-- 1. Create Login RPC (Bypass RLS securely)
-- =============================================================================

CREATE OR REPLACE FUNCTION login_with_pin(pin_input text)
RETURNS SETOF employees
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with privileges of the creator (postgres), bypassing RLS
AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM employees
  WHERE pin_hash = pin_input
    AND is_active = true;
END;
$$;

-- Grant execute permission to everyone (public/anon can call this)
GRANT EXECUTE ON FUNCTION login_with_pin(text) TO anon, authenticated, service_role;

-- =============================================================================
-- 2. Verification (Optional)
-- =============================================================================
-- You can test this function in SQL Editor:
-- SELECT * FROM login_with_pin('YOUR_HASHED_PIN_HERE');
