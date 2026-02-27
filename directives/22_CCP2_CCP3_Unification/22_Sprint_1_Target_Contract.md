# Sprint 1: Kontrakt Docelowy i Decyzje Architektoniczne

Data: 2026-02-26  
Status: STARTED (decision-complete v1)

## Cel sprintu
Domknąć kontrakty i reguły tak, aby Sprinty 2-6 wykonywać bez otwartych decyzji architektonicznych.

## Decyzje zamrożone
1. Semantyka okresu:
- CCP2 i CCP3 działają miesięcznie.
- Parametr `date` w routingu jest wyłącznie kotwicą miesiąca.
- `generation_date` zawsze = pierwszy dzień miesiąca (`YYYY-MM-01`).
2. Nawigacja M03 Historia:
- CCP2 klik -> `/reports/preview/ccp2?date=YYYY-MM-DD`.
- CCP3 klik -> `/reports/preview/ccp3?date=YYYY-MM-DD`.
3. Cache key:
- Klucz logiczny: `venue_id + report_type + generation_date`.
4. Legacy:
- Brak fallback cross-venue.
- Rekordy bez `venue_id` nie są używane do odczytu tenantowego.
- Naprawa legacy wyłącznie przez migracje DB (Sprint 4).

## Kontrakt I/O (Router -> Provider -> Repository)

## 1) Router contract
1. Wejścia do preview:
- `M03/GMP Historia`: `gmp_history_screen.dart` push dla CCP2/CCP3.
- `M06/Reports Panel`: `reports_panel_screen.dart` push dla CCP2/CCP3.
- `M06/Archiwum`: `saved_reports_screen.dart` push z `force=1` przy uszkodzonym PDF.
2. Trasy docelowe:
- `/reports/preview/ccp2?date={YYYY-MM-DD}[&force=1]`
- `/reports/preview/ccp3?date={YYYY-MM-DD}[&force=1]`
3. Parsing:
- `date` niepoprawne lub puste -> `DateTime.now()` (fallback runtime).
- `force` aktywne dla `1` lub `true`.

## 2) Provider contract (CCP2/CCP3)
1. DTO request:
- `date: DateTime`
- `forceRegenerate: bool = false`
2. Normalizacja okresu:
- `periodStart = DateTime(date.year, date.month, 1)`
- `periodEnd = firstDay(nextMonth) - 1 ms`
3. Read path:
- Resolve `venueId` z `currentZoneProvider`, fallback `employeeZonesProvider`.
- `getSavedReport(periodStart, reportType, venueId)` gdy `forceRegenerate=false`.
- Jeżeli cache hit i PDF poprawny -> zwróć bytes.
4. Generate path:
- Pobierz dane miesięczne (`getRoastingLogs` / `getCoolingLogs`).
- Wygeneruj PDF.
- Upload do storage.
- `saveReportMetadata(...)` z kontraktową metadanych.
5. Write guard:
- Brak zapisu, gdy brak `venueId` lub brak `user`.

## 3) Repository contract
1. `getRoastingLogs(month, {zoneId, venueId})`
- Zakres miesięczny.
- `form_id` kompatybilny: `meat_roasting`, `meat_roasting_daily`.
- Priorytet scoping: `zone_id`, fallback: `venue_id`.
2. `getCoolingLogs(month, {zoneId, venueId})`
- Zakres miesięczny.
- `form_id = food_cooling`.
- Priorytet scoping: `zone_id`, fallback: `venue_id`.
3. `getSavedReport(date, type, {required venueId})`
- Wyszukiwanie po `venue_id + report_type + generation_date`.
4. `saveReportMetadata(...)`
- Upsert na `onConflict: venue_id,report_type,generation_date`.

## Kontrakt metadanych `generated_reports.metadata`
Wymagane klucze:
1. `period_start`: `YYYY-MM-DD`.
2. `period_end`: `YYYY-MM-DD`.
3. `template_version`: string.
4. `source_form_id`: string.

Wartości docelowe:
1. CCP2:
- `template_version = ccp2_pdf_v2`
- `source_form_id = meat_roasting`
2. CCP3:
- `template_version = ccp3_pdf_v2`
- `source_form_id = food_cooling`

Klucze opcjonalne:
1. `generated_automatically: true`
2. Dodatkowe pola diagnostyczne per raport.

## Kontrakt `storage_path`
Format docelowy:
1. `reports/{venueId}/{YYYY}/{MM}/{fileName}.pdf`

Konwencja plików:
1. CCP2: `ccp2_roasting_{YYYY-MM}.pdf`
2. CCP3: `ccp3_cooling_{YYYY-MM}.pdf`

Zasada kompatybilności:
1. Runtime odczytuje zarówno ścieżki z prefiksem `reports/`, jak i bez prefiksu.
2. Nowe zapisy od Sprint 1 mają używać formatu docelowego z prefiksem `reports/`.

## Kontrakt bezpieczeństwa i tenancji
1. Read i write tylko w kontekście aktywnego `venue_id`.
2. Bez fallbacku do innego venue przy miss cache lub braku `venue_id`.
3. Zgodność z RLS: brak odczytu cross-tenant i brak regeneracji cross-tenant.

## Kompatybilność wsteczna (lista zamknięta)
1. Legacy `form_id`:
- `meat_roasting_daily` obsługiwane tylko jako alias odczytu.
2. Legacy `storage_path`:
- Akceptowane w odczycie, normalizacja w repo.
3. Legacy `generated_reports` bez `venue_id`:
- Nieużywane w tenantowym read path; naprawa wyłącznie migracją Sprint 4.

## Mapa refaktoru do kolejnych sprintów
1. M03:
- `lib/features/m03_gmp/screens/gmp_history_screen.dart`
- `lib/features/m03_gmp/config/gmp_form_ids.dart`
2. M06:
- `lib/features/m06_reports/screens/ccp2_preview_screen.dart`
- `lib/features/m06_reports/screens/ccp3_preview_screen.dart`
- `lib/features/m06_reports/screens/reports_panel_screen.dart`
- `lib/features/m06_reports/screens/saved_reports_screen.dart`
- `lib/features/m06_reports/repositories/reports_repository.dart`
3. Routing:
- `lib/core/router/app_router.dart`
4. DB:
- `supabase/migrations/*generated_reports*`

## Zadania dla juniora (Sprint 1)
1. Rozpisz mapowanie endpointów i providerów na podstawie tego kontraktu.
2. Zidentyfikuj wszystkie miejsca zapisu `storage_path` i potwierdź format docelowy.
3. Przygotuj checklistę kompatybilności wstecznej do review.

## Exit criteria
1. Brak otwartych decyzji architektonicznych dla unifikacji CCP2/CCP3.
2. Kontrakt zatwierdzony przez seniora jako baza dla Sprintów 2-6.
