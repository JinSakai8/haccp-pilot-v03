-- M08: products RLS hardening (kiosk scope + manager/owner writes)
-- Date: 2026-02-24

begin;

alter table public.products enable row level security;

drop policy if exists "Allow public read access" on public.products;
drop policy if exists "Enable read access for all" on public.products;
drop policy if exists "products_select_kiosk_scope" on public.products;
drop policy if exists "products_insert_manager_owner_kiosk_scope" on public.products;
drop policy if exists "products_update_manager_owner_kiosk_scope" on public.products;
drop policy if exists "products_delete_manager_owner_kiosk_scope" on public.products;

-- Read path: global products (venue_id is null) + local products from kiosk venue.
create policy "products_select_kiosk_scope"
  on public.products
  as permissive
  for select
  to authenticated
  using (
    products.venue_id is null
    or exists (
      select 1
      from public.kiosk_sessions ks
      where ks.auth_user_id = auth.uid()
        and ks.venue_id = products.venue_id
    )
  );

-- Write path: only manager/owner and only within kiosk venue (not global rows).
create policy "products_insert_manager_owner_kiosk_scope"
  on public.products
  as permissive
  for insert
  to authenticated
  with check (
    products.venue_id is not null
    and exists (
      select 1
      from public.kiosk_sessions ks
      join public.employees e on e.id = ks.employee_id
      where ks.auth_user_id = auth.uid()
        and ks.venue_id = products.venue_id
        and e.is_active = true
        and e.role in ('manager', 'owner')
    )
  );

create policy "products_update_manager_owner_kiosk_scope"
  on public.products
  as permissive
  for update
  to authenticated
  using (
    products.venue_id is not null
    and exists (
      select 1
      from public.kiosk_sessions ks
      join public.employees e on e.id = ks.employee_id
      where ks.auth_user_id = auth.uid()
        and ks.venue_id = products.venue_id
        and e.is_active = true
        and e.role in ('manager', 'owner')
    )
  )
  with check (
    products.venue_id is not null
    and exists (
      select 1
      from public.kiosk_sessions ks
      join public.employees e on e.id = ks.employee_id
      where ks.auth_user_id = auth.uid()
        and ks.venue_id = products.venue_id
        and e.is_active = true
        and e.role in ('manager', 'owner')
    )
  );

create policy "products_delete_manager_owner_kiosk_scope"
  on public.products
  as permissive
  for delete
  to authenticated
  using (
    products.venue_id is not null
    and exists (
      select 1
      from public.kiosk_sessions ks
      join public.employees e on e.id = ks.employee_id
      where ks.auth_user_id = auth.uid()
        and ks.venue_id = products.venue_id
        and e.is_active = true
        and e.role in ('manager', 'owner')
    )
  );

commit;
