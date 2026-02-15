-- 21_fix_temperature_logs.sql
-- Cel: Dodać brakujące kolumny do obsługi potwierdzania alarmów zgodnie z kodem Dart

BEGIN;

-- 1. Sprawdź i dodaj kolumnę is_acknowledged
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'temperature_logs' AND column_name = 'is_acknowledged') THEN
        ALTER TABLE temperature_logs ADD COLUMN is_acknowledged BOOLEAN DEFAULT false;
    END IF;
END $$;

-- 2. Sprawdź i dodaj kolumnę acknowledged_by (UUID pracownika)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'temperature_logs' AND column_name = 'acknowledged_by') THEN
        ALTER TABLE temperature_logs ADD COLUMN acknowledged_by UUID REFERENCES employees(id);
    END IF;
END $$;

-- 3. Sprawdź i dodaj kolumnę acknowledged_at (Data potwierdzenia)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'temperature_logs' AND column_name = 'acknowledged_at') THEN
        ALTER TABLE temperature_logs ADD COLUMN acknowledged_at TIMESTAMPTZ;
    END IF;
END $$;

COMMIT;
