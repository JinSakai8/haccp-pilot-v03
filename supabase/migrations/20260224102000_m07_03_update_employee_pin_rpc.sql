begin;

create or replace function public.update_employee_pin(
  employee_id uuid,
  new_pin_hash text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if new_pin_hash is null or btrim(new_pin_hash) = '' then
    raise exception 'M07_PIN_REQUIRED';
  end if;

  if exists (
    select 1
    from public.employees e
    where e.pin_hash = new_pin_hash
      and e.id <> employee_id
  ) then
    raise exception 'M07_PIN_DUPLICATE';
  end if;

  update public.employees e
  set pin_hash = new_pin_hash,
      updated_at = now()
  where e.id = employee_id;

  if not found then
    raise exception 'M07_EMPLOYEE_NOT_FOUND';
  end if;
end;
$$;

grant execute on function public.update_employee_pin(uuid, text)
  to anon, authenticated, service_role;

commit;
