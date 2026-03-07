# Sprint 5: Testing, QA, Release

## Cel
Zamknac jakosc i regresje dla refactoru alarmow.

## Zakres testow
- Widget tests:
  - render aktywnej karty i buttona ACK
  - render historii bez buttona ACK
  - brak overflow na `360px`
  - long press <1s nie wysyla ACK
  - long press >=1s wysyla pojedynczy ACK
- Regresja M02:
  - `TemperatureDashboardScreen` nawiguje do `/monitoring/alarms`
  - `SensorChartScreen` i tryb 7D pozostaja bez regresji

## QA manual
- Sprawdzic taby aktywne/historia na tablet i web.
- Potwierdzic czytelnosc danych alarmu z dystansu roboczego.
- Potwierdzic touch targety i responsywnosc.

## Release checklist
1. `dart run build_runner build --delete-conflicting-outputs`
2. `flutter test`
3. (opcjonalnie) `supabase db push`
4. smoke test M02 na srodowisku docelowym
