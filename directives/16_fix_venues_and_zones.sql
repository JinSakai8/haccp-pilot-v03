-- Directive 16: Create Venues & Fix Zones Data
-- Run this in Supabase SQL Editor

-- Problem: Error "relation 'venues' does not exist"
-- Cause: The venues table (M08) was not created, but zones depend on it.

-- 1. Create venues table
CREATE TABLE IF NOT EXISTS venues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    address TEXT,
    nip TEXT,
    logo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- 2. Enable RLS for venues
ALTER TABLE venues ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for authenticated users" ON venues
FOR SELECT USING (auth.role() = 'authenticated');

-- 3. Insert Default Venue
INSERT INTO venues (id, name, address, nip, created_at)
VALUES (
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', -- Fixed UUID for consistency
    'Główny Lokal', 
    'Adres Lokalu', 
    '1234567890',
    NOW()
)
ON CONFLICT (id) DO NOTHING;

-- 4. Update existing zones to link to this venue
-- This fixes the "null check operator used on a null value" error in the app
UPDATE zones
SET venue_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
WHERE venue_id IS NULL;

-- 5. Trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS set_venues_updated_at ON venues;
CREATE TRIGGER set_venues_updated_at
BEFORE UPDATE ON venues
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
