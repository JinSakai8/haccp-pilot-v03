-- 25_fix_force_kuchnia.sql
-- Cel: Przypisać sensory do strefy 'Kuchnia', do której Twój użytkownik ma dostęp.

DO $$
DECLARE
    v_kuchnia_zone_id UUID;
BEGIN
    -- 1. Znajdź ID strefy o nazwie 'Kuchnia' (lub podobnej), która JEST w twoich uprawnieniach (employee_zones)
    SELECT ez.zone_id INTO v_kuchnia_zone_id
    FROM employee_zones ez
    JOIN zones z ON z.id = ez.zone_id
    WHERE z.name ILIKE '%Kuchnia%'  -- ILIKE = case insensitive
    LIMIT 1;

    -- Jeśli nie znaleziono w employee_zones, szukaj w ogólnej tabeli zones
    IF v_kuchnia_zone_id IS NULL THEN
        SELECT id INTO v_kuchnia_zone_id
        FROM zones
        WHERE name ILIKE '%Kuchnia%'
        LIMIT 1;
    END IF;

    IF v_kuchnia_zone_id IS NULL THEN
        RAISE EXCEPTION 'Nie znaleziono strefy Kuchnia!';
    END IF;

    RAISE NOTICE 'Updating sensors to Kuchnia Zone ID: %', v_kuchnia_zone_id;

    -- 2. Aktualizuj sensory
    UPDATE sensors
    SET zone_id = v_kuchnia_zone_id;

END $$;
