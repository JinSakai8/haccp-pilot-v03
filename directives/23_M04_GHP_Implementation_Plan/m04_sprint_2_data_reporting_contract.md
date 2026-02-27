# Sprint 2 - Data + Reporting Contract

## Status Sprintu
- Status: Zakonczony (kontrakt danych i reporting zamrozony)
- Data zamkniecia: 2026-02-27
- Decyzja: READY FOR SPRINT 3

## Cel Sprintu
Zdefiniowac i wdrozyc kontrakt danych dla GHP i raportow tak, aby Sprint 3/4 byl czysta implementacja logiki i UI.

## 1. Zakres (wykonany)
- Rozszerzenie kontraktu wpisu GHP o date/godzine wykonania (payload `data`).
- Kontrakt raportu GHP w `generated_reports`.
- Finalny kontrakt storage path dla PDF GHP.

## 2. Zamrozony kontrakt danych
### 2.1 GHP payload -> `haccp_logs`
- `category`: `ghp`
- `form_id`: `ghp_personnel` | `ghp_rooms` | `ghp_maintenance` | `ghp_chemicals`
- `data.execution_date`: `YYYY-MM-DD` (required)
- `data.execution_time`: `HH:mm` (required)
- `data.answers`: obiekt odpowiedzi checklisty/chemii (required)
- `data.notes`: string (optional)

Mapowanie (skad -> dokad):
1. UI (M04 checklist/chemicals) -> provider M04 -> repository M04 -> `haccp_logs.data.execution_*`.
2. `zone_id`, `venue_id`, `user_id` z auth contextu -> `haccp_logs`.

### 2.2 GHP report metadata -> `generated_reports`
- `report_type`: `ghp_checklist_monthly`
- `generation_date`: pierwszy dzien miesiaca raportowego (`YYYY-MM-01`)
- `storage_path`: `reports/<venueId>/<YYYY>/<MM>/ghp_checklist_<YYYY-MM>.pdf`
- `metadata` (minimum):
  - `period_start`
  - `period_end`
  - `template_version` (`ghp_pdf_v1`)
  - `source_form_id` (`ghp_all` lub konkretny `ghp_*`)
  - `zone_id` (dla raportu strefowego)

Mapowanie (skad -> dokad):
1. M06 dataset GHP (z `haccp_logs`) -> PDF bytes -> storage bucket `reports`.
2. `uploadReport` path -> `generated_reports.storage_path` (z prefixem `reports/`).
3. period/template/source -> `generated_reports.metadata`.

## 3. Zmiany wdrozone w Sprint 2
### 3.1 Dokumentacja
- Zaktualizowano `supabase.md` (kontrakt GHP payload, report_type, storage path).
- Zaktualizowano `Code_description.MD` (M04/M06 contract update).

### 3.2 DB
- Dodano migracje:
  - `supabase/migrations/20260227133000_m04_ghp_generated_reports_report_type.sql`
- Efekt: `generated_reports_report_type_check` dopuszcza `ghp_checklist_monthly`.

### 3.3 App code (contract readiness)
- `lib/features/m06_reports/repositories/reports_repository.dart`
  - dodane `getGhpLogs(...)` (dataset source pod Sprint 3),
  - `saveReportMetadata` normalizuje `storage_path` do formatu `reports/<path>`,
  - domyslne mapowanie dla `ghp_checklist_monthly`:
    - `template_version = ghp_pdf_v1`
    - `source_form_id = ghp_all`

## 4. Ryzyka i guardrails
- Ryzyko: rozjazd danych `execution_*` miedzy formularzami i repozytorium.
  - Guardrail: pola mandatory w kontrakcie i testy repo/provider w Sprint 3.
- Ryzyko: niespojne `storage_path` (z/bez prefixu bucketu).
  - Guardrail: normalizacja w `saveReportMetadata`.
- Ryzyko: brak implementacji raportu GHP w UI (jeszcze Sprint 3/4).
  - Guardrail: kontrakt gotowy, implementacja bez zmian DB.

## 5. Exit Criteria
- Kontrakt danych jest jednoznaczny i zatwierdzony: SPELNIONE.
- Wszystkie pola GHP i raportowe maja mapowanie "skad -> dokad": SPELNIONE.
- Sprint 3 moze implementowac bez dodatkowych decyzji DB: SPELNIONE.

## 6. Ready for Sprint 3
Sprint 2 zamkniety. Mozna przejsc do Sprint 3 (Domain + Providers).
