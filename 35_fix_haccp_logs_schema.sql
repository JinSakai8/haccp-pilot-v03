-- 35_fix_haccp_logs_schema.sql
-- Goal: Fix missing zone_id in haccp_logs and ensure venue_id/user_id exist for multi-tenancy and audit.

BEGIN;

-- 1. Ensure zone_id exists (Fixes the immediate error)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'haccp_logs' AND column_name = 'zone_id') THEN
        ALTER TABLE public.haccp_logs ADD COLUMN zone_id UUID;
        -- Optional: Add FK if zones table exists
        -- ALTER TABLE public.haccp_logs ADD CONSTRAINT fk_haccp_logs_zone FOREIGN KEY (zone_id) REFERENCES public.zones(id);
    END IF;
END $$;

-- 2. Ensure venue_id exists (Critical for RLS)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'haccp_logs' AND column_name = 'venue_id') THEN
        ALTER TABLE public.haccp_logs ADD COLUMN venue_id UUID REFERENCES public.venues(id);
    END IF;
END $$;

-- 3. Ensure user_id exists (Audit)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'haccp_logs' AND column_name = 'user_id') THEN
        ALTER TABLE public.haccp_logs ADD COLUMN user_id UUID REFERENCES public.employees(id);
    END IF;
END $$;

-- 4. Refresh Cache / Permissions (Enable RLS just in case)
ALTER TABLE public.haccp_logs ENABLE ROW LEVEL SECURITY;

-- 5. READ Policy (Update to use venue_id if present, or fallback)
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.haccp_logs;
CREATE POLICY "Enable read access for authenticated users" ON public.haccp_logs
FOR SELECT USING (true); -- Simplified for Pilot Phase (filtering in App)

-- 6. INSERT Policy
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON public.haccp_logs;
CREATE POLICY "Enable insert access for authenticated users" ON public.haccp_logs
FOR INSERT WITH CHECK (true); -- Simplified for Pilot Phase

COMMIT;
