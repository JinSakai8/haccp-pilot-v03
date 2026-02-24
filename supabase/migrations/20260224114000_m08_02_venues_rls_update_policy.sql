-- M08: venues RLS scoped to kiosk context + manager/owner update
-- Date: 2026-02-24

begin;

alter table public.venues enable row level security;

drop policy if exists "Enable read access for authenticated users" on public.venues;
drop policy if exists "venues_select_kiosk_scope" on public.venues;
drop policy if exists "venues_update_manager_owner_kiosk_scope" on public.venues;

create policy "venues_select_kiosk_scope"
  on public.venues
  as permissive
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.kiosk_sessions ks
      where ks.auth_user_id = auth.uid()
        and ks.venue_id = venues.id
    )
  );

create policy "venues_update_manager_owner_kiosk_scope"
  on public.venues
  as permissive
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.kiosk_sessions ks
      join public.employees e on e.id = ks.employee_id
      where ks.auth_user_id = auth.uid()
        and ks.venue_id = venues.id
        and e.is_active = true
        and e.role in ('manager', 'owner')
    )
  )
  with check (
    exists (
      select 1
      from public.kiosk_sessions ks
      join public.employees e on e.id = ks.employee_id
      where ks.auth_user_id = auth.uid()
        and ks.venue_id = venues.id
        and e.is_active = true
        and e.role in ('manager', 'owner')
    )
  );

commit;
