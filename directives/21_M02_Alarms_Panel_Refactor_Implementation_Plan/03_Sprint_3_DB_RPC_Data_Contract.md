# Sprint 3: DB RPC + Data Contract

## Cel
Przestawic read path alarmow na jeden RPC zwracajacy dane gotowe pod UI.

## Zakres DB
- Migracja:
  - `supabase/migrations/20260223163000_m02_get_temperature_alarms_rpc.sql`
- RPC:
  - `get_temperature_alarms(zone_id_input uuid, active_only_input boolean, limit_input int, offset_input int)`
- Security:
  - `SECURITY DEFINER`
  - scope przez `kiosk_sessions` + `sensor->zone->venue`
  - `grant execute` dla `authenticated` i `service_role`
- Wydajnosc:
  - indeks czesciowy dla alertow (`is_alert=true`)

## Zakres aplikacji
- `MeasurementsRepository.getAlerts(...)` pobiera dane z RPC.
- `alarmsProvider(...)` zwraca `List<AlarmListItem>`.

## Kryteria akceptacji
- 1 request = komplet danych karty alarmu.
- Brak dwuetapowego mapowania alarmy+sensory po stronie UI.
