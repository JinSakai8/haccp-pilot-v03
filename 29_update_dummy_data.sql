-- 29_update_dummy_data.sql
-- Cel: Uzupełnienie danych temperatury od 15.02.2026 do dziś (19.02.2026).
-- Skrypt dodaje pomiary co 15 minut dla wszystkich aktywnych sensorów.

DO $$
DECLARE
    v_sensor RECORD;
    v_timestamp TIMESTAMPTZ;
    v_temp NUMERIC;
    v_is_alert BOOLEAN;
BEGIN
    -- Dla każdego aktywnego sensora
    FOR v_sensor IN SELECT id, name FROM sensors WHERE is_active = true LOOP
        RAISE NOTICE 'Aktualizacja danych dla sensora: %', v_sensor.name;

        -- Generujemy dane od 15 lutego 2026, godz. 00:00 do teraz
        FOR v_timestamp IN 
            SELECT generate_series(
                '2026-02-15 00:00:00+01'::timestamptz, 
                NOW(), 
                INTERVAL '15 minutes'
            ) 
        LOOP
            -- Symulacja temperatury (analogiczna do skryptu 28):
            -- Standardowo: 2.0 - 6.0 °C
            -- Alert (1% szans): 8.0 - 10.5 °C
            
            IF random() < 0.01 THEN
               v_temp := 8.0 + (random() * 2.5);
               v_is_alert := true; 
            ELSE
               v_temp := 2.0 + (random() * 4.0);
               v_is_alert := false;
            END IF;

            -- Wstawiamy tylko jeśli rekord dla tego sensora i czasu jeszcze nie istnieje
            -- (Zabezpieczenie przed duplikatami)
            INSERT INTO temperature_logs (sensor_id, temperature_celsius, recorded_at, is_alert)
            SELECT v_sensor.id, ROUND(v_temp, 2), v_timestamp, v_is_alert
            WHERE NOT EXISTS (
                SELECT 1 FROM temperature_logs 
                WHERE sensor_id = v_sensor.id AND recorded_at = v_timestamp
            );
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Aktualizacja zakońona. Dane od 15.02 do dziś są już w bazie.';
END $$;
