-- Sprint 3 hardening: haccp_logs RLS + indexes + constraints (kiosk-aware)
-- Date: 2026-02-22

begin;

-- 1) Kiosk context table (maps current auth user -> employee + venue + zone)
create table if not exists public.kiosk_sessions (
  auth_user_id uuid primary key,
  employee_id uuid not null references public.employees(id) on delete cascade,
  venue_id uuid not null references public.venues(id) on delete cascade,
  zone_id uuid references public.zones(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.kiosk_sessions enable row level security;

drop policy if exists "kiosk_sessions_self_select" on public.kiosk_sessions;
create policy "kiosk_sessions_self_select"
  on public.kiosk_sessions
  as permissive
  for select
  to authenticated
  using (auth_user_id = auth.uid());

drop policy if exists "kiosk_sessions_self_modify" on public.kiosk_sessions;
create policy "kiosk_sessions_self_modify"
  on public.kiosk_sessions
  as permissive
  for all
  to authenticated
  using (auth_user_id = auth.uid())
  with check (auth_user_id = auth.uid());

-- 2) RPCs for kiosk context lifecycle
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
  v_zone_is_valid boolean;
begin
  v_auth_uid := auth.uid();
  if v_auth_uid is null then
    raise exception 'auth.uid() is null';
  end if;

  select e.venue_id
    into v_venue_id
  from public.employees e
  where e.id = employee_id_input
    and e.is_active = true;

  if v_venue_id is null then
    raise exception 'employee is missing or inactive';
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

  insert into public.kiosk_sessions (auth_user_id, employee_id, venue_id, zone_id, created_at, updated_at)
  values (v_auth_uid, employee_id_input, v_venue_id, zone_id_input, now(), now())
  on conflict (auth_user_id) do update
    set employee_id = excluded.employee_id,
        venue_id = excluded.venue_id,
        zone_id = excluded.zone_id,
        updated_at = now();
end;
$$;

grant execute on function public.set_kiosk_context(uuid, uuid) to authenticated, service_role;

create or replace function public.clear_kiosk_context()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.kiosk_sessions where auth_user_id = auth.uid();
end;
$$;

grant execute on function public.clear_kiosk_context() to authenticated, service_role;

-- 3) haccp_logs query indexes
create index if not exists haccp_logs_category_form_created_at_idx
  on public.haccp_logs (category, form_id, created_at);

create index if not exists haccp_logs_zone_created_at_idx
  on public.haccp_logs (zone_id, created_at);

create index if not exists haccp_logs_venue_created_at_idx
  on public.haccp_logs (venue_id, created_at);

-- 4) haccp_logs constraints
alter table public.haccp_logs
  drop constraint if exists haccp_logs_category_check;
alter table public.haccp_logs
  add constraint haccp_logs_category_check
  check (category in ('gmp', 'ghp')) not valid;

alter table public.haccp_logs
  drop constraint if exists haccp_logs_form_id_check;
alter table public.haccp_logs
  add constraint haccp_logs_form_id_check
  check (
    (category = 'gmp' and form_id in (
      'food_cooling',
      'meat_roasting',
      'delivery_control',
      'meat_roasting_daily',
      'delivery_control_daily'
    ))
    or
    (category = 'ghp' and form_id in (
      'personnel',
      'rooms',
      'maintenance',
      'chemicals'
    ))
  ) not valid;

-- 5) haccp_logs RLS hardening
-- Remove pilot-mode permissive policies.
drop policy if exists "Enable insert access for authenticated users" on public.haccp_logs;
drop policy if exists "Enable read access for authenticated users" on public.haccp_logs;

create policy "haccp_logs_select_kiosk_scope"
  on public.haccp_logs
  as permissive
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.kiosk_sessions ks
      where ks.auth_user_id = auth.uid()
        and ks.venue_id = haccp_logs.venue_id
        and (ks.zone_id is null or haccp_logs.zone_id = ks.zone_id)
    )
  );

create policy "haccp_logs_insert_kiosk_scope"
  on public.haccp_logs
  as permissive
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.kiosk_sessions ks
      where ks.auth_user_id = auth.uid()
        and ks.employee_id = haccp_logs.user_id
        and ks.venue_id = haccp_logs.venue_id
        and (ks.zone_id is null or haccp_logs.zone_id = ks.zone_id)
    )
  );

commit;
