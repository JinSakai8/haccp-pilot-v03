-- 18_seed_monitoring.sql
-- Cel: Wyczyszczenie starych danych monitoringowych i wygenerowanie danych testowych.
-- WERSJA POPRAWIONA: Używa istniejącego ZONE_ID przypisanego do pracowników (Kuchnia).

BEGIN;

-- 1. Czyszczenie starych danych
DELETE FROM annotations; -- Usuwamy też adnotacje jeśli są FK
DELETE FROM temperature_logs;
DELETE FROM sensors;

-- 2. Pobranie ID strefy 'Kuchnia' która JEST UŻYWANA przez pracowników
-- Zamiast tworzyć nową, szukamy takiej, która jest w employee_zones
DO $$
DECLARE
    v_venue_id UUID;
    v_zone_id UUID;
    v_sensor_mies UUID;
    v_sensor_nabial UUID;
    v_sensor_mroznia UUID;
    v_time TIMESTAMP;
    v_temp NUMERIC;
    v_is_alert BOOLEAN;
    i INT;
BEGIN
    -- Pobierz ID strefy 'Kuchnia' powiązanej z jakimkolwiek pracownikiem
    -- Dzieki temu po zalogowaniu na usera, dashboard (korzystający z employee_zones) pokaże te sensory
    SELECT ez.zone_id INTO v_zone_id
    FROM employee_zones ez
    JOIN zones z ON z.id = ez.zone_id
    WHERE z.name = 'Kuchnia'
    LIMIT 1;

    -- Fallback: Jeśli nie ma pracownika w Kuchni, weź po prostu strefę Kuchnia z tabeli zones
    IF v_zone_id IS NULL THEN
        SELECT id INTO v_zone_id FROM zones WHERE name = 'Kuchnia' LIMIT 1;
    END IF;

    -- Jeśli nadal NULL, rzuć błąd (User musi najpierw odpalić Auth seeda)
    IF v_zone_id IS NULL THEN
        RAISE EXCEPTION 'Brak strefy Kuchnia. Uruchom najpierw skrypty 15_fix_venues_and_zones.sql lub dodaj strefę.';
    END IF;

    RAISE NOTICE 'Seeding sensors for Zone ID: %', v_zone_id;

    -- 3. Dodanie Sensorów (z ustalonym ID do logów)
    v_sensor_mies := gen_random_uuid();
    v_sensor_nabial := gen_random_uuid();
    v_sensor_mroznia := gen_random_uuid();

    INSERT INTO sensors (id, name, zone_id, is_active, interval_minutes)
    VALUES 
        (v_sensor_mies, 'Chłodnia Mięs', v_zone_id, true, 15),
        (v_sensor_nabial, 'Chłodnia Nabiał', v_zone_id, true, 15),
        (v_sensor_mroznia, 'Mroźnia Główna', v_zone_id, true, 60);

    -- 4. Generowanie Logów (24h wstecz)
    -- Generujemy 96 pomiarów (24h * 4 pomiary/h)
    FOR i IN 0..96 LOOP
        v_time := NOW() - (INTERVAL '15 minutes' * i);
        
        -- A. Chłodnia Nabiał (Stabilna: 3.0 - 5.0)
        v_temp := 3.0 + (random() * 2.0);
        INSERT INTO temperature_logs (sensor_id, temperature_celsius, recorded_at, is_alert, is_acknowledged)
        VALUES (v_sensor_nabial, round(v_temp, 1), v_time, false, false);

        -- B. Chłodnia Mięs (Skoki w nocy)
        -- Normalnie 2.0 - 4.0. Ale 5 pomiarów temu (ok 1h temu) skok do 12.0
        IF i BETWEEN 4 AND 6 THEN
            v_temp := 11.0 + (random() * 2.0); -- AWARIA (11-13st)
            v_is_alert := true;
        ELSE
            v_temp := 2.0 + (random() * 2.0); -- OK (2-4st)
            v_is_alert := false;
        END IF;

        INSERT INTO temperature_logs (sensor_id, temperature_celsius, recorded_at, is_alert, is_acknowledged)
        VALUES (v_sensor_mies, round(v_temp, 1), v_time, v_is_alert, false);

        -- C. Mroźnia (Rzadziej, ale symulujemy co 15min dla uproszczenia pętli, w realu byłoby rzadziej)
        v_temp := -18.0 + (random() * 2.0); -- -18 do -16
        INSERT INTO temperature_logs (sensor_id, temperature_celsius, recorded_at, is_alert, is_acknowledged)
        VALUES (v_sensor_mroznia, round(v_temp, 1), v_time, false, false);
        
    END LOOP;

    -- Dodaj przykładowe adnotacje
    INSERT INTO annotations (sensor_id, label, comment, created_at)
    VALUES 
        (v_sensor_mies, 'Dostawa', 'Przyjęcie towaru', NOW() - INTERVAL '2 hours'),
        (v_sensor_nabial, 'Mycie', 'Dezynfekcja okresowa', NOW() - INTERVAL '5 hours');

END $$;

COMMIT;
