-- Sprint 3 (Efento): mapping hygiene + quality guardrails
-- Date: 2026-03-06
-- Scope:
-- 1) Sanitize unsafe measurement_point_name values.
-- 2) Add write-time hygiene constraint to block URL/secret-like patterns.

begin;

do $$
declare
  v_sanitized_rows integer := 0;
begin
  update public.efento_measurement_point_map m
  set
    measurement_point_name = 'Efento MP ' || m.measurement_point_id::text,
    updated_at = now()
  where
    m.measurement_point_name is null
    or btrim(m.measurement_point_name) = ''
    or m.measurement_point_name ~* '(https?://|secret\s*=|x-haccp|bearer)';

  get diagnostics v_sanitized_rows = row_count;

  raise notice
    'Efento map hygiene: sanitized rows=% (null/blank/url/secret-like names replaced with fallback).',
    v_sanitized_rows;
end;
$$;

alter table public.efento_measurement_point_map
  drop constraint if exists efento_map_measurement_point_name_hygiene_check;

alter table public.efento_measurement_point_map
  add constraint efento_map_measurement_point_name_hygiene_check
  check (
    measurement_point_name is null
    or (
      btrim(measurement_point_name) <> ''
      and measurement_point_name !~* '(https?://|secret\s*=|x-haccp|bearer)'
    )
  ) not valid;

alter table public.efento_measurement_point_map
  validate constraint efento_map_measurement_point_name_hygiene_check;

commit;

