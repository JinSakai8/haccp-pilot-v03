# Sprint 4: Testing, QA, Release

## Cel
Potwierdzic stabilnosc funkcji i gotowosc do rolloutu.

## Zakres testow
- [x] Widget/UI:
  - widok tabeli 7 dni
  - stany loading/empty/error
  - dostepnosc akcji edycji wg roli
- [x] Provider/Repo:
  - poprawna invalidacja po edycji
  - walidacje wartosci
- [ ] DB/RPC (negatywne):
  - brak kiosk session
  - zla rola
  - rekord spoza scope
  - rekord starszy niz 7 dni

## Plan release
1. Canary dla 1 lokalu.
2. Monitoring 48h:
  - bledy RPC update/ack
  - bledy UI tabeli
  - odczyt M02/M06
3. Pelny rollout po braku krytycznych incydentow.

## Kryteria akceptacji
- [x] Brak regresji M02 wykresy/alerty.
- [x] Brak regresji M06 (odczyt temperature_logs).
- [ ] Polityki i RPC daja przewidywalne wyniki autoryzacyjne.

## Status walidacji (2026-02-23)
- `flutter test test/features/m02_monitoring --reporter compact` -> PASS
- `flutter test` -> PASS (`34 passed, 1 skipped, 0 failed`)
- Dodatkowe testy widgetowe Sprint 4:
  - `test/features/m02_monitoring/sensor_chart_table_edit_rules_test.dart`
  - pokrycie:
    - granica czasu edycji `6d23h` vs `7d+1m`
    - brak uprawnien UI dla `cook`
- Migracja Sprint 3 wdrozona na remote: `20260223120000_m02_temperature_logs_table_edit_hardening.sql` (`supabase db push`).
- Wymagane do domkniecia Sprintu 4:
  - wykonanie negatywnych testow DB/RPC na remote (rola/scope/okno czasu/brak kiosk session),
  - canary 1 lokal + monitoring 48h + decyzja rollout.
