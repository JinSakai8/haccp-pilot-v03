-- Sprint 5 hotfix: backfill employees.venue_id and improve kiosk context errors
-- Date: 2026-02-22

begin;

-- 1) Backfill employee venue_id from assigned zones when mapping is unambiguous.
with inferred_employee_venue as (
  select
    ez.employee_id,
    (array_agg(distinct z.venue_id))[1] as inferred_venue_id
  from public.employee_zones ez
  join public.zones z on z.id = ez.zone_id
  where z.venue_id is not null
  group by ez.employee_id
  having count(distinct z.venue_id) = 1
)
update public.employees e
set
  venue_id = iev.inferred_venue_id,
  updated_at = now()
from inferred_employee_venue iev
where e.id = iev.employee_id
  and e.venue_id is null;

-- 2) Improve guardrails in set_kiosk_context for clearer operational diagnosis.
create or replace function public.set_kiosk_context(
  employee_id_input uuid,
  zone_id_input uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_uid uuid;
  v_venue_id uuid;
  v_is_active boolean;
  v_zone_is_valid boolean;
begin
  v_auth_uid := auth.uid();
  if v_auth_uid is null then
    raise exception 'auth.uid() is null';
  end if;

  select e.venue_id, e.is_active
    into v_venue_id, v_is_active
  from public.employees e
  where e.id = employee_id_input;

  if not found then
    raise exception 'employee is missing';
  end if;

  if coalesce(v_is_active, false) = false then
    raise exception 'employee is inactive';
  end if;

  if v_venue_id is null then
    raise exception 'employee has no venue assignment';
  end if;

  if zone_id_input is not null then
    select exists (
      select 1
      from public.zones z
      join public.employee_zones ez on ez.zone_id = z.id
      where z.id = zone_id_input
        and z.venue_id = v_venue_id
        and ez.employee_id = employee_id_input
    ) into v_zone_is_valid;

    if coalesce(v_zone_is_valid, false) = false then
      raise exception 'zone is invalid for employee/venue';
    end if;
  end if;

  insert into public.kiosk_sessions (
    auth_user_id,
    employee_id,
    venue_id,
    zone_id,
    created_at,
    updated_at
  )
  values (
    v_auth_uid,
    employee_id_input,
    v_venue_id,
    zone_id_input,
    now(),
    now()
  )
  on conflict (auth_user_id) do update
    set employee_id = excluded.employee_id,
        venue_id = excluded.venue_id,
        zone_id = excluded.zone_id,
        updated_at = now();
end;
$$;

grant execute on function public.set_kiosk_context(uuid, uuid) to authenticated, service_role;

commit;
