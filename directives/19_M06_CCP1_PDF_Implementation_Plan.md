# Plan Implementacji M06 -> PDF CCP-1 (Index)

Ten pakiet zawiera wytyczne wykonawcze dla junior architekta/dewelopera dla migracji raportu temperatur M06 z HTML do PDF w układzie CCP-1 (zgodnym z template CSV).

## Cel biznesowy i techniczny
- Raport `temperature` w M06 ma byc generowany jako prawdziwy PDF, nie HTML.
- Uklad raportu ma odpowiadac arkuszowi CCP-1 z template CSV.
- Raport ma byc archiwizowany w Supabase (`storage + generated_reports`).

## Zakres
- Raport miesieczny dla 1 urzadzenia/sensora.
- Kolumny:
  - `Data`
  - `Godzina`
  - `Wartosc temperatury`
  - `Zgodnosc z ustaleniami` (auto)
  - `Dzialania korygujace` (puste)
  - `Podpis` (puste)

## Zamrozone decyzje
- `report_type = ccp1_temperature`
- Regula zgodnosci:
  - `TAK` dla zakresu `0..4°C`
  - `NIE` dla `<0°C` lub `>4°C`
- Naglowek raportu: staly (jak template CSV).
- `generation_date`: data generacji (spojnie dla wszystkich nowych rekordow tego typu).

## Podzial na sprinty (1 sprint = 1 okno kontekstowe)
1. `01_Context_And_Decisions.md`
2. `02_Sprint_0_DB_Baseline.md`
3. `03_Sprint_1_DB_Migration_Report_Type.md`
4. `04_Sprint_2_Repository_And_Data_Mapping.md`
5. `05_Sprint_3_PDF_Engine_CCP1.md`
6. `06_Sprint_4_M06_Provider_UI_Archive.md`
7. `07_Sprint_5_Testing_QA_Release.md`

## Zaleznosci sprintow
- Sprint 0 -> Sprint 1 -> Sprint 2 -> Sprint 3 -> Sprint 4 -> Sprint 5
- Sprint 1 (DB migration) jest blokujacy dla pelnej archiwizacji w Sprint 4.
- Sprint 2 (dataset) jest blokujacy dla Sprint 3 (silnik PDF).

## Plan wspoldzialania z baza danych
- Odczyt:
  - `temperature_logs`
  - `sensors`
- Zapis:
  - `generated_reports`
- Storage:
  - bucket `reports`
- Zmiana DB:
  - tylko rozszerzenie `generated_reports_report_type_check` o `ccp1_temperature`.
- Brak nowych tabel i brak nowych kolumn.

## Kontrakt rekordu archiwum
- `report_type = 'ccp1_temperature'`
- `generation_date = data generacji`
- `storage_path = reports/{venueId}/{YYYY}/{MM}/ccp1_temperature_{sensorId}_{YYYY-MM}.pdf`
- `metadata` zawiera minimum:
  - `sensor_id`
  - `sensor_name`
  - `month`
  - `template_version` (np. `ccp1_csv_v1`)

## Publiczne interfejsy/kontrakty do aktualizacji
- `PdfService`: nowa metoda generacji raportu CCP-1 temperatur.
- `ReportsRepository`: metoda poboru danych miesiecznych dla 1 sensora.
- `ReportsNotifier.generateReport(reportType: 'temperature', ...)`:
  - generuje PDF zamiast HTML
  - zapisuje wpis `ccp1_temperature` do archiwum
- Kontrakt DB `generated_reports.report_type` rozszerzony o `ccp1_temperature`.

## Macierz ryzyk i rollback
1. Ryzyko: niespojnosc DB constraint `report_type`.
   - Mitigacja: migracja z testem pozytywnym/negatywnym.
   - Rollback: przywrocenie poprzedniego check constraint.
2. Ryzyko: blad generacji PDF.
   - Mitigacja: walidacja datasetu i testy wielostronicowe.
   - Fallback: brak publikacji do `generated_reports` przy bledzie PDF.
3. Ryzyko: regresja UI M06.
   - Mitigacja: testy provider/widget + manual QA.

## Definicja sukcesu
- Brak `.html` dla raportu temperatur.
- Kazdy wygenerowany raport temperatur:
  - jest PDF,
  - moze byc otwarty/pobrany,
  - posiada wpis w `generated_reports` jako `ccp1_temperature`.

