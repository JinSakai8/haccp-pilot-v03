-- M02: Alarm panel read model RPC
-- Date: 2026-02-23

begin;

create or replace function public.get_temperature_alarms(
  zone_id_input uuid,
  active_only_input boolean,
  limit_input integer default 100,
  offset_input integer default 0
)
returns table (
  log_id uuid,
  sensor_id uuid,
  sensor_name text,
  temperature numeric,
  started_at timestamptz,
  last_seen_at timestamptz,
  duration_minutes integer,
  is_acknowledged boolean,
  acknowledged_at timestamptz,
  acknowledged_by uuid
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_uid uuid;
  v_venue_id uuid;
  v_zone_id uuid;
begin
  v_auth_uid := auth.uid();
  if v_auth_uid is null then
    raise exception 'auth.uid() is null';
  end if;

  select ks.venue_id, ks.zone_id
    into v_venue_id, v_zone_id
  from public.kiosk_sessions ks
  where ks.auth_user_id = v_auth_uid;

  if v_venue_id is null then
    raise exception 'kiosk session missing';
  end if;

  return query
  select
    tl.id as log_id,
    s.id as sensor_id,
    s.name as sensor_name,
    tl.temperature_celsius::numeric as temperature,
    tl.recorded_at as started_at,
    tl.recorded_at as last_seen_at,
    greatest(
      0,
      floor(
        extract(
          epoch from (
            coalesce(tl.acknowledged_at, now()) - tl.recorded_at
          )
        ) / 60
      )::integer
    ) as duration_minutes,
    coalesce(tl.is_acknowledged, false) as is_acknowledged,
    tl.acknowledged_at,
    tl.acknowledged_by
  from public.temperature_logs tl
  join public.sensors s on s.id = tl.sensor_id
  join public.zones z on z.id = s.zone_id
  where z.venue_id = v_venue_id
    and (v_zone_id is null or s.zone_id = v_zone_id)
    and (zone_id_input is null or s.zone_id = zone_id_input)
    and tl.is_alert = true
    and (
      (active_only_input = true and coalesce(tl.is_acknowledged, false) = false)
      or
      (active_only_input = false and coalesce(tl.is_acknowledged, false) = true)
    )
  order by tl.recorded_at desc
  limit greatest(coalesce(limit_input, 100), 1)
  offset greatest(coalesce(offset_input, 0), 0);
end;
$$;

grant execute on function public.get_temperature_alarms(uuid, boolean, integer, integer)
  to authenticated, service_role;

create index if not exists temperature_logs_alerts_sensor_recorded_desc_idx
  on public.temperature_logs (sensor_id, recorded_at desc)
  where is_alert = true;

commit;
