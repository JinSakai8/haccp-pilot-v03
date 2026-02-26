# Sprint 3: M06 CCP3 Monthly + Spójnoœæ z CCP2

Data: 2026-02-26  
Status: COMPLETED

## Cel sprintu
Przejœæ z dziennego CCP3 na miesiêczny w M06 i zrównaæ kontrakt z CCP2.

## Zakres
1. `ReportsRepository.getCoolingLogs(...)` -> logika miesiêczna.
2. `ccp3ReportProvider` -> request DTO (`date`, `forceRegenerate`) i cache miesiêczny.
3. `saveReportMetadata` dla CCP3 z pe³nymi polami kontraktowymi.
4. Routing `/reports/preview/ccp3` z obs³ug¹ `force=1`.
5. Archiwum: fallback regeneracji CCP3 przy uszkodzonym PDF.

## Zmiany techniczne
1. `reports_repository.dart` (query spec zakresu miesi¹ca).
2. `ccp3_preview_screen.dart` (monthly lifecycle).
3. `app_router.dart` (query param `force`).
4. `saved_reports_screen.dart` (fallback regeneration CCP3).

## Zadania dla juniora
1. Wdró¿ DTO request i pomocnicze funkcje okresu (monthStart/monthEnd).
2. Dopnij scoping `zone_id`/`venue_id` bez os³abiania bezpieczeñstwa.
3. Zweryfikuj brak regresji CCP2.

## Exit criteria
1. M06 generuje i wyœwietla CCP2 + CCP3 miesiêcznie.
2. Archiwum otwiera oba typy raportów.

## Implementacja (wykonana)
1. CCP3 monthly zosta³ utrzymany i zweryfikowany:
- `Ccp3ReportRequest(date, forceRegenerate)` dzia³a jako DTO request,
- lookup cache i zapis metadata dzia³aj¹ na `generation_date = pierwszy dzieñ miesi¹ca`.
2. Routing `force=1` dzia³a dla preview:
- `/reports/preview/ccp3?...&force=1` w `app_router.dart`.
3. Archiwum ma fallback regeneracji CCP3:
- przy uszkodzonym PDF: przekierowanie do `/reports/preview/ccp3?date=...&force=1`.
4. Dodatkowe domkniêcie kontraktu miesiêcznego cache-key:
- `Ccp3ReportRequest` porównuje tylko rok+miesi¹c (dzieñ ignorowany),
- analogicznie ujednolicono `Ccp2ReportRequest`, aby zachowaæ spójnoœæ CCP2/CCP3.

## Testy i walidacja
1. Dodany test kontraktowy requestów miesiêcznych:
- `test/features/m06_reports/ccp_monthly_request_contract_test.dart`.
2. Uruchomiono:
- `C:\scr\flutter\bin\flutter.bat test test/features/m06_reports --reporter compact`
3. Wynik:
- PASS (`30 passed, 0 failed`).
