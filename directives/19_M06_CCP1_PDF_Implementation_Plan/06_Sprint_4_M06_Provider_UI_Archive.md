# Sprint 4: Integracja M06 (provider + UI + archiwum)

## Cel
Zamienic flow `temperature` z HTML na PDF i zapisac raport do archiwum.

## Zadania
- [x] `reports_provider`:
  - usunac sciezke `HtmlReportGenerator` dla `temperature`
  - wymusic wybor sensora (1 raport = 1 urzadzenie)
  - wywolac nowa metode PDF CCP-1
  - zapisac raport do storage `reports`
  - dodac wpis do `generated_reports` z `report_type='ccp1_temperature'`
- [x] `reports_panel_screen`:
  - walidacja: brak wyboru sensora blokuje generacje
  - komunikat bledu czytelny dla usera
  - preview/akcje zgodne z PDF
- [x] `saved_reports_screen`:
  - dodac etykiete dla `ccp1_temperature`
  - zapewnic otwarcie/pobranie raportu

## Kontrakt metadata (DB)
- [x] `metadata` zawiera:
  - `sensor_id`
  - `sensor_name`
  - `month`
  - `template_version` (`ccp1_csv_v1`)

## Testy
- [x] Integracyjny test providera:
  - sukces
  - brak danych
  - brak sensora
  - blad uploadu / zapis metadanych
- [x] Test UI walidacji wyboru sensora.

## Artefakty
- Kod:
  - `lib/features/m06_reports/providers/reports_provider.dart`
  - `lib/features/m06_reports/screens/reports_panel_screen.dart`
  - `lib/features/m06_reports/screens/saved_reports_screen.dart`
  - `lib/features/m06_reports/repositories/reports_repository.dart`
- Testy:
  - `test/features/m06_reports/reports_provider_integration_test.dart`
  - `test/features/m06_reports/reports_panel_validation_test.dart`

## Kryteria akceptacji (AC)
- [x] User generuje PDF zamiast HTML.
- [x] Po generacji jest wpis w archiwum `generated_reports`.
- [x] Raport mozna pobrac/otworzyc z poziomu UI.
