-- Create table for storing generated PDF reports
create table if not exists public.generated_reports (
    id uuid not null default gen_random_uuid(),
    venue_id uuid references public.venues(id) on delete cascade,
    report_type text not null check (report_type in ('ccp3_cooling', 'waste_monthly', 'gmp_daily')),
    generation_date date not null, -- The date the report covers
    created_at timestamptz not null default now(),
    created_by uuid references public.employees(id), -- Changed from auth.users to public.employees
    storage_path text not null, -- Path in Supabase Storage
    metadata jsonb default '{}'::jsonb,
    
    primary key (id)
);

-- Enable RLS
alter table public.generated_reports enable row level security;

-- Policies (Simplified for Kiosk/Anon access, matching haccp_logs pattern)
create policy "Enable read access for all"
    on public.generated_reports for select
    to anon, authenticated
    using (true);

create policy "Enable insert for all"
    on public.generated_reports for insert
    to anon, authenticated
    with check (true);

-- Storage Bucket: 'reports'
insert into storage.buckets (id, name, public)
values ('reports', 'reports', false)
on conflict (id) do nothing;

-- Storage Policies for 'reports' bucket
-- Allow anonymouse/authenticated users to upload/read reports
create policy "Allow all uploads to reports"
on storage.objects for insert
to anon, authenticated
with check ( bucket_id = 'reports' );

create policy "Allow all reads from reports"
on storage.objects for select
to anon, authenticated
using ( bucket_id = 'reports' );
