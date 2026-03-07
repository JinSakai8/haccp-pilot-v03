-- Sprint 4: historical data migration for haccp_logs
-- Date: 2026-02-22
--
-- Scope:
-- 1) Canonicalize legacy GMP form_id values.
-- 2) Fill missing venue_id where it can be inferred from employees.
-- 3) Fill missing zone_id only for employees assigned to exactly one zone in the same venue.
-- 4) Keep an explicit backup table for rollback.

begin;

create table if not exists public.haccp_logs_sprint4_backup_20260222 as
select
  h.id,
  h.form_id as old_form_id,
  h.venue_id as old_venue_id,
  h.zone_id as old_zone_id
from public.haccp_logs h
where
  (h.category = 'gmp' and h.form_id in ('meat_roasting_daily', 'delivery_control_daily'))
  or h.venue_id is null
  or h.zone_id is null;

create index if not exists haccp_logs_sprint4_backup_20260222_id_idx
  on public.haccp_logs_sprint4_backup_20260222 (id);

-- S4.1 Canonical form_id values.
update public.haccp_logs
set form_id = 'meat_roasting'
where category = 'gmp'
  and form_id = 'meat_roasting_daily';

update public.haccp_logs
set form_id = 'delivery_control'
where category = 'gmp'
  and form_id = 'delivery_control_daily';

-- S4.2 Fill missing venue_id only when user_id resolves directly to an employee.
update public.haccp_logs h
set venue_id = e.venue_id
from public.employees e
where h.venue_id is null
  and h.user_id = e.id;

-- S4.2 Fill missing zone_id only when mapping is unambiguous and venue-safe.
with single_employee_zone as (
  select
    ez.employee_id,
    (array_agg(ez.zone_id))[1] as zone_id
  from public.employee_zones ez
  group by ez.employee_id
  having count(distinct ez.zone_id) = 1
)
update public.haccp_logs h
set zone_id = sez.zone_id
from public.employees e
join single_employee_zone sez on sez.employee_id = e.id
join public.zones z on z.id = sez.zone_id
where h.zone_id is null
  and h.user_id = e.id
  and h.venue_id is not null
  and z.venue_id = h.venue_id;

commit;

-- Post-run report (manual):
-- select form_id, count(*) from public.haccp_logs where category = 'gmp' group by form_id order by form_id;
-- select count(*) as missing_venue_id from public.haccp_logs where venue_id is null;
-- select count(*) as missing_zone_id from public.haccp_logs where zone_id is null;
