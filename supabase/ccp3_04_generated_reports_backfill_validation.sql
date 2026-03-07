-- Sprint 4 validation: generated_reports CCP3 venue backfill
-- Run after migration 20260226200000_sprint4_ccp3_generated_reports_venue_backfill.sql

-- 1) Baseline vs current target size
select
  (select count(*) from public.generated_reports_ccp3_backfill_20260226_backup) as initial_null_venue_target,
  (select count(*) from public.generated_reports where report_type = 'ccp3_cooling' and venue_id is null) as current_null_venue,
  (select count(*) from public.generated_reports where report_type = 'ccp3_cooling' and metadata->>'ccp3_backfill_status' = 'resolved') as resolved_count,
  (select count(*) from public.generated_reports where report_type = 'ccp3_cooling' and metadata->>'ccp3_backfill_status' = 'unresolved') as unresolved_count;

-- 2) Unresolved rows with reasons
select
  id,
  generation_date,
  storage_path,
  metadata->>'ccp3_backfill_reason' as unresolved_reason,
  metadata
from public.generated_reports
where report_type = 'ccp3_cooling'
  and venue_id is null
order by generation_date desc, created_at desc;

-- 3) Duplicate key check (must be zero rows)
select
  venue_id,
  report_type,
  generation_date,
  count(*) as duplicates
from public.generated_reports
where report_type in ('ccp2_roasting', 'ccp3_cooling')
  and venue_id is not null
group by venue_id, report_type, generation_date
having count(*) > 1;

-- 4) Storage path and venue consistency sample (recent)
select
  id,
  venue_id,
  report_type,
  generation_date,
  storage_path,
  metadata->>'ccp3_backfill_status' as backfill_status,
  metadata->>'ccp3_backfill_reason' as backfill_reason,
  created_at
from public.generated_reports
where report_type = 'ccp3_cooling'
order by created_at desc
limit 50;

-- 5) Tenant scope sanity (rows still missing venue_id)
-- Expected result after successful backfill: preferably 0.
-- If >0, all remaining rows should carry metadata.ccp3_backfill_status='unresolved'.
select
  count(*) as remaining_without_venue,
  count(*) filter (where metadata->>'ccp3_backfill_status' = 'unresolved') as marked_unresolved
from public.generated_reports
where report_type = 'ccp3_cooling'
  and venue_id is null;

