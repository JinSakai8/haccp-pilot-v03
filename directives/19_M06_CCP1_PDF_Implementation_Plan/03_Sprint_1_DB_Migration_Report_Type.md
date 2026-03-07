# Sprint 1: Migracja DB pod `ccp1_temperature`

## Cel
Umozliwic legalny zapis raportow CCP-1 temperatur w `generated_reports`.

## Zadania DB
- [x] Przygotowac migracje SQL:
  - drop constraint `generated_reports_report_type_check`
  - add constraint z lista:
    - `ccp3_cooling`
    - `waste_monthly`
    - `gmp_daily`
    - `ccp1_temperature`
- [x] Zweryfikowac, ze polityki RLS pozostaja funkcjonalnie bez zmian.
- [x] Przygotowac rollback SQL (przywrocenie poprzedniego check constraint).

## Testy DB
- [x] Test pozytywny: insert z `report_type='ccp1_temperature'` przechodzi.
- [x] Test negatywny: insert z nieznanym `report_type` jest blokowany.
- [x] Test regresji: insert dla starych typow nadal przechodzi.

## Artefakty
- Plik migracji w `supabase/migrations/...`.
- Krotki runbook: apply + rollback.
- Wykonany plik migracji:
  - `supabase/migrations/20260222130356_m06_ccp1_generated_reports_report_type.sql`
- Runbook Sprint 1:
  - `directives/19_M06_CCP1_PDF_Implementation_Plan/09_Sprint_1_DB_Runbook.md`

## Kryteria akceptacji (AC)
- [x] Migracja dziala lokalnie.
- [x] Migracja dziala na staging.
- [x] Rollback jest opisany i przetestowany.
