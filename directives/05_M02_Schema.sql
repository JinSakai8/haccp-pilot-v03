-- 05_M02_Schema.sql
-- Run this in Supabase SQL Editor

-- 1. Tabela Sensorów
CREATE TABLE sensors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    zone_id UUID REFERENCES zones(id), -- Powiązanie ze strefą (np. Chłodnia, Kuchnia)
    is_active BOOLEAN DEFAULT true,
    interval_minutes INTEGER DEFAULT 15, -- Częstotliwość pomiaru (domyślnie 15 min)
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tabela Logów Temperatury
CREATE TABLE temperature_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_id UUID REFERENCES sensors(id),
    temperature_celsius NUMERIC(5, 2) NOT NULL, -- np. -18.50
    recorded_at TIMESTAMPTZ DEFAULT NOW(),
    is_alert BOOLEAN DEFAULT false -- Flaga dla przekroczeń (Algorytm 10/5/3)
);

-- 3. RLS Policies
ALTER TABLE sensors ENABLE ROW LEVEL SECURITY;
ALTER TABLE temperature_logs ENABLE ROW LEVEL SECURITY;

-- Polityka dla sensors (Authenticated Users mogą czytać)
CREATE POLICY "Enable read access for authenticated users" ON sensors
FOR SELECT USING (auth.role() = 'authenticated');

-- Polityka dla temperature_logs (Authenticated Users mogą czytać)
CREATE POLICY "Enable read access for authenticated users" ON temperature_logs
FOR SELECT USING (auth.role() = 'authenticated');

-- Polityka dla symulacji (Authenticated Users mogą pisać - tymczasowo dla dev)
CREATE POLICY "Enable insert access for authenticated users" ON temperature_logs
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- 4. Dane testowe (opcjonalne)
-- INSERT INTO sensors (name, is_active) VALUES ('Chłodnia #1', true);
-- INSERT INTO sensors (name, is_active) VALUES ('Piec Konwekcyjny', true);
