# Sprint 3 - Domain + Providers (M04/M06)

## Status Sprintu
- Status: Zakonczony (implementacja domenowa + providery)
- Data zamkniecia: 2026-02-27
- Decyzja: READY FOR SPRINT 4

## Cel Sprintu
Wdrozyc logike domenowa zapisu GHP i generacji raportow GHP w warstwie repository/provider.

## 1. Zakres implementacyjny (wykonany)
- M04: zapis checklist z data/godzina wykonania.
- M06: wlaczenie raportu GHP do generatora raportow.
- Archiwizacja PDF GHP: upload + metadata upsert.

## 2. Wdrozone zmiany
### 2.1 M04 repository/provider
- `lib/features/m04_ghp/providers/ghp_provider.dart`
  - `submitChecklist` normalizuje payload do kontraktu:
    - `execution_date`
    - `execution_time`
    - `answers`
    - `notes` (opcjonalnie)
  - nadal zachowany scope: `zone_id`, `venue_id`, `user_id`.
- `lib/features/m04_ghp/repositories/ghp_repository.dart`
  - zapis bez zmian warstwowych (insert do `haccp_logs`, `category='ghp'`).

### 2.2 M06 reports provider
- `lib/features/m06_reports/providers/reports_provider.dart`
  - usunieto blokade "GHP w przygotowaniu".
  - dodano realny case `reportType == 'ghp'`:
    - pobranie datasetu GHP,
    - mapowanie rows,
    - generacja PDF bytes,
    - upload do storage `reports`,
    - upsert metadata w `generated_reports` (`report_type='ghp_checklist_monthly'`).

### 2.3 M06 reports repository
- `lib/features/m06_reports/repositories/reports_repository.dart`
  - wykorzystany query datasetu: `getGhpLogs(start, end, zoneId, venueId)`.
  - dodane mapowanie do formatu PDF rows:
    - `mapGhpLogToReportRow(...)`.
  - dodane helpery summary odpowiedzi GHP (`TAK/NIE`) dla kolumny raportowej.

## 3. Kontrakt raportu GHP (runtime)
- `reportType` UI/provider: `ghp`
- `generated_reports.report_type`: `ghp_checklist_monthly`
- PDF file name: `ghp_checklist_<YYYY-MM>.pdf`
- storage path w buckecie `reports`: `<venueId>/<YYYY>/<MM>/<file>.pdf`
- metadata:
  - `period_start`
  - `period_end`
  - `template_version`
  - `source_form_id`
  - `zone_id`
  - `month`

## 4. Kontrole jakosci (wynik)
- Brak bezposrednich wywolan Supabase ze screenow: SPELNIONE.
- Bledy mapowane w provider/repository: SPELNIONE.
- Brak zmian w CCP2/CCP3 flow: SPELNIONE.

## 5. Exit Criteria
- Raport GHP generuje bytes PDF: SPELNIONE.
- Raport GHP archiwizuje sie w storage i `generated_reports`: SPELNIONE.
- Payload GHP zawiera date/godzine wykonania zgodna z kontraktem: SPELNIONE.

## 6. Ready for Sprint 4
Sprint 3 zamkniety. Mozna przejsc do Sprint 4 (UI + History + Preview).
