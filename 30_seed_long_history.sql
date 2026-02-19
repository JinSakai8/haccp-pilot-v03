-- 30_seed_long_history.sql
-- Cel: Wygenerowanie długiej historii danych temperatury od września 2025 do dziś.
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
        RAISE NOTICE 'Generowanie długiej historii dla sensora: %', v_sensor.name;

        -- Generujemy dane od 1 września 2025 do teraz
        FOR v_timestamp IN 
            SELECT generate_series(
                '2025-09-01 00:00:00+01'::timestamptz, 
                NOW(), 
                INTERVAL '15 minutes'
            ) 
        LOOP
            -- Symulacja temperatury:
            -- Chłodnia: 2.0 - 6.0 °C
            -- Alert (1% szans): 8.5 - 11.5 °C
            
            IF random() < 0.01 THEN
               v_temp := 8.5 + (random() * 3.0);
               v_is_alert := true; 
            ELSE
               v_temp := 2.0 + (random() * 4.0);
               v_is_alert := false;
            END IF;

            -- Wstawiamy rekord tylko jeśli jeszcze go nie ma
            INSERT INTO temperature_logs (sensor_id, temperature_celsius, recorded_at, is_alert)
            SELECT v_sensor.id, ROUND(v_temp, 2), v_timestamp, v_is_alert
            WHERE NOT EXISTS (
                SELECT 1 FROM temperature_logs 
                WHERE sensor_id = v_sensor.id AND recorded_at = v_timestamp
            );
        END LOOP;
        
        RAISE NOTICE 'Zakończono sensor: %', v_sensor.name;
    END LOOP;
    
    RAISE NOTICE 'Gotowe! Baza zawiera teraz historię od września 2025.';
END $$;
