# Sprint 1: UI + Read Path tabeli 7 dni

## Cel
Dodac nowy tryb widoku i read path danych 7-dniowych bez naruszania istniejacych wykresow.

## Zadania
- [x] S1.1 Dodac 4. tryb w `SensorChartScreen`: `Tabela 7 dni`.
- [x] S1.2 Dodac provider read-only dla tabeli 7 dni.
- [x] S1.3 Dodac metode repo pobierajaca logi 7-dniowe per sensor.
- [x] S1.4 Dodac UI tabeli z kolumnami:
  - data
  - godzina
  - temperatura
  - alert
  - status potwierdzenia
  - akcja
- [x] S1.5 Obsluzyc stany: loading/empty/error.

## Kryteria akceptacji
- [x] Uzytkownik widzi kompletna tabele 7 dni dla wybranego sensora.
- [x] Wykresy `24h/7 dni/30 dni` dzialaja bez regresji.

## Status walidacji
- 2026-02-23: walidacja uruchomiona lokalnie (`C:\scr\flutter\bin`), ale zablokowana bledem kompilacji:
  - `lib/features/m02_monitoring/providers/monitoring_provider.dart`
  - `Type 'AutoDisposeAsyncNotifier' not found`
  - wplyw: testy M02 i pelny `flutter test` nie przechodza do etapu wykonania asercji.
- 2026-02-23: po poprawce zgodnosci Riverpod (`AutoDisposeAsyncNotifier` -> `AsyncNotifier`) walidacja przechodzi:
  - `flutter test test/features/m02_monitoring --reporter compact` -> PASS
  - `flutter test` -> PASS (`32 passed, 1 skipped, 0 failed`)
