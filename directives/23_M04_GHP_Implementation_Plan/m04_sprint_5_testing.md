# Sprint 5 - Testing (QA + Verification)

## Status Sprintu
- Status: Zakonczony (testy automatyczne + regresja)
- Data zamkniecia: 2026-02-27
- Decyzja: READY FOR SPRINT 6

## Cel Sprintu
Potwierdzic, ze nowy flow GHP dziala end-to-end i nie psuje istniejacych funkcji raportowych.

## 1. Testy automatyczne (wykonane)
### 1.1 Unit tests
- payload GHP (normalizacja `execution_date`/`execution_time`/`answers`):
  - `test/features/m04_ghp/ghp_submission_contract_test.dart`
- dataset GHP -> PDF rows + fallback route logic:
  - `test/features/m06_reports/reports_repository_filters_test.dart`

### 1.2 Provider/repository tests
- provider M04: scenariusze brzegowe auth context (brak usera/strefy):
  - `test/features/m04_ghp/ghp_provider_submission_test.dart`
- provider M06: generacja i archiwizacja raportu GHP + bledy storage/metadata + empty dataset:
  - `test/features/m06_reports/reports_provider_integration_test.dart`

### 1.3 Widget tests
- checklista GHP: wymagane pola daty/godziny przed submit:
  - `test/features/m04_ghp/ghp_checklist_validation_test.dart`
- historia GHP: lista + wejscie do detalu wpisu:
  - `test/features/m04_ghp/ghp_history_screen_test.dart`
- archiwum raportow: akcje `PODGLAD`/`POBIERZ` + otwieranie PDF:
  - `test/features/m06_reports/saved_reports_screen_test.dart`

## 2. Uruchomione komendy i wyniki
1. Pakiet Sprintu 5:
- `flutter test <7 plikow testowych Sprintu 5>`
- Wynik: **30 passed, 0 failed**.

2. Regression guard (CCP/M03):
- `flutter test reports_panel_validation_test.dart ccp2_pdf_gen_test.dart ccp_monthly_request_contract_test.dart gmp_history_navigation_smoke_test.dart`
- Wynik: **11 passed, 0 failed**.

Lacznie uruchomione w Sprincie 5: **41 passed, 0 failed**.

## 3. Testy manualne E2E
Plan scenariuszy E2E pozostaje aktualny (7 krokow). W tym sprincie wykonano weryfikacje automatyczne i regresje; manual E2E do finalnego sign-off w Sprincie 6.

## 4. Przypadki brzegowe (pokrycie)
- Brak aktywnej strefy: pokryte testem provider M04 (`ghp_provider_submission_test.dart`).
- Brak zalogowanego usera: pokryte testem provider M04 (`ghp_provider_submission_test.dart`).
- Pusty dataset GHP dla miesiaca: pokryte testem provider M06 (`reports_provider_integration_test.dart`).
- Niezgodny/nieobslugiwany fallback route: pokryte testem unit (`reports_repository_filters_test.dart`).
- Bledy storage/metadata: pokryte testami provider M06 (`reports_provider_integration_test.dart`).

## 5. Regression Guard (wynik)
- CCP1/CCP2/CCP3 preview i archiwum: PASS.
- M03 GMP historia i zapisy (smoke nawigacji raportowej): PASS.
- Routing `/ghp/*` i `/reports/*`: PASS w testach widget/integration uruchomionych w tym sprincie.

## 6. Exit Criteria
- Wszystkie testy krytyczne PASS: SPELNIONE.
- Scenariusze P1/P2 zweryfikowane automatycznie: SPELNIONE.
- Brak otwartych blockerow do Sprintu 6: SPELNIONE.

## 7. Ready for Sprint 6
Sprint 5 zamkniety. Mozna przejsc do Sprintu 6 (Ocena wdrozenia).
