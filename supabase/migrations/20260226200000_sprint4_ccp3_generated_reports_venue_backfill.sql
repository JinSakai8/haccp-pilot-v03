-- Sprint 4: CCP3 generated_reports venue backfill
-- Date: 2026-02-26
-- Goal:
-- 1) Fill missing venue_id for legacy ccp3_cooling reports using storage_path.
-- 2) Mark unresolved rows in metadata.
-- 3) Avoid cross-tenant fallback and avoid uniqueness conflicts.
-- 4) Keep migration idempotent.

begin;

create table if not exists public.generated_reports_ccp3_backfill_20260226_backup (
  report_id uuid primary key,
  previous_venue_id uuid,
  previous_metadata jsonb,
  previous_storage_path text,
  captured_at timestamptz not null default now()
);

insert into public.generated_reports_ccp3_backfill_20260226_backup (
  report_id,
  previous_venue_id,
  previous_metadata,
  previous_storage_path
)
select
  g.id,
  g.venue_id,
  g.metadata,
  g.storage_path
from public.generated_reports g
where g.report_type = 'ccp3_cooling'
  and g.venue_id is null
on conflict (report_id) do nothing;

with target as (
  select
    g.id as report_id,
    g.generation_date,
    regexp_replace(trim(coalesce(g.storage_path, '')), '^/+', '') as normalized_storage_path
  from public.generated_reports g
  where g.report_type = 'ccp3_cooling'
    and g.venue_id is null
),
parsed as (
  select
    t.report_id,
    t.generation_date,
    case
      when t.normalized_storage_path ~* '(^|/)reports/[0-9a-fA-F-]{36}(/|$)'
        then substring(t.normalized_storage_path from 'reports/([0-9a-fA-F-]{36})')
      when split_part(t.normalized_storage_path, '/', 1) ~* '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
        then split_part(t.normalized_storage_path, '/', 1)
      else null
    end as venue_token
  from target t
),
resolved as (
  select
    p.report_id,
    p.generation_date,
    p.venue_token::uuid as candidate_venue_id
  from parsed p
  join public.venues v
    on v.id::text = p.venue_token
  where p.venue_token is not null
    and p.venue_token ~* '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
),
eligible as (
  select
    r.report_id,
    r.generation_date,
    r.candidate_venue_id
  from resolved r
  where not exists (
    select 1
    from public.generated_reports g2
    where g2.id <> r.report_id
      and g2.report_type = 'ccp3_cooling'
      and g2.generation_date = r.generation_date
      and g2.venue_id = r.candidate_venue_id
  )
)
update public.generated_reports g
set
  venue_id = e.candidate_venue_id,
  metadata = coalesce(g.metadata, '{}'::jsonb) || jsonb_build_object(
    'ccp3_backfill_status', 'resolved',
    'ccp3_backfill_source', 'storage_path',
    'ccp3_backfill_at', now()
  )
from eligible e
where g.id = e.report_id
  and g.report_type = 'ccp3_cooling'
  and g.venue_id is null;

with target as (
  select
    g.id as report_id,
    g.generation_date,
    regexp_replace(trim(coalesce(g.storage_path, '')), '^/+', '') as normalized_storage_path
  from public.generated_reports g
  where g.report_type = 'ccp3_cooling'
    and g.venue_id is null
),
parsed as (
  select
    t.report_id,
    t.generation_date,
    case
      when t.normalized_storage_path ~* '(^|/)reports/[0-9a-fA-F-]{36}(/|$)'
        then substring(t.normalized_storage_path from 'reports/([0-9a-fA-F-]{36})')
      when split_part(t.normalized_storage_path, '/', 1) ~* '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
        then split_part(t.normalized_storage_path, '/', 1)
      else null
    end as venue_token
  from target t
),
classified as (
  select
    p.report_id,
    case
      when p.venue_token is null then 'venue_not_resolved_from_storage_path'
      when not exists (
        select 1
        from public.venues v
        where v.id::text = p.venue_token
      ) then 'venue_missing_in_venues'
      when exists (
        select 1
        from public.generated_reports g2
        join public.generated_reports g_self on g_self.id = p.report_id
        where g2.id <> p.report_id
          and g2.report_type = 'ccp3_cooling'
          and g2.generation_date = g_self.generation_date
          and g2.venue_id::text = p.venue_token
      ) then 'unique_conflict_existing_report'
      else 'unknown'
    end as unresolved_reason
  from parsed p
)
update public.generated_reports g
set
  metadata = coalesce(g.metadata, '{}'::jsonb) || jsonb_build_object(
    'ccp3_backfill_status', 'unresolved',
    'ccp3_backfill_reason', c.unresolved_reason,
    'ccp3_backfill_at', now()
  )
from classified c
where g.id = c.report_id
  and g.report_type = 'ccp3_cooling'
  and g.venue_id is null;

commit;
