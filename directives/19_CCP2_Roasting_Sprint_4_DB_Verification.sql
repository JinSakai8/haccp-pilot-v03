-- CCP2 Sprint 4: DB verification queries
-- Run in Supabase SQL editor for incident diagnostics.

-- 1) Recent roasting logs by form_id
select form_id, count(*)
from public.haccp_logs
where category = 'gmp'
  and form_id in ('meat_roasting', 'meat_roasting_daily')
group by form_id
order by form_id;

-- 2) Roasting logs missing scope
select
  count(*) filter (where venue_id is null) as missing_venue,
  count(*) filter (where zone_id is null) as missing_zone
from public.haccp_logs
where category = 'gmp'
  and form_id in ('meat_roasting', 'meat_roasting_daily');

-- 3) Generated CCP2 reports metadata snapshot
select
  id,
  venue_id,
  report_type,
  generation_date,
  storage_path,
  metadata->>'period_start' as period_start,
  metadata->>'period_end' as period_end,
  metadata->>'source_form_id' as source_form_id,
  created_at
from public.generated_reports
where report_type = 'ccp2_roasting'
order by generation_date desc, created_at desc
limit 200;

-- 4) Duplicate key check (should be 0 rows)
select venue_id, report_type, generation_date, count(*)
from public.generated_reports
where report_type = 'ccp2_roasting'
group by venue_id, report_type, generation_date
having count(*) > 1;

-- 5) Contract check for source form ids
select
  metadata->>'source_form_id' as source_form_id,
  count(*)
from public.generated_reports
where report_type = 'ccp2_roasting'
group by metadata->>'source_form_id'
order by 2 desc;

-- 6) Optional repair template (uncomment and fill ids)
-- update public.generated_reports
-- set metadata = coalesce(metadata, '{}'::jsonb)
--   || jsonb_build_object(
--       'period_start', generation_date::text,
--       'period_end', generation_date::text,
--       'source_form_id', 'meat_roasting',
--       'template_version', 'ccp2_pdf_v2'
--   )
-- where report_type = 'ccp2_roasting'
--   and id = '<REPORT_ID>';
