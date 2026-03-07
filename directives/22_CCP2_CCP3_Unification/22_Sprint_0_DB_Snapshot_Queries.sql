-- Sprint 0 baseline snapshot queries
-- Data: 2026-02-26
-- Scope: generated_reports (CCP2/CCP3), haccp_logs (roasting/cooling)

-- 1) Count reports per type
select report_type, count(*) as cnt
from public.generated_reports
where report_type in ('ccp2_roasting', 'ccp3_cooling')
group by report_type
order by report_type;

-- 2) Count reports per venue and type
select venue_id, report_type, count(*) as cnt
from public.generated_reports
where report_type in ('ccp2_roasting', 'ccp3_cooling')
group by venue_id, report_type
order by venue_id, report_type;

-- 3) Find possible contract issues in generated_reports
select
  id,
  venue_id,
  report_type,
  generation_date,
  storage_path,
  metadata
from public.generated_reports
where report_type in ('ccp2_roasting', 'ccp3_cooling')
  and (
    venue_id is null
    or storage_path is null
    or storage_path = ''
    or metadata is null
    or not (metadata ? 'period_start')
    or not (metadata ? 'period_end')
    or not (metadata ? 'template_version')
    or not (metadata ? 'source_form_id')
  )
order by generation_date desc;

-- 4) Sample recent reports
select
  id,
  venue_id,
  report_type,
  generation_date,
  storage_path,
  metadata,
  created_at
from public.generated_reports
where report_type in ('ccp2_roasting', 'ccp3_cooling')
order by created_at desc
limit 20;

-- 5) Count haccp_logs relevant for CCP2/CCP3
select form_id, count(*) as cnt
from public.haccp_logs
where category = 'gmp'
  and form_id in ('meat_roasting', 'meat_roasting_daily', 'food_cooling')
group by form_id
order by form_id;

-- 6) Monthly distribution for haccp_logs (last 12 months)
select
  date_trunc('month', created_at)::date as month_start,
  form_id,
  count(*) as cnt
from public.haccp_logs
where category = 'gmp'
  and form_id in ('meat_roasting', 'meat_roasting_daily', 'food_cooling')
  and created_at >= date_trunc('month', now()) - interval '12 months'
group by 1, 2
order by 1 desc, 2;

-- 7) Legacy roasting ids still present
select count(*) as legacy_roasting_cnt
from public.haccp_logs
where category = 'gmp'
  and form_id = 'meat_roasting_daily';

-- 8) Check uniqueness contract for generated_reports
select
  venue_id,
  report_type,
  generation_date,
  count(*) as duplicates
from public.generated_reports
where report_type in ('ccp2_roasting', 'ccp3_cooling')
group by venue_id, report_type, generation_date
having count(*) > 1
order by duplicates desc;

-- 9) Optional: validate storage path pattern (simple heuristic)
select
  id,
  report_type,
  storage_path
from public.generated_reports
where report_type in ('ccp2_roasting', 'ccp3_cooling')
  and storage_path !~ '^[^/]+/[0-9]{4}/[0-9]{2}/.+\\.pdf$'
order by created_at desc;
