-- M08: branding storage hardening (bucket + kiosk scoped policies)
-- Date: 2026-02-27

begin;

-- Ensure branding bucket exists and is publicly readable via public URL.
insert into storage.buckets (id, name, public)
values ('branding', 'branding', true)
on conflict (id) do update
set
  name = excluded.name,
  public = excluded.public;

drop policy if exists "branding_select_kiosk_scope" on storage.objects;
drop policy if exists "branding_insert_manager_owner_kiosk_scope" on storage.objects;
drop policy if exists "branding_update_manager_owner_kiosk_scope" on storage.objects;
drop policy if exists "branding_delete_manager_owner_kiosk_scope" on storage.objects;

-- Read path: authenticated users can read only objects from their kiosk venue folder.
create policy "branding_select_kiosk_scope"
  on storage.objects
  as permissive
  for select
  to authenticated
  using (
    bucket_id = 'branding'
    and exists (
      select 1
      from public.kiosk_sessions ks
      where ks.auth_user_id = auth.uid()
        and storage.objects.name like ('logos/' || ks.venue_id::text || '/%')
    )
  );

-- Write path: only manager/owner in active kiosk context, only into own venue folder.
create policy "branding_insert_manager_owner_kiosk_scope"
  on storage.objects
  as permissive
  for insert
  to authenticated
  with check (
    bucket_id = 'branding'
    and exists (
      select 1
      from public.kiosk_sessions ks
      join public.employees e on e.id = ks.employee_id
      where ks.auth_user_id = auth.uid()
        and e.is_active = true
        and e.role in ('manager', 'owner')
        and storage.objects.name like ('logos/' || ks.venue_id::text || '/%')
    )
  );

create policy "branding_update_manager_owner_kiosk_scope"
  on storage.objects
  as permissive
  for update
  to authenticated
  using (
    bucket_id = 'branding'
    and exists (
      select 1
      from public.kiosk_sessions ks
      join public.employees e on e.id = ks.employee_id
      where ks.auth_user_id = auth.uid()
        and e.is_active = true
        and e.role in ('manager', 'owner')
        and storage.objects.name like ('logos/' || ks.venue_id::text || '/%')
    )
  )
  with check (
    bucket_id = 'branding'
    and exists (
      select 1
      from public.kiosk_sessions ks
      join public.employees e on e.id = ks.employee_id
      where ks.auth_user_id = auth.uid()
        and e.is_active = true
        and e.role in ('manager', 'owner')
        and storage.objects.name like ('logos/' || ks.venue_id::text || '/%')
    )
  );

create policy "branding_delete_manager_owner_kiosk_scope"
  on storage.objects
  as permissive
  for delete
  to authenticated
  using (
    bucket_id = 'branding'
    and exists (
      select 1
      from public.kiosk_sessions ks
      join public.employees e on e.id = ks.employee_id
      where ks.auth_user_id = auth.uid()
        and e.is_active = true
        and e.role in ('manager', 'owner')
        and storage.objects.name like ('logos/' || ks.venue_id::text || '/%')
    )
  );

commit;
