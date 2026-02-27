-- Sprint 1 (M06 CCP-1): allow archiving temperature PDF reports as ccp1_temperature.
-- Scope: generated_reports.report_type check constraint only.

alter table public.generated_reports
  drop constraint if exists generated_reports_report_type_check;

alter table public.generated_reports
  add constraint generated_reports_report_type_check
  check (
    report_type = any (
      array[
        'ccp3_cooling'::text,
        'waste_monthly'::text,
        'gmp_daily'::text,
        'ccp1_temperature'::text
      ]
    )
  ) not valid;

alter table public.generated_reports
  validate constraint generated_reports_report_type_check;
