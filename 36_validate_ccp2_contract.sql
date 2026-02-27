-- CCP2 contract validation script (read-only checks)
-- Run manually after migrations/deployment.

-- 1) Verify report_type constraint includes ccp2_roasting
select conname, pg_get_constraintdef(c.oid) as definition
from pg_constraint c
join pg_class t on t.oid = c.conrelid
where t.relname = 'generated_reports'
  and c.conname = 'generated_reports_report_type_check';

-- 2) Verify uniqueness guard for venue/type/date
select indexname, indexdef
from pg_indexes
where tablename = 'generated_reports'
  and indexname in (
    'generated_reports_unique_venue_type_date',
    'generated_reports_venue_type_date_idx'
  );

-- 3) Verify kiosk-scoped RLS policies
select policyname, cmd, qual, with_check
from pg_policies
where schemaname = 'public'
  and tablename = 'generated_reports'
order by policyname;

-- 4) Verify recent roasting logs contain ccp2 payload fields (best-effort)
select
  id,
  created_at,
  form_id,
  data ? 'is_compliant' as has_is_compliant,
  data ? 'corrective_actions' as has_corrective_actions
from public.haccp_logs
where category = 'gmp'
  and form_id = 'meat_roasting'
order by created_at desc
limit 50;
