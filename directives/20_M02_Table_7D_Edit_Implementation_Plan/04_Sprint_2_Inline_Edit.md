# Sprint 2: Inline Edit + autoryzacja aplikacyjna

## Cel
Wlaczyc edycje temperatury bezposrednio w tabeli przy zachowaniu ograniczen roli i czasu.

## Zadania
- [x] S2.1 Dodac akcje `editTemperatureLog(...)` w providerze.
- [x] S2.2 Dodac dialog edycji w UI tabeli.
- [x] S2.3 Walidacje klienta:
  - liczba dziesietna
  - maks. 2 miejsca po przecinku
  - zakres `-50..150`
  - blokada dla rekordow starszych niz 7 dni
- [x] S2.4 Uprawnienia UI:
  - `manager/owner`: edycja aktywna
  - `cook/cleaner`: readonly
- [x] S2.5 Po zapisie invalidowac read path (`sensorSevenDayTable` i `sensorHistory`).

## Kryteria akceptacji
- [x] Edycja dziala E2E po stronie aplikacji.
- [x] Uzytkownicy bez uprawnien nie widza aktywnej akcji edycji.

## Status walidacji
- 2026-02-23: implementacja zgodna z planem (provider + dialog + walidacje + invalidacja).
- 2026-02-23: walidacja testami:
  - `flutter test test/features/m02_monitoring --reporter compact` -> PASS
  - `flutter test` -> PASS (`32 passed, 1 skipped, 0 failed`)
