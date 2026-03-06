-- Sprint 4 (Efento): upstream blocked-state lifecycle
-- Date: 2026-03-06
-- Scope:
-- 1) Add upstream access lifecycle columns for measurement point mapping.
-- 2) Backfill defaults and indexing for scheduler/backfill filtering.

begin;

alter table public.efento_measurement_point_map
  add column if not exists upstream_access_state text;

update public.efento_measurement_point_map
set upstream_access_state = 'unknown'
where upstream_access_state is null;

alter table public.efento_measurement_point_map
  alter column upstream_access_state set default 'unknown';

alter table public.efento_measurement_point_map
  alter column upstream_access_state set not null;

alter table public.efento_measurement_point_map
  drop constraint if exists efento_map_upstream_access_state_check;

alter table public.efento_measurement_point_map
  add constraint efento_map_upstream_access_state_check
  check (upstream_access_state in ('unknown', 'ok', 'blocked')) not valid;

alter table public.efento_measurement_point_map
  validate constraint efento_map_upstream_access_state_check;

alter table public.efento_measurement_point_map
  add column if not exists upstream_access_last_checked_at timestamptz;

alter table public.efento_measurement_point_map
  add column if not exists upstream_access_last_error text;

create index if not exists efento_measurement_point_map_active_state_idx
  on public.efento_measurement_point_map (is_active, upstream_access_state, measurement_point_id);

commit;

