-- 18_seed_monitoring.sql
-- Cel: Wyczyszczenie starych danych monitoringowych i wygenerowanie danych testowych.

BEGIN;

-- 1. Czyszczenie starych danych (z zachowaniem integralności)
DELETE FROM temperature_logs;
DELETE FROM sensors;
-- Nie usuwamy stref (zones), bo mogą być używane przez inne moduły (np. users).

-- 2. Pobranie lub utworzenie strefy 'Kuchnia'
DO $$
DECLARE
    v_venue_id UUID;
    v_zone_id UUID;
BEGIN
    -- Pobierz pierwsze venue (zakładamy że istnieje po poprzednich fixach)
    SELECT id INTO v_venue_id FROM venues LIMIT 1;
    
    -- Jeśli nie ma venue, przerwij (to nie powinno się zdarzyć w działającej appce)
    IF v_venue_id IS NULL THEN
        RAISE EXCEPTION 'Brak Venue w bazie. Uruchom najpierw skrypty podstawowe.';
    END IF;

    -- Sprawdź czy strefa 'Kuchnia' istnieje w tym venue
    SELECT id INTO v_zone_id FROM zones WHERE name = 'Kuchnia' AND venue_id = v_venue_id LIMIT 1;

    -- Jeśli nie, utwórz
    IF v_zone_id IS NULL THEN
        INSERT INTO zones (name, venue_id) VALUES ('Kuchnia', v_venue_id) RETURNING id INTO v_zone_id;
    END IF;

    -- 3. Dodanie Sensorów
    -- Sensor A: Chłodnia Mięs (Skoki temperatur)
    INSERT INTO sensors (id, name, zone_id, is_active, interval_minutes)
    VALUES 
        (gen_random_uuid(), 'Chłodnia Mięs', v_zone_id, true, 15),
        (gen_random_uuid(), 'Chłodnia Nabiał', v_zone_id, true, 15);

END $$;

-- 4. Generowanie Logów (PL/pgSQL dla złożonej logiki)
DO $$
DECLARE
    v_sensor_mies UUID;
    v_sensor_nabial UUID;
    v_time TIMESTAMP;
    v_temp NUMERIC;
    v_is_alert BOOLEAN;
    i INT;
BEGIN
    SELECT id INTO v_sensor_mies FROM sensors WHERE name = 'Chłodnia Mięs' LIMIT 1;
    SELECT id INTO v_sensor_nabial FROM sensors WHERE name = 'Chłodnia Nabiał' LIMIT 1;

    -- Generujemy 96 pomiarów (24h * 4 pomiary/h)
    FOR i IN 0..96 LOOP
        v_time := NOW() - (INTERVAL '15 minutes' * i);
        
        -- A. Chłodnia Nabiał (Stabilna: 3.0 - 5.0)
        v_temp := 3.0 + random() * 2.0;
        INSERT INTO temperature_logs (sensor_id, temperature_celsius, recorded_at, is_alert)
        VALUES (v_sensor_nabial, round(v_temp, 1), v_time, false);

        -- B. Chłodnia Mięs (Skoki w nocy)
        -- Normalnie 2.0 - 4.0. Ale 5 pomiarów temu (ok 1h temu) skok do 12.0
        IF i BETWEEN 4 AND 6 THEN
            v_temp := 11.0 + random() * 2.0; -- AWARIA (11-13st)
            v_is_alert := true;
        ELSE
            v_temp := 2.0 + random() * 2.0; -- OK (2-4st)
            v_is_alert := false;
        END IF;

        INSERT INTO temperature_logs (sensor_id, temperature_celsius, recorded_at, is_alert)
        VALUES (v_sensor_mies, round(v_temp, 1), v_time, v_is_alert);
        
    END LOOP;
END $$;

COMMIT;
