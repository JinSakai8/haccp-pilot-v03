-- M08: venues settings columns + validation constraints
-- Date: 2026-02-24

begin;

alter table public.venues
  add column if not exists temp_interval integer;

alter table public.venues
  add column if not exists temp_threshold numeric(5,2);

-- Normalize legacy values before constraints.
update public.venues
set temp_interval = 15
where temp_interval is null
   or temp_interval not in (5, 15, 60);

update public.venues
set temp_threshold = 8.0
where temp_threshold is null
   or temp_threshold < 0
   or temp_threshold > 15;

update public.venues
set nip = nullif(regexp_replace(nip, '[^0-9]', '', 'g'), '')
where nip is not null;

update public.venues
set nip = null
where nip is not null
  and nip !~ '^[0-9]{10}$';

alter table public.venues
  alter column temp_interval set default 15;

alter table public.venues
  alter column temp_threshold set default 8.0;

alter table public.venues
  drop constraint if exists venues_temp_interval_check;
alter table public.venues
  add constraint venues_temp_interval_check
  check (temp_interval in (5, 15, 60));

alter table public.venues
  drop constraint if exists venues_temp_threshold_check;
alter table public.venues
  add constraint venues_temp_threshold_check
  check (temp_threshold >= 0 and temp_threshold <= 15);

alter table public.venues
  drop constraint if exists venues_nip_digits_check;
alter table public.venues
  add constraint venues_nip_digits_check
  check (nip is null or nip ~ '^[0-9]{10}$');

commit;
