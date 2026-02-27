# Sprint 2: Repository i mapowanie danych

## Cel
Przygotowac poprawny, deterministyczny dataset wejsciowy do generatora PDF CCP-1.

## Zadania
- [x] Dodac metode repo do poboru danych miesiecznych dla 1 sensora:
  - filtr po `sensor_id`
  - zakres dat: caly miesiac
  - sort `recorded_at ASC`
- [x] Upewnic sie, ze join zwraca `sensors.name` do metadanych.
- [x] Zdefiniowac mapowanie rekordu na wiersz raportu:
  - data: `dd.MM.yyyy`
  - godzina: `HH:mm`
  - temperatura: `x.y°C`
  - zgodnosc: `TAK/NIE` wedlug reguly `0..4`
  - dzialania korygujace: pusty string
  - podpis: pusty string
- [x] Uzgodnic i utrwalic kontrakt DTO/funkcji miedzy repo a PDF service.

## Testy
- [x] Granice miesiaca:
  - pierwszy dzien 00:00:00
  - ostatni dzien 23:59:59
- [x] Tylko 1 sensor w dataset.
- [x] Poprawnosc mapowania zgodnosci:
  - `-0.1` -> `NIE`
  - `0.0` -> `TAK`
  - `4.0` -> `TAK`
  - `4.1` -> `NIE`

## Artefakty
- Testy repo/mapowania.
- Spisana specyfikacja datasetu przekazywanego do PDF generatora.
- Pliki testowe:
  - `test/features/m06_reports/reports_repository_filters_test.dart`
  - `test/features/m06_reports/temperature_report_contract_test.dart`
- Specyfikacja datasetu:
  - `directives/19_M06_CCP1_PDF_Implementation_Plan/10_Sprint_2_Dataset_Spec.md`

## Kryteria akceptacji (AC)
- [x] Provider otrzymuje gotowa liste wierszy raportu.
- [x] Brak logiki HTML na sciezce `temperature`.

## Uwaga wykonawcza
- W tym srodowisku CLI brak komendy `flutter`, dlatego `flutter test` nie mogl zostac uruchomiony lokalnie mimo przygotowania testow.
