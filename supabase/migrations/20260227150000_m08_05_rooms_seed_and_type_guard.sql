-- M08/M04 integration: add rooms dictionary entries and optional type check support.
-- Date: 2026-02-27

begin;

-- If an explicit type check exists in some environments, extend it with `rooms`.
do $$
begin
  if exists (
    select 1
    from pg_constraint
    where conname = 'products_type_check'
      and conrelid = 'public.products'::regclass
  ) then
    alter table public.products drop constraint products_type_check;
  end if;

  alter table public.products
    add constraint products_type_check
    check (type in ('cooling', 'roasting', 'general', 'rooms'));
exception
  when duplicate_object then null;
end $$;

insert into public.products (name, type, venue_id)
values
  ('kuchnia', 'rooms', null),
  ('myjnia', 'rooms', null),
  ('pomieszczenie do obierania warzyw', 'rooms', null),
  ('bar', 'rooms', null)
on conflict (name, venue_id) do nothing;

commit;
