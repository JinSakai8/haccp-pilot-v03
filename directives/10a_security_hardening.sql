-- Directive 10a: Security Hardening SQL Script
-- Run this in Supabase SQL Editor

-- =============================================================================
-- 1. SEC-04: RLS na tabeli employees (Ochrona danych osobowych i PIN-ów)
-- =============================================================================

ALTER TABLE employees ENABLE ROW LEVEL SECURITY;

-- 1.1. Polityka odczytu: Autoryzowani użytkownicy widzą listę, ale...
-- UWAGA: To jest warstwa bazy danych. Aplikacja i tak nie powinna prosić o pin_hash.
-- W RLS trudno ukryć pojedynczą kolumnę bez tworzenia VIEW, więc polegamy
-- na poprawnym zapytaniu SELECT w aplikacji (SEC-03) oraz zaufaniu do zalogowanego użytkownika.
-- Jeśli chcielibyśmy hardkorowo ukryć kolumnę, musielibyśmy zrobić VIEW.
CREATE POLICY "Enable read access for authenticated users" ON employees
FOR SELECT USING (auth.role() = 'authenticated');

-- 1.2. Polityka zapisu: Tylko MANAGER i OWNER mogą tworzyć/edytować pracowników
-- Zakładamy, że auth.uid() mapuje się na usera w tabeli employees, ale w tym modelu
-- autoryzacja jest niestandardowa (PIN). Supabase Auth User ID != Employee ID.
-- W modelu Kiosk Mode, 'auth.role()' to zawsze 'authenticated' (anonimowy login lub service role).
-- Logika biznesowa "kto jest managerem" jest w aplikacji.
-- Zabezpieczamy więc przed całkowicie anonimowym dostępem (public).
CREATE POLICY "Enable insert for authenticated users" ON employees
FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users" ON employees
FOR UPDATE USING (auth.role() = 'authenticated');

-- =============================================================================
-- 2. SEC-05: Audit Log (created_by, updated_by, dates)
-- =============================================================================

-- Funkcja automatycznie aktualizująca updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 2.1. Tabela employees
ALTER TABLE employees 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

CREATE TRIGGER set_employees_updated_at
BEFORE UPDATE ON employees
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2.2. Tabela gmp_logs
ALTER TABLE gmp_logs 
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES employees(id),
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES employees(id),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

CREATE TRIGGER set_gmp_logs_updated_at
BEFORE UPDATE ON gmp_logs
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2.3. Tabela ghp_logs
ALTER TABLE ghp_logs 
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES employees(id),
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES employees(id),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

CREATE TRIGGER set_ghp_logs_updated_at
BEFORE UPDATE ON ghp_logs
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2.4. Tabela waste_records (miała już user_id jako created_by, dodajemy resztę)
ALTER TABLE waste_records
ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES employees(id),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;
-- created_at już istnieje w waste_records

CREATE TRIGGER set_waste_records_updated_at
BEFORE UPDATE ON waste_records
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2.5. Tabela sensor_annotations (jeśli istnieje, dla M02)
-- Sprawdzamy czy tabela istnieje, jeśli nie - pomijamy (bezpiecznik)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'sensor_annotations') THEN
        ALTER TABLE sensor_annotations
        ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES employees(id),
        ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
    END IF;
END $$;
