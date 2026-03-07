-- Sprint 2 (M04 GHP): allow archiving monthly GHP checklist reports.
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
        'ccp1_temperature'::text,
        'ccp2_roasting'::text,
        'ghp_checklist_monthly'::text
      ]
    )
  ) not valid;

alter table public.generated_reports
  validate constraint generated_reports_report_type_check;
