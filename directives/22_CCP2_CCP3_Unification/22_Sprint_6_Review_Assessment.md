# Sprint 6: Review i Ocena Wdro¿enia

Data: 2026-02-26  
Status: IN PROGRESS (review completed, final SQL validation pending)

## Cel sprintu
Formalne zamkniêcie wdro¿enia i decyzja release readiness.

## Zakres
1. Code review jakoœciowe i bezpieczeñstwa.
2. Odbiór funkcjonalny wobec dokumentów referencyjnych.
3. Raport koñcowy GO/NO-GO z uzasadnieniem.

## Checklista review
1. Spójnoœæ okresu raportu (CCP2/CCP3 = miesi¹c).
2. Poprawnoœæ routingu z GMP Historii.
3. Archiwum M06: otwieranie obu typów raportów.
4. Scoping `venue_id` i zgodnoœæ z RLS.
5. Brak regresji CCP1.

## Wynik checklisty (z dowodami)
1. Spójnoœæ okresu raportu (CCP2/CCP3 = miesi¹c): PASS
- `ccp2_preview_screen.dart` i `ccp3_preview_screen.dart`: zakres `monthStart/monthEnd`.
- Request DTO cache-key ujednolicony do `year+month`.
- Dowód testowy: `test/features/m06_reports/ccp_monthly_request_contract_test.dart`.

2. Poprawnoœæ routingu z GMP Historii: PASS
- `gmp_history_screen.dart`: mapowanie CCP2/CCP3 przez resolver trasy.
- Legacy `meat_roasting_daily` mapowany do CCP2.
- Dowód testowy: `test/features/m03_gmp/gmp_history_navigation_smoke_test.dart`.

3. Archiwum M06: otwieranie obu typów raportów: PASS
- `saved_reports_screen.dart`: fallback regeneracji dla uszkodzonego PDF:
  - `/reports/preview/ccp2?...&force=1`
  - `/reports/preview/ccp3?...&force=1`
- `app_router.dart`: obs³uga query param `force`.

4. Scoping `venue_id` i zgodnoœæ z RLS: PARTIAL
- `supabase db push` wykonany dla migracji:
  - `20260226200000_sprint4_ccp3_generated_reports_venue_backfill.sql`.
- `supabase migration list`: `Local=Remote` dla `20260226200000`.
- Brakuje uruchomienia walidacji SQL na remote:
  - `supabase/ccp3_04_generated_reports_backfill_validation.sql`.

5. Brak regresji CCP1: PASS
- Z testów M06 i full suite brak regresji CCP1.

## Testy wykonane (Sprint 5 evidence)
1. `C:\scr\flutter\bin\flutter.bat test --reporter compact`
- PASS: `62 passed, 1 skipped, 0 failed`.
2. `C:\scr\flutter\bin\flutter.bat test test/features/m03_gmp --reporter compact`
- PASS: `12 passed, 0 failed`.
3. `C:\scr\flutter\bin\flutter.bat test test/features/m06_reports --reporter compact`
- PASS: `30 passed, 0 failed`.

## Ryzyka rezydualne
1. R1 (P1): Niepotwierdzony wynik walidacji SQL backfill po migracji na remote.
2. R2 (P2): W danych historycznych mog¹ pozostaæ rekordy `ccp3_cooling` nierozwi¹zywalne bez `venue_id` (oznaczone metadata).
3. R3 (P3): Czêœæ historycznych `storage_path` mo¿e pozostaæ w mixed formacie (`reports/...` vs bez prefiksu), choæ runtime ma normalizacjê.

## Decyzja release (na ten moment)
1. Decyzja: CONDITIONAL GO
- GO dla warstwy aplikacyjnej (routing, miesiêczny kontrakt, testy).
- Warunek blokuj¹cy zamkniêcie Sprint 6: wykonanie i zapis wyniku walidacji SQL z pliku `ccp3_04_generated_reports_backfill_validation.sql`.

## Plan monitoringu 48h po release
1. Co 4h: liczba nowych rekordów `generated_reports` dla `ccp2_roasting` i `ccp3_cooling` per `venue_id`.
2. Co 4h: liczba rekordów `ccp3_cooling` z `venue_id is null`.
3. Co 4h: liczba konfliktów unikalnoœci `(venue_id, report_type, generation_date)`.
4. Co 4h: incydenty otwarcia uszkodzonego PDF i u¿ycia fallback `force=1`.
5. Po 48h: decyzja finalna GO-LIVE CLOSE lub rollback wg runbooka Sprint 4.

## Zadania dla juniora
1. Wype³nij checklistê review dowodami (logi/testy/screeny).
2. Przygotuj listê ryzyk rezydualnych.
3. Zaproponuj plan monitoringu 48h po release.

## Exit criteria
1. Raport koñcowy zatwierdzony.
2. Jednoznaczna decyzja GO/NO-GO.

## Stan exit criteria
1. Raport koñcowy: GOTOWY (warunkowo).
2. Jednoznaczna decyzja GO/NO-GO: OCZEKUJE (po walidacji SQL -> final GO lub NO-GO).
