-- Migration: Allow ccp2_roasting in generated_reports
-- Date: 2026-02-26

-- Replace constraint to allow ccp2_roasting
ALTER TABLE public.generated_reports
  DROP CONSTRAINT IF EXISTS generated_reports_report_type_check;

ALTER TABLE public.generated_reports
  ADD CONSTRAINT generated_reports_report_type_check
  CHECK (
    report_type = ANY (
      ARRAY[
        'ccp3_cooling'::text,
        'waste_monthly'::text,
        'gmp_daily'::text,
        'ccp1_temperature'::text,
        'ccp2_roasting'::text
      ]
    )
  ) not valid;

ALTER TABLE public.generated_reports
  VALIDATE CONSTRAINT generated_reports_report_type_check;
