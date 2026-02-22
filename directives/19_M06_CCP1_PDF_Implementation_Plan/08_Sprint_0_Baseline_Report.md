# Sprint 0 Baseline Report (M06 CCP-1 PDF)

Data wykonania: 2026-02-22

## 1) Snapshot `generated_reports.report_type`

### Stan danych (remote Supabase, REST)
- `generated_reports` total: `3` rekordy
- Aktualnie wystepujace `report_type`:
  - `ccp3_cooling`: `3`

### Stan kontraktu DB (schema)
- Constraint: `generated_reports_report_type_check`
- Dozwolone typy aktualnie:
  - `ccp3_cooling`
  - `waste_monthly`
  - `gmp_daily`
- Zrodlo: `supabase/migrations/20260222084803_remote_schema.sql:277`

Wniosek: `ccp1_temperature` nie jest jeszcze legalny na poziomie check constraint (Sprint 1 jest wymagany).

## 2) Probe `temperature_logs` (kolumny + jakosc)

### Stan danych (remote Supabase, REST)
- `temperature_logs` total: `54279` rekordow
- Probe: ostatnie `1000` rekordow
- Wynik jakosci probki:
  - `sensor_id IS NULL`: `0`
  - `temperature_celsius IS NULL`: `0`
  - `recorded_at IS NULL`: `0`
  - Join `sensors(...) IS NULL`: `0`
  - `sensors.name IS NULL`: `0`
  - Zakres temperatur w probce: `2.00 .. 9.99`

### Stan kontraktu DB (schema)
- `temperature_logs.temperature_celsius numeric(5,2) not null`
- `temperature_logs.recorded_at timestamptz not null`
- FK: `temperature_logs.sensor_id -> sensors.id`
- Zrodlo:
  - `supabase/migrations/20260222084803_remote_schema.sql:141`
  - `supabase/migrations/20260222084803_remote_schema.sql:323`

Wniosek: baseline danych i relacji jest spojny, join do `sensors.name` dziala.

## 3) Aktualny flow raportu `temperature` (M06)

1. UI wywoluje `ReportsNotifier.generateReport(reportType: 'temperature', ...)`.
   - `lib/features/m06_reports/screens/reports_panel_screen.dart:86`
2. Provider pobiera `temperature_logs` przez repo (`select('*, sensors(name)')`).
   - `lib/features/m06_reports/repositories/reports_repository.dart:115`
3. Provider agreguje dane i generuje HTML przez `HtmlReportGenerator.generateHtml(...)`.
   - `lib/features/m06_reports/providers/reports_provider.dart:151`
   - `lib/features/m06_reports/services/html_report_generator.dart:3`
4. Wynik jest kodowany jako UTF-8 i zwracany jako plik `.html`.
   - `lib/features/m06_reports/providers/reports_provider.dart:159`
   - `lib/features/m06_reports/providers/reports_provider.dart:160`
5. Dalszy upload z `uploadCurrentReport()` idzie na Google Drive (nie do `generated_reports`).
   - `lib/features/m06_reports/providers/reports_provider.dart:175`

Wniosek: aktualna sciezka temperatur to HTML, bez archiwizacji w `generated_reports`.

## 4) Lista miejsc do zmiany (Sprint 1+)

### DB / migracje
- `supabase/migrations/<new>_m06_ccp1_report_type.sql`
  - rozszerzenie `generated_reports_report_type_check` o `ccp1_temperature`

### Repository
- `lib/features/m06_reports/repositories/reports_repository.dart`
  - nowa metoda poboru miesiecznych danych temperatur dla 1 sensora
  - doprecyzowanie kontraktu metadanych pod CCP-1

### PDF service
- `lib/core/services/pdf_service.dart`
  - nowa metoda generacji CCP-1 temperatur (dedykowany layout tabeli)

### Provider / orchestration
- `lib/features/m06_reports/providers/reports_provider.dart`
  - usuniecie sciezki HTML dla `temperature`
  - przejscie na PDF
  - upload do bucketu `reports`
  - insert do `generated_reports` z `report_type='ccp1_temperature'`

### UI
- `lib/features/m06_reports/screens/reports_panel_screen.dart`
  - usuniecie logiki `isHtml`
  - jednolita obsluga PDF dla `temperature`
- `lib/features/m06_reports/screens/saved_reports_screen.dart`
  - etykieta i obsluga `ccp1_temperature`

### Testy
- `test/pdf_service_test.dart`
  - test nowej metody CCP-1
- `test/features/m06_reports/*` (nowe testy provider/repository)
  - mapowanie danych i compliance `TAK/NIE` dla zakresu `0..4`
  - brak fallbacku HTML
  - zapis metadanych `generated_reports`

## 5) Luki i ryzyka na start Sprint 1

1. Ryzyko kontraktu DB:
   - bez migracji check constraint insert `ccp1_temperature` bedzie blokowany.
2. Ryzyko rozjazdu typu raportu:
   - w kodzie M06 istnieja typy UI (`temperature`) i archiwalne (`ccp3_cooling`), trzeba jednoznacznie mapowac na `ccp1_temperature`.
3. Ryzyko regresji UX:
   - obecny ekran ma warunek `.html`; po usunieciu sciezki HTML musi pozostac dzialajacy preview/download PDF.
4. Ryzyko danych:
   - probe pokazuje wartosci powyzej 4C, co jest poprawne biznesowo, ale wymaga poprawnej implementacji kolumny zgodnosci `TAK/NIE`.

## 6) Status Sprint 0

- Sprint 0: zakonczony.
- AC spelnione:
  - kompletna lista miejsc do zmiany istnieje
  - brak istotnych "unknown unknowns" przed Sprintem 1
