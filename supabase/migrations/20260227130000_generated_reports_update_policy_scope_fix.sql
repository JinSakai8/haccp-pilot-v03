-- M06/M06+CCP2 follow-up:
-- Allow upsert UPDATE on generated_reports within kiosk venue scope,
-- even if created_by belongs to a different employee in the same venue.
-- INSERT policy remains strict and unchanged.

begin;

drop policy if exists "generated_reports_update_kiosk_scope" on public.generated_reports;

create policy "generated_reports_update_kiosk_scope"
  on public.generated_reports
  as permissive
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.kiosk_sessions ks
      where ks.auth_user_id = auth.uid()
        and ks.venue_id = generated_reports.venue_id
    )
  )
  with check (
    exists (
      select 1
      from public.kiosk_sessions ks
      where ks.auth_user_id = auth.uid()
        and ks.venue_id = generated_reports.venue_id
    )
  );

commit;
