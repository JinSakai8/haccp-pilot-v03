-- Directive 15: Fix Zones Schema
-- Run this in Supabase SQL Editor

-- Problem: Application expects 'venue_id' in 'zones' table, but it's missing.
-- Error: column zones_1.venue_id does not exist

-- 1. Add venue_id column to zones
ALTER TABLE zones 
ADD COLUMN IF NOT EXISTS venue_id UUID; 
-- Optionally add REFERENCES venues(id) if venues table exists, 
-- but to be safe and avoid dependency errors now, we just add the column.

-- 2. Update existing zones with a default venue_id if needed (optional)
-- UPDATE zones SET venue_id = '...' WHERE venue_id IS NULL;

-- 3. Verify RLS (from Directive 13, just in case)
ALTER TABLE zones ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'zones' AND policyname = 'Enable read access for authenticated users'
    ) THEN
        CREATE POLICY "Enable read access for authenticated users" ON zones
        FOR SELECT USING (auth.role() = 'authenticated');
    END IF;
END $$;
