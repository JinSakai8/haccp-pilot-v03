# Sprint 0: Baseline i kontrakt

## Cel
Zamknac faze przygotowawcza i zminimalizowac ryzyko regresji.

## Zadania
- [x] S0.1 Potwierdzic miejsca zmian w kodzie M02:
  - `lib/features/m02_monitoring/models/temperature_log.dart`
  - `lib/features/m02_monitoring/repositories/measurements_repository.dart`
  - `lib/features/m02_monitoring/providers/monitoring_provider.dart`
  - `lib/features/m02_monitoring/screens/sensor_chart_screen.dart`
- [x] S0.2 Potwierdzic miejsca zmian DB:
  - migracja: `supabase/migrations/20260223120000_m02_temperature_logs_table_edit_hardening.sql`
- [x] S0.3 Potwierdzic kryteria uprawnien i okna czasowego:
  - role: `manager` / `owner`
  - okno czasu: `recorded_at >= now() - interval '7 days'`
  - zrodlo: `directives/20_M02_Table_7D_Edit_Implementation_Plan/01_Context_And_Decisions.md`
- [x] S0.4 Spisac ryzyka i plan rollback.

## Kryteria akceptacji
- [x] Decyzje zamrozone sa spisane i niezmienne w sprintach S1-S4.
- [x] Lista plikow i migracji jest kompletna.

## Ryzyka (baseline)
- Regresja wykresow `24h/7 dni/30 dni` przy rozbudowie ekranu o tryb tabeli.
- Niespojnosc autoryzacji (UI vs backend) dla edycji temperatury.
- Bledy scope kiosk (`venue_id`/`zone_id`) po hardeningu RLS.
- Bledy operacyjne przy rollout (RPC edit/ack), wymagajace hotfix read-only.

## Plan rollback
- Kanoniczny runbook: `directives/20_M02_Table_7D_Edit_Implementation_Plan/07_DB_Runbook_Rollback.md`
- Strategia preferowana: fix-forward.
- Rollback tylko w przypadku krytycznego incydentu runtime.

## Status
- Sprint 0: CLOSED (2026-02-23).
