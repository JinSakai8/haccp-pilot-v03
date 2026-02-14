-- Directive 13: Fix Schema Mismatch & Harden Security
-- Run this in Supabase SQL Editor

-- =============================================================================
-- 1. Fix Hash Mismatch: Secure the active `haccp_logs` table
-- =============================================================================

-- Ensure table exists (if not created by code)
CREATE TABLE IF NOT EXISTS haccp_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category TEXT NOT NULL, -- 'gmp' or 'ghp'
    form_id TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    user_id UUID, -- References employees(id) logically
    zone_id UUID, -- References zones(id) logically
    created_at TIMESTAMPTZ DEFAULT NOW(),
    -- Audit columns
    created_by UUID REFERENCES auth.users(id), -- Supabase Auth User (Anon)
    updated_at TIMESTAMPTZ,
    updated_by UUID REFERENCES auth.users(id)
);

-- Enable RLS
ALTER TABLE haccp_logs ENABLE ROW LEVEL SECURITY;

-- Policy: Allow Read for Authenticated (incl. Anon with session)
CREATE POLICY "Enable read access for authenticated users" ON haccp_logs
FOR SELECT USING (auth.role() = 'authenticated');

-- Policy: Allow Insert for Authenticated (incl. Anon with session)
CREATE POLICY "Enable insert access for authenticated users" ON haccp_logs
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Trigger for updated_at (reuses function from Directive 10a)
DROP TRIGGER IF EXISTS set_haccp_logs_updated_at ON haccp_logs;
CREATE TRIGGER set_haccp_logs_updated_at
BEFORE UPDATE ON haccp_logs
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- 2. Secure Zones & Employee Zones
-- =============================================================================

-- Zones
ALTER TABLE zones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for authenticated users" ON zones
FOR SELECT USING (auth.role() = 'authenticated');

-- Employee Zones
ALTER TABLE employee_zones ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for authenticated users" ON employee_zones
FOR SELECT USING (auth.role() = 'authenticated');

-- =============================================================================
-- 3. Cleanup (Optional)
-- Drop unused tables if they are empty and not used
-- DROP TABLE IF EXISTS gmp_logs;
-- DROP TABLE IF EXISTS ghp_logs;
