# Directive 01: Database Foundation & Auth (Supabase)

## Cel

Stworzenie tabel bazodanowych dla modułu M01 (Autoryzacja Kiosk Mode) zgodnie z architekturą Online-First dla HACCP Pilot.

## Struktura Tabel

1. `employees` (id: uuid, full_name: text, pin_hash: text, role: enum[owner, manager, cook, cleaner], is_active: boolean)
2. `zones` (id: uuid, name: text)
3. `employee_zones` (employee_id: uuid, zone_id: uuid)

## Zasady RLS (Row Level Security)

- Nikt nie ma publicznego dostępu.
- Tylko role 'owner' i 'manager' mogą wykonywać INSERT/UPDATE w `employees`.
- Aplikacja (Frontend) autoryzuje się przez weryfikację PIN_HASH.

## Oczekiwany rezultat (Execution)

Wygenerowanie skryptu SQL (np. `execution/01_init_db.sql`) do uruchomienia w konsoli Supabase. Po wykonaniu skryptu, zaktualizuj plik `src/types/supabase.ts` w projekcie Flutter (Strict Type Safety Sync).
