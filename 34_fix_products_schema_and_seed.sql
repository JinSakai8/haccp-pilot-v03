-- 34_fix_products_schema_and_seed.sql
-- Goal: Fix potentially missing venue_id column and restore deleted product data.

BEGIN;

-- 1. Ensure venue_id column exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'products' AND column_name = 'venue_id') THEN
        ALTER TABLE public.products ADD COLUMN venue_id UUID REFERENCES public.venues(id) ON DELETE CASCADE;
        -- We drop the old constraint if it exists to allow the new one
        ALTER TABLE public.products DROP CONSTRAINT IF EXISTS products_name_key; 
        ALTER TABLE public.products ADD CONSTRAINT products_name_venue_unique UNIQUE NULLS NOT DISTINCT (name, venue_id);
    END IF;
END $$;

-- 2. Re-seed Data (Safe Insert)
INSERT INTO public.products (name, type, venue_id) VALUES 
('Pierogi z Mięsem', 'cooling', NULL),
('Pierogi Ruskie', 'cooling', NULL),
('Pierogi z Kapustą', 'cooling', NULL),
('Pierogi z Owocami', 'cooling', NULL),
('Gołąbki', 'cooling', NULL),
('Bigos', 'cooling', NULL),
('Udka z Kurczaka', 'roasting', NULL),
('Kurczak Cały', 'roasting', NULL),
('Filet z Kurczaka', 'roasting', NULL),
('Schab Pieczony', 'roasting', NULL)
ON CONFLICT (name, venue_id) DO NOTHING;

-- 3. Ensure RLS allows reading (in case it was messed up)
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable read access for all" ON public.products;
CREATE POLICY "Enable read access for all" ON public.products FOR SELECT
USING (true);

COMMIT;
