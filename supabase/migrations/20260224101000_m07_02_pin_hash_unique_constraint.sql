begin;

do $$
begin
  if exists (
    select 1
    from public.employees e
    group by e.pin_hash
    having count(*) > 1
  ) then
    raise exception 'M07_PIN_DUPLICATES_EXIST';
  end if;
end
$$;

create unique index if not exists employees_pin_hash_unique_idx
  on public.employees (pin_hash);

commit;
