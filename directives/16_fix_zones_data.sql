-- Directive 16: Fix Zones Data (Null venue_id)
-- Run this in Supabase SQL Editor

-- Problem: Error "type 'null' is not a subtype of type 'String'"
-- Cause: 'zones' table has 'venue_id' column (added recently), but it is NULL for existing records.
-- The app requires a non-null String.

-- 1. Ensure a default venue exists
INSERT INTO venues (id, name, address, nip, created_at)
VALUES (
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', -- Default UUID
    'Główny Lokal', 
    'Adres Lokalu', 
    '1234567890',
    NOW()
)
ON CONFLICT (id) DO NOTHING; -- Skip if already exists or conflict logic applies (assuming id is pkey)
-- NOTE: If venues have no hardcoded ID, we just insert if table empty.

-- 2. Update existing zones to link to this venue
UPDATE zones
SET venue_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
WHERE venue_id IS NULL;

-- 3. (Optional) Enforce NOT NULL for future safety
-- ALTER TABLE zones ALTER COLUMN venue_id SET NOT NULL;
