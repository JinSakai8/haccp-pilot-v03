-- 20_diagnostic_zones.sql
-- DIAGNOSTYKA: Sprawdź co jest w tabelach zones i employee_zones
-- Uruchom to w Supabase SQL Editor żeby zobaczyć aktualny stan

-- 1. Pokaż WSZYSTKIE strefy
SELECT id, name, venue_id FROM zones ORDER BY name;

-- 2. Pokaż WSZYSTKIE powiązania pracownik-strefa
SELECT 
    ez.employee_id,
    e.full_name,
    ez.zone_id,
    z.name as zone_name
FROM employee_zones ez
LEFT JOIN employees e ON e.id = ez.employee_id
LEFT JOIN zones z ON z.id = ez.zone_id
ORDER BY e.full_name;

-- 3. Pokaż typ kolumny id w zones
SELECT column_name, data_type, udt_name 
FROM information_schema.columns 
WHERE table_name = 'zones' AND column_name = 'id';

-- 4. Pokaż typ kolumny zone_id w sensors
SELECT column_name, data_type, udt_name 
FROM information_schema.columns 
WHERE table_name = 'sensors' AND column_name = 'zone_id';

-- 5. Pokaż typ kolumny zone_id w employee_zones
SELECT column_name, data_type, udt_name 
FROM information_schema.columns 
WHERE table_name = 'employee_zones' AND column_name = 'zone_id';

-- 6. Pokaż sensory
SELECT id, name, zone_id, is_active FROM sensors;
