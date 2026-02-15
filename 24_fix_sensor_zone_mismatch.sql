-- 24_fix_sensor_zone_mismatch.sql
-- Cel: Brutalne przypisanie WSZYSTKICH sensorów do PIERWSZEJ aktywnej strefy znalezionej w employee_zones.
-- To naprawi błąd "Brak aktywnych sensorów" na środowisku dev/demo.

DO $$
DECLARE
    v_active_zone_id UUID;
BEGIN
    -- 1. Znajdź pierwszą strefę, która jest faktycznie przypisana do jakiegoś pracownika
    SELECT zone_id INTO v_active_zone_id
    FROM employee_zones
    LIMIT 1;

    IF v_active_zone_id IS NULL THEN
        RAISE EXCEPTION 'Nie znaleziono żadnej strefy przypisanej do pracownika! Upewnij się, że tabela employee_zones nie jest pusta.';
    END IF;

    RAISE NOTICE 'Updating all sensors to Zone ID: %', v_active_zone_id;

    -- 2. Zaktualizuj WSZYSTKIE sensory, aby należały do tej strefy
    UPDATE sensors
    SET zone_id = v_active_zone_id;

    -- 3. Zaktualizuj logs (opcjonalnie, choć one są po sensor_id, ale dla porządku)
    -- (Logs nie mają zone_id, relacja idzie przez sensors, więc update sensors wystarczy)

END $$;
