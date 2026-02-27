begin;

create or replace function public.create_employee(
  name_input text,
  pin_hash_input text,
  role_input text,
  sanepid_input timestamptz,
  zone_ids_input uuid[],
  is_active_input boolean default true
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id uuid;
  derived_venue_id uuid;
  requested_zone_count int;
  found_zone_count int;
  venue_count int;
begin
  requested_zone_count := coalesce(array_length(zone_ids_input, 1), 0);
  if requested_zone_count = 0 then
    raise exception 'M07_ZONE_REQUIRED';
  end if;

  if pin_hash_input is null or btrim(pin_hash_input) = '' then
    raise exception 'M07_PIN_REQUIRED';
  end if;

  select count(*)
    into found_zone_count
  from public.zones z
  where z.id = any(zone_ids_input);

  if found_zone_count <> requested_zone_count then
    raise exception 'M07_ZONE_NOT_FOUND';
  end if;

  select count(distinct z.venue_id), min(z.venue_id)
    into venue_count, derived_venue_id
  from public.zones z
  where z.id = any(zone_ids_input);

  if venue_count <> 1 or derived_venue_id is null then
    raise exception 'M07_ZONE_MULTI_VENUE';
  end if;

  if exists (
    select 1
    from public.employees e
    where e.pin_hash = pin_hash_input
  ) then
    raise exception 'M07_PIN_DUPLICATE';
  end if;

  insert into public.employees (
    full_name,
    pin_hash,
    role,
    sanepid_expiry,
    is_active,
    venue_id,
    updated_at
  )
  values (
    name_input,
    pin_hash_input,
    role_input::public.user_role,
    sanepid_input::date,
    is_active_input,
    derived_venue_id,
    now()
  )
  returning id into new_id;

  insert into public.employee_zones (employee_id, zone_id)
  select new_id, unnest(zone_ids_input)
  on conflict do nothing;

  return new_id;
end;
$$;

grant execute on function public.create_employee(text, text, text, timestamptz, uuid[], boolean)
  to anon, authenticated, service_role;

commit;
