# Sprint 4: DB Backfill + Security + Operability

Data: 2026-02-26  
Status: COMPLETED (artefakty gotowe do rolloutu staging -> production)

## Cel sprintu
Naprawiæ legacy rekordy CCP3 i utrzymaæ bezpieczne scoping tenantów.

## Zakres
1. Migracja backfill `generated_reports`:
- uzupe³nienie `venue_id` dla `ccp3_cooling` na podstawie `storage_path`,
- oznaczenie nierozwi¹zywalnych rekordów flag¹ metadata.
2. Skrypt walidacyjny po migracji:
- count before/after,
- unresolved rows,
- kontrola konfliktów unikalnoœci.
3. Runbook rollback:
- kroki cofniêcia i procedura awaryjna.

## Wymagania bezpieczeñstwa
1. Bez fallback bez `venue_id`.
2. Bez odczytu cross-tenant.
3. Zgodnoœæ z RLS.

## Zadania dla juniora
1. Przygotuj migracjê SQL z idempotentnym update.
2. Dodaj skrypt walidacyjny SQL.
3. Opisz rollback krok po kroku.

## Exit criteria
1. Archiwum M06 widzi poprawnie legacy CCP3 po backfill.
2. 0 naruszeñ RLS i 0 wycieków miêdzy venue.

## Implementacja (wykonana)
1. Dodana migracja:
- `supabase/migrations/20260226200000_sprint4_ccp3_generated_reports_venue_backfill.sql`
2. Dodany skrypt walidacyjny:
- `supabase/ccp3_04_generated_reports_backfill_validation.sql`
3. Dodany runbook rollback:
- `directives/22_CCP2_CCP3_Unification/22_Sprint_4_Rollback_Runbook.md`

## Za³o¿enia techniczne migracji
1. Migracja jest idempotentna:
- backup rows z `on conflict do nothing`,
- update tylko dla `ccp3_cooling` z `venue_id is null`.
2. Ekstrakcja `venue_id` oparta o `storage_path`:
- obs³uga œcie¿ek z i bez prefiksu `reports/`.
3. Brak naruszeñ unikalnoœci:
- rekordy prowadz¹ce do konfliktu `(venue_id, report_type, generation_date)` nie s¹ ustawiane,
- s¹ oznaczane jako `metadata.ccp3_backfill_status='unresolved'` z powodem.
4. Brak fallback cross-tenant:
- tylko deterministiczne mapowanie `storage_path -> venue_id`.

## Uwaga wdro¿eniowa
1. W tym kroku przygotowano artefakty.
2. `supabase db push` i walidacja SQL maj¹ byæ wykonane zgodnie z master planem:
- najpierw staging,
- potem produkcja.
