# Migration Notes

- `migrations/20260222084436_remote_schema.sql`:
  history-repair placeholder (no-op) created while aligning local/remote migration history.
- `migrations/20260222084803_remote_schema.sql`:
  first successful full remote schema snapshot from `supabase db pull` on 2026-02-22.
- `migrations/20260222130356_m06_ccp1_generated_reports_report_type.sql`:
  Sprint 1 (M06 CCP-1). Extends `generated_reports_report_type_check` with
  `ccp1_temperature`.
- `migrations/20260224100000_m07_01_create_employee_contract_fix.sql`:
  Sprint 1 (M07). Reworks `create_employee` to derive and persist `employees.venue_id`
  from `zone_ids_input`, validates one-venue zone domain, and throws domain errors:
  `M07_ZONE_REQUIRED`, `M07_ZONE_NOT_FOUND`, `M07_ZONE_MULTI_VENUE`, `M07_PIN_DUPLICATE`.
  Rollback: reapply prior `create_employee` definition from
  `migrations/20260222084803_remote_schema.sql`.
- `migrations/20260224101000_m07_02_pin_hash_unique_constraint.sql`:
  Sprint 1 (M07). Adds unique index `employees_pin_hash_unique_idx` on `employees(pin_hash)`.
  Guard check raises `M07_PIN_DUPLICATES_EXIST` if duplicates already exist.
  Rollback: `drop index if exists public.employees_pin_hash_unique_idx;`.
- `migrations/20260224102000_m07_03_update_employee_pin_rpc.sql`:
  Sprint 1 (M07). Adds secure RPC `update_employee_pin(employee_id, new_pin_hash)`
  with domain errors `M07_PIN_REQUIRED`, `M07_PIN_DUPLICATE`, `M07_EMPLOYEE_NOT_FOUND`.
  Rollback: `drop function if exists public.update_employee_pin(uuid, text);`.
- `migrations/20260224103000_m07_05_fix_create_employee_uuid_aggregate.sql`:
  Hotfix (M07). Fixes `create_employee` venue derivation by replacing unsupported
  `min(uuid)` with `min(venue_id::text)::uuid` for compatibility.
  Rollback: reapply prior `create_employee` definition from
  `migrations/20260224100000_m07_01_create_employee_contract_fix.sql`.

Keep both files to preserve parity with the remote migration history table.
