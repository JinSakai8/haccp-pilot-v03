-- CCP2 hardening: generated_reports uniqueness + kiosk-scoped RLS
-- Date: 2026-02-26

begin;

alter table public.generated_reports enable row level security;

drop policy if exists "Enable insert for all" on public.generated_reports;
drop policy if exists "Enable read access for all" on public.generated_reports;
drop policy if exists "generated_reports_select_kiosk_scope" on public.generated_reports;
drop policy if exists "generated_reports_insert_kiosk_scope" on public.generated_reports;
drop policy if exists "generated_reports_update_kiosk_scope" on public.generated_reports;

create policy "generated_reports_select_kiosk_scope"
  on public.generated_reports
  as permissive
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.kiosk_sessions ks
      where ks.auth_user_id = auth.uid()
        and ks.venue_id = generated_reports.venue_id
    )
  );

create policy "generated_reports_insert_kiosk_scope"
  on public.generated_reports
  as permissive
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.kiosk_sessions ks
      where ks.auth_user_id = auth.uid()
        and ks.employee_id = generated_reports.created_by
        and ks.venue_id = generated_reports.venue_id
    )
  );

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
        and ks.employee_id = generated_reports.created_by
        and ks.venue_id = generated_reports.venue_id
    )
  )
  with check (
    exists (
      select 1
      from public.kiosk_sessions ks
      where ks.auth_user_id = auth.uid()
        and ks.employee_id = generated_reports.created_by
        and ks.venue_id = generated_reports.venue_id
    )
  );

create index if not exists generated_reports_venue_type_date_idx
  on public.generated_reports (venue_id, report_type, generation_date desc);

-- Keep only the newest report per (venue, type, generation_date) before
-- enforcing uniqueness.
with ranked as (
  select
    ctid,
    row_number() over (
      partition by venue_id, report_type, generation_date
      order by created_at desc, id desc
    ) as rn
  from public.generated_reports
)
delete from public.generated_reports g
using ranked r
where g.ctid = r.ctid
  and r.rn > 1;

create unique index if not exists generated_reports_unique_venue_type_date
  on public.generated_reports (venue_id, report_type, generation_date);

commit;
