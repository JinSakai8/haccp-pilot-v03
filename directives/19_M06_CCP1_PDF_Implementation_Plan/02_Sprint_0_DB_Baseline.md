# Sprint 0: Baseline i kontrakt

## Cel
Potwierdzic stan wyjsciowy i usunac niepewnosci przed zmianami.

## Zadania
- [x] Zrobic snapshot aktualnych typow w `generated_reports.report_type`.
- [x] Zweryfikowac probe danych w `temperature_logs` (kolumny + jakosc danych).
- [x] Zweryfikowac powiazanie `temperature_logs.sensor_id -> sensors.id` i dostepnosc `sensors.name`.
- [x] Spisac aktualny flow raportu `temperature` (M06), wskazac gdzie powstaje HTML.
- [x] Spisac liste miejsc do zmiany:
  - repo
  - pdf service
  - provider
  - ui
  - testy

## Artefakty
- Krotki raport baseline:
  - liczba rekordow probki
  - aktualne `report_type`
  - lista luk i ryzyk
- Lista plikow docelowych do modyfikacji.
- Raport wykonania Sprint 0:
  - `directives/19_M06_CCP1_PDF_Implementation_Plan/08_Sprint_0_Baseline_Report.md`

## Kryteria akceptacji (AC)
- [x] Junior ma kompletna liste miejsc do zmiany.
- [x] Brak "unknown unknowns" przed startem Sprintu 1.
