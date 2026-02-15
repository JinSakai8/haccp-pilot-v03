-- 28_seed_dummy_data.sql
-- Cel: Wygenerowanie testowych danych temperatury dla wszystkich aktywnych sensorów z ostatnich 30 dni.
-- Używa pętli integer do generowania historii co 15 minut (bezpieczniejsze niż cursor loop).

DO $$
DECLARE
    v_sensor RECORD;
    v_timestamp TIMESTAMPTZ;
    v_temp NUMERIC;
    v_is_alert BOOLEAN;
    v_steps INTEGER;
    i INTEGER;
BEGIN
    -- Obliczamy ile kroków po 15 minut jest w 30 dniach
    -- 30 dni * 24h * 4 kwadranse = 2880
    v_steps := 30 * 24 * 4;

    -- Dla każdego aktywnego sensora
    FOR v_sensor IN SELECT id, name FROM sensors WHERE is_active = true LOOP
        RAISE NOTICE 'Generowanie danych dla sensora: % (ID: %)', v_sensor.name, v_sensor.id;

        FOR i IN 0..v_steps LOOP
            -- Obliczamy czas wstecz od teraz
            v_timestamp := NOW() - (INTERVAL '15 minutes' * i);

            -- Symulacja temperatury:
            -- Standardowo: 2.0 - 6.0 °C (Chłodnia)
            -- Czasami (1% szans): Skok do 8.0 - 10.5 °C (Alert)
            
            IF random() < 0.01 THEN
               v_temp := 8.0 + (random() * 2.5); -- 8.0 do 10.5
               v_is_alert := true; 
            ELSE
               v_temp := 2.0 + (random() * 4.0); -- 2.0 do 6.0
               v_is_alert := false;
            END IF;

            -- Wstawienie rekordu
            INSERT INTO temperature_logs (
                sensor_id, 
                temperature_celsius, 
                recorded_at, 
                is_alert
            )
            VALUES (
                v_sensor.id,
                ROUND(v_temp, 2),
                v_timestamp,
                v_is_alert
            );
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Zakończono generowanie danych testowych. Dashboard powinien ożyć.';
END $$;
