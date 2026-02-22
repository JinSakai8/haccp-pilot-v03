# Migration Notes

- `migrations/20260222084436_remote_schema.sql`:
  history-repair placeholder (no-op) created while aligning local/remote migration history.
- `migrations/20260222084803_remote_schema.sql`:
  first successful full remote schema snapshot from `supabase db pull` on 2026-02-22.
- `migrations/20260222130356_m06_ccp1_generated_reports_report_type.sql`:
  Sprint 1 (M06 CCP-1). Extends `generated_reports_report_type_check` with
  `ccp1_temperature`.

Keep both files to preserve parity with the remote migration history table.
