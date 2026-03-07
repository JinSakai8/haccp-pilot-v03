# Sprint 5 QA/Release Report (M06 CCP-1)

Data wykonania: 2026-02-22

## 1) Wynik testow automatycznych

Uruchomiono:
- `flutter test` (caly projekt)

Wynik:
- `31 passed, 1 skipped, 0 failed`

Zakres pokrycia istotny dla M06 CCP-1:
- mapowanie i kontrakt datasetu:
  - `test/features/m06_reports/reports_repository_filters_test.dart`
- kontrakt braku HTML dla `temperature`:
  - `test/features/m06_reports/temperature_report_contract_test.dart`
- silnik PDF CCP-1 (smoke + multipage):
  - `test/pdf_service_test.dart`
- integracja provider archiwizacji:
  - `test/features/m06_reports/reports_provider_integration_test.dart`
- walidacja UI wyboru sensora:
  - `test/features/m06_reports/reports_panel_validation_test.dart`

## 2) Manual QA (scenariusze)

Scenariusze zamkniete:
- pusty miesiac: provider zwraca kontrolowany blad
- wartosci skrajne temperatur:
  - `-0.1` -> `NIE`
  - `0.0` -> `TAK`
  - `4.0` -> `TAK`
  - `4.1` -> `NIE`
- duzy wolumen:
  - PDF wielostronicowy z powtarzanym headerem tabeli
- archiwum:
  - zapis metadanych `generated_reports` + otwieranie/pobieranie z UI

## 3) Brak regresji

Brak regresji potwierdzony przez pelny suite testow oraz brak zmian kontraktow dla:
- `waste`
- `gmp`
- `ccp3_cooling`

## 4) Gotowosc release

Status:
- technicznie gotowe do canary
- operacyjnie wymagane:
  1. wdrozenie canary na 1 lokalu
  2. monitoring 48h (PDF/storage/generated_reports)
  3. decyzja o pelnym rollout

## 5) Rollback

Dostepne:
- rollback DB constraint (`generated_reports_report_type_check`) opisany i testowany:
  - `directives/19_M06_CCP1_PDF_Implementation_Plan/09_Sprint_1_DB_Runbook.md`
- powrot do poprzedniej wersji aplikacji mozliwy standardowa procedura release

Otwarte:
- brak dedykowanego feature toggle runtime tylko dla sciezki `ccp1_temperature`

