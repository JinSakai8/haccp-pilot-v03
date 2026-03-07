-- M02: 7-day table + temperature edit hardening
-- Date: 2026-02-23

begin;

-- 1) Schema extensions for edit metadata.
alter table public.temperature_logs
  add column if not exists edited_at timestamptz;

alter table public.temperature_logs
  add column if not exists edited_by uuid references public.employees(id);

alter table public.temperature_logs
  add column if not exists edit_reason text;

-- 2) Index for table view by sensor + time.
create index if not exists temperature_logs_sensor_recorded_at_desc_idx
  on public.temperature_logs (sensor_id, recorded_at desc);

-- 3) Replace overly-permissive policies.
drop policy if exists "Enable insert access for authenticated users" on public.temperature_logs;
drop policy if exists "Logs readable by all" on public.temperature_logs;
drop policy if exists "Logs updateable by all" on public.temperature_logs;

create policy "temperature_logs_select_kiosk_scope"
  on public.temperature_logs
  as permissive
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.kiosk_sessions ks
      join public.sensors s on s.id = temperature_logs.sensor_id
      join public.zones z on z.id = s.zone_id
      where ks.auth_user_id = auth.uid()
        and z.venue_id = ks.venue_id
        and (ks.zone_id is null or s.zone_id = ks.zone_id)
    )
  );

create policy "temperature_logs_insert_kiosk_scope"
  on public.temperature_logs
  as permissive
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.kiosk_sessions ks
      join public.sensors s on s.id = temperature_logs.sensor_id
      join public.zones z on z.id = s.zone_id
      where ks.auth_user_id = auth.uid()
        and z.venue_id = ks.venue_id
        and (ks.zone_id is null or s.zone_id = ks.zone_id)
    )
  );

-- 4) RPC: scoped edit for manager/owner only and 7-day window.
create or replace function public.update_temperature_log_value(
  log_id_input uuid,
  new_temperature_input numeric,
  edit_reason_input text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_uid uuid;
  v_employee_id uuid;
  v_role public.user_role;
  v_venue_id uuid;
  v_zone_id uuid;
  v_recorded_at timestamptz;
begin
  v_auth_uid := auth.uid();
  if v_auth_uid is null then
    raise exception 'auth.uid() is null';
  end if;

  select ks.employee_id, e.role, ks.venue_id, ks.zone_id
    into v_employee_id, v_role, v_venue_id, v_zone_id
  from public.kiosk_sessions ks
  join public.employees e on e.id = ks.employee_id
  where ks.auth_user_id = v_auth_uid;

  if v_employee_id is null then
    raise exception 'kiosk session missing';
  end if;

  if v_role not in ('manager', 'owner') then
    raise exception 'insufficient role';
  end if;

  if new_temperature_input is null
     or new_temperature_input < -50
     or new_temperature_input > 150 then
    raise exception 'temperature out of range';
  end if;

  select tl.recorded_at
    into v_recorded_at
  from public.temperature_logs tl
  join public.sensors s on s.id = tl.sensor_id
  join public.zones z on z.id = s.zone_id
  where tl.id = log_id_input
    and z.venue_id = v_venue_id
    and (v_zone_id is null or s.zone_id = v_zone_id);

  if v_recorded_at is null then
    raise exception 'temperature log not in kiosk scope';
  end if;

  if v_recorded_at < now() - interval '7 days' then
    raise exception 'edit window exceeded';
  end if;

  update public.temperature_logs
  set temperature_celsius = round(new_temperature_input, 2),
      edited_by = v_employee_id,
      edited_at = now(),
      edit_reason = nullif(btrim(edit_reason_input), '')
  where id = log_id_input;
end;
$$;

grant execute on function public.update_temperature_log_value(uuid, numeric, text)
  to authenticated, service_role;

-- 5) RPC: keep alarm acknowledge without direct table update from client.
create or replace function public.acknowledge_temperature_alert(
  log_id_input uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_uid uuid;
  v_employee_id uuid;
  v_venue_id uuid;
  v_zone_id uuid;
begin
  v_auth_uid := auth.uid();
  if v_auth_uid is null then
    raise exception 'auth.uid() is null';
  end if;

  select ks.employee_id, ks.venue_id, ks.zone_id
    into v_employee_id, v_venue_id, v_zone_id
  from public.kiosk_sessions ks
  where ks.auth_user_id = v_auth_uid;

  if v_employee_id is null then
    raise exception 'kiosk session missing';
  end if;

  if not exists (
    select 1
    from public.temperature_logs tl
    join public.sensors s on s.id = tl.sensor_id
    join public.zones z on z.id = s.zone_id
    where tl.id = log_id_input
      and z.venue_id = v_venue_id
      and (v_zone_id is null or s.zone_id = v_zone_id)
  ) then
    raise exception 'temperature log not in kiosk scope';
  end if;

  update public.temperature_logs
  set is_acknowledged = true,
      acknowledged_by = v_employee_id,
      acknowledged_at = now()
  where id = log_id_input;
end;
$$;

grant execute on function public.acknowledge_temperature_alert(uuid)
  to authenticated, service_role;

commit;
