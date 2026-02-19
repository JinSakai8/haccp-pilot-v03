-- Create products table
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    type TEXT NOT NULL, -- 'cooling', 'roasting', 'delivery', etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can read products
CREATE POLICY "Allow public read access" ON products
    FOR SELECT USING (true);

-- Policy: Only authenticated (or specific roles) can insert/update - for now open for auth users if needed, or just admin
-- We typically want employees to just read, but maybe Managers can add? 
-- For now, let's allow authenticated to read (already covered by public) and maybe insert if we add a "Manage Products" screen later.
-- Safe default: Read-only for app users.

-- Seed Data (Pierogi) for Cooling/Roasting
INSERT INTO products (name, type) VALUES 
('Pierogi z Mięsem', 'cooling'),
('Pierogi Ruskie', 'cooling'),
('Pierogi z Kapustą', 'cooling'),
('Pierogi z Owocami', 'cooling'),
('Gołąbki', 'cooling'),
('Bigos', 'cooling')
ON CONFLICT (name) DO NOTHING;
