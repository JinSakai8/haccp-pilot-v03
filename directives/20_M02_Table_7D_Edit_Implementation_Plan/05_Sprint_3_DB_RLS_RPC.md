# Sprint 3: DB Hardening (RLS + RPC)

## Cel
Przeniesc enforcement uprawnien i okna czasu do warstwy bazy.

## Zadania
- [x] S3.1 Rozszerzyc `temperature_logs` o metadata edycji:
  - `edited_at timestamptz`
  - `edited_by uuid`
  - `edit_reason text`
- [x] S3.2 Dodac indeks:
  - `(sensor_id, recorded_at desc)`
- [x] S3.3 Usunac policy update typu `using (true)`.
- [x] S3.4 Dodac nowy scoped SELECT (kiosk_sessions + sensor->zone->venue).
- [x] S3.5 Dodac RPC `update_temperature_log_value(...)`:
  - rola manager/owner
  - scope kiosk
  - limit 7 dni
  - zakres temperatur
- [x] S3.6 Podpiac aplikacje pod RPC zamiast bezposredniego update.
- [x] S3.7 Utrzymac ACK alarmu przez RPC, aby uniknac regresji po zamknieciu direct update.

## Kryteria akceptacji
- [x] Backend blokuje edycje spoza roli/scope/okna czasu.
- [x] `manager/owner` moga edytowac tylko rekordy w swoim kontekscie.
- [x] Brak regresji panelu alarmow.

## Status walidacji
- Migracja Sprint 3 dla M02: `supabase/migrations/20260223120000_m02_temperature_logs_table_edit_hardening.sql`
- Potwierdzone w artefakcie SQL:
  - metadata edit (`edited_at`, `edited_by`, `edit_reason`)
  - indeks `(sensor_id, recorded_at desc)`
  - usuniecie liberalnych policy i dodanie scoped SELECT/INSERT
  - RPC `update_temperature_log_value(...)` z enforcement roli/scope/okna czasu/zakresu
  - RPC `acknowledge_temperature_alert(...)` dla ACK bez direct update z klienta
- Potwierdzone po stronie aplikacji:
  - edycja przez RPC: `update_temperature_log_value`
  - ACK przez RPC: `acknowledge_temperature_alert`
  - brak bezposredniego `.update()` na `temperature_logs` w kliencie
