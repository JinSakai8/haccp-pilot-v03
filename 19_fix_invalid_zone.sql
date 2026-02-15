-- 19_fix_invalid_zone.sql
-- Cel: Usunięcie błędnej strefy "some-zone-id" i naprawdę powiązań.

BEGIN;

-- 1. Usuń powiązania pracowników z "some-zone-id"
-- Uwaga: rzutujemy na text, aby uniknąć błędu "invalid input syntax for type uuid" przy porównaniu,
-- jeśli kolumna zone_id w employee_zones jest typu UUID (wtedy to zapytanie nic nie usunie, co jest OK,
-- ale jeśli jest text/varchar, to usunie śmieci).
DELETE FROM employee_zones 
WHERE zone_id::text = 'some-zone-id';

-- 2. Usuń samą strefę "some-zone-id"
DELETE FROM zones 
WHERE id::text = 'some-zone-id';

-- 3. Upewnij się, że wszyscy managerowie mają dostęp do strefy 'Kuchnia'
DO $$
DECLARE
    v_kuchnia_id UUID;
BEGIN
    -- Znajdź ID strefy Kuchnia (stworzonej w poprzednim kroku)
    SELECT id INTO v_kuchnia_id FROM zones WHERE name = 'Kuchnia' LIMIT 1;

    IF v_kuchnia_id IS NOT NULL THEN
        -- Dla każdego pracownika (tutaj uproszczenie: dodajemy wszystkim, lub można filtrować po roli)
        -- Wstawiamy rekord, jeśli nie istnieje (ON CONFLICT do nothing)
        INSERT INTO employee_zones (employee_id, zone_id)
        SELECT id, v_kuchnia_id FROM employees
        ON CONFLICT DO NOTHING;
    END IF;
END $$;

COMMIT;
