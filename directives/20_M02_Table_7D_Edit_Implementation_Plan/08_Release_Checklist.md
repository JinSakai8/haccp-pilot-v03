# Release Checklist (M02 7D Table + Edit)

## Code
- [x] `SensorChartScreen` ma 4 tryby i dziala tabela 7 dni.
- [x] Edycja inline dziala tylko dla `manager/owner`.
- [x] Walidacje klienta sa aktywne.
- [x] ACK alarmu dziala po przejsciu na RPC.

## DB
- [x] Migracja wdrozona na remote.
- [x] RLS nie ma liberalnego update policy.
- [x] RPC edit/ack sa wykonywalne przez `authenticated`.
- [ ] Testy negatywne RLS/RPC przechodza.

## QA
- [x] Test scenariuszy 6d23h vs 7d+1m.
- [x] Test braku uprawnien (`cook/cleaner`).
- [ ] Test scope (inna strefa/lokal).
- [x] Regresja wykresow 24h/7/30.
- [x] Regresja panelu alarmow.

## Evidence (2026-02-23)
- Widget test granicy czasu i roli:
  - `test/features/m02_monitoring/sensor_chart_table_edit_rules_test.dart`
  - przypadki:
    - `6d23h` editable, `7d+1m` readonly
    - `cook` readonly
- Suite:
  - `flutter test test/features/m02_monitoring --reporter compact` -> PASS
  - `flutter test` -> PASS (`34 passed, 1 skipped, 0 failed`)

## Rollout
- [ ] Canary 1 lokal.
- [ ] Monitoring 48h.
- [ ] Decyzja full rollout.
